#!/usr/bin/env perl
#
#   Mailcleaner - SMTP Antivirus/Antispam Gateway
#   Copyright (C) 2004-2014 Olivier Diserens <olivier@diserens.ch>
#   Copyright (C) 2015-2017 Florian Billebault <florian.billebault@gmail.com>
#   Copyright (C) 2023 John Mertz <git@john.me.tz>
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
#   This script will dump the apache config file with the configuration
#   settings found in the database.
#
#   Usage:
#           dump_apache_config.pl


use v5.36;
use strict;
use warnings;
use utf8;
use Carp qw( confess );

our ($SRCDIR, $VARDIR, $HOSTID, $MYMAILCLEANERPWD);
BEGIN {
    if ($0 =~ m/(\S*)\/\S+.pl$/) {
        my $path = $1."/../lib";
        unshift (@INC, $path);
    }
    require ReadConfig;
    my $conf = ReadConfig::getInstance();
    $SRCDIR = $conf->getOption('SRCDIR');
    $VARDIR = $conf->getOption('VARDIR');
    $HOSTID = $conf->getOption('HOSTID');
    $MYMAILCLEANERPWD = $conf->getOption('MYMAILCLEANERPWD');
    unshift(@INC, $SRCDIR."/lib");
}

require DB;
use lib_utils qw( open_as rmrf );
use File::Touch qw( touch );

our $DEBUG = 1;
our $uid = getpwnam('mailcleaner');
our $gid = getgrnam('mailcleaner');

my $lasterror = "";

# Delete old session files
mkdir('/tmp/php_sessions') unless (-d '/tmp/php_sessions');
unlink($_) foreach (glob('/tmp/php_sessions/*'));
unlink('/tmp/php_sessions.sqlite') if (-e '/tmp/php_sessions.sqlite');
unlink($_) foreach (glob("$VARDIR/www/stats/*.png"));

# Create necessary dirs/files if they don't exist
touch('/tmp/php_sessions.sqlite') || print("Failed to create /tmp/php_sessions.sqlite\n");
mkdir('/var/mailcleaner/log/apache') unless (-d '/var/mailcleaner/log/apache');
mkdir('/var/mailcleaner/www') unless (-d '/var/mailcleaner/www');
mkdir('/var/mailcleaner/www/mrtg') unless (-d '/var/mailcleaner/www/mrtg');
mkdir('/var/mailcleaner/www/stats') unless (-d '/var/mailcleaner/www/stats');

# Set proper permissions
chown($uid, $gid,
    '/tmp/php_sessions/',
    '/tmp/php_sessions.sqlite',
    '/var/mailcleaner/log/apache',
    '/var/mailcleaner/www/',
    glob('/var/mailcleaner/www/*'),
    glob('/var/mailcleaner/www/mrtg/*'),
    glob('/var/mailcleaner/www/stats/*'),
    '/var/mailcleaner/run/ssl.cache',
    '/var/mailcleaner/run/apache2',
    glob('/var/mailcleaner/run/apache2/*'),
    '/etc/apache2',
    glob('/etc/apache2/*'),
    glob($VARDIR.'/log/apache/*'),
    glob($SRCDIR.'/etc/apache/sites-available/*'),
    glob($SRCDIR.'/www/guis/admin/public/tmp/*'),
);

# Fix symlinks if broken
my %links = (
    '/etc/apparmor.d/mailcleaner' => ${SRCDIR}.'/etc/apparmor',
    '/etc/apache2' => ${SRCDIR}.'/etc/apache',
);
foreach my $link (keys(%links)) {
    if (-e $link) {
        if (-l $link) {
            next if (readlink($link) eq $links{$link});
	    unlink($link);
        } else {
            rmrf($link);
        }
    }
    symlink($links{$link}, $link);
}

# Reload AppArmor rules
`apparmor_parser -r ${SRCDIR}/etc/apparmor.d/apache` if ( -d '/sys/kernel/security/apparmor' );

# Configure sudoer permissions if they are not already
mkdir '/etc/sudoers.d' unless (-d '/etc/sudoers.d');
if (open(my $fh, '>', '/etc/sudoers.d/apache')) {
    print $fh "
User_Alias  APACHE = mailcleaner
Runas_Alias EXIM = mailcleaner
Cmnd_Alias  CHECKSPOOLS = $SRCDIR/bin/check_spools.sh
Cmnd_Alias  GETSTATUS = $SRCDIR/bin/get_status.pl -s

APACHE      * = (ROOT) NOPASSWD: SETPINDB
APACHE      * = (EXIM) NOPASSWD: CHECKSPOOLS
APACHE      * = (ROOT) NOPASSWD: GETSTATUS
";
}

