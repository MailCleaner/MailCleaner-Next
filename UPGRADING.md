# WARNING:

Migration procedure is not fully tested and documented. If you are going to [Alpha test](/CONTRIBUTING.md) MailCleaner-Next, we would ask you to work from a new installation, without migrating your configuration, until this procedure is verified.

# Upgrading from MailCleaner (Jessie)

Note: MailCleaner Next is still in Alpha status, it should not be used for production.

In order to have the best roll-out possible for new appliances, we are seeking Alpha testers for the Community release.

## Why Upgrade?

The [current release](https://github.com/MailCleaner/MailCleaner) is based on Debian Jessie, which is now EOL. By upgrading, you will gain access to new, supported packages as well as the following benefitial changes (checks indicate completed changes):

[ ] Upgrades to core package versions:
    [x] Apache2 => 2.4.57
    [ ] Exim => 4.96 (recompiled Debian package with extra features)
    [x] PHP => 8.2 
    [x] Perl => 5.36
    [ ] MariaDB (replaces MySQL) => 10.11.3
    [ ] SpamAssassin (spamd) => 4.0.0
    [ ] ClamAV => 1.0.1
    [ ] Fail2Ban => v1.0.2
    [ ] Many others from upstream Debian Bookworm repositories
[x] Adoption of mostly upstream Debian versions of packages to provide easier upgrades and better security guarantees going forward.
[ ] Adoption of `systemd` for service management
[] Changing to distinct user account for each service to better isolate permissions and limit threat of vulnerabilities
[x] Migration from `openssl` to `gnutls` inside `exim` for better cipher compatibility and additional features (eg. DANE)
[ ] Migration from `iptables` to `nftables` (with `ufw` front-end) for improved firewall usability and performance
[x] Complete overhaul of WebUI libraries for new PHP version and Zend framework
[x] Lightly updated WebUI template with backwards-compatibility for custom templates.

Other upgrades, changes and features targetted for the official release later in the year:

[ ] New VM images, including OVA, QCOW2, VHDX, AMI, and Azure VHD.
[ ] Simplified first-start installation script.
[ ] (Optional) New OCR module using TessoractOCR
[ ] (Enterprise) Enhancements to ESET Anti-Virus integration
[ ] (Enterprise) New MachineLearning module

## How to Upgrade

First, you will need to [install a new appliance](/INSTALL.md). This will be referred to as `new-server` below.

Ensure that your existing appliance is up-to-date by checking that `/root/Updater4MC/updater4mc.sh` completes without errors. This will be referred to as `old-server` below.

We are working on a single-command migration script to ingest and upgrade your existing data, but for now it is a manual process:

* Stop MailCleaner on old_server and new_server

```shell
/etc/init.d/mailcleaner stop
```

* Copy to the database and all quarantines from old_server to new_server:

```shell
rsync -av --delete --exclude 'spool/tmp' --exclude 'run' /var/mailcleaner/* root@new_server:/var/mailcleaner
```

* Copy config file `/etc/mailcleaner.conf` from old_server to new_server

```shell
rsync -av --delete /etc/mailcleaner.conf root@new_server:/etc/mailcleaner.conf
```

* Copy your network configuration

```shell
rsync -av --delete /etc/mailcleaner.conf root@new_server:/etc/mailcleaner.conf
```

* Take old_server offline

* Restart networking on new_server

```shell
/etc/init.d/networking restart
```

* Now restart MailCleaner on new_server. Beware of IP address and network configuration.

```shell
/etc/init.d/mailcleaner start
```

* Repair and resync databases:

```shell
/usr/mailcleaner/bin/check_db.pl -m --myrepair
/usr/mailcleaner/bin/check_db.pl -s --myrepair
/usr/mailcleaner/bin/resync_db.sh
```

* Verify that everything is working by accessing the WebUI at the address of old_server (which now belongs to new_server), test sending/receiving emails, etc. In the event of a failure, you can take down new_server and then bring old_server back up so that it reclaims it's IP.'

## Other considerations

There may be some additional files that you need to copy if you have customized your configuration. Specifically, you may have a custom set of template files in `/usr/mailcleaner/www/user/htdocs/templates` and `/usr/mailcleaner/templates/*`.
