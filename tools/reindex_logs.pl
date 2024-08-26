#!/usr/bin/env perl

#   Mailcleaner - SMTP Antivirus/Antispam Gateway
#   Copyright (C) 2024 John Mertz <git@john.me.tz>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#
#   This script will generate outbound relaying summaries to assist in the
#   diagnosing of outbound blacklisting or other unexpected relaying behaviour
#
#   See Usage menu below or by running with the --help option

use strict;
use warnings;
use Time::Piece;
use Time::Seconds qw( ONE_DAY );
use Module::Load::Conditional qw( check_install );
use File::Copy qw( mv );
use File::Path qw( rmtree );

check_install( 'module' => 'PerlIO::gzip', 'version' => 0.18) || die "Reindexing requires the library PerlIO::gzip. Please install with:\n  apt-get install libperlio-gzip-perl\n\n";

$| = 1;
our $VAR = "/var/mailcleaner";

# Define services with ownership UID, GID, init commands, and timestamp search patterns per file.
# A handful of logs are incompatible with simple per-line searches, so they are excluded:
=unimplemented
    'freshclam.log' 
        starts with  '[%Y-%m-%d.* Starting ClamAV update...',
        ends with  '[%Y-%m-%d.* Done.',
    'mc_counts-cleaner.log'
        starts with '%a %b %d .* %Z %Y: Sleeping'
        ends with '%a %b %d .* %Z %Y: Cleaning terminated'
    'summaries.log'
        need to insert 'Send daily summaries:' at the start of each file '%Y-%m-%d',
    'updater4mc.log'
        starts with '%Y-%m-%d.* Launching Updater4MC'
        ends with '>> Logfile present here: /var/mailcleaner/log/mailcleaner/updater4mc.log'
