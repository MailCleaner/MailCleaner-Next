#!/usr/bin/env perl
#
#   Mailcleaner - SMTP Antivirus/Antispam Gateway
#   Copyright (C) 2004 Olivier Diserens <olivier@diserens.ch>
#   Copyright (C) 2023 John Mertz <git@john.me.tz>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
#   Commtouch prefilter module for MailScanner (Custom version for MailCleaner)

package MailScanner::Commtouch;

use v5.36;
use strict;
use warnings;
use utf8;

use IO;
use POSIX qw(:signal_h); # For Solaris 9 SIG bug workaround
use LWP::UserAgent;
use HTTP::Request::Common;

my $MODULE = "Commtouch";
my %conf;
my $lwp;

sub initialise
{
    MailScanner::Log::InfoLog("$MODULE module initializing...");

    my $confdir = MailScanner::Config::Value('prefilterconfigurations');
    my $configfile = $confdir."/$MODULE.cf";
    %Commtouch::conf = (
        header => "X-$MODULE",
        putHamHeader => 0,
        putSpamHeader => 1,
        maxSize => 0,
        active => 1,
        timeOut => 10,
        lwp => null,
        use_ctaspd => 1,
        ctaspd_server_host => 'localhost',
        ctaspd_server_port => 8088,
        detect_spam_bulk => 1,
        detect_spam_suspected => 0,
        detect_vod_high => 1,
        detect_vod_medium => 0,
        use_ctipd => 1,
        ctipd_server_host => 'localhost',
        ctipd_server_port => 8086,
        ctipd_blocktempfail => 0,
        decisive_field => 'none',
        pos_text => '',
        neg_text => '',
        pos_decisive => 0,
        neg_decisive => 0,
        position => 0
    );

    if (open(my $CONFIG, '<', $configfile)) {
        while (<$CONFIG>) {
            if (/^(\S+)\s*\=\s*(.*)$/) {
                $Commtouch::conf{$1} = $2;
            }
        }
        close $CONFIG;
    } else {
        MailScanner::Log::WarnLog("$MODULE configuration file ($configfile) could not be found !");
    }
    $Commtouch::lwp = LWP::UserAgent->new();

    if ($Commtouch::conf{'pos_decisive'} && ($Commtouch::conf{'decisive_field'} eq 'pos_decisive' || $Commtouch::conf{'decisive_field'} eq 'both')) {
        $Commtouch::conf{'pos_text'} = 'position : '.$Commtouch::conf{'position'}.', spam decisive';
    } else {
        $Commtouch::conf{'pos_text'} = 'position : '.$Commtouch::conf{'position'}.', not decisive';
    }
    if ($Commtouch::conf{'neg_decisive'} && ($Commtouch::conf{'decisive_field'} eq 'neg_decisive' || $Commtouch::conf{'decisive_field'} eq 'both')) {
        $Commtouch::conf{'neg_text'} = 'position : '.$Commtouch::conf{'position'}.', ham decisive';
    } else {
        $Commtouch::conf{'neg_text'} = 'position : '.$Commtouch::conf{'position'}.', not decisive';
    }
}

