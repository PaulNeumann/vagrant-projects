#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 04_setup_chrony.sh
#   Disable chronyd (and any stray ntpd) so Oracle's Cluster Time
#   Synchronization Service (CTSS) runs in *active* mode — the only
#   configuration that satisfies CVU PRVG-13606 on an isolated lab where
#   no external NTP peer is reachable.
#
#   Why not 'local stratum 10'?
#     chronyc tracking reports Leap=Normal with that, but the 23.26.1 CVU
#     post-crsinst check inspects the Reference ID and rejects local
#     refclocks — PRVG-13606 still fires.
#
#   Why not node-to-node peering?
#     With both nodes self-stratum 10, chrony's source selector won't prefer
#     the peer over its own local clock, so node1 at least keeps reporting
#     a local refid and CVU fails on that node.
#
#   CTSS active mode is what Oracle's own RAC Vagrant projects use, and is
#   documented as the intended path when no external time source exists.
#
#   CRITICAL: this must run BEFORE GI root.sh / executeConfigTools. CTSS's
#   mode (observer vs active) is latched at CRS startup based on whether a
#   time daemon is active at that moment. If chronyd is already running when
#   CRS starts, CTSS registers as observer and this fix won't help without
#   a CRS restart.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_root

log_section "Disabling chronyd (CTSS will run in active mode instead)"
systemctl stop    chronyd 2>/dev/null || true
systemctl disable chronyd 2>/dev/null || true

log_section "Disabling ntpd if present (belt-and-suspenders)"
systemctl stop    ntpd 2>/dev/null || true
systemctl disable ntpd 2>/dev/null || true

log_section "Moving /etc/chrony.conf aside"
# Rename rather than delete so an operator can still see the original if
# they ever want to re-enable chrony.
if [[ -f /etc/chrony.conf && ! -f /etc/chrony.conf.rac-backup ]]; then
  mv /etc/chrony.conf /etc/chrony.conf.rac-backup
fi
# Also rip up any previous attempts (local stratum 10, etc.) left over in
# an already-provisioned VM.
rm -f /etc/chrony.conf

log_section "Removing stale chrony runtime artefacts"
# Belt-and-suspenders: make sure CTSS doesn't see a lingering pid/socket
# and decide to register as observer.
rm -f /var/run/chrony/chronyd.pid   /var/run/chronyd.pid \
      /var/run/chrony/chronyd.sock  /var/run/chronyd.sock \
      /var/run/ntpd.pid 2>/dev/null || true

log_section "Verifying no time daemon is active"
for svc in chronyd ntpd ntp; do
  if systemctl is-active --quiet "${svc}"; then
    log_error "${svc} is still active — CTSS will register as observer, not active"
    exit 1
  fi
done
log_success "No time daemon active; CTSS will enter active mode on CRS startup"
