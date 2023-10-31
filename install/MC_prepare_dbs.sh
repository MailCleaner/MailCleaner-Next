#!/bin/bash

if [ -z "$SRCDIR" ]; then
	SRCDIR=$(grep 'SRCDIR' /etc/mailcleaner.conf | cut -d ' ' -f3)
	if [ "SRCDIR" = "" ]; then
		SRCDIR=/usr/mailcleaner
	fi
fi
if [ -z "$VARDIR" ]; then
	VARDIR=$(grep 'VARDIR' /etc/mailcleaner.conf | cut -d ' ' -f3)
	if [ "VARDIR" = "" ]; then
		VARDIR=/var/mailcleaner
	fi
fi
if [ "$ORGANIZATION" = "" ]; then
	ORGANIZATION=$(grep 'ORGANIZATION' /etc/mailcleaner.conf | cut -d ' ' -f3-)
	MCHOSTNAME=$(grep 'MCHOSTNAME' /etc/mailcleaner.conf | cut -d ' ' -f3)
	HOSTID=$(grep 'HOSTID' /etc/mailcleaner.conf | cut -d ' ' -f3)
	CLIENTID=$(grep 'CLIENTID' /etc/mailcleaner.conf | cut -d ' ' -f3)
	DEFAULTDOMAIN=$(grep 'DEFAULTDOMAIN' /etc/mailcleaner.conf | cut -d ' ' -f3)
	CLIENTTECHMAIL=$(grep 'CLIENTTECHMAIL' /etc/mailcleaner.conf | cut -d ' ' -f3)
	MYMAILCLEANERPWD=$(grep 'MYMAILCLEANERPWD' /etc/mailcleaner.conf | cut -d ' ' -f3)
	ISMASTER=$(grep 'ISMASTER' /etc/mailcleaner.conf | cut -d ' ' -f3)
fi

cd $SRCDIR/install

