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
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU General Public License for more details.
#
#   You should have received a copy of the GNU General Public License
#   along with this program; if not, write to the Free Software
#   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#
#   This script will dump the exim configuration file from the configuration
#   setting found in the database.
#
#   Usage:
#           dump_exim_config.pl [stage id]
#   where stage id is:
#   1 for the incoming mta
#   2 for the queuing mta (for antivirus/antispam process)
#   4 for the outgoing mta
#   if no stage id is given, the three configuration files will be dumped


use v5.36;
use strict;
use warnings;
use utf8;
use Carp qw( confess );

our ($SRCDIR, $VARDIR, $MYMAILCLEANERPWD, $MCHOSTNAME, $DEFAULTDOMAIN, $HELONAME, $SMTPPROXY);
BEGIN {
    if ($0 =~ m/(\S*)\/\S+.pl$/) {
        my $path = $1."/../lib";
        unshift (@INC, $path);
    }
    require ReadConfig;
    my $conf = ReadConfig::getInstance();
    $SRCDIR = $conf->getOption('SRCDIR') || '/usr/mailcleaner';
    $VARDIR = $conf->getOption('VARDIR') || '/var/mailcleaner';
    confess "Could not get DB password" unless ($MYMAILCLEANERPWD = $conf->getOption('MYMAILCLEANERPWD'));
    $MCHOSTNAME = $conf->getOption('MCHOSTNAME') || 'mailcleaner';
    $DEFAULTDOMAIN = $conf->getOption('DEFAULTDOMAIN') || '';
    $HELONAME = $conf->getOption('HELONAME') || '';
    $SMTPPROXY = $conf->getOption('SMTPPROXY') || '';
    unshift(@INC, $SRCDIR."/lib");
}

use lib_utils qw(open_as);

require ConfigTemplate;
require MCDnsLists;
require GetDNS;
require DB;
use File::Path qw (make_path);
use File::Touch;
use File::Copy;

our $DEBUG = 0;
our $SPMC = "$VARDIR/spool/mailcleaner";
our $db = DB::connect('slave', 'mc_config');
our $include_debug = 0;

our $uid = getpwnam( 'mailcleaner' );
our $gid = getgrnam( 'mailcleaner' );

my $lasterror = "";
my $eximid = shift;
my @eximids;
if (! $eximid ) {
    @eximids = (1, 2, 4);
} else {
    if ( $eximid =~ /\D/ ) {
        print_usage();
    }
    if ( $eximid > 4) {
        print_usage();
    } else {
        @eximids = ($eximid);
    }
}

## check for tmp dir
my $tmpdir = ${VARDIR}."/spool/tmp/exim";
if ( ! -d "$tmpdir") {
    make_path("$tmpdir", {'mode'=>0755,'user'=>'mailcleaner','group'=>'mailcleaner'}) or fatal_error("COULDNOTCREATETMPDIR", "could not create temporary directory");
}

my %sys_conf = get_system_config() or fatal_error("NOSYSTEMCONFIGURATIONFOUND", "no record found for system configuration");

## dump master informations
my %m_infos = get_master();
dump_master_file(${VARDIR}."/spool/mailcleaner/master.conf", \%m_infos);

## dump the outgoing script
dump_spam_route();

my %exim_conf;

my $exim_conf_lpd = dump_lists_ip_domain();

my $syslog_restart = 0;
foreach my $stage (@eximids) {
    if ($stage == 1) {
        if ( ! -d "${VARDIR}/spool/tmp/exim" ) {
            make_path("${VARDIR}/spool/tmp/exim_stage1", {'mode'=>0755,'user'=>'mailcleaner','group'=>'mailcleaner'}) or fatal_error("COULDNOTCREATETMPDIR", "could not create directory");
        }
        if ( ! -d "${VARDIR}/spool/tmp/exim_stage1" ) {
            make_path("${VARDIR}/spool/tmp/exim_stage1", {'mode'=>0755,'user'=>'mailcleaner','group'=>'mailcleaner'}) or fatal_error("COULDNOTCREATETMPDIR", "could not create directory");
        }
        if ( ! -d "${VARDIR}/spool/tmp/exim_stage1/blacklists" ) {
            make_path("${VARDIR}/spool/tmp/exim_stage1/blacklists", {'mode'=>0755,'user'=>'mailcleaner','group'=>'mailcleaner'}) or fatal_error("COULDNOTCREATETMPDIR", "could not create directory");
        }
        if ( ! -d "${VARDIR}/spool/tmp/exim_stage1/rblwhitelists" ) {
            make_path("${VARDIR}/spool/tmp/exim_stage1/rblwhitelists", {'mode'=>0755,'user'=>'mailcleaner','group'=>'mailcleaner'}) or fatal_error("COULDNOTCREATETMPDIR", "could not create directory");
        }
        if ( ! -d "${VARDIR}/spool/tmp/exim_stage1/spamcwhitelists" ) {
            make_path("${VARDIR}/spool/tmp/exim_stage1/spamcwhitelists", {'mode'=>0755,'user'=>'mailcleaner','group'=>'mailcleaner'}) or fatal_error("COULDNOTCREATETMPDIR", "could not create directory");
        }
        ## dump the blacklists files
        dump_blacklists();
    }
    %exim_conf = get_exim_config($stage) or fatal_error("NOEXIMCONFIGURATIONFOUND", "no exim configuration found for stage ${stage}");

    # Generate the included files and the associated customized files
    my $custom = 0;
    while ( $custom != 2) {
        my $dir;
        my $dest_dir = "${VARDIR}/spool/tmp/exim_stage${stage}";
        if ($custom) {
            $dir = "/usr/mailcleaner/etc/exim/custom/stage${stage}";
        } else {
            $dir = "/usr/mailcleaner/etc/exim/stage${stage}";
        }
        if ( -d "$dir") {
            my @conf_files = glob("$dir/*_template");
            foreach my $current_file (@conf_files) {
                $current_file =~ s/.*\///;
                dump_exim_file($stage, "$dir/$current_file") or fatal_error("CANNOTDUMPEXIMFILE1", $lasterror);
            }
        }
        $custom++;
    }

    dump_exim_file($stage) or fatal_error("CANNOTDUMPEXIMFILE2", $lasterror);
    ownership($stage);
}
my $stage = grep(/^1$/, @eximids);
exit unless ($stage);
my %stage1_conf = get_exim_config($stage) or fatal_error("NOEXIMCONFIGURATIONFOUND", "no exim configuration found for stage ${stage}");

## dump the rbl ignore hosts file
if (!$stage1_conf{'rbls_ignore_hosts'}) {
    $stage1_conf{'rbls_ignore_hosts'} = '';
}
dump_ignore_list($stage1_conf{'rbls_ignore_hosts'}, 'rbl_ignore_hosts');

if (!$stage1_conf{'spf_dmarc_ignore_hosts'}) {
    $stage1_conf{'spf_dmarc_ignore_hosts'} = '';
}
dump_ignore_list($stage1_conf{'spf_dmarc_ignore_hosts'}, 'spf_and_dmarc_ignore_hosts');

## dump certificates
dump_certificate($stage1_conf{'tls_certificate_data'}, $stage1_conf{'tls_certificate_key'});