=cut
my $cluid = getpwnam('clamav');
my $clgid = getgrnam('clamav');
my $mcuid = getpwnam('mailcleaner');
my $mcgid = getgrnam('mailcleaner');
my $myuid = getpwnam('mysql');
our $services = {
    'apache' => {
        'uid' => $mcuid,
        'gid' => $mcgid,
        'start' => '/usr/mailcleaner/etc/init.d/apache start',
        'stop' => '/usr/mailcleaner/etc/init.d/apache stop',
        'files' => {
            'access.log' => [ '%d/%b/%Y' ],
            'access_configurator.log' => [ '%d/%b/%Y' ],
            'access_soap.log' => [ '%d/%b/%Y' ],
            'error.log' => [ '%a %d %b' ],
            'error_configurator.log' => [ '%a %d %b' ],
            'error_soap.log' => [ '%a %d %b' ],
            'mc_auth.log' => [ '%d/%b/%Y' ],
        },
    },
    'clamav' => {
        'uid' => $cluid,
        'gid' => $clgid,
        'start' => '/usr/mailcleaner/etc/init.d/clamd start && /usr/mailcleaner/etc/init.d/clamspamd start',
        'stop' => '/usr/mailcleaner/etc/init.d/clamd stop && /usr/mailcleaner/etc/init.d/clamspamd stop',
        'files' => {
            'clamd.log' => [ '%Y-%m-%d', '%a %b %d' ],
            'clamspamd.log' => [ '%Y-%m-%d', '%a %b %d' ],
        },
    },
    'exim_stage1' => {
        'uid' => $mcuid,
        'gid' => $mcgid,
        'start' => '/usr/mailcleaner/etc/init.d/exim_stage1 start',
        'stop' => '/usr/mailcleaner/etc/init.d/exim_stage1 stop',
        'files' => {
            'mainlog' => [ '%Y-%m-%d' ],
            'paniclog' => [ '%Y-%m-%d' ],
            'rejectlog' => [ '%Y-%m-%d' ],
        },
    },
    'exim_stage2' => {
        'uid' => $mcuid,
        'gid' => $mcgid,
        'start' => '/usr/mailcleaner/etc/init.d/exim_stage2 start',
        'stop' => '/usr/mailcleaner/etc/init.d/exim_stage2 stop',
        'files' => {
            'mainlog' => [ '%Y-%m-%d' ],
            'paniclog' => [ '%Y-%m-%d' ],
            'rejectlog' => [ '%Y-%m-%d' ],
        },
    },
    'exim_stage4' => {
        'uid' => $mcuid,
        'gid' => $mcgid,
        'start' => '/usr/mailcleaner/etc/init.d/exim_stage4 start',
        'stop' => '/usr/mailcleaner/etc/init.d/exim_stage4 stop',
        'files' => {
            'mainlog' => [ '%Y-%m-%d' ],
            'paniclog' => [ '%Y-%m-%d' ],
            'rejectlog' => [ '%Y-%m-%d' ],
        },
    },
    'fail2ban' => {
        'uid' => 0,
        'gid' => 0,
        'start' => '/usr/mailcleaner/etc/init.d/fail2ban start',
        'stop' => '/usr/mailcleaner/etc/init.d/fail2ban stop',
        'files' => {
            'mc-fail2ban.log' => [ '%Y-%m-%d' ],
        },
    },
    'mailcleaner' => {
        'uid' => $mcuid,
        'gid' => $mcgid,
        'files' => {
            'downloadDatas.log' => [ '%Y/%m/%d' ],
            'PrefTDaemon.log' => [ '%Y-%m-%d' ],
            'SpamHandler.log' => [ '%Y-%m-%d' ],
            'spam_sync.log' => [ '%Y-%m-%d' ],
            'StatsDaemon.log' => [ '%Y-%m-%d' ],
            'summaries.log' => [ '%Y-%m-%d' ],
            'update.log' => [ '%Y-%m-%d' ],
        },
    },
    'mailscanner' => {
        'uid' => $mcuid,
        'gid' => $mcgid,
        'start' => '/usr/mailcleaner/etc/init.d/mailscanner start',
        'stop' => '/usr/mailcleaner/etc/init.d/mailscanner stop',
        'files' => {
            'infolog' => [ '%b %d' ],
            'newsld.log' => [ '%Y-%m-%d', '%a %b %d \d\d:\d\d:\d\d %Y' ],
            'spamd.log' => [ '%Y-%m-%d', '%a %b %d \d\d:\d\d:\d\d %Y' ],
            'warnlog' => [ '%b %d' ],
        },
    },
    'mysql_master' => {
        'uid' => $myuid,
        'gid' => $mcuid,
        'start' => '/usr/mailcleaner/etc/init.d/mysql_master start',
        'stop' => '/usr/mailcleaner/etc/init.d/mysql_master stop',
        'files' => {
            'mysql.log' => [ '%y%m%d' ],
        },
    },
    'mysql_slave' => {
        'uid' => $myuid,
        'gid' => $mcuid,
        'start' => '/usr/mailcleaner/etc/init.d/mysql_slave start',
        'stop' => '/usr/mailcleaner/etc/init.d/mysql_slave stop',
        'files' => {
            'mysql.log' => [ '%y%m%d' ],
        },
    }
};

sub usage {
    print("$0 <services>

--backup -b
    Original log directories will be kept at $VAR/log.bk

--stop -s
    Automatically stop service when processing current day's log and start it when that log is
    done. This will cause the service to be stopped and started once for each log type for that
    service.

Provide a list of services you'd like to re-index logs for. All services will be processed by
default.\n");
    exit();
}

sub fast_write {
    my ($logs, $service, $path, $suffix) = @_;
    if (defined($logs->{$path}->{$suffix}) && scalar(@{$logs->{$path}->{$suffix}})) {
        my $out_method = '>>';
        $out_method .= ':gzip' if ($suffix =~ m/\.gz$/);
        print("Writing logs for ${path}${suffix}\n");
        if (open(my $oh, $out_method, $path.$suffix)) {
            foreach my $line (@{$logs->{$path}->{$suffix}}) {
                print $oh $line;
            }
            close($oh);
            chown($services->{$service}->{'uid'}, $services->{$service}->{'gid'}, $path.$suffix);
            my $size = (stat("$path$suffix"))[7];
        } else {
            die("Failed to open ${path}${suffix}\n") 
        }
    } else {
        print("No logs found for $path$suffix\n");
    }
    delete($logs->{$path}->{$suffix});
}

# Collect arguments
my ($backup, $stop, @services_to_index, @error) = ( 0, 0 );
    if ($arg eq '--backup' || $arg eq '-b') {
        $backup = 1;
    } elsif ($arg eq '--stop' || $arg eq '-s') {
        $stop = 1;
    } elsif ($arg eq '--help' || $arg eq '-h') {
        usage();
    } elsif (defined($services->{$arg}) && !scalar(grep(@services_to_index, $arg))) {
        push(@services_to_index, $arg);
    } else {
        push(@error, $arg);
    }
}
die("Invalid option(s) or service(s): ".join(', ', @error)."\n") if (scalar(@error));