echo "-- removing previous mariadb databases and stopping mariadb"
systemctl stop mariadb@slave
systemctl stop mariadb@master
pkill mariadb
rm -rf $VARDIR/spool/mysql_master/*
rm -rf $VARDIR/spool/mysql_slave/* 2>&1
rm -rf $VARDIR/log/mysql_master/*
rm -rf $VARDIR/log/mysql_slave/* 2>&1
rm -rf $VARDIR/run/mysql_master/*
rm -rf $VARDIR/run/mysql_slave/* 2>&1

##
# first, ask for the mysql admin password

if [ -z $MYROOTPWD ]; then
	echo -n "enter mysql root password: "
	read -s MYROOTPWD
	echo ""
fi

if [ -z $MYMAILCLEANERPWD ]; then
	echo -n "enter mysql mailcleaner password: "
	read -s MYMAILCLEANERPWD
	echo ""
fi

##
# next generate databases
#
# slave:

$SRCDIR/bin/dump_mysql_config.pl 2>&1

echo "-- generating slave database"
/usr/bin/mariadb-install-db --datadir=${VARDIR}/spool/mysql_slave --defaults-file=$SRCDIR/etc/mysql/my_slave.cnf 2>&1
chown -R mysql:mysql ${VARDIR}/spool/mysql_slave 2>&1

# master

echo "-- generating master database"
/usr/bin/mariadb-install-db --datadir=${VARDIR}/spool/mysql_master --defaults-file=$SRCDIR/etc/mysql/my_master.cnf 2>&1
chown -R mysql:mysql ${VARDIR}/spool/mysql_master 2>&1

##
# start db

cp $SRCDIR/etc/mysql/my_slave.cnf_template $SRCDIR/etc/mysql/my_slave.cnf
echo "-- starting mysql"
systemctl start mariadb@master-nopass
systemctl start mariadb@slave-nopass

##
# delete default users and dbs and create mailcleaner dbs and users

echo "-- deleting default databases and users and creating mailcleaner dbs and user"
cat >/tmp/tmp_install.sql <<EOF
USE mysql;
UPDATE user SET Password=PASSWORD('$MYROOTPWD') WHERE User='root';
DELETE FROM user WHERE User='';
DELETE FROM db WHERE User='';
DROP DATABASE test;
DELETE FROM user WHERE Password='';
DROP DATABASE IF EXISTS mc_config;
DROP DATABASE IF EXISTS mc_spool;
DROP DATABASE IF EXISTS mc_stats;
CREATE DATABASE mc_config;
CREATE DATABASE mc_spool;
CREATE DATABASE mc_stats;
CREATE DATABASE dmarc_reporting;
DELETE FROM user WHERE User='mailcleaner';
DELETE FROM db WHERE User='mailcleaner';
GRANT ALL PRIVILEGES ON mc_config.* TO mailcleaner@"%" IDENTIFIED BY '$MYMAILCLEANERPWD' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON mc_spool.* TO mailcleaner@"%" IDENTIFIED BY '$MYMAILCLEANERPWD' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON mc_stats.* TO mailcleaner@"%" IDENTIFIED BY '$MYMAILCLEANERPWD' WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON dmarc_reporting.* TO mailcleaner@"%" IDENTIFIED BY '$MYMAILCLEANERPWD' WITH GRANT OPTION;
GRANT REPLICATION SLAVE , REPLICATION CLIENT ON * . * TO  mailcleaner@"%";
USE mysql;
UPDATE user SET Reload_priv='Y' WHERE User='mailcleaner';
UPDATE user SET Repl_slave_priv='Y', Repl_client_priv='Y' WHERE User='mailcleaner';
FLUSH PRIVILEGES;
EOF

/usr/bin/mariadb -S ${VARDIR}/run/mysql_slave/mysqld.sock </tmp/tmp_install.sql 2>&1
/usr/bin/mariadb -S ${VARDIR}/run/mysql_master/mysqld.sock </tmp/tmp_install.sql 2>&1

rm /tmp/tmp_install.sql 2>&1

echo "-- creating mailcleaner configuration tables"
$SRCDIR/bin/check_db.pl --update 2>&1
echo "-- creating mailcleaner spool tables"

for SOCKDIR in mysql_slave mysql_master; do
	for file in $(ls dbs/spam/*.sql); do
		/usr/bin/mariadb -umailcleaner -p$MYMAILCLEANERPWD -S$VARDIR/run/$SOCKDIR/mysqld.sock mc_spool <$file
	done
	/usr/bin/mariadb -umailcleaner -p$MYMAILCLEANERPWD -S$VARDIR/run/$SOCKDIR/mysqld.sock mc_spool <dbs/t_sp_spam.sql
done

/usr/bin/mariadb -umailcleaner -p$MYMAILCLEANERPWD -S$VARDIR/run/mysql_master/mysqld.sock dmarc_reporting <dbs/dmarc_reporting.sql

echo "-- inserting config and default values"

## TO DO: check these values !! either coming from the superior installation script or from /etc/mailcleaner.conf

HOSTKEY=$(cat /etc/ssh/ssh_host_ed25519_key.pub)
if [ "$ISMASTER" = "Y" ]; then
	MASTERHOST=127.0.0.1
	MASTERKEY=$(cat $VARDIR/.ssh/id_ed25519.pub)
	MASTERPASSWD=$MYMAILCLEANERPWD
fi

for SOCKDIR in mysql_master; do
	echo "INSERT INTO system_conf (organisation, company_name, hostid, clientid, default_domain, contact_email, summary_from, analyse_to, falseneg_to, falsepos_to, src_dir, var_dir) VALUES ('$ORGANIZATION', '$MCHOSTNAME', '$HOSTID', '$CLIENTID', '$DEFAULTDOMAIN', '$CLIENTTECHMAIL', '$CLIENTTECHMAIL', '$CLIENTTECHMAIL', '$CLIENTTECHMAIL', '$CLIENTTECHMAIL', '$SRCDIR', '$VARDIR');" | /usr/bin/mariadb -umailcleaner -p$MYMAILCLEANERPWD -S$VARDIR/run/$SOCKDIR/mysqld.sock mc_config
	echo "INSERT INTO slave (id, hostname, password, ssh_pub_key) VALUES ('$HOSTID', '127.0.0.1', '$MYMAILCLEANERPWD', '$HOSTKEY');" | /usr/bin/mariadb -umailcleaner -p$MYMAILCLEANERPWD -S$VARDIR/run/$SOCKDIR/mysqld.sock mc_config
	echo "INSERT INTO master (hostname, password, ssh_pub_key) VALUES ('$MASTERHOST', '$MASTERPASSWD', '$MASTERKEY');" | /usr/bin/mariadb -umailcleaner -p$MYMAILCLEANERPWD -S$VARDIR/run/$SOCKDIR/mysqld.sock mc_config
	echo "INSERT INTO httpd_config (serveradmin, servername) VALUES('root', 'mailcleaner');" | /usr/bin/mariadb -umailcleaner -p$MYMAILCLEANERPWD -S$VARDIR/run/$SOCKDIR/mysqld.sock mc_config
done

systemctl start mariadb@slave-nopass
## MySQL redundency
echo "STOP SLAVE; CHANGE MASTER TO master_host='$MASTERHOST', master_user='mailcleaner', master_password='$MASTERPASSWD'; START SLAVE;" | /usr/bin/mariadb -umailcleaner -p$MYMAILCLEANERPWD -S$VARDIR/run/mysql_slave/mysqld.sock mc_config
$SRCDIR/etc/init.d/mysql_slave restart

## creating stats tables
/usr/bin/mariadb -umailcleaner -p$MYMAILCLEANERPWD -S$VARDIR/run/mysql_slave/mysqld.sock mc_config <dbs/t_st_maillog.sql

## creating local update table
/usr/bin/mariadb -umailcleaner -p$MYMAILCLEANERPWD -S$VARDIR/run/mysql_slave/mysqld.sock mc_config <dbs/t_cf_update_patch.sql

## creating temp soap authentication table
/usr/bin/mariadb -umailcleaner -p$MYMAILCLEANERPWD -S$VARDIR/run/mysql_slave/mysqld.sock mc_spool <dbs/t_sp_soap_auth.sql

## creating web admin user
echo "INSERT INTO administrator (username, password, can_manage_users, can_manage_domains, can_configure, can_view_stats, can_manage_host, domains) VALUES('admin', ENCRYPT('$WEBADMINPWD'), 1, 1, 1, 1, 1, '*');" | /usr/bin/mariadb -umailcleaner -p$MYMAILCLEANERPWD -S$VARDIR/run/mysql_master/mysqld.sock mc_config

## inserting last version update
echo "INSERT INTO update_patch VALUES('$ACTUALUPDATE', NOW(), NOW(), 'OK', 'CD release');" | /usr/bin/mariadb -umailcleaner -p$MYMAILCLEANERPWD -S$VARDIR/run/mysql_slave/mysqld.sock mc_config

#$SRCDIR/etc/init.d/mysql_master stop
echo "-- DONE -- mailcleaner dbs are ready !"