## dump the stockme filter
dump_stockme_file();

## dump smtp proxy file
my $proxyfile = ${VARDIR}."/spool/mailcleaner/smtp_proxy.conf";
if (-f $proxyfile) {
    unlink($proxyfile);
}
dump_proxy_file( $proxyfile, $SMTPPROXY) if ($SMTPPROXY ne '');

## dump DKIM
dump_default_dkim(\%stage1_conf) if ($stage == 1);

## dump TLS access files
dump_tls_force_files();

## restart syslog
dump_syslog_config();
if ( -f "/etc/init.d/rsyslog" ) {
    `/etc/init.d/rsyslog restart`;
} else {
    # TODO: deprecated. Migrate to syslog-ng
    #`/etc/init.d/sysklogd restart`;
}

sub dump_exim_file($stage, $include_file=undef)
{

    my ($template, $source, $destination);
    if (defined($include_file)) {
        my $dest_file = $include_file;
        $dest_file =~ s/_template$//;
        if (-e "${SRCDIR}/etc/exim/${include_file}") {
            $source = $include_file;
            $destination = $dest_file;
        } else {
            $source = $include_file;
            $destination = $dest_file;
        }
    } else {
        if (-e "${SRCDIR}/etc/exim/exim_stage${stage}.conf_template") {
            $source = "${SRCDIR}/etc/exim/exim_stage${stage}.conf_template";
            $destination = "${SRCDIR}/etc/exim/exim_stage${stage}.conf";
        } else {
            $source = "${SRCDIR}/etc/exim/exim_stage${stage}.conf_template";
            $destination = "${SRCDIR}/etc/exim/exim_stage${stage}.conf";
        }
    }
    $template = ConfigTemplate::create($source, $destination);

    my $if_syslog = "#no syslog_facility";
    $exim_conf{'__IF_USE_SYSLOGENABLED__'} = "";
    if ($sys_conf{'__ANTISPAM_SYSLOG__'}) {
        $exim_conf{'__IF_USE_SYSLOGENABLED__'} = 'syslog : ';
        if ($stage < 4) {
            $if_syslog = "syslog_facility = local1\nsyslog_processname = stage1";
        } else {
            $if_syslog = "syslog_facility = local1\nsyslog_processname = stage4";
        }
    }
    $exim_conf{'__IF_USE_SYSLOG__'} = $if_syslog;

    my $stockme = "#";
    if ($sys_conf{'__STOCKME__'}) {
        $stockme = "";
    }

    $sys_conf{'__DBPASSWD__'} = ${MYMAILCLEANERPWD};
    $exim_conf{'__IF_STOCK__'} = $stockme;


    if ($stage == 4) {
        $exim_conf{'__OUTSCRIPT__'} = ${SRCDIR}."/scripts/exim/spam_route.pl";
        my $optimizedscript = ${SRCDIR}."/scripts/exim/spam_route.opt.pl";
        if ( -f $optimizedscript) {
            $exim_conf{'__OUTSCRIPT__'} = $optimizedscript;
        }
        my $bytecompiledscript = ${SRCDIR}."/scripts/exim/spam_route.bbin";
        if ( -f $bytecompiledscript) {
            $exim_conf{'__OUTSCRIPT__'} = $bytecompiledscript;
        }
    }

    $template->setCondition('DEBUG', 0);
    if ($include_debug) {
        $template->setCondition('DEBUG', 1);
    }
    $template->setCondition('SENDERVERIFY', 0);
    if ($exim_conf{'__VERIFY_SENDER__'}) {
        $template->setCondition('SENDERVERIFY', 1);
    }
    $template->setCondition('RBL', 0);
    if ($exim_conf{'__RBLS__'} =~ /\S/) {
        $template->setCondition('RBL', 1);
    }
    $template->setCondition('RCPTRBL', 0);
    if ($exim_conf{'__RCPTRBLS__'} =~ /\S/) {
        $template->setCondition('RCPTRBL', 1);
        $template->setCondition('RBL', 0);
    }
    $template->setCondition('BSRBL', 0);
    if ($exim_conf{'__BSRBLS__'} =~ /\S/) {
        $template->setCondition('BSRBL', 1);
    }
    $template->setCondition('RATELIMIT', 0);
    if ($exim_conf{'__RATELIMIT_ENABLE__'}) {
        $template->setCondition('RATELIMIT', 1);
    }
    $template->setCondition('TRUSTED_RATELIMIT', 0);
    if ($exim_conf{'__TRUSTED_RATELIMIT_ENABLE__'}) {
        $template->setCondition('TRUSTED_RATELIMIT', 1);
    }
    $template->setCondition('USESSMTPPORT', 0);
    if ($exim_conf{'tls_use_ssmtp_port'} && $exim_conf{'__USE_INCOMINGTLS__'}) {
        $template->setCondition('USESSMTPPORT', 1);
    }
    $template->setCondition('TAGMODEBYPASSWHITELISTS', 0);
    if ($sys_conf{'__TAGMODEBYPASSWHITELISTS__'}) {
        $template->setCondition('TAGMODEBYPASSWHITELISTS', 1);
    }
    if ($sys_conf{'__WHITELISTBOTHFROM__'}) {
        if ( ! -e '${SPMC}/mc-wl-on-both-from' ) {
            confess "Cannot touch ${SPMC}/mc-wl-on-both-from" unless touch("${SPMC}/mc-wl-on-both-from");
        }
    } else {
        if ( -e '${SPMC}/mc-wl-on-both-from' ) {
            confess "Cannot remove ${SPMC}/mc-wl-on-both-from" unless unlink("${SPMC}/mc-wl-on-both-from");
        }
    }
    $template->setCondition('USETLS', $exim_conf{'__USE_INCOMINGTLS__'});
    $template->setCondition('ALLOW_LONG', 1);
    if ($exim_conf{'__ALLOW_LONG__'}) {
        $template->setCondition('ALLOW_LONG', $exim_conf{'__ALLOW_LONG__'});
    }
    $template->setCondition('FOLDING', 0);
    if ($exim_conf{'__FOLDING__'}) {
        $template->setCondition('FOLDING', 1);
    }
    $template->setCondition('USEARCHIVER', 0);
    if ($sys_conf{'use_archiver'}) {
        $template->setCondition('USEARCHIVER', 1);
    }
    $template->setCondition('OUTGOINGVIRUSSCAN', 0);
    if ($exim_conf{'outgoing_virus_scan'}) {
        $template->setCondition('OUTGOINGVIRUSSCAN', 1);
    }
    $template->setCondition('MASKRELAY', 0);
    if ($exim_conf{'mask_relayed_ip'}) {
        $template->setCondition('MASKRELAY', 1);
    }
    $template->setCondition('BLOCK25AUTH', 0);
    if ($exim_conf{'block_25_auth'}) {
        $template->setCondition('BLOCK25AUTH', 1);
    }
    $template->setCondition('MASQUERADE_OUTGOING_HELO', 0);
    if ($exim_conf{'masquerade_outgoing_helo'}) {
        $template->setCondition('MASQUERADE_OUTGOING_HELO', 1);
    }
    $template->setCondition('LOG_SUBJECT', 0);
    if ($exim_conf{'log_subject'}) {
        $template->setCondition('LOG_SUBJECT', 1);
    }
    $template->setCondition('LOG_ATTACHMENTS', 0);
    if ($exim_conf{'log_attachments'}) {
        $template->setCondition('LOG_ATTACHMENTS', 1);
    }
    $template->setCondition('FORBIDCLEARAUTH', 0);
    if ($exim_conf{'forbid_clear_auth'} && $exim_conf{'__USE_INCOMINGTLS__'}) {
        $template->setCondition('FORBIDCLEARAUTH', 1);
    }
    $template->setCondition('PREVENTRELAYFROMUNKNOWNDOMAIN', 1);
    if ($exim_conf{'allow_relay_for_unknown_domains'}) {
        $template->setCondition('PREVENTRELAYFROMUNKNOWNDOMAIN', 0);
    }
    $template->setCondition('REJECTBADSPF', 0);
    if ($exim_conf{'reject_bad_spf'}) {
        $template->setCondition('REJECTBADSPF', 1);
    }
    $template->setCondition('REJECTBADRDNS', 0);
    if ($exim_conf{'reject_bad_rdns'}) {
        $template->setCondition('REJECTBADRDNS', 1);
    }
    $template->setCondition('REJECTDMARC', 0);
    if ($exim_conf{'dmarc_follow_reject_policy'}) {
        $template->setCondition('REJECTDMARC', 1);
    }
    $template->setCondition('DMARCREPORTING', 0);
    if ($exim_conf{'dmarc_enable_reports'}) {
        $template->setCondition('DMARCREPORTING', 1);
    }
    $template->setCondition('ERRORS_REPLY_TO', 0);
    if ($exim_conf{'__ERRORS_REPLY_TO__'} ne '') {
        $template->setCondition('ERRORS_REPLY_TO', 1);
    }

    $template->setCondition('__LISTS_PER_DOMAIN__', $exim_conf_lpd);

    my @net_interfaces = get_interfaces6();
    $template->setCondition('DISABLE_IPV6', 1);
    foreach my $interface (@net_interfaces){
        if ($interface =~ /eth\d*/ && ! is_ipv6_disabled($interface)) {
            $template->setCondition('DISABLE_IPV6', 0);
        }
    }

    $template->setReplacements(\%sys_conf);
    $template->setReplacements(\%exim_conf);

    my $ret = $template->dump() || die "Failed to dump $source to $destination: $!\n";

    # Below is not needed when we are generating the files included in exim configuration
    return $ret if ( $include_file );

    my $tmptarget_file = ${SRCDIR}."/etc/exim/exim_stage${stage}.conf";
    my $target_file = ${VARDIR}."/spool/tmp/exim/exim_stage${stage}.conf";
    move($tmptarget_file, $target_file);
    chown $uid, $gid, $target_file;

    return $ret;
}

