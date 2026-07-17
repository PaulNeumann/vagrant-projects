#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 13_make_reco_dg.sh
#   Create the +RECO diskgroup using the P2 partitions of each shared disk.
#   Runs as the grid user.
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_user grid
for v in GI_HOME GI_VERSION DB_VERSION ORESTART; do
  require_var "${v}"
done

export ORACLE_HOME="${GI_HOME}"
if [[ "${ORESTART}" == "true" ]]; then
  export ORACLE_SID='+ASM'
else
  export ORACLE_SID='+ASM1'
fi

# Build the SQL DISK clause — one entry per P2 device.
declare -a disk_devices=()
for d in /dev/ORCL_DISK*_p2; do
  [[ -e "${d}" ]] || continue
  disk_devices+=("${d}")
done

if (( ${#disk_devices[@]} == 0 )); then
  log_error "no P2 devices found for RECO"
  exit 1
fi

disk_clause=''
for dev in "${disk_devices[@]}"; do
  disk_clause+="  '${dev}',\n"
done
disk_clause="${disk_clause%,\\n}"   # strip trailing comma
disk_clause="$(printf '%b' "${disk_clause}")"

compat_asm="${GI_VERSION}"
compat_rdbms="${DB_VERSION}"

# GI was configured with a DATA-only discovery string on stacks built before
# asm_diskstring covered both partitions; ASM rejects any CREATE DISKGROUP path
# outside its discovery set (ORA-15014), so widen it to the P1+P2 glob first.
log_section "Ensuring asm_diskstring covers the P2 partitions"
"${GI_HOME}/bin/sqlplus" -S / as sysasm <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE;
SET ECHO ON
ALTER SYSTEM SET asm_diskstring = '$(asm_disk_glob all)' SCOPE=BOTH SID='*';
EXIT;
EOF

log_section "Creating +RECO diskgroup (NORMAL redundancy)"
"${GI_HOME}/bin/sqlplus" -S / as sysasm <<EOF
WHENEVER SQLERROR EXIT SQL.SQLCODE;
SET ECHO ON
CREATE DISKGROUP RECO NORMAL REDUNDANCY
 DISK
${disk_clause}
 ATTRIBUTE
   'compatible.asm'   = '${compat_asm}',
   'compatible.rdbms' = '${compat_rdbms}',
   'sector_size'      = '512',
   'AU_SIZE'          = '4M',
   'content.type'     = 'recovery';
EXIT;
EOF
log_success "RECO diskgroup created"