sub Checks($self,$message)
{
    my $maxsize = $Commtouch::conf{'maxSize'};
    if ($maxsize > 0 && $message->{size} > $maxsize) {
        MailScanner::Log::InfoLog(
            "Message %s is too big for Commtouch checks (%d > %d bytes)",
            $message->{id}, $message->{size}, $maxsize
        );
        $global::MS->{mta}->AddHeaderToOriginal(
            $message, $Commtouch::conf{'header'}, "too big (".$message->{size}." > $maxsize)"
        );
        return 0;
    }

    if ($Commtouch::conf{'active'} < 1) {
        MailScanner::Log::WarnLog("$MODULE has been disabled");
        $global::MS->{mta}->AddHeaderToOriginal($message, $Commtouch::conf{'header'}, "disabled");
        return 0;
    }

    ### check against ctipd
    my $ctipd_header = '';
    if ($Commtouch::conf{'use_ctipd'}) {
        my $client_ip = $message->{clientip};

        my $url = "http://".$Commtouch::conf{'ctipd_server_host'}.":".$Commtouch::conf{'ctipd_server_port'}."/ctipd/iprep";

        my $request = "x-ctch-request-type: classifyip\r\nx-ctch-pver: 1.0\r\n\r\nx-ctch-ip: $client_ip\r\n";

        my $tim = $Commtouch::conf{'timeOut'};
        use Mail::SpamAssassin::Timeout;
        my $t = Mail::SpamAssassin::Timeout->new({ secs => $tim });
        my $response = "";

        $t->run(sub {
            ## do the job...
            $response = $Commtouch::lwp->request(POST $url, Content => $request);
        });
        if ($t->timed_out()) {
            MailScanner::Log::InfoLog("$MODULE ctipd timed out for ".$message->{id}."!");
            $global::MS->{mta}->AddHeaderToOriginal($message, $Commtouch::conf{'header'}, 'ctipd timeout');
        } else {

            my $status_line = $response->status_line . "\n";
            chomp $status_line;

            ### parse results:
            my $status = -1; # unknown
            my $status_message = '';

            if ($status_line =~ m/^(\d+)\s+(.*)/) {
                $status = $1;
                $status_message = $2;
            }

            my $res = $response->content;
            if ($status != 200 || $res eq '') {
                MailScanner::Log::InfoLog("$MODULE ctipd returned error: ".$status." ".$status_message." for ".$message->{id});
                $global::MS->{mta}->AddHeaderToOriginal($message, $Commtouch::conf{'header'}, "$MODULE ctipd returned error: ".$status." ".$status_message);
            } else {

                my $refid = '';
                my $action_result = '';

                my @res_lines = split('\n', $res);
                foreach my $line (@res_lines) {
                    if ($line =~ m/^X-CTCH-RefID:\s*(.*)/i) {
                        $refid = $1;
                    }
                    if ($line =~m/^x-ctch-dm-action:\s*(.*)/i) {
                        $action_result = $1;
                    }
                }
                $refid =~ s/[\n\r]+//;
                $action_result =~ s/[\n\r]+//;
                $global::MS->{mta}->AddHeaderToOriginal($message, $Commtouch::conf{'header'}."-ctIPd-RefID", $refid);

                if ($action_result eq 'permfail' || ($action_result eq 'tempfail' && $Commtouch::conf{'ctipd_blocktempfail'})) {
                    MailScanner::Log::InfoLog("$MODULE result is spam (ip: $action_result) for ".$message->{id});
                    if ($Commtouch::conf{'putSpamHeader'}) {
                        $global::MS->{mta}->AddHeaderToOriginal($message, $Commtouch::conf{'header'}, "is spam (ip: $action_result, ".$Commtouch::conf{pos_text} .")");
                    }
                    $message->{prefilterreport} .= ", $MODULE (ip: $action_result, ".$Commtouch::conf{pos_text} .")";
                    return 1;
                } elsif ($action_result eq 'tempfail') {
                    $ctipd_header = "ip: $action_result";
                }
            }
        }
    }

    if ($ctipd_header ne '') {
        $ctipd_header .= ', ';
    }
### check against ctaspd
    if ($Commtouch::conf{'use_ctaspd'}) {
        my (@WholeMessage, $maxsize);
        push(@WholeMessage, $global::MS->{mta}->OriginalMsgHeaders($message, "\n"));
        push(@WholeMessage, "\n");
        $message->{store}->ReadBody(\@WholeMessage, 0);

        my $tim = $Commtouch::conf{'timeOut'};
        use Mail::SpamAssassin::Timeout;
        my $t = Mail::SpamAssassin::Timeout->new({ secs => $tim });
        my $is_prespam = 0;
        my $ret = -5;
        my $response = "";

        my $request = "X-CTCH-PVer: 0000001\r\nX-CTCH-MailFrom: $message->{from}\r\nX-CTCH-SenderIP: $message->{clientip}\r\n\r\n";

        foreach my $line (@WholeMessage) {
            $request .= $line;
        }
        my $url = "http://".$Commtouch::conf{'ctaspd_server_host'}.":".$Commtouch::conf{'ctaspd_server_port'}."/ctasd/ClassifyMessage_Inline";

        $t->run(sub {
            ## do the job...
            $response = $Commtouch::lwp->request(POST $url, Content => $request);
        });

        if ($t->timed_out()) {
            MailScanner::Log::InfoLog("$MODULE ctaspd timed out for ".$message->{id}."!");
            $global::MS->{mta}->AddHeaderToOriginal($message, $Commtouch::conf{'header'}, 'ctaspd timeout');
            return 0;
        }
        $ret = -1;
        my $score = 0;

        my $status_line = $response->status_line . "\n";
        chomp $status_line;

        my $res = $response->content;

        ### parse results:
        my $status = -1; # unknown
        my $status_message = '';

        if ($status_line =~ m/^(\d+)\s+(.*)/) {
            $status = $1;
            $status_message = $2;
        }

        if ($status != 200 || $res eq '') {
            MailScanner::Log::InfoLog("$MODULE ctaspd returned error: ".$status." ".$status_message." for ".$message->{id});
            $global::MS->{mta}->AddHeaderToOriginal($message, $Commtouch::conf{'header'}, "$MODULE ctaspd returned error: ".$status." ".$status_message);
            return 0;
        }

        my $spam_result = '';
        my $vod_result = '';
        my $refid = '';

        my @res_lines = split('\n', $res);
        foreach my $line (@res_lines) {
            if ($line =~ m/^X-CTCH-RefID:\s+(.*)/i) {
                $refid = $1;
            }
            if ($line =~m/^X-CTCH-Spam:\s+(.*)/i) {
                $spam_result = $1;
            }
            if ($line =~m/^X-CTCH-VOD:\s+(.*)/i) {
                $vod_result = $1;
                $vod_result = 'Medium';
            }
        }
        $refid =~ s/[\n\r]+//;
        $spam_result =~ s/[\n\r]+//;
        $vod_result =~ s/[\n\r]+//;

        if ($refid eq '') {
            MailScanner::Log::InfoLog("$MODULE ctaspd cannot get RefID for ".$message->{id});
            $global::MS->{mta}->AddHeaderToOriginal($message, $Commtouch::conf{'header'}, "$MODULE ctaspd cannot get RefID");
            return 0;
        }
        $global::MS->{mta}->AddHeaderToOriginal($message, $Commtouch::conf{'header'}."-ctasd-RefID", $refid);


        ## find out spam and VOD positives
        if (
            $spam_result eq 'Confirmed' ||
            ( $spam_result eq 'Bulk' && $Commtouch::conf{'detect_spam_bulk'}) ||
            ( $spam_result eq 'Suspected' && $Commtouch::conf{'detect_spam_suspected'})
        ) {
            MailScanner::Log::InfoLog("$MODULE result is spam (".$ctipd_header."Spam: $spam_result) for ".$message->{id});
            if ($Commtouch::conf{'putSpamHeader'}) {
                $global::MS->{mta}->AddHeaderToOriginal($message, $Commtouch::conf{'header'}, "is spam (".$ctipd_header."Spam: $spam_result, ".$Commtouch::conf{pos_text}. ")");
            }
            $message->{prefilterreport} .= ", $MODULE ($ctipd_header Spam: $spam_result, ".$Commtouch::conf{pos_text}. ")");

            return 1;
        }

        if ($vod_result eq 'Virus' ||
            ($vod_result eq 'High' && $Commtouch::conf{'detect_vod_high'}) ||
            ($vod_result eq 'Medium' && $Commtouch::conf{'detect_vod_medium'})
        ) {
            MailScanner::Log::InfoLog("$MODULE result is spam (".$ctipd_header."VOD: $vod_result) for ".$message->{id});
            if ($Commtouch::conf{'putSpamHeader'}) {
                $global::MS->{mta}->AddHeaderToOriginal($message, $Commtouch::conf{'header'}, "is spam (".$ctipd_header."VOD: $vod_result, ".$Commtouch::conf{pos_text}. ")");
            }
            $message->{prefilterreport} .= ", $MODULE ($ctipd_header VOD: $vod_result, ".$Commtouch::conf{pos_text}. ")");

            return 1;
        }

        MailScanner::Log::InfoLog("$MODULE result is not spam (".$ctipd_header."Spam: $spam_result, VOD: $vod_result) for ".$message->{id});
        if ($Commtouch::conf{'putHamHeader'}) {
            $global::MS->{mta}->AddHeaderToOriginal($message, $Commtouch::conf{'header'}, "is not spam (".$ctipd_header."Spam: $spam_result, VOD: $vod_result," .$Commtouch::conf{'neg_text'}. ")");
        }
        $message->{prefilterreport} .= ", $MODULE ($ctipd_header VOD: $vod_result, " .$Commtouch::conf{'neg_text'}. ")";

        return 0;
    }

}

sub dispose
{
    MailScanner::Log::InfoLog("$MODULE module disposing...");
}

1;