#############################
sub dump_proxy_file($file, $smtp_proxy)
{
    my $port = 25;
    my $destinations = $smtp_proxy;
    if ($smtp_proxy =~ m/(.*)\/(\d+)+$/ ) {
        $destinations = $1;
        $port = $2;
    }

    my @dest_hosts;
    # parse for different hosts
    while ($destinations =~ m/^\s*:?\s*([a-zA-Z0-9\.\-\_\/]+(::\d+)?)(.*)/) {
        my $host = $1;
        if (defined($2)) {
            my $tmp_port = $2;
            $tmp_port =~ s/\:\://;
            $host =~ s/\:\:\d+//;
            push @dest_hosts, $host."::".$tmp_port;
        } else {
            push @dest_hosts, $host."::$port";
        }
        $destinations = "";
        if (defined($3)) {
            $destinations = $3;
            next;
        }

        if (defined($2) && $2 !~ /::\d+$/) {
            $destinations = $2;
            next;
        }
    }

    my $str = "*:\t\t";
    foreach my $dest (@dest_hosts) {
        $str .= $dest." \: ";
    }
    $str =~ s/\s*\:\s*$//;

    my $TARGET;
    confess "Cannot open $file: $!" unless ($TARGET = ${open_as($file, '>', 0664, 'mailcleaner:mailcleaner')});
    print $TARGET $str;
    close $TARGET;
}

