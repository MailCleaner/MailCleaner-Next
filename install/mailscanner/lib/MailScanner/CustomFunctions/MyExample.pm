#
#   MailScanner - SMTP E-Mail Virus Scanner
#   Copyright (C) 2002  Julian Field
#
#   $Id: MyExample.pm 2331 2004-03-23 09:23:43Z jkf $
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
#   The author, Julian Field, can be contacted by email at
#      Jules@JulianField.net
#   or by paper mail at
#      Julian Field
#      Dept of Electronics & Computer Science
#      University of Southampton
#      Southampton
#      SO17 1BJ
#      United Kingdom
#

package MailScanner::CustomConfig;

use strict 'vars';
use strict 'refs';
no  strict 'subs'; # Allow bare words for parameter %'s

use vars qw($VERSION);

### The package version, both in 1.23 style *and* usable by MakeMaker:
$VERSION = substr q$Revision: 2331 $, 10;

#
# These are the custom functions that you can write to produce a value
# for any configuration keyword that you want to do clever things such
# as retrieve values from a database.
#
# Your function may be passed a "message" object, and must return
# a legal value for the configuration parameter. No checking will be
# done on the result, for extra speed. If you want to find out what
# there is in a "message" object, look at Message.pm as they are all
# listed there.
#
# You must handle the case when no "message" object is passed to your
# function. In this case it should return a sensible default value.
#
# Return value: You must return the internal form of the result values.
#               For example, if you are producing a yes or no value,
#               you return 1 or 0. To find all the internal values
#               look in ConfigDefs.pl.
#
# For each function "FooValue" that you write, there needs to be a
# function "InitFooValue" which will be called when the configuration
# file is read. In the InitFooValue function, you will need to set up
# any global state such as create database connections, read more
# configuration files and so on.
#

##
## This is a trivial example function to get you started.
## You could use it in the main MailScanner configuration file like
## this:
##      VirusScanning = &ScanningValue
##
#sub InitScanningValue {
#  # No initialisation needs doing here at all.
#  MailScanner::Log::InfoLog("Initialising ScanningValue");
#}
#
#sub EndScanningValue {
#  # No shutdown code needed here at all.
#  # This function could log total stats, close databases, etc.
#  MailScanner::Log::InfoLog("Ending ScanningValue");
#}
#
## This will return 1 for all messages except those generated by this
## computer.
#sub ScanningValue {
#  my($message) = @_;
#
#  return 1 unless $message; # Default if no message passed in
#
#  return 0 if $message->{subject} =~ /jules/i;
#  return 1;
#
#  #my($IPAddress);
#  #$IPAddress = $message->{clientip};
#  #return 0 if $IPAddress eq '127.0.0.1';
#  #return 1;
#}

1;
