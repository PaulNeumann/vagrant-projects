# Oracle SEHA Vagrant projects

This directory contains Vagrant projects to provision Oracle database lab
environments automatically, using Vagrant and shell scripts.

Available projects:

| Directory | Purpose |
| --- | --- |
| `19.3.0` | Oracle Standard Edition High Availability (SEHA) based on 19.3 |
| `21.3.0` | Oracle Standard Edition High Availability (SEHA) based on 21.3 |

## Prerequisites

Read the [prerequisites in the top level README](../README.md#prerequisites) to set up either Vagrant with either VirtualBox or KVM

## Getting started

1. Clone this repository `git clone https://github.com/oracle/vagrant-projects`
2. Change into the desired project folder, for example `19.3.0`
3. Run `vagrant up`
4. You can shut down the VM via the usual `vagrant halt` and the start it up again via `vagrant up`.

**For more information please check the individual README within each folder!**