#############################
sub get_system_config()
{
    my %sconfig = ();
    my %row = $db->getHashRow("SELECT hostname, default_domain, sysadmin, clientid, ad_server,
        ad_param, smtp_proxy, syslog_host, sc.use_syslog, do_stockme, use_ssl, servername,
        use_archiver, archiver_host, trusted_ips, html_wl_ips, tag_mode_bypass_whitelist,
        whitelist_both_from FROM system_conf sc, antispam an, httpd_config hc");
    return unless %row;

    $sconfig{'__PRIMARY_HOSTNAME__'} = $row{'hostname'};
    if (${MCHOSTNAME}) {
         $sconfig{'__PRIMARY_HOSTNAME__'} = ${MCHOSTNAME};
    }
    $sconfig{'__QUALIFY_DOMAIN__'} = `/bin/hostname --fqdn`;
    if (${DEFAULTDOMAIN} ne '') {
        $sconfig{'__QUALIFY_DOMAIN__'} =  ${DEFAULTDOMAIN};
    }
    if ($row{'default_domain'} =~ m/[^*]+/) {
        $sconfig{'__QUALIFY_DOMAIN__'} = $row{'default_domain'};
    }
    $sconfig{'__HELO_NAME__'} = $sconfig{'__QUALIFY_DOMAIN__'};
    if ($sconfig{'__HELO_NAME__'} !~ /\./) {
        my $ifconfig = `/sbin/ifconfig | /bin/grep 'inet addr' | /bin/grep -v '127.0.0.1'`;
        if ($ifconfig =~ /inet addr:([0-9.]+)/) {
            $sconfig{'__HELO_NAME__'} = $1;
        }
    }
    if (${HELONAME} ne '') {
        $sconfig{'__HELO_NAME__'} = ${HELONAME};
    }

    $sconfig{'__QUALIFY_RECIPIENT__'} = $row{'sysadmin'};
    $sconfig{'__AD_SERVERS__'} = "";
    if ($row{'ad_server'}) {
        $sconfig{'__AD_SERVERS__'} = $row{'ad_server'};
    }
    $sconfig{'__AD_BASEDN__'} = "";
    $sconfig{'__AD_BINDDN__'} = "";
    $sconfig{'__AD_PASS__'} = "";
    if ($row{'ad_param'}) {
        my ($ad_basedn, $ad_binddn, $ad_pass) = split(':', $row{'ad_param'});
        $sconfig{'__AD_BASEDN__'} = $ad_basedn;
        $sconfig{'__AD_BINDDN__'} = $ad_binddn;
        $sconfig{'__AD_PASS__'} = $ad_pass;
    }
    $sconfig{'__SMTP_PROXY__'} = $row{'smtp_proxy'};
    $sconfig{'__SYSLOG_HOST__'} = $row{'syslog_host'};
    if ( -f "${SRCDIR}/etc/mailcleaner/syslog/force_syslog_on_this_host" ) {
        if (open(my $FH, '<', "${SRCDIR}/etc/mailcleaner/syslog/force_syslog_on_this_host") ) {
            my $line = <$FH>;
            chomp $line;
            $sconfig{'__SYSLOG_HOST__'} = $line;
            close $FH;
        }
    }
    $sconfig{'__ANTISPAM_SYSLOG__'} = $row{'use_syslog'};
    $sconfig{'__STOCKME__'} = $row{'do_stockme'};

    $sconfig{'use_archiver'} = $row{'use_archiver'};
    if ($row{'archiver_host'}) {
        $sconfig{'__ARCHIVER_HOST__'} = $row{'archiver_host'};
        $sconfig{'__ARCHIVER_PORT__'} = $row{'archiver_host'};
        $sconfig{'__ARCHIVER_HOST__'} =~ s/\:\d+$//;
        $sconfig{'__ARCHIVER_PORT__'} =~ s/^[^:]+://;
    } else {
        $sconfig{'__ARCHIVER_HOST__'} = '';
        $sconfig{'__ARCHIVER_PORT__'} = '';
    }
    $sconfig{'__TRUSTED_HOSTS__'} = '';
    if ($row{'trusted_ips'}) {
        $sconfig{'__TRUSTED_HOSTS__'} = join(' ; ', expand_host_string($row{'trusted_ips'},('dumper'=>'exim/trusted_hosts')));
    }
    $sconfig{'__HTML_CTRL_WL_HOSTS__'} = '';
    if ($row{'html_wl_ips'}) {
        $sconfig{'__HTML_CTRL_WL_HOSTS__'} = join(' ; ', expand_host_string($row{'html_wl_ips'},('dumper'=>'exim/html_ctrl_wl_hosts')));
    }
    $sconfig{'__TAGMODEBYPASSWHITELISTS__'} = $row{'tag_mode_bypass_whitelist'};
    $sconfig{'__WHITELISTBOTHFROM__'} = $row{'whitelist_both_from'};


    my $http = "http://";
    if ( $row{'use_ssl'} =~ /true/i ) {
        $http = "https://";
    }
    my $baseurl = $http.$row{'servername'};
    $sconfig{'__REPORT_URL__'} = $baseurl."/rs.php";

    return %sconfig;
}

#############################
sub get_master()
{
    my %master = ();

    my %row = $db->getHashRow("SELECT hostname, port, password FROM master");
    return unless %row;

    $master{'host'} = $row{'hostname'};
    $master{'port'} = $row{'port'};
    $master{'password'} = $row{'password'};

    return %master;
}

#############################
sub dump_master_file($file, $m_h)
{
    my %master = %$m_h;

    my $MASTERFILE;
    confess "Cannot open $file: $!" unless ($MASTERFILE = ${open_as($file, '>', 0664, 'mailcleaner:mailcleaner')});

    print $MASTERFILE "HOST ".$master{'host'}."\n";
    print $MASTERFILE "PORT ".$master{'port'}."\n";
    print $MASTERFILE "PASS ".$master{'password'}."\n";
    close $MASTERFILE;
    return 1;
}

#############################
sub dump_stockme_file()
{

    my $template = ConfigTemplate::create(
        "etc/exim/stockme_template",
        "etc/exim/stockme"
    );

    $template->setCondition('STOCK', 0);
    if ($sys_conf{'__STOCKME__'}) {
        $template->setCondition('STOCK', 1);
    }
    my $ret = $template->dump();

    my $target_file = ${SRCDIR}."/etc/exim/stockme";
    chown $uid, $gid, $target_file;
    return $ret;
}

#############################
sub dump_spam_route()
{
    my $template = ConfigTemplate::create(
        "scripts/exim/spam_route.template.pl",
        "scripts/exim/spam_route.opt.pl"
    );

    my $template2 = ConfigTemplate::create(
        "etc/exim/spam_route.template.pl",
        "etc/exim/spam_route.opt.pl"
    );

    my %replace = ();
    my $rblstags = "";
    my @rbls = $db->getListOfHash("SELECT name FROM dnslist;");
    foreach my $rblh (@rbls) {
        my %rbl = %$rblh;
        $rblstags .= "'".$rbl{'name'}."',";
    }
    $rblstags =~ s/,$//;
    $rblstags =~ s/\+/\\+/g;
    my $pftags;
    my @prefilters = $db->getListOfHash("SELECT name FROM prefilter;");
    foreach my $pfh (@prefilters) {
        my %pf = %$pfh;
        $pftags .= "'".$pf{'name'}."',";
    }
    $pftags =~ s/,$//;

    $replace{'\'__RBLS_TAGS__\''} = $rblstags;
    $replace{'\'__PREFILTERS_TAGS__\''} = $pftags;
    $template->setReplacements(\%replace);
    $template2->setReplacements(\%replace);

    $template2->dump();
    my $ret = $template->dump();

    my $target_file = ${SRCDIR}."/scripts/exim/spam_route.opt.pl";

    my $bytecompiledscript = ${SRCDIR}."/scripts/exim/spam_route.bbin";
    if ( -f $bytecompiledscript) {
        unlink $bytecompiledscript;
    }
    my $compile = "perlcc -B $target_file >/dev/null 2>&1; mv a.out $bytecompiledscript >/dev/null 2>&1;";
    `$compile`;

    chown $uid, $gid, $target_file;
    chmod 0754, $target_file;
    chown $uid, $gid, $bytecompiledscript;
    chmod 0754, $bytecompiledscript;

    my $template3 = ConfigTemplate::create(
        "etc/exim/out_scripts.pl_template",
        "etc/exim/out_scripts.pl"
    );
    $template3->dump();

    my $template4 = ConfigTemplate::create(
        "etc/exim/stage1_scripts.pl_template",
        "etc/exim/stage1_scripts.pl"
    );
    $template4->dump();

    my $template5 = ConfigTemplate::create(
        "etc/exim/address_list.pl_template",
        "etc/exim/address_list.pl"
    );
    $template5->dump();
    chown $uid, $gid, ${SRCDIR}."/etc/exim/address_list.pl";
    chmod 0755, ${SRCDIR}."/etc/exim/address_list.pl";
    return $ret;

}

#############################
sub dump_syslog_config()
{
    my $file = "/etc/syslog.conf";
    if ( -d "/etc/rsyslog.d" ) {
        $file = "/etc/rsyslog.d/mailcleaner.conf";
    }

    my $cmd = "";
    if ( -f $file) {
        $cmd = "perl -pi -e 's/\^\\n\$//g' $file";
        `$cmd`;

        $cmd = "perl -pi -e 's/\^local[012]\.\*\ +@.*\$//g' $file";
        `$cmd`;
    }

    if ( -d "/etc/rsyslog.d" ) {
        $cmd = "echo \"local0.info     -".${VARDIR}."/log/mailscanner/infolog \
local0.warn     -".${VARDIR}."/log/mailscanner/warnlog \
local0.err      ".${VARDIR}."/log/mailscanner/errorlog\n\" > $file";
        `$cmd`;
    }

    if (!$sys_conf{'__SYSLOG_HOST__'}) {
        return;
    }
    $cmd = "echo \"";
    #if ( $sys_conf{'__ANTISPAM_SYSLOG__'} && $sys_conf{'__SYSLOG_HOST__'}) {
        $cmd .= "local0.*   @".$sys_conf{'__SYSLOG_HOST__'}."\n";
    #}
    $cmd .= "local1.*   @".$sys_conf{'__SYSLOG_HOST__'}."\n";
    $cmd .= "local2.*   @".$sys_conf{'__SYSLOG_HOST__'}."\" >> $file";
   `$cmd`;
}

#############################
sub get_exim_config($stage)
{
    my %config = ();
    my %row = $db->getHashRow("SELECT * FROM mta_config WHERE stage=${stage}");
    return unless %row;

    $config{'__SMTP_ACCEPT_MAX_PER_HOST__'} = $row{'smtp_accept_max_per_host'};
    $config{'__SMTP_ACCEPT_MAX_PER_TRUSTED_HOST__'} = $row{'smtp_accept_max_per_trusted_host'} || 0;
    $config{'__CIPHERS__'} = $row{'ciphers'};
    if ($config{'__CIPHERS__'} eq '') {
        $config{'__CIPHERS__'} = 'ALL:!aNULL:!ADH:!eNULL:!LOW:!EXP:RC4+RSA:+HIGH:+MEDIUM:!SSLv2';
    }
    $config{'__SMTP_RECEIVE_TIMEOUT__'} = $row{'smtp_receive_timeout'};
    $config{'__SMTP_ACCEPT_MAX__'} = $row{'smtp_accept_max'};
    $config{'__SMTP_RESERVE__'} = $row{'smtp_reserve'};
    $config{'__SMTP_ACCEPT_QUEUE_PER_CONNECTION__'} = $row{'smtp_accept_queue_per_connection'};
    $config{'__SMTP_ACCEPT_MAX_PER_CONNECTION__'} = $row{'smtp_accept_max_per_connection'};
    $config{'__IGNORE_BOUNCE_ERROR_AFTER__'} = $row{'ignore_bounce_after'};
    $config{'__TIMEOUT_FROZEN_AFTER__'} = $row{'timeout_frozen_after'};
    $config{'__RECEIVED_HEADER_TEXT__'} = $row{'header_txt'};
    $config{'__RELAY_FROM_HOSTS__'} = $row{'relay_from_hosts'};
    if ($config{'__RELAY_FROM_HOSTS__'}) {
        $config{'__RELAY_FROM_HOSTS__'} = join(' ; ',expand_host_string($config{'__RELAY_FROM_HOSTS__'},('dumper'=>'exim/relay_from_hosts')));
    }
    my $dns = GetDNS->new();
    $config{'__NO_RATELIMIT_HOSTS__'} = $dns->getA($m_infos{'host'}) || '';
    if (defined( $row{'no_ratelimit_hosts'}) && $row{'no_ratelimit_hosts'} ne '' ) {
        $config{'__NO_RATELIMIT_HOSTS__'} = join(' ; ',expand_host_string($config{'__NO_RATELIMIT_HOSTS__'} . ' ' . $row{'no_ratelimit_hosts'},('dumper'=>'exim/no_ratelimit_hosts')));
    }
    if (!defined($config{'__RELAY_FROM_HOSTS__'})) {
        $config{'__RELAY_FROM_HOSTS__'} = '';
    }
    if (defined( $row{'hosts_require_tls'}) ) {
        $config{'__HOSTS_REQUIRE_TLS__'} = $row{'hosts_require_tls'};
    } else {
        $config{'__HOSTS_REQUIRE_TLS__'} = '';
    }
    if ($config{'__HOSTS_REQUIRE_TLS__'}) {
        $config{'__HOSTS_REQUIRE_TLS__'} = join(' ; ',expand_host_string($config{'__HOSTS_REQUIRE_TLS__'},('dumper'=>'exim/hosts_require_tls')));
    }

    if (defined( $row{'hosts_require_incoming_tls'}) ) {
        $config{'__HOSTS_REQUIRE_INCOMING_TLS__'} = $row{'hosts_require_incoming_tls'};
    } else {
        $config{'__HOSTS_REQUIRE_INCOMING_TLS__'} = '';
    }
    if ($config{'__HOSTS_REQUIRE_INCOMING_TLS__'}) {
        $config{'__HOSTS_REQUIRE_INCOMING_TLS__'} =~ s/\r\n/ ; /g;
        $config{'__HOSTS_REQUIRE_INCOMING_TLS__'} =~ s/\n/ ; /g;
    }

    foreach my $f ( ('domains_require_tls_from', 'domains_require_tls_to')) {
        my $o = '__'.uc($f).'__';
        if (defined( $row{$f}) ) {
            $config{$o} = $row{$f};
        } else {
            $config{$o} = '';
        }
        if ($config{$o}) {
            $config{$o} =~ s/[:, ]/\n/g;
        }
    }
    $config{'relay_refused_to_domain'} = '';
    if (defined($row{'relay_refused_to_domains'})) {
        $config{'relay_refused_to_domain'} = $row{'relay_refused_to_domains'};
    }

    $config{'__SMTP_CONN_ACCESS__'} = $row{'smtp_conn_access'};
    if ($config{'__SMTP_CONN_ACCESS__'}) {
        $config{'__SMTP_CONN_ACCESS__'} = join(' ; ',expand_host_string($config{'__SMTP_CONN_ACCESS__'},('dumper'=>'exim/smtp_conn_access')));
    }
    $config{'__MAX_RCPT__'} = $row{'max_rcpt'};
    $config{'__MAX_RECEIVED__'} = $row{'received_headers_max'};
    $config{'__SMTP_LOAD_RESERVE__'} = $row{'smtp_load_reserve'};
    $config{'__VERIFY_SENDER__'} = 0;
    $config{'__GLOBAL_MAXMSGSIZE__'} = $row{'global_msg_max_size'};
    if (!defined($config{'__GLOBAL_MAXMSGSIZE__'}) || $config{'__GLOBAL_MAXMSGSIZE__'} !~ /^\d+[KM]?$/) {
        $config{'__GLOBAL_MAXMSGSIZE__'} = '50M';
    }
    if ($row{'verify_sender'}) {
        $config{'__VERIFY_SENDER__'} = 1;
    }
    $config{'__SMTP_ENFORCE_SYNC__'} = $row{'smtp_enforce_sync'};
    $config{'__ALLOW_MX_TO_IP__'} = $row{'allow_mx_to_ip'};

    my $rblsstring = '';
    if ($row{'rbls'}) {
        $rblsstring = $row{'rbls'};
    }
    my $bsrblsstring = '';
    if ($row{'bs_rbls'}) {
        $bsrblsstring = $row{'bs_rbls'};
    }

    my $dnslists = MCDnsLists->new(\&log_dns, 1);
    $dnslists->loadRBLs( ${SRCDIR}."/etc/rbls",
        $rblsstring, 'IPRBL', '', '', '' , 'dump_exim');

    my $rbls = $dnslists->getAllRBLs();
    my $useablrbls = $dnslists->getUseablRBLs();

    my $rbl_exim_string = '';
    my %rbls = %{$rbls};
    foreach my $r (@{$useablrbls}) {
        next if (! defined($rbls{$r}{'dnsname'}));
        $rbl_exim_string .= ' : '.$rbls{$r}{'dnsname'};
    }
    $rbl_exim_string =~ s/^\s*:\s*//;

    my $bsdnslists = MCDnsLists->new(\&log_dns, 1);
    $bsdnslists->loadRBLs( ${SRCDIR}."/etc/rbls",
        $bsrblsstring, 'BSRBL', '', '', '' , 'dump_exim');

    my $bsrbls = $bsdnslists->getAllRBLs();
    my $useablbsrbls = $bsdnslists->getUseablRBLs();

    my $bsrbl_exim_string = '';
    my %bsrbls = %{$bsrbls};
    foreach my $r (@{$useablbsrbls}) {
        next if (! defined($bsrbls{$r}{'dnsname'}));
        $bsrbl_exim_string .= ' : '.$bsrbls{$r}{'dnsname'};
    }
    $bsrbl_exim_string =~ s/^\s*:\s*//;

    $config{'__RBLS__'} = $rbl_exim_string;
    $config{'__RCPTRBLS__'} = $row{'rbls_after_rcpt'};
    $config{'__RBLTIMEOUT__'} = $row{'rbls_timeout'};
    $config{'rbls_ignore_hosts'} = $row{'rbls_ignore_hosts'};
    $config{'spf_dmarc_ignore_hosts'} = $row{'spf_dmarc_ignore_hosts'};
    $config{'__BSRBLS__'} = $bsrbl_exim_string;
    $config{'__RATELIMIT_ENABLE__'} = $row{'ratelimit_enable'};
    $config{'__RATELIMIT_RULE__'} = $row{'ratelimit_rule'};
    $config{'__RATELIMIT_DELAY__'} = $row{'ratelimit_delay'};
    $config{'__TRUSTED_RATELIMIT_ENABLE__'} = $row{'trusted_ratelimit_enable'};
    $config{'__TRUSTED_RATELIMIT_RULE__'} = $row{'trusted_ratelimit_rule'};
    $config{'__TRUSTED_RATELIMIT_DELAY__'} = $row{'trusted_ratelimit_delay'};
    $config{'__CALLOUT_TIMEOUT__'} = $row{'callout_timeout'};
    $config{'__RETRY_RULE__'} = $row{'retry_rule'};

    my $certname = 'default';
    $config{'__USE_INCOMINGTLS__'} = 0;
    if ($row{'use_incoming_tls'}) {
        $config{'__USE_INCOMINGTLS__'} = 1;
    }
    if (defined($row{'tls_certificate'}) && ! ($row{'tls_certificate'} eq '') ) {
        $certname = $row{'tls_certificate'};
    }
    $config{'tls_certificate_data'} = $row{'tls_certificate_data'};
    $config{'tls_certificate_key'} = $row{'tls_certificate_key'};
    $config{'__TLSSERT__'} = $certname.".crt";
    $config{'__TLSPRIVATEKEY__'} = $certname.".pkey";
    $config{'__USE_SYSLOG__'} = $row{'use_syslog'};
    $config{'__SMTP_BANNER__'} = $row{'smtp_banner'};
    $config{'__ERRORS_REPLY_TO__'} = $row{'errors_reply_to'};

    if ( -f "${SRCDIR}/etc/mailcleaner/version.def" && -f "${SRCDIR}/etc/edition.def") {
        my ($version, $cmd) = ('', '');
        unless (-f "${VARDIR}/spool/mailcleaner/hide_smtp_version") {
            $cmd = "cat ${SRCDIR}/etc/mailcleaner/version.def";
            $version = `$cmd`;
            chomp($version);
            $version = ' '.$version;
        }
        $cmd = "cat ".${SRCDIR}."/etc/edition.def";
        my $edition = `$cmd`;
        chomp($edition);
        $config{'__SMTP_BANNER__'} = '$smtp_active_hostname ESMTP MailCleaner ('.$edition.$version.') $tod_full';
    }

    $config{'host_reject'} = $row{'host_reject'};
    $config{'sender_reject'} = $row{'sender_reject'};
    $config{'user_reject'} = $row{'user_reject'};
    $config{'recipient_reject'} = $row{'recipient_reject'};
    $config{'tls_use_ssmtp_port'} = $row{'tls_use_ssmtp_port'};
    $config{'outgoing_virus_scan'} = $row{'outgoing_virus_scan'};
    $config{'mask_relayed_ip'} = $row{'mask_relayed_ip'};
    $config{'block_25_auth'} = $row{'block_25_auth'};
    $config{'masquerade_outgoing_helo'} = $row{'masquerade_outgoing_helo'};
    $config{'log_subject'} = $row{'log_subject'};
    $config{'log_attachments'} = $row{'log_attachments'};
    $config{'reject_bad_spf'} = $row{'reject_bad_spf'};
    $config{'reject_bad_rdns'} = $row{'reject_bad_rdns'};
    $config{'dmarc_follow_reject_policy'} = $row{'dmarc_follow_reject_policy'};
    $config{'dmarc_enable_reports'} = $row{'dmarc_enable_reports'};
    $config{'forbid_clear_auth'} = $row{'forbid_clear_auth'};
    $config{'dkim_default_domain'} = $row{'dkim_default_domain'};
    $config{'dkim_default_pkey'} = $row{'dkim_default_pkey'};
    $config{'allow_relay_for_unknown_domains'} = $row{'allow_relay_for_unknown_domains'};
    $config{'__FULL_WHITELIST_HOSTS__'} = '';
    my $fh;
    if (-e "${VARDIR}/spool/mailcleaner/full_whitelisted_hosts.list") {
        open($fh, '<', "${VARDIR}/spool/mailcleaner/full_whitelisted_hosts.list") ||
            confess "Cannot open ${VARDIR}/spool/mailcleaner/full_whitelisted_hosts.list: $!";
        while (<$fh>) {
            $config{'__FULL_WHITELIST_HOSTS__'} .= $_ . ' ';
        }
        chomp($config{'__FULL_WHITELIST_HOSTS__'});
    } else {
        touch "${VARDIR}/spool/mailcleaner/full_whitelisted_hosts.list";
    }
    unless (-e "${VARDIR}/spool/mailcleaner/full_whitelisted_senders.list") {
        touch "${VARDIR}/spool/mailcleaner/full_whitelisted_senders.list";
    }
    if ($config{'__FULL_WHITELIST_HOSTS__'} ne '') {
        $config{'__FULL_WHITELIST_HOSTS__'} = join(' ; ',expand_host_string($config{'__FULL_WHITELIST_HOSTS__'},('dumper'=>'exim/full_whitelist_hosts')));
    }
    $config{'__ALLOW_LONG__'} = $row{'allow_long'};
    $config{'__FOLDING__'} = $row{'folding'};
    my $max_length;
    if ( -e '${SPMC}/exim_max_line_length' ) {
        open(my $fh, '<', "${SPMC}/exim_max_line_length") ||
            confess "Cannot open ${SPMC}/exim_max_line_length: $!";
        $max_length = <$fh>;
        chomp($max_length);
        close($fh);
    }
    $max_length = 5000000 unless (defined($max_length) && $max_length =~ m/^\d+$/);
    $config{'__LENGTH_LIMIT__'} = $max_length;
    return %config;
}

#############################
sub dump_ignore_list($ignorehosts,$filename)
{
    my $file = $tmpdir.'/'.$filename;

    my @list = expand_host_string($ignorehosts,('dumper'=>'exim/dump_ignore_list/'.$filename));
    my $RBLFILE;
    confess "Cannot open $file: $!" unless ($RBLFILE = ${open_as($file, '>', 0664, 'mailcleaner:mailcleaner')});
    foreach my $host (@list) {
        print $RBLFILE $host."\n";
    }
    close $RBLFILE;
}

###############################
sub dump_blacklists()
{
    my %files = (
        host_reject => 'blacklists/hosts',
        sender_reject => 'blacklists/senders',
        user_reject => 'blacklists/users',
        recipient_reject => 'blacklists/recipients',
        relay_refused_to_domain => 'blacklists/relaytodomains'
    );
    unless ( -d $tmpdir."/blacklists" ) {
        confess "Cannot mkdir $tmpdir/blacklists: $!" unless make_path($tmpdir."/blacklists",{'mode'=>0755,'user'=>'mailcleaner','group'=>'mailcleaner'});
    }
    my %incoming_config = get_exim_config(1);
    foreach my $file (keys %files) {
        my $filepath = $tmpdir."/".$files{$file};

        my $FILE;
        confess "Cannot open $file: $!" unless ($FILE = ${open_as($filepath, '>', 0664, 'mailcleaner:mailcleaner')});
        if ($incoming_config{$file}) {
            if ($file =~ /host_reject/) {
                foreach my $host (expand_host_string($incoming_config{$file},('dumper'=>'exim/dump_blacklists/'.$file))) {
                    print $FILE $host."\n";
                }
            } else {
                foreach my $host (split(/[\n\s:;]/, $incoming_config{$file})) {
                    print $FILE $host."\n";
                }
            }
        }
        close $FILE;
    }
}


#############################
sub dump_lists_ip_domain()
{
    my @types = ('black-ip-dom', 'spam-ip-dom', 'white-ip-dom', 'wh-spamc-ip-dom');
    unlink ${VARDIR} . '/spool/tmp/exim_stage1/blacklists/ip-domain';
    unlink glob ${VARDIR} . "/spool/tmp/exim_stage1/rblwhitelists/*";
    unlink glob ${VARDIR} . "/spool/tmp/exim_stage1/spamcwhitelists/*";

    my $request = "SELECT count(*) FROM wwlists where type in (";
    foreach my $type (@types) {
        $request .= "'$type', ";
    }
    $request =~ s/, $/);/;
    my $count = $db->getCount($request);
    if ($count eq 0) {
        return 0;
    }

    foreach my $type (@types) {
        my @row = $db->getListOfHash("SELECT sender, recipient FROM wwlists where type = '$type' order by recipient");
        my $array_i = scalar @row;

        next if ( ! $array_i );

        my $last_domain = '';
        my $sender_list = '';
        my $i=0;

        foreach my $line (@row) {
            my $current_domain = $$line{'recipient'};
            $last_domain = $$line{'recipient'}      if ($last_domain eq '');

            if ( $current_domain ne $last_domain ) {
                print_ip_domain_rule($sender_list, $last_domain, $type);
                $sender_list = $$line{'sender'} .' ; ';
                $last_domain = $current_domain;
            } else {
                $sender_list .= $$line{'sender'} .' ; ';
            }
            $i++;
        }
        print_ip_domain_rule($sender_list, $last_domain, $type);
    }
    return 1;
}