# Run for all services if none were provided
@services_to_index = keys(%{$services}) unless scalar(@services_to_index);

# Set up a hash which string replacement values for each day:
# eg. '.0' extension should have day value '%d' of '01')
# As well as a simple reverse-order array of file suffixes ('.366.gz', ... '.0', '')
my %filemap;
my @rev_order;
my $t = Time::Piece->localtime();
#$t = $t->truncate(to => 'day');
my %regex_map = ( '%a' => '(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)', '%b' => '(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)', '%d' => '\d\d', '%m' => '\d\d', '%Y' => '\d\d\d\d', '%y' => '\d\d' );
for (my $i = 0; $i <= 365; $i++) {
    my $suffix;
    if ($i == 0) {
        $suffix  = '';
    } elsif ($i == 1) {
        $suffix = '.0';
    } else {
        $suffix = '.'.($i-1).'.gz';
    }
    my ($a, $b, $d, $m, $Y, $y);
    $filemap{$suffix} = { '%a' => $t->wdayname(), '%b' => $t->monname(), '%d' => sprintf('%02d', $t->mday()), '%m' => sprintf('%02d', $t->mon()), '%Y' => $t->year(), '%y' => $t->yy() };
    unshift(@rev_order, $suffix);
    $t -= ONE_DAY;
    #$t = $t->truncate(to => 'day');
}

# Create a working and backup directory on the same partition as the logs for fast renaming.
my $tmp_dir = '/var/tmp/reindex_logs';
rmtree(${tmp_dir}) if (-d ${tmp_dir});
mkdir(${tmp_dir});
mkdir("${VAR}/log.bk") unless (-d "${VAR}/log.bk");

