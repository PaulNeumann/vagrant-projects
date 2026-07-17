#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 08_setup_user_equ.sh
#   Secure wrapper around 08_setup_user_equ.expect. Passes the user password
#   via the RAC_USER_PASSWORD env var — so it never appears in 'ps' output.
#
#   Args:
#     $1 = username (root | grid | oracle)
#     $2 = password (plain text — from setup.env, never from argv on disk)
#     $3 = node1 hostname
#     $4 = node2 hostname
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_root
require_var GI_HOME

if [[ $# -ne 4 ]]; then
  log_error "usage: $0 <user> <password> <node1> <node2>"
  exit 1
fi

user="$1"
password="$2"
node1="$3"
node2="$4"
ssh_setup="${GI_HOME}/oui/prov/resources/scripts/sshUserSetup.sh"

if [[ ! -x "${ssh_setup}" ]]; then
  log_error "sshUserSetup.sh not found or not executable: ${ssh_setup}"
  exit 1
fi

log_info "Configuring SSH equivalence for '${user}' between ${node1} and ${node2}"

# Pass the password through the environment so it is not visible in 'ps'.
RAC_USER_PASSWORD="${password}" \
  expect -f /vagrant/scripts/08_setup_user_equ.expect \
    "${user}" "${node1}" "${node2}" "${ssh_setup}"