#############################
sub print_ip_domain_rule($sender_list, $domain, $type)
{
    my $smtp_rule = '';

    my $path = "${VARDIR}/spool/tmp/exim_stage1";
    my $FH_IP_DOM;
    if ( ($type eq 'black-ip-dom') || ($type eq 'spam-ip-dom') )  {
        confess "Cannot open $path/blacklists/ip-domain: $!" unless ($FH_IP_DOM = ${open_as("$path/blacklists/ip-domain",'>>',0664,'mailcleaner:mailcleaner')});
    } elsif ($type eq 'white-ip-dom') {
        confess "Cannot open $path/rblwhitelists/$domain: $!" unless ($FH_IP_DOM = ${open_as("$path/rblwhitelists/$domain",'>>',0664,'mailcleaner:mailcleaner')});
    } elsif ($type eq 'wh-spamc-ip-dom') {
        confess "Cannot open $path/spamcwhitelists/$domain: $!" unless ($FH_IP_DOM = ${open_as("$path/spamcwhitelists/$domain",'>>',0664,'mailcleaner:mailcleaner')});
    }

    $sender_list = join(' ; ', expand_host_string($sender_list,('dumper'=>'exim/sender_list')));
    if ($type eq 'spam-ip-dom') {
        $smtp_rule = <<"END";
warn    hosts         = <; $sender_list
        domains       = <; $domain
    add_header    = X-MailCleaner-Black-IP-DOM: quarantine

END
    } elsif ($type eq 'black-ip-dom') {
        $smtp_rule = <<"END";
deny    hosts         = <; $sender_list
        domains       = <; $domain
        message       = blacklisted host by domain: \$sender_host_address
        set acl_c8    = smtp:refused:host_blacklist
        set acl_c9    = STATSADD
        set acl_c8    = smtp:refused
        set acl_c9    = STATSADD

END
    } elsif ( ($type eq 'white-ip-dom') || ($type eq 'wh-spamc-ip-dom') ) {
        my @arr = split(' ; ', $sender_list);
        foreach ( @arr ) {
            $smtp_rule .= "$_\n";
        }
    }

    print $FH_IP_DOM $smtp_rule;
    close $FH_IP_DOM;
}

