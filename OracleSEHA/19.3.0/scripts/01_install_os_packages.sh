#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 01_install_os_packages.sh
#   Installs base packages and the Oracle preinstall bundle for RAC 19c on OL7.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_root

log_section "Installing base packages"
yum install -y deltarpm expect tree unzip zip openssl

log_section "Installing oracle-database-preinstall-19c"
yum install -y oracle-database-preinstall-19c

log_section "Installing cluster prerequisites"
yum install -y bc ksh libaio libaio-devel net-tools nfs-utils \
               policycoreutils-python sysstat smartmontools chrony \
               dnsmasq bind-utils

log_section "Disabling firewalld"
systemctl stop    firewalld 2>/dev/null || true
systemctl disable firewalld 2>/dev/null || true