# SystemD auth causes timeouts
`sed -iP '/^session.*pam_systemd.so/d' /etc/pam.d/common-session`;

# Dump configuration
my $dbh;
$dbh = DB::connect('slave', 'mc_config');

my %sys_conf = get_system_config() or fatal_error("NOSYSTEMCONFIGURATIONFOUND", "no record found for system configuration");

my %apache_conf;
%apache_conf = get_apache_config() or fatal_error("NOAPACHECONFIGURATIONFOUND", "no apache configuration found");

dump_apache_file("${SRCDIR}/etc/apache/apache2.conf_template", "${SRCDIR}/etc/apache/apache2.conf") or fatal_error("CANNOTDUMPAPACHEFILE", $lasterror);

dump_apache_file("${SRCDIR}/etc/apache/sites-available/mailcleaner.conf_template", "${SRCDIR}/etc/apache/sites-available/mailcleaner.conf") or fatal_error("CANNOTDUMPAPACHEFILE", $lasterror);
dump_apache_file("${SRCDIR}/etc/apache/sites-available/soap.conf_template", "${SRCDIR}/etc/apache/sites-available/soap.conf") or fatal_error("CANNOTDUMPAPACHEFILE", $lasterror);

dump_soap_wsdl($sys_conf{'HOST'}, $apache_conf{'__USESSL__'}) or fatal_error("CANNOTDUMPWSDLFILE", $lasterror);

dump_certificate(${SRCDIR},$apache_conf{'tls_certificate_data'}, $apache_conf{'tls_certificate_key'}, $apache_conf{'tls_certificate_chain'});

$dbh->disconnect();

#############################
sub dump_apache_file($template_file, $target_file)
{
    my ($TEMPLATE, $TARGET);
    unless ( $TEMPLATE = ${open_as($template_file, '<')} ) {
        confess("Cannot open template file: $template_file");
    }
    unless ( $TARGET = ${open_as($target_file)} ) {
        close $template_file;
        confess("Cannot open target file: $target_file");
    }

    my $inssl = 0;
    while(<$TEMPLATE>) {
        my $line = $_;

        $line =~ s/__VARDIR__/${VARDIR}/g;
        $line =~ s/__SRCDIR__/${SRCDIR}/g;
        $line =~ s/__DBPASSWD__/${MYMAILCLEANERPWD}/g;

        foreach my $key (keys %sys_conf) {
            $line =~ s/$key/$sys_conf{$key}/g;
        }
        foreach my $key (keys %apache_conf) {
            $line =~ s/$key/$apache_conf{$key}/g;
        }

        if ($line =~ /^\_\_IFSSLCHAIN\_\_(.*)/) {
            if ($apache_conf{'tls_certificate_chain'} && $apache_conf{'tls_certificate_chain'} ne '') {
                print $TARGET $1."\n";
            }
            next;
        }
        if ($line =~ /\_\_IFSSL\_\_/) {
            $inssl = 1;
            next;
        }

        if ($line =~ /\_\_ENDIFSSL\_\_/) {
            $inssl = 0;
            $line = "";
            next;
        }

        if ( (! $inssl) || ($apache_conf{'__USESSL__'} =~ /true/) ) {
            print $TARGET $line;
        }
    }

    close $TEMPLATE;
    close $TARGET;
    chown($uid, $gid, $target_file);

    return 1;
}

sub dump_soap_wsdl($host, $use_ssl)
{

    my $template_file = "${SRCDIR}/www/soap/htdocs/mailcleaner.wsdl_template";
    my $target_file = "${SRCDIR}/www/soap/htdocs/mailcleaner.wsdl";

    my $protocol = 'http';
    $protocol .= 's' if ($use_ssl);

    my ($TEMPLATE, $TARGET);
    if ( !open($TEMPLATE, '<', $template_file) ) {
        $lasterror = "Cannot open template file: $template_file";
        return 0;
    }
    if ( !open($TARGET, '>', $target_file) ) {
        $lasterror = "Cannot open target file: $target_file";
        close $template_file;
        return 0;
    }

    my $inssl = 0;
    while(<$TEMPLATE>) {
        my $line = $_;

        $line =~ s/__HOST__/$host/g;
        $line =~ s/__PROTOCOL__/$protocol/g;
        print $TARGET $line;
    }

    close $TEMPLATE;
    close $TARGET;
    chown($uid, $gid, $target_file);

    return 1;
}