sub dump_certificate($cert,$key)
{
    my $backup_path = ${SRCDIR}."/etc/exim/certs/";

    my $cmd;
    my $certfile = $tmpdir."/certificate";
    if (!$cert || $cert =~ /^\s+$/) {
        $cmd = "cp -a ".$backup_path."default.crt ".$certfile;
        `$cmd`;
    } else {
        $cert =~ s/\r\n/\n/g;
        my $FILE;
        confess "Cannot open $certfile: $!" unless ($FILE = ${open_as($certfile,'>',0664,'mailcleaner:mailcleaner')});
        print $FILE $cert."\n";
        close $FILE;
    }

    my $keyfile = $tmpdir."/privatekey";
    if (!$key || $key =~ /^\s+$/) {
        $cmd = "cp -a ".$backup_path."default.pkey ".$keyfile;
        `$cmd`;
    } else {
        $key =~ s/\r\n/\n/g;
        my $FILE;
        confess "Cannot open $keyfile: $!" unless ($FILE = ${open_as($keyfile,'>',0664,'mailcleaner:mailcleaner')});
        print $FILE $key."\n";
        close $FILE;
    }
}

sub dump_default_dkim($stage1_conf)
{
    my $keypath = ${VARDIR}."/spool/tmp/mailcleaner/dkim";
    if (! -d $keypath) {
        make_path($keypath);
    }
    my $keyfile = $keypath."/default.pkey";
    my ($FILE, $DEFAULT);
    confess "Cannot open $keyfile: $!" unless ($FILE = ${open_as($keyfile, '>', 0664, 'mailcleaner:mailcleaner')});
    if (defined($stage1_conf{'dkim_default_pkey'})) {
        if ( -e $keypath."/".$stage1_conf{'dkim_default_domain'}.".pkey" ) {
            open($DEFAULT, '<', $keypath."/".$stage1_conf{'dkim_default_domain'}.".pkey");
            while (<$DEFAULT>) {
                print $FILE $_;
            }
            close $DEFAULT;
        } else {
            print $FILE $stage1_conf{'dkim_default_pkey'}."\n";
        }
    }
    close $FILE;
}

