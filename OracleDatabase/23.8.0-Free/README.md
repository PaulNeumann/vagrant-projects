# oracle23ai-free-vagrant

This Vagrant project provisions Oracle Database automatically, using Vagrant, an Oracle Linux 9 box and a shell script.

## Prerequisites

1. Read the [prerequisites in the top level README](../../README.md#prerequisites) to set up Vagrant with either VirtualBox or KVM.
2. The [vagrant-env](https://github.com/gosuri/vagrant-env) plugin is optional but
makes configuration much easier

## Getting started

1. Clone this repository `git clone https://github.com/oracle/vagrant-projects`
2. Change into the `vagrant-projects/OracleDatabase/23.8.0-Free` directory
3. Run `vagrant up`
   1. The first time you run this it will provision everything and may take a while. Ensure you have a good internet connection as the scripts will update the VM to the latest via `dnf`.
   2. The installation can be customized, if desired (see [Configuration](#configuration)).
4. Connect to the database (see [Connecting to Oracle](#connecting-to-oracle))
5. You can shut down the VM via the usual `vagrant halt` and then start it up again via `vagrant up`

## Connecting to Oracle

The default database connection parameters are:

* Hostname: `localhost`
* Port: `1521`
* SID: `FREE`
* PDB: `FREEPDB1`
* Database passwords are auto-generated and printed on install

These parameters can be customized, if desired (see [Configuration](#configuration)).

## Resetting password

You can reset the password of the Oracle database accounts (SYS, SYSTEM and PDBADMIN only) by switching to the oracle user (`sudo su - oracle`), then executing `/home/oracle/setPassword.sh <Your new password>`.

## Running scripts after setup

You can have the installer run scripts after setup by putting them in the `userscripts` directory below the directory where you have this file checked out. Any shell (`.sh`) or SQL (`.sql`) scripts you put in the `userscripts` directory will be executed by the installer after the database is set up and started. Only shell and SQL scripts will be executed; all other files will be ignored. These scripts are completely optional.

Shell scripts will be executed as root. SQL scripts will be executed as SYS. SQL scripts will run against the CDB, not the PDB, unless you include an `ALTER SESSION SET CONTAINER = FREEPDB1` statement in the script.

To run scripts in a specific order, prefix the file names with a number, e.g., `01_shellscript.sh`, `02_tablespaces.sql`, `03_shellscript2.sh`, etc.

## Configuration

The `Vagrantfile` can be used _as-is_, without any additional configuration. However, there are several parameters you can set to tailor the installation to your needs.

### How to configure

There are three ways to set parameters:

1. Update the `Vagrantfile`. This is straightforward; the downside is that you will lose changes when you update this repository.
2. Use environment variables. It might be difficult to remember the parameters used when the VM was instantiated.
3. Use the `.env`/`.env.local` files (requires
[vagrant-env](https://github.com/gosuri/vagrant-env) plugin). You can configure your installation by editing the `.env` file, but `.env` will be overwritten on updates, so it's better to make a copy of `.env` called `.env.local`, then make changes in `.env.local`. The `.env.local` file won't be overwritten when you update this repository and it won't mark your Git tree as changed (you won't accidentally commit your local configuration!).

Parameters are considered in the following order (first one wins):

1. Environment variables
2. `.env.local` (if it exists and the  [vagrant-env](https://github.com/gosuri/vagrant-env) plugin is installed)
3. `.env` (if the [vagrant-env](https://github.com/gosuri/vagrant-env) plugin is installed)
4. `Vagrantfile` definitions

### VM parameters

* `VM_NAME` (default: `oracle23ai-free-vagrant`): VM name.
* `VM_MEMORY` (default: `2300`): memory for the VM (in MB, 2300 MB is ~2.25 GB).
* `VM_SYSTEM_TIMEZONE` (default: host time zone (if possible)): VM time zone.
  * The system time zone is used by the database for SYSDATE/SYSTIMESTAMP.
  * The guest time zone will be set to the host time zone when the host time zone is a full hour offset from GMT.
  * When the host time zone isn't a full hour offset from GMT (e.g., in India and parts of Australia), the guest time zone will be set to UTC.
  * You can specify a different time zone using a time zone name (e.g., "America/Los_Angeles") or an offset from GMT (e.g., "Etc/GMT-2"). For more information on specifying time zones, see [List of tz database time zones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).

### Oracle Database parameters

* `VM_KEEP_DB_INSTALLER` (default: `false`): save database installer RPM file for reuse when VM is rebuilt.
* `VM_ORACLE_CHARACTERSET` (default: `AL32UTF8`): database character set.
* `VM_LISTENER_PORT` (default: `1521`): Listener port.
* `VM_ORACLE_PWD` (default: automatically generated): Oracle Database password for the SYS, SYSTEM and PDBADMIN accounts. **Important: Database creation will fail if the password contains spaces or special characters.**

## Optional plugins

When installed, this Vagrant project will make use of the following third party Vagrant plugins:

* [vagrant-env](https://github.com/gosuri/vagrant-env): loads environment
variables from .env files;
* [vagrant-proxyconf](https://github.com/tmatilai/vagrant-proxyconf): set
proxies in the guest VM if you need to access the Internet through a proxy. See
the plugin documentation for configuration.

To install Vagrant plugins run:

```shell
vagrant plugin install <name>...
```

## Other info

* If you need to, you can connect to the virtual machine via `vagrant ssh`.
* You can `sudo su - oracle` to switch to the oracle user.
* On the guest OS, the directory `/vagrant` is a shared folder and maps to wherever you have this file checked out.