#############################
sub get_system_config()
{
    my %config;

    my $sth = $dbh->prepare("SELECT hostname, default_domain, sysadmin, clientid FROM system_conf");
    $sth->execute() or fatal_error("CANNOTEXECUTEQUERY", $dbh->errstr);

    if ($sth->rows < 1) {
        return;
    }
    my $ref = $sth->fetchrow_hashref() or return;

    $config{'__PRIMARY_HOSTNAME__'} = $ref->{'hostname'};
    $config{'__QUALIFY_DOMAIN__'} = $ref->{'default_domain'};
    $config{'__QUALIFY_RECIPIENT__'} = $ref->{'sysadmin'};
    $config{'__CLIENTID__'} = $ref->{'clientid'};

    $sth->finish();

    $sth = $dbh->prepare("SELECT hostname FROM slave WHERE id=".$HOSTID);
    $sth->execute() or fatal_error("CANNOTEXECUTEQUERY", $dbh->errstr);
    if ($sth->rows < 1) {
        return;
    }
    $ref = $sth->fetchrow_hashref() or return;
    $config{'HOST'} = $ref->{'hostname'};
    $sth->finish();

    return %config;
}

#############################
sub get_apache_config()
{
    my %config;

    my $sth = $dbh->prepare("SELECT serveradmin, servername, use_ssl, timeout, keepalivetimeout,
        min_servers, max_servers, start_servers, http_port, https_port, certificate_file, tls_certificate_data, tls_certificate_key, tls_certificate_chain FROM httpd_config");
    $sth->execute() or fatal_error("CANNOTEXECUTEQUERY", $dbh->errstr);

    if ($sth->rows < 1) {
        return;
    }
    my $ref = $sth->fetchrow_hashref() or return;

    $config{'__TIMEOUT__'} = $ref->{'timeout'};
    $config{'__MINSERVERS__'} = $ref->{'min_servers'};
    $config{'__MAXSERVERS__'} = $ref->{'max_servers'};
    $config{'__STARTSERVERS__'} = $ref->{'start_servers'};
    $config{'__KEEPALIVETIMEOUT__'} = $ref->{'keepalivetimeout'};
    $config{'__HTTPPORT__'} = 8080;
    $config{'__HTTPSPORT__'} = 4443;
    $config{'__USESSL__'} = $ref->{'use_ssl'};
    $config{'__SERVERNAME__'} = $ref->{'servername'};
    $config{'__SERVERADMIN__'} = $ref->{'serveradmin'};
    $config{'__CERTFILE__'} = $ref->{'certificate_file'};
    $config{'tls_certificate_data'} = $ref->{'tls_certificate_data'};
    $config{'tls_certificate_key'} = $ref->{'tls_certificate_key'};
    $config{'tls_certificate_chain'} = $ref->{'tls_certificate_chain'};
    $config{'__PHP_VERSION__'} = 8.2;

    $sth->finish();
    return %config;
}

#############################
sub fatal_error($msg,$full)
{
    print $msg . ($DEBUG ? "\nFull information: $full \n" : "\n");
}

#############################
sub print_usage
{
    print "Bad usage: dump_exim_config.pl [stage-id]\n\twhere stage-id is an integer between 0 and 4 (0 or null for all).\n";
    exit(0);
}

sub dump_certificate($srcdir,$cert,$key,$chain)
{
    my $path = $srcdir."/etc/apache/certs/certificate.pem";
    my $backup = $srcdir."/etc/apache/certs/default.pem";
    my $chainpath = $srcdir."/etc/apache/certs/certificate-chain.pem";

    if (!$cert || !$key || $cert =~ /^\s+$/ || $key =~ /^\s+$/) {
        my $cmd = "cp $backup $path";
        `$cmd`;
    } else {
        $cert =~ s/\r\n/\n/g;
        $key =~ s/\r\n/\n/g;
        if ( open(my $FILE, '>', $path)) {
            print $FILE $cert."\n";
            print $FILE $key."\n";
            close $FILE;
        }
    }

    if ( $chain && $chain ne '' ) {
        if ( open(my $FILE, '>', $chainpath)) {
            print $FILE $chain."\n";
            close $FILE;
        }
    }
    chown($uid, $gid, $path, $backup, $chainpath);
}