#############################
sub dump_tls_force_files()
{
    foreach my $f ( ('domains_require_tls_from', 'domains_require_tls_to') ) {
        my $o = '__'.uc($f).'__';
        my $file = ${VARDIR}."/spool/tmp/mailcleaner/".$f.".list";
        my $FILE;
        confess "Cannot open $file: $!" unless ($FILE = ${open_as($file,'>',0664,'mailcleaner:mailcleaner')});
        print $FILE $exim_conf{$o};
        close $FILE;
    }
}

#############################
sub print_usage()
{
    print "Bad usage: dump_exim_config.pl [stage-id]\n\twhere stage-id is an integer between 0 and 4 (0 or null for all).\n";
    exit(0);
}

#############################
sub get_interfaces6()
{
    my $interface_file = "/etc/network/interfaces";
    my @interfaces;

    open (my $fh, '<', $interface_file) or die "could not open interface file";
    my $name;
    while (my $row = <$fh>){
        chomp $row;
        if (defined($name)) {
            push @interfaces, $1 if ($row =~ m/\d+\:\d+/);
            $name = undef;
        }
        if($row =~ /^iface\s+(\w+).+$/){
            $name = $1;
        }
    }
    return @interfaces;
}

sub is_ipv6_disabled($interface)
{
    my $sysctl_result = `sysctl -a 2>&1 | grep disable_ipv6 | grep $interface`;
    if($sysctl_result =~ /^net\.ipv6\.conf\.$interface\.disable_ipv6\s=\s(\d)$/){
        return $1
    } else {
        return 0
    }
}

