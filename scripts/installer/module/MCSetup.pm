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

package module::MCSetup;

use v5.36;
use strict;
use warnings;
use utf8;

require Exporter;
require DialogFactory;
BEGIN {
    if ($0 =~ m/(\S*)\/\S+\.pl/) {
        my $path = $1."/../../lib";
        unshift (@INC, $path);
    }
    require ReadConfig;
}

our @ISA = qw(Exporter);
our @EXPORT = qw(get ask do);
our $VERSION = 1.0;
my $conf = ReadConfig::getInstance();

sub get
{
    my $this = {
        logfile => '/tmp/mailcleaner_install.log',
        srcdir => '/usr/mailcleaner',
        vardir => '/var/mailcleaner',
        logfile => '/tmp/mailcleaner_install.log',
        conffile => '/etc/mailcleaner.conf'
    };

    bless $this, 'module::MCSetup';
    return $this;
}

sub do($this)
{
    my $dfact = DialogFactory::get('InLine');
    my $dlg = $dfact->getSimpleDialog();
    my $yndlg = $dfact->getYesNoDialog();

    unless ($this->isBootstrapped) {
        print "Configuring Debian...\n";
        `cd $this->{srcdir}; debian-bootstrap/install.sh`;
    }
    unless ($this->isInstalled) {
        `$this->{srcdir}/install/install.sh`;
    }

    $dlg->clear();
    print "MailCleaner installation\n";
    print "------------------------\n\n";

    my $hostid = $conf->{HOSTID} || 1;
    $dlg->build('Enter the unique ID of this MailCleaner in your infrastucture', $hostid);
    $hostid = $dlg->display();

    my $domain = '';

    my $pass1 = '-';
    my $pass2 = '';
    my $pdlg = $dfact->getPasswordDialog();
    while ( $pass1 ne $pass2) {
        print "Password mismatch, please try again.\n" if ! $pass2 eq '';
        $pdlg->build('Enter the admin user password for the web interface', '');
        $pass1 = $pdlg->display();
        $pdlg->build('Please confirm the admin user password', '');
        $pass2 = $pdlg->display();
    }

    ## setting environment variable
    my $hostname = `hostname`;
    chomp $hostname;
    $ENV{'SRCDIR'} = $conf->{SRCDIR} || $this->{srcdir};
    $ENV{'VARDIR'} = $conf->{VARDIR} || $this->{vardir};
    $ENV{'HOSTID'} = $hostid;
    $ENV{'MCHOSTNAME'} = $conf->{MCHOSTNAME} || $hostname;
    $ENV{'DEFAULTDOMAIN'} = $conf->{DEFAULTDOMAIN} || $domain;
    if (defined($conf->{ISMASTER}) && $conf->{ISMASTER} eq 'N') {
        $ENV{'ISSLAVE'} = 'Y';
        $ENV{'ISMASTER'} = 'N';
    } else {
        $ENV{'ISSLAVE'} = 'N';
        $ENV{'ISMASTER'} = 'Y';
    }
    $ENV{'MYROOTPWD'} = $pass1;
    $ENV{'MASTERHOST'} = $conf->{DEFAULTDOMAIN} || '';
    $ENV{'MASTERKEY'} = $conf->{DEFAULTDOMAIN} || '';
    $ENV{'MASTERPASSWD'} = $conf->{DEFAULTDOMAIN} || '';
    $ENV{'WEBADMINPWD'} = $pass1;
    $ENV{'INTERACTIVE'} = 'n';
    $ENV{'LOGFILE'} = $this->{logfile};
    $ENV{'USEDEBS'} = 'Y';

    print "Updating configuration file...\n";
    open(my $CONF, '>', $this->{conffile});
    print $CONF "SRCDIR = ".$ENV{SRCDIR}."\n";
    print $CONF "VARDIR = ".$ENV{VARDIR}."\n";
    print $CONF "MCHOSTNAME = ".$ENV{'MCHOSTNAME'}."\n";
    print $CONF "HOSTID = ".$ENV{'HOSTID'}."\n";
    print $CONF "DEFAULTDOMAIN = ".$ENV{'DEFAULTDOMAIN'}."\n";
    print $CONF "ISMASTER = $ENV{'ISMASTER'}\n";
    close $CONF;
    if ($ENV{'ISSLAVE'} eq 'Y') {
        print("Slave node detected. Please run \`/usr/mailcleaner/scripts/configuration/slaves.pl\` on master node and add this node as a slave before proceeding, if you have not done so already. [Enter]\n");
        my $null = <STDIN>;
        `$ENV{SRCDIR}/install/slaves.pl --setmaster`
    }
    $dlg->clear();

    #TODO Set web admin password
}

sub isBootstrapped($this)
{
    # TODO: Update to look for mc-exim instead when available
    # if (-d '/opt/exim4/bin/exim') {
    if (-e '/usr/sbin/exim') {
        return 1;
    }
    return 0;
}

sub isInstalled($this)
{
    if ( -e '/etc/mailcleaner.conf' ) {
        return 1;
    }
    return 0;
}

1;
