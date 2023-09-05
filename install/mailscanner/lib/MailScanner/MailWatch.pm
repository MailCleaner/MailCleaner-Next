#
# MailWatch for MailScanner
# Copyright (C) 2003  Steve Freegard (smf@f2s.com)
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#

package MailScanner::CustomConfig;

use strict;
use DBI;
use Sys::Hostname;
use Storable(qw[freeze thaw]);
use POSIX;
use Socket;

# Trace settings - uncomment this to debug
# DBI->trace(2,'/root/dbitrace.log');

my($dbh);
my($sth);
my($hostname) = hostname;
my $loop = inet_aton("127.0.0.1");
my $server_port = 11553;
my $timeout = 120;


# Modify this as necessary for your configuration
## MAILCLEANER
my %config = readConfig("/etc/mailcleaner.conf");
my($db_name) = "mc_stats";
my($db_user) = "mailcleaner";
my($db_socket) = $config{'VARDIR'}."/run/mysql_slave/mysqld.sock";
my($db_pass) = $config{'MYMAILCLEANERPWD'};
my($vardir) = $config{'VARDIR'};

 sub InitMailWatchLogging {
   my $pid = fork();
   if ($pid) {
     # MailScanner child process
     waitpid $pid, 0;
     MailScanner::Log::InfoLog("Started SQL Logging child");

   } else {
     # New process
     # Detach from parent, make connections, and listen for requests
     POSIX::setsid();
     if (!fork()) {
       $SIG{HUP} = $SIG{INT} = $SIG{PIPE} = $SIG{TERM} = $SIG{ALRM} = \&ExitLogging;
       alarm $timeout;
       $0 = "MailWatch SQL";
       InitConnection();
       ListenForMessages();
     }
     exit;
   }
 }

 sub InitConnection {
   # Set up TCP/IP socket.  We will start one server per MailScanner
   # child, but only one child will actually be able to get the socket.
   # The rest will die silently.  When one of the MailScanner children
   # tries to log a message and fails to connect, it will start a new
   # server.
   socket(SERVER, PF_INET, SOCK_STREAM, getprotobyname("tcp"));
   setsockopt(SERVER, SOL_SOCKET, SO_REUSEADDR, 1);
   my $addr = sockaddr_in($server_port, $loop);
   bind(SERVER, $addr) or exit;
   listen(SERVER, SOMAXCONN) or exit;

   # Our reason for existence - the persistent connection to the database
   $dbh = DBI->connect("DBI:MariaDB:database=$db_name;host=localhost;mariadb_socket=$db_socket", $db_user, $db_pass, {PrintError => 0});
   if (!$dbh) {
    MailScanner::Log::WarnLog("Unable to initialise database connection: %s", $DBI::errstr);
   }

   $sth = $dbh->prepare("INSERT INTO maillog (timestamp, id, size, from_address, from_domain, to_address, to_domain, subject, clientip, archive, isspam, ishighspam, issaspam, isrblspam, spamwhitelisted, spamblacklisted, sascore, spamreport, virusinfected, nameinfected, otherinfected, report, ismcp, ishighmcp, issamcp, mcpwhitelisted, mcpblacklisted, mcpsascore, mcpreport, hostname, date, time, headers, quarantined) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)") or 
   MailScanner::Log::WarnLog($DBI::errstr);
 }


 sub ExitLogging {
   # Server exit - commit changes, close socket, and exit gracefully.
   close(SERVER);
## Olivier Diserens, for MailCleaner
   #$dbh->commit;
## end MailCleaner
   $dbh->disconnect;
   exit;
 }

 sub ListenForMessages {
   my $message;
   # Wait for messages
   while (my $cli = accept(CLIENT, SERVER)) {
     my($port, $packed_ip) = sockaddr_in($cli);
     my $dotted_quad = inet_ntoa($packed_ip);

     # reset emergency timeout - if we haven"t heard anything in $timeout
     # seconds, there is probably something wrong, so we should clean up
     # and let another process try.
     alarm $timeout;
     # Make sure we"re only receiving local connections
     if ($dotted_quad ne "127.0.0.1") {
        close CLIENT;
        next;
     }
     my @in;
     while (<CLIENT>) {
        # End of normal logging message
        last if /^END$/;
        # MailScanner child telling us to shut down
         ExitLogging if /^EXIT$/;
        chop;
        push @in, $_;
     }
     my $data = join "", @in;
     my $tmp = unpack("u", $data);
     $message = thaw $tmp;

     next unless defined $$message{id};

     # Check to make sure DB connection is still valid
     InitConnection unless $dbh->ping;

     # Log message
     $sth->execute(
      $$message{timestamp},
      $$message{id},
      $$message{size},
      $$message{from},
      $$message{from_domain},
      $$message{to},
      $$message{to_domain},
      $$message{subject},
      $$message{clientip},
      $$message{archiveplaces},
      $$message{isspam},
      $$message{ishigh},
      $$message{issaspam},
      $$message{isrblspam},
      $$message{spamwhitelisted},
      $$message{spamblacklisted},
      $$message{sascore},
      $$message{spamreport},
      $$message{virusinfected},
      $$message{nameinfected},
      $$message{otherinfected},
      $$message{reports},
      $$message{ismcp},
      $$message{ishighmcp},
      $$message{issamcp},
      $$message{mcpwhitelisted},
      $$message{mcpblacklisted},
      $$message{mcpsascore},
      $$message{mcpreport},
      $$message{hostname},
      $$message{date},
      $$message{"time"},
      $$message{headers},
      $$message{quarantined});

    # this doesn't work in the event we have no connection by now ?
    if (!$sth) {
     MailScanner::Log::WarnLog("$$message{id}: MailWatch SQL Cannot insert row: %s", $sth->errstr);
    } else {
     MailScanner::Log::InfoLog("$$message{id}: Logged to MailWatch SQL");
    }
    
    # Unset
    $message = undef;

   }
 }

 sub EndMailWatchLogging {
   # Tell server to shut down.  Another child will start a new server
   # if we are here due to old age instead of administrative intervention
   socket(TO_SERVER, PF_INET, SOCK_STREAM, getprotobyname("tcp"));
   my $addr = sockaddr_in($server_port, $loop);
   connect(TO_SERVER, $addr) or return;

   print TO_SERVER "EXIT\n";
   close TO_SERVER;
 }

 sub MailWatchLogging {
   my($message) = @_;

   # Don't bother trying to do an insert if  no message is passed-in
   return unless $message;

   # Fix duplicate 'to' addresses for Postfix users
   my(%rcpts);
   map { $rcpts{$_}=1; } @{$message->{to}};
   @{$message->{to}} = keys %rcpts;

   # Get rid of control chars and tidy-up SpamAssassin report
   my $spamreport = $message->{spamreport};
   $spamreport =~ s/\n/ /g;
   $spamreport =~ s/\t//g;

   # Same with MCP report
   my $mcpreport = $message->{mcpreport};
   $mcpreport =~ s/\n/ /g;
   $mcpreport =~ s/\t//g;

   # Workaround tiny bug in original MCP code
   my($mcpsascore);
   if (defined $message->{mcpsascore}) {
    $mcpsascore = $message->{mcpsascore};
   } else {
    $mcpsascore = $message->{mcpscore};
   }

   # Set quarantine flag - this only works on 4.43.7 or later
   my($quarantined);
   if ( (scalar(@{$message->{quarantineplaces}}))
      + (scalar(@{$message->{spamarchive}})) > 0 )
   {
        $quarantined = 1;
   } else {
        $quarantined = 0;
   }

   # Get timestamp, and format it so it is suitable to use with MariaDB
   my($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime();
   my($timestamp) = sprintf("%d-%02d-%02d %02d:%02d:%02d",
                           $year+1900,$mon+1,$mday,$hour,$min,$sec);

   my($date) = sprintf("%d-%02d-%02d",$year+1900,$mon+1,$mday);
   my($time) = sprintf("%02d:%02d:%02d",$hour,$min,$sec);

   # Also print 1 line for each report about this message. These lines
   # contain all the info above, + the attachment filename and text of
   # each report.
   my($file, $text, @report_array);
   while(($file, $text) = each %{$message->{allreports}}) {
     $file = "the entire message" if $file eq "";
     # Use the sanitised filename to avoid problems caused by people forcing
     # logging of attachment filenames which contain nasty SQL instructions.
     $file = $message->{file2safefile}{$file} or $file;
     $text =~ s/\n/ /;  # Make sure text report only contains 1 line
     $text =~ s/\t/ /; # and no tab characters
     push (@report_array, $text);
   }

   # Sanitize reports
   my $reports = join(",",@report_array);

   # Fix the $message->{clientip} for later versions of Exim
   # where $message->{clientip} contains ip.ip.ip.ip.port
   my $clientip = $message->{clientip};
   $clientip =~ s/^(\d+\.\d+\.\d+\.\d+)(\.\d+)$/$1/;

   # Integrate SpamAssassin Whitelist/Blacklist reporting
   if($spamreport =~ /USER_IN_WHITELIST/) {
    $message->{spamwhitelisted} = 1;
   }
   if($spamreport =~ /USER_IN_BLACKLIST/) {
    $message->{spamblacklisted} = 1;
   }

   # Get the first domain from the list of recipients
   my($todomain,@todomain);
   @todomain = @{$message->{todomain}};
   $todomain = $todomain[0];

   # Place all data into %msg
   my %msg;
   $msg{timestamp} = $timestamp;
   $msg{id} = $message->{id};
   $msg{size} = $message->{size};
   $msg{from} = $message->{from};
   $msg{from_domain} = $message->{fromdomain};
   $msg{to} = join(",", @{$message->{to}});
   $msg{to_domain} = $todomain;
   $msg{subject} = $message->{subject};
   $msg{clientip} = $clientip;
   $msg{archiveplaces} = join(",", @{$message->{archiveplaces}});
   $msg{isspam} = $message->{isspam};
   $msg{ishigh} = $message->{ishigh};
   $msg{issaspam} = $message->{issaspam};
   $msg{isrblspam} = $message->{isrblspam};
   $msg{spamwhitelisted} = $message->{spamwhitelisted};
   $msg{spamblacklisted} = $message->{spamblacklisted};
   $msg{sascore} = $message->{sascore};
   $msg{spamreport} = $spamreport;
   $msg{ismcp} = $message->{ismcp};
   $msg{ishighmcp} = $message->{ishighmcp};
   $msg{issamcp} = $message->{issamcp};
   $msg{mcpwhitelisted} = $message->{mcpwhitelisted};
   $msg{mcpblacklisted} = $message->{mcpblacklisted};
   $msg{mcpsascore} = $mcpsascore;
   $msg{mcpreport} = $mcpreport;
   $msg{virusinfected} = $message->{virusinfected};
   $msg{nameinfected} = $message->{nameinfected};
   $msg{otherinfected} = $message->{otherinfected};
   $msg{reports} = $reports;
   $msg{hostname} = $hostname;
   $msg{date} = $date;
   $msg{"time"} = $time;
   $msg{headers} = join("\n",@{$message->{headers}});
   $msg{quarantined} = $quarantined;

   if ($message->{batchdropped}) {
     MailScanner::Log::DebugLog("Counts for message ".$message->{id}." not updated cause batch has been dropped!");
     return; 
   }

   if ($quarantined > 0 ) {
     # Prepare data for transmission
     my $f = freeze \%msg;
     my $p = pack("u", $f);

     # Connect to server
     while (1) {
       socket(TO_SERVER, PF_INET, SOCK_STREAM, getprotobyname("tcp"));
       my $addr = sockaddr_in($server_port, $loop);
       connect(TO_SERVER, $addr) and last;
       # Failed to connect - kick off new child, wait, and try again
       InitMailWatchLogging();
       sleep 5;
     }

     # Pass data to server process
     MailScanner::Log::InfoLog("Logging message $msg{id} to SQL");
     print TO_SERVER $p;
     print TO_SERVER "END\n";
     close TO_SERVER;
   } else {
     #MailScanner::Log::InfoLog("Not need to log message ".$message->{id}." to SQL: not quarantined");
   }
   ## MAILCLEANER
   ## update messages counts
   updateCounts($message->{id}, $msg{date}, \@{$message->{to}}, $msg{isspam}, $msg{ishigh}, $msg{virusinfected}, $msg{nameinfected}, $msg{otherinfected}, $msg{size});
}

## MAILCLEANER
sub updateCounts {
  my ($mid, $date, $tos_ref, $isspam, $ishigh, $virusinfected, $nameinfected, $otherinfected, $size) = @_;

  my $statsclient = StatsClient->new();

  my @tos = @$tos_ref;
  my $newusers = 0;
  my $newdomains = 0;

  ## update domains and user counts
  my %domains_done;

  my %domains = 0;
  my %data;
  my $daemon_error = 'NOERROR';

#print STDERR "spam: $isspam  -  hispam: $ishigh\n";

  foreach my $to (@tos) {
    if ($to =~ /^(\S+)\@(\S+)$/) {
     my $t_domain = lc($2);
     my $t_user = lc($1);

     my $domain_dir = $vardir."/spool/mailcleaner/counts/".$t_domain;
     if (! -d $domain_dir) {
       next if ! mkdir $domain_dir;
     }

     # user
     my $user_subject = 'user:'.$t_domain.':'.$t_user;
     my $domain_subject = 'domain:'.$t_domain;
     %data = ('virus' => $virusinfected, 'name' => $nameinfected, 'other' => $otherinfected, 'size' => $size, 'spam' => $isspam, 'highspam' => $ishigh);
     my $ret = $statsclient->addMessageStats($user_subject, \%data);
     if ($ret =~ /^ADDED\s+(\d+)/) {
       if ($1 == 1) {
         $statsclient->addValue($domain_subject.':user', 1);
         $statsclient->addValue('global:user', 1);
       }
     } elsif ( $ret !~ /^ADDED/ ) {
       $daemon_error = $ret;
     }

     if (! defined($domains{$t_domain})) {
       %data = ('virus' => $virusinfected, 'name' => $nameinfected, 'other' => $otherinfected, 'size' => $size, 'spam' => $isspam, 'highspam' => $ishigh);
       my $ret = $statsclient->addMessageStats($domain_subject, \%data);
       if ($ret =~ /^ADDED\s+(\d+)/) {
         if ($1 == 1) {
           $statsclient->addValue('global:domain', 1);
         }
       } elsif ( $ret !~ /^ADDED/ ) {
         $daemon_error = $ret;
       }

       $domains{$t_domain} = 1;
     }

     my $user_dir = $domain_dir."/".$t_user;
     $newusers = $newusers + updateCountFiles($user_dir, $date, $isspam, $ishigh, $virusinfected, $nameinfected, $otherinfected, $size, 0, 0);

     # domain
     if (! defined($domains_done{$t_domain})) {
       $newdomains = $newdomains + updateCountFiles($domain_dir."/_global", $date, $isspam, $ishigh, $virusinfected, $nameinfected, $otherinfected, $size, $newusers, 0);
       $domains_done{$t_domain} = 1;
     }
    }
  }

  ## update global counts
  %data = ('virus' => $virusinfected, 'name' => $nameinfected, 'other' => $otherinfected, 'size' => $size, 'spam' => $isspam, 'highspam' => $ishigh);
  my $ret = $statsclient->addMessageStats('global', \%data);
  if ($ret !~ /^ADDED/) {
     $daemon_error = $ret;
  }


  updateCountFiles($vardir."/spool/mailcleaner/counts/_global", $date, $isspam, $ishigh, $virusinfected, $nameinfected, $otherinfected, $size, $newusers, $newdomains);

  MailScanner::Log::InfoLog("Count updated for $mid");
  if ($daemon_error eq 'NOERROR') {
     MailScanner::Log::InfoLog("Count updated in daemon for $mid");
  } else {
     MailScanner::Log::InfoLog("Count NOT updated in daemon for $mid: $daemon_error");
  }
  return;
}

sub updateCountFiles {
  my ($dir, $date, $isspam, $ishigh, $virusinfected, $nameinfected, $otherinfected, $size, $newusers, $newdomains) = @_;
  my $newfile = 0;
  my $ret = 0;

  ## create parent directory if not existing
  if ( ! -d $dir) {
    if (! mkdir($dir) ) {
     MailScanner::Log::InfoLog("Could not create counts file dir: $dir");
     return 0;
    }
  }
  
  ## compute date
  my $filename = "";
  if ($date =~ m/(\d{4})\-(\d{2})\-(\d{2})/ ) {
    $filename = $1.$2.$3;
  } else {
    MailScanner::Log::InfoLog("Could not compute date from $date");
    return 0;
  }
  my $file = $dir."/".$filename."_counts";

  my $c_msgs = 0;
  my $c_spams = 0;
  my $c_highspams = 0;
  my $c_viruses = 0;
  my $c_names = 0;
  my $c_others = 0;
  my $c_cleans = 0;
  my $c_bytes = 0;
  my $c_domains = 0;
  my $c_users = 0;
  
  ## read existing counts
  if ( -f $file ) {
    if (!open(COUNTFILE, $file)) {
      MailScanner::Log::InfoLog("Could not open counts file: $file, but it is present...");
    } else {
      while (<COUNTFILE>) {
        if (/^MSGS\ (\d+)$/) {
           $c_msgs = $1;
        }
        if (/^SPAMS\ (\d+)$/) {
           $c_spams = $1;
        }
        if (/^HIGHSPAMS\ (\d+)$/) {
           $c_highspams = $1;
        }
        if (/^VIRUSES\ (\d+)$/) {
           $c_viruses = $1;
        }
        if (/^NAMES\ (\d+)$/) {
           $c_names = $1;
        } 
        if (/^OTHERS\ (\d+)$/) {
           $c_others = $1;
        }
        if (/^CLEANS\ (\d+)$/) {
           $c_cleans = $1;
        }
        if (/^BYTES\ (\d+)$/) {
           $c_bytes = $1;
        }
        if (/^DOMAINS\ (\d+)$/) {
           $c_domains = $1;
        }
        if (/^USERS\ (\d+)$/) {
           $c_users = $1;
        }
      }
      close COUNTFILE;
      if ( $c_msgs == 0 ) {
        MailScanner::Log::InfoLog("WARNING, message count is zero for file: $file but file was opened");
        return 0;
      }
    }
    if ( $c_msgs == 0 ) {
        MailScanner::Log::InfoLog("WARNING, message count is zero for file: $file but file was present");
        return 0;
    }
  }
  if ( $c_msgs == 0 ) {
   $ret = 1;
   MailScanner::Log::InfoLog("NOTICE, message count is zero for file: $file");
  }

  ## compute new counts
  $c_msgs = $c_msgs + 1;
  $c_bytes = $c_bytes + $size;
  if ($virusinfected > 0) {
   $c_viruses = $c_viruses + 1;
  } elsif ($nameinfected > 0) {
   $c_names = $c_names + 1;
  } elsif ($otherinfected > 0) {
   $c_others = $c_others + 1;
  } elsif ($isspam > 0) {
   $c_spams = $c_spams + 1;
  } elsif ($ishigh > 0) {
   $c_highspams = $c_highspams + 1;
  } else {
   $c_cleans = $c_cleans + 1;
  }
  
  ## finally write updates counts
  if (!open(COUNTFILE, ">$file")) {
    MailScanner::Log::InfoLog("Could not open counts file for writing: $file");
    return 0;
  }

  print COUNTFILE "MSGS $c_msgs\n";
  print COUNTFILE "SPAMS $c_spams\n";
  print COUNTFILE "HIGHSPAMS $c_highspams\n";
  print COUNTFILE "VIRUSES $c_viruses\n";
  print COUNTFILE "NAMES $c_names\n";
  print COUNTFILE "OTHERS $c_others\n";
  print COUNTFILE "CLEANS $c_cleans\n";
  print COUNTFILE "BYTES $c_bytes\n";
  if ($file =~ /counts\/\_global/) {
    $c_users = $c_users + $newusers;
    print COUNTFILE "USERS $c_users\n";
    $c_domains = $c_domains + $newdomains;
    print COUNTFILE "DOMAINS $c_domains\n";
  } elsif ($file =~ /\_global/) {
    $c_users = $c_users + $newusers;
    print COUNTFILE "USERS $c_users\n";
  }
  close COUNTFILE;

  #MailScanner::Log::InfoLog("Count updated on file $file ");
 return $ret;  
}


sub readConfig
{
        my $configfile = shift;
        my %config;
        my ($var, $value);

        open CONFIG, $configfile or die "Cannot open $configfile: $!\n";
        while (<CONFIG>) {
                chomp;                  # no newline
                s/#.*//;                # no comments
                s/;.*//;                # no comments
                s/^\s+//;               # no leading white
                s/\s+$//;               # no trailing white
                next unless length;     # anything left?
                my ($var, $value) = split(/\s*=\s*/, $_, 2);
                $config{$var} = $value;
        }
        close CONFIG;
        return %config;
}



1;