# Run one service at a time
foreach my $service (@services_to_index) {
    print "Indexing ${service}...\n";
    mkdir("${tmp_dir}/${service}");
    chown($services->{$service}->{'uid'}, $services->{$service}->{'gid'}, "${tmp_dir}/${service}");
    rmtree("${VAR}/log.bk/${service}") if (-d "${VAR}/log.bk/${service}");
    chown($services->{$service}->{'uid'}, $services->{$service}->{'gid'}, "${VAR}/log.bk/${service}");
    mkdir("${VAR}/log.bk/${service}");

    # Run one file type at a time
    foreach my $file (keys %{$services->{$service}->{'files'}}) {

        my $logs = {};
        my $start_offset = 0;

        # Delete old backups
        unlink($_) foreach (glob("${VAR}/log.bk/${service}/${file}*"));

        # If in 'stop' mode, stop service when on current days log
        `$services->{$service}->{'stop'}` if ($stop && defined($services->{$service}->{'stop'}));

        my @search_dates = @rev_order;

        # regex pattern to find any date
        my $generic_search;
        my @patterns = @{$services->{$service}->{'files'}->{$file}};
        for (my $i = 0; $i < scalar(@patterns); $i++) {
            foreach my $key (keys(%regex_map)) {
                $patterns[$i] =~ s/$key/$regex_map{$key}/;
            }
            $generic_search = "(".join('|', @patterns).")"
        }

        # Build a list of a searches using patterns from filemap and actual date expected
        my %searches;
        foreach my $date (@search_dates) {

            # Insert actual date values into date search pattern(s)
            @patterns = @{$services->{$service}->{'files'}->{$file}};
            for (my $i = 0; $i < scalar(@patterns); $i++) {
                foreach my $key (keys(%{$filemap{$date}})) {
                    $patterns[$i] =~ s/$key/$filemap{$date}->{$key}/;
                }
            }

            # Create regex with this dates available patterns
            $searches{$date} = "(".join('|', @patterns).")"
        }

        my $oh;
        print "Processing all ${service}/${file} files at once...\n";
        %{$logs->{"${tmp_dir}/${service}/${file}"}} = map { $_ => [] } keys(%filemap);

        my $prev_date;
        foreach my $input (@rev_order) {
            my $file_hit = 0;
            # Skip if the expected input file does not exist
            next unless (-e "${VAR}/log/${service}/${file}${input}");

            my $in_method = '<';
            $in_method .= ':gzip' if ($input =~ m/\.gz$/);
            if (open(my $ih, $in_method, "${VAR}/log/${service}/${file}${input}")) {
                while (my $line = <$ih>) {
                    my $hit = 0;
                    my $done = 0;

                    # For each line, search for all expected date stamps
                    my @new_dates = @search_dates;
                    foreach my $date (@new_dates) {
                        next unless(defined($date));

                        # If the line matched for this date, write or record it
                        if ($line =~ m/$searches{$date}/) {
                            # Record current search date as success
                            $hit = $date;
                            if (defined($prev_date)) {
                                if ($prev_date ne $date) {
                                    while (my $drop = shift(@search_dates)) {
                                        if ($drop eq $date) {
                                            fast_write($logs, $service, "${tmp_dir}/${service}/${file}", $prev_date);
                                            unshift(@search_dates, $drop);
                                            last;
                                        } else {
                                            fast_write($logs, $service, "${tmp_dir}/${service}/${file}", $drop);
                                        }
                                    }
                                }
                            }
                            $prev_date = $date;
                            # Append to log array for $date
                            if (defined($logs->{"${tmp_dir}/${service}/${file}"}->{$date})) {
                                push(@{$logs->{"${tmp_dir}/${service}/${file}"}->{$date}}, $line);
                            } else {
                                $logs->{"${tmp_dir}/${service}/${file}"}->{$date} = ( $line );
                            }
                            # Don't search other dates after succesful hit
                            last;

                            # Previously hit for this date, but did not for this line
                            # Different date found
                        } elsif ($line =~ m/^$generic_search/) {
                            shift(@search_dates);
                            next();
                        }
                        # Otherwise, just proceed to next date search
                    }
                    # If zero hits for any date, it is likely that the file had a blank line or dates older than our search scope.
                    # In this case, restore last good search dates list
                    if ($hit) {
                        $file_hit = 1;
                    } else {
                        @search_dates = @new_dates;
                    }
                }
                close($ih);
            }
        }

        foreach my $date (keys(%{$logs->{"${tmp_dir}/${service}/${file}"}})) {
            fast_write($logs, $service, "${tmp_dir}/${service}/${file}", $date);
        }

        # Remove/backup existing files
        if ($backup) {
            print("Moving old ${service}/${file} logs to ${VAR}/log.bk/${service}...\n");
        } else {
            print("Deleting old ${service}/${file} logs...\n");
        }
        foreach my $f (glob("${VAR}/log/${service}/${file}*")) {
            if ($backup) {
                my ($name) = $f =~ m#.*/([^/]*)#;
                mv($f, "${VAR}/log.bk/${service}/${name}");
            } else {
                unlink($f);
            }
        }

        # Replace with new files
        print("Moving new ${service}/${file} logs to ${VAR}/log/${service}...\n");
        foreach my $f (glob("${tmp_dir}/${service}/*")) {
            my ($name) = $f =~ m#.*/([^/]*)#;
            mv($f, "${VAR}/log/${service}/${name}");
        }

        # Start service again before processing next file type
        `$services->{$service}->{'start'}` if ($stop && defined($services->{$service}->{'start'}));
    }
}

rmtree("${tmp_dir}");
