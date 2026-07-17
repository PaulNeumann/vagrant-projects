#!/usr/bin/env bash
#------------------------------------------------------------------------------
# LICENSE UPL 1.0
# Copyright (c) 1982-2026 Oracle and/or its affiliates. All rights reserved.
#
# 17_create_database.sh
#   Create the SEHA database: dbca (silent) followed by the srvctl failover
#   node list. Runs as oracle.
#
#   21c's dbca has no notion of SEHA — it only ever creates a plain
#   single-instance database on ASM. What makes it a SEHA database is the
#   candidate node list, which only srvctl can set, so the database is not
#   fully created until both steps below have run.
#
#   (Verified against the 21.3 media: assistants/dbca/jlib/dbcaext.jar declares
#   databaseConfigType as < SINGLE | RAC | RACONENODE > and has no
#   -sehaNodeList. The 23.26.1 project does have a SEHA-aware dbca and creates
#   the database in a single step.)
#------------------------------------------------------------------------------
. /vagrant/scripts/_common.sh
require_user oracle
for v in DB_HOME DB_NAME CDB SYS_PASSWORD \
         NODE1_HOSTNAME NODE2_HOSTNAME \
         DB_RECOVERY_FILE_DEST_SIZE; do
  require_var "${v}"
done

log_info "Using DBCA fast recovery area size '${DB_RECOVERY_FILE_DEST_SIZE}'"

dbca_args=(
  -silent -createDatabase
  -templateName General_Purpose.dbc
  -initParams "db_recovery_file_dest_size=${DB_RECOVERY_FILE_DEST_SIZE}"
  -responseFile NO_VALUE
  -gdbname "${DB_NAME}"
  -sid "${DB_NAME}"
  -characterSet AL32UTF8
  -sysPassword    "${SYS_PASSWORD}"
  -systemPassword "${SYS_PASSWORD}"
  -databaseType MULTIPURPOSE
  -automaticMemoryManagement false
  -totalMemory 2048
  -redoLogFileSize 50
  -emConfiguration NONE
  -ignorePreReqs
  -storageType ASM
  -diskGroupName +DATA
  -recoveryGroupName +RECO
  -asmsnmpPassword "${SYS_PASSWORD}"
  # SINGLE, not SEHA: dbca only accepts SINGLE|RAC|RACONENODE. No -nodelist
  # either — it is a RAC-context argument, and srvctl owns the node list.
  -databaseConfigType SINGLE
)

if [[ "${CDB}" == "true" ]]; then
  require_var PDB_NAME
  require_var PDB_PASSWORD
  dbca_args+=(
    -createAsContainerDatabase true
    -numberOfPDBs 1
    -pdbName "${PDB_NAME}"
    -pdbAdminPassword "${PDB_PASSWORD}"
  )
fi

log_section "Running dbca (silent, create single-instance database)"
"${DB_HOME}/bin/dbca" "${dbca_args[@]}"
log_success "Database ${DB_NAME} created"

# dbca leaves the database registered on this node only. Adding the candidate
# node list is what lets Clusterware relocate it to the other node — i.e. what
# makes this a SEHA database rather than a plain single instance.
log_section "Setting SEHA failover nodes for ${DB_NAME}: ${NODE1_HOSTNAME},${NODE2_HOSTNAME}"
"${DB_HOME}/bin/srvctl" modify database -d "${DB_NAME}" \
  -node "${NODE1_HOSTNAME},${NODE2_HOSTNAME}"
log_success "SEHA database ${DB_NAME} created"
