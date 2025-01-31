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

package MailScanner::Accounting;

use v5.36;
use strict 'vars';
use strict 'refs';
no  strict 'subs'; # Allow bare words for parameter %'s

use vars qw($VERSION);

require Email;
require Domain;
require SystemPref;
require StatsClient;

# Constructor.
sub new($preposttype='post')
{
    if ($preposttype ne 'pre') {
  	    $preposttype = 'post';
    }
    my $self = {
        last_message => '',
        prepost_type => $preposttype
    };

    $self->{statsclient} = StatsClient->new();

    bless $self, 'MailScanner::Accounting';
    return $self;
}

sub checkCheckeableUser($self,$user)
{
    if (! $self->isUserCheckeable($user)) {
  	    $self->{last_message} = 'Number of licensed users has been exhausted';
        return 0;
    }
    if (! $self->isUserCheckeableForDomain($user)) {
  	    $self->{last_message} = 'Number of licensed users for domain has been exhausted';
        return 0;
    }
    return 1;
}

sub checkCheckeable($self,$msg)
{
    my $nb_notcheakable = 0;
    my $nb_recipients = @{$msg->{to}};

    ## check globally
    foreach my $rcpt (@{$msg->{to}}) {
        if (! $self->isUserCheckeable($rcpt)) {
            $nb_notcheakable++;
        }
    }
    ## only of all recipients are not checkeable, otherwise still filter message
    if ($nb_notcheakable >= $nb_recipients) {
        $self->{last_message} = 'Number of licensed users has been exhausted';
        return 0;
    }

    ## check per domain
    $nb_notcheakable = 0;
    foreach my $rcpt (@{$msg->{to}}) {
  	    if (! $self->isUserCheckeableForDomain($rcpt)) {
            $nb_notcheakable++;
        }
    }
    ## only of all recipients are not checkeable, otherwise still filter message
    if ($nb_notcheakable >= $nb_recipients) {
  	  $self->{last_message} = 'Number of licensed users for domain has been exhausted';
  	  return 0;
    }

    return 1;
}

sub isUserCheckeable($self,$user)
{
	  if ($user =~ m/(\S+)\@(\S+)/) {
        my $domain_name = $2;
        my $local_part = $1;

        if ($self->{statsclient}->getValue('user:'.$domain_name.":".$local_part.":unlicenseduser") > 0) {
            ## if user already has exhausted license
            return 0;
        }
        if ($self->{statsclient}->getValue('user:'.$domain_name.":".$local_part.":licenseduser") > 0) {
            ## user already has been counted
            return 1;
        }

        my $maxusers = 0;
        if ($maxusers > 0) {
        	  my $current_count = $self->{statsclient}->getValue('global:user');
        	  if ($self->{prepost_type} eq 'pre') {
                $current_count++;
            }
            if ($current_count > $maxusers) {
                $self->{statsclient}->addValue('user:'.$domain_name.":".$local_part.":unlicenseduser", 1);
                return 0;
            } else {
                $self->{statsclient}->addValue('user:'.$domain_name.":".$local_part.":licenseduser", 1);
            }
        }
	  }
    return 1;
}

sub isUserCheckeableForDomain($self,$user)
{
	  if ($user =~ m/(\S+)\@(\S+)/) {
	      my $domain_name = $2;
	      my $local_part = $1;
	
	      if ($self->{statsclient}->getValue('user:'.$domain_name.":".$local_part.":domainunlicenseduser") > 0) {
	    	    ## if user already has exhausted license
	    	    return 0;
	      }
	      if ($self->{statsclient}->getValue('user:'.$domain_name.":".$local_part.":domainlicenseduser") > 0) {
            ## user already has been counted
            return 1;
        }

        my $domain = Domain::create($domain_name);
        if ($domain) {
            my $maxusers = $domain->getPref('acc_max_daily_users');
            if ($maxusers > 0) {	
            	  my $domain_subject = 'domain:'.$domain_name.":user";
                my $current_count = $self->{statsclient}->getValue($domain_subject);
                if ($self->{prepost_type} eq 'pre') {
                    $current_count++;
                }
                if ($current_count > $maxusers) {
                	  $self->{statsclient}->addValue('user:'.$domain_name.":".$local_part.":domainunlicenseduser", 1);
                    return 0;
                } else {
                	  $self->{statsclient}->addValue('user:'.$domain_name.":".$local_part.":domainlicenseduser", 1);
                }
            }
        }
	  }
	  return 1;
}

sub getLastMessage($self)
{
    return $self->{last_message};
}

1;

