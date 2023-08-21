# MailCleaner Source Installation

**These instructions are intended to allow for the installation of MailCleaner on top of a generic Debian installation. This option is available for community testing of pre-release versions of MailCleaner-Next. For production use, we recommend waiting until pre-built images are available.**

## Install Debian

To use this installation method, you will first need an existing Debian Bookworm installation. If you use a cloud hosting solution, it probably already has a Debian Bookworm (12) image available. Otherwise, you can find various images here:

    https://www.debian.org/distrib/

We recommend using a minimal image:

    * ISO - https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.0.0-amd64-netinst.iso
    * QCOW2 - https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2

We recommend at least 8GB of RAM and 2 CPU cores.

### ISO

Follow through the installation wizard and Debian's installation instructions.

### Other

Currently the only VM version being tested is the QCOW2 image using `libvirtd`. If you have experience with any other image type or hypervisor, we are willing to accept contributions to this guide.

Debian provides special images for certain cloud hosts (eg. AWS and Azure). You should be able to follow the instructions for those services to get Debian running and to install MailCleaner-Next on top, but it is uncertain whether this will be a supported deployment method long-term.

## Install Git

```
apt-get update ; apt install git -y
```

All other dependencies will be installed in the next step.

## Install MailCleaner-Next


Clone this repository to `/usr/mailcleaner/`:

```
git clone --depth 1 https://github.com/MailCleaner/MailCleaner-Next.git /usr/mailcleaner
```

Run installation script:

```
cd /usr/mailcleaner/
debian-bootstrap/install-mailcleaner.sh
```

## Configure

Run the first-run installer:

```
scripts/installer/installer.pl
```

## (optional) Clone Existing Installation

If you already have a MailCleaner installation, you can clone each host one-to-one using the [upgrading](/UPGRADING.md) guide.


## Bugs

Be aware that this version of MailCleaner, and the installation script are still in development and we can provide no guarantees on stability or complete functionality. You should expect bugs. We appreciate anyone who opts to help us test the new release and welcome all bug reports as [Issues](https://github.com/MailCleaner/MailCleaner-Next/issues) in our GitHub repository.

Please check to see if there is an existing issue related to your problem and feel free to comment on that thread before opening a duplicate.

If you have the knowledge to be able to fix any issues you discover, we welcome Pull Requests.