sub expand_host_string($string,%args)
{
    my $dns = GetDNS->new();
    return $dns->dumper($string,%args);
}

sub log_dns($str)
{
    #print "$str\n";
}

sub ownership($stage)
{
    use File::Touch qw( touch );

    mkdir('/etc/sudoers.d') unless (-d '/etc/sudoers.d/');
    if (open(my $fh, '>', '/etc/sudoers.d/exim')) {
        print $fh "
User_Alias  EXIMUSER = mailcleaner
Cmnd_Alias  EXIMBIN = /opt/exim4/bin/exim

EXIMUSER    * = (ROOT) NOPASSWD: EXIMBIN
";
    }

    my @dirs = (
        "${VARDIR}/log/exim_stage${stage}",
        "${VARDIR}/spool/tmp/exim_stage${stage}",
        "${VARDIR}/spool/exim_stage${stage}",
        glob("${VARDIR}/spool/tmp/exim_stage${stage}/*"),
        glob("${VARDIR}/spool/exim_stage${stage}/*"),
    );
    push(@dirs,
        "${SRCDIR}/etc/exim/certs",
        "${VARDIR}/spool/tmp/exim",
        "${VARDIR}/spool/tmp/exim/blacklists",
        "${VARDIR}/spool/tmp/exim/certs",
        "${VARDIR}/spool/exim_stage${stage}/input",
        glob("${VARDIR}/spool/exim_stage${stage}/input/*"),
    ) if ($stage == 1);
    push(@dirs,
        "${VARDIR}/spool/exim_stage${stage}/paniclog",
        "${VARDIR}/spool/exim_stage${stage}/spamstore",
        "${VARDIR}/spool/tmp/mailcleaner/dkim",
        glob("${VARDIR}/spool/tmp/mailcleaner/dkim"),
    ) if ($stage == 4);
    foreach my $dir (@dirs) {
        mkdir ($dir) unless (-d $dir);
        chown($uid, $gid, $dir);
    }

    my @files = (
        glob("${VARDIR}/log/exim_stage${stage}/*"),
        glob("${VARDIR}/spool/exim_stage${stage}/db/*"),
        glob("${VARDIR}/spool/tmp/mailcleaner/*.list"),
    );
    push (@files,
        "${SRCDIR}/etc/exim/stage1_scripts.pl",
        "${SRCDIR}/etc/exim/out_scripts.pl",
        "${VARDIR}/spool/tmp/exim/frozen_senders",
        "${VARDIR}/spool/tmp/exim/dmarc.history",
        "${VARDIR}/spool/tmp/exim/blacklists/hosts",
        "${VARDIR}/spool/tmp/exim/blacklists/senders",
        "${VARDIR}/spool/mailcleaner/full_whitelisted_hosts.list",
        "${VARDIR}/spool/mailcleaner/full_whitelisted_senders.list",
        glob("${SRCDIR}/etc/exim/certs/*"),
        glob("${VARDIR}/spool/tmp/mailcleaner/dkim/*"),
    ) if ($stage == 1);
    push (@files,
        glob("${SRCDIR}/etc/exim/certs/*"),
        glob("${VARDIR}/spool/tmp/mailcleaner/dkim/*"),
    ) if ($stage == 4);
    foreach my $file (@files) {
        touch($file) unless (-e $file);
        chown($uid, $gid, $file);
        if ($file =~ m/\.pl$/) {
            chmod 0774, $file;
        } else {
            chmod 0664, $file;
        }
    }

    if ($stage == 1) {
        unlink("${VARDIR}/spool/exim_stage1/db/callout") if (-e "${VARDIR}/spool/exim_stage1/db/callout");
        foreach (glob("${VARDIR}/spool/tmp/exim/certs/*")) {
            unlink($_) unless (-l $_);
        }
        foreach (glob("${SRCDIR}/etc/exim/certs/*")) {
            my ($file) = $_ =~ m#.*/([^/]+)$#;
            $file = "${VARDIR}/spool/tmp/exim/certs/${file}";
            symlink($_, $file) unless (-e $file && readlink($file) eq $_);
        }
    }

    symlink($SRCDIR.'/etc/apparmor', '/etc/apparmor.d/mailcleaner') unless (-e '/etc/apparmor.d/mailcleaner');

    # Reload AppArmor rules
    `apparmor_parser -r ${SRCDIR}/etc/apparmor.d/exim` if ( -d '/sys/kernel/security/apparmor' );

    my $dir = "${SRCDIR}/etc/exim/stage${stage}";
    if (-d $dir) {
        chown($uid, $gid, $dir);
        chown($uid, $gid, $_) foreach (glob("$dir/*"));
    }
}

sub fatal_error($msg,$full)
{
    print $msg . ($DEBUG ? "\nFull information: $full \n" : "\n");
}
