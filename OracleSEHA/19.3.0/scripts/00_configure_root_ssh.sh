#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 18_configure_root_ssh.sh
#   Idempotently set sshd's PermitRootLogin policy. Used by setup.sh to keep
#   password-based root SSH available only during RAC bootstrap, then switch
#   back to key-only once root SSH equivalence is established.
#
#   Args:
#     $1 = PermitRootLogin mode (yes | prohibit-password)
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_root

if [[ $# -ne 1 ]]; then
  log_error "usage: $0 <yes|prohibit-password>"
  exit 1
fi

mode="$1"
sshd_config='/etc/ssh/sshd_config'

case "${mode}" in
  yes|prohibit-password) ;;
  *)
    log_error "unsupported PermitRootLogin mode '${mode}'"
    exit 1
    ;;
esac

set_sshd_option() {
  local key="$1" value="$2"
  if grep -Eq "^[#[:space:]]*${key}[[:space:]]+" "${sshd_config}"; then
    sed -ri "s/^[#[:space:]]*${key}[[:space:]]+.*/${key} ${value}/" "${sshd_config}"
  else
    printf '\n%s %s\n' "${key}" "${value}" >> "${sshd_config}"
  fi
}

set_sshd_option PermitRootLogin "${mode}"

# Keep PasswordAuthentication in lock-step with PermitRootLogin. The bootstrap
# provisioner turned it on so sshUserSetup.sh could seed keys; once we're in
# prohibit-password mode the whole cluster is key-only and password SSH for
# oracle/grid would just be an unnecessary attack surface.
case "${mode}" in
  yes)               set_sshd_option PasswordAuthentication yes ;;
  prohibit-password) set_sshd_option PasswordAuthentication no  ;;
esac

/usr/sbin/sshd -t -f "${sshd_config}"
systemctl restart sshd

log_success "Configured sshd: PermitRootLogin ${mode}"
