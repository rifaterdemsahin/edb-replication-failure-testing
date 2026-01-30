#!/bin/bash
# check-replication.sh - Monitors PostgreSQL replication health
# This script checks both Primary and Replica replication status

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PRIMARY_HOST=${PRIMARY_HOST:-postgres-primary}
REPLICA_HOST=${REPLICA_HOST:-postgres-replica}
POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}
POSTGRES_DB=${POSTGRES_DB:-testdb}

export PGPASSWORD=${POSTGRES_PASSWORD}

echo "========================================"
echo "PostgreSQL Replication Health Check"
echo "========================================"
echo "Primary: ${PRIMARY_HOST}"
echo "Replica: ${REPLICA_HOST}"
echo "Timestamp: $(date)"
echo "========================================"

# Function to check primary status
check_primary() {
    echo -e "\n${GREEN}[1] Checking Primary Server...${NC}"
    
    # Check if primary is accessible
    if ! psql -h ${PRIMARY_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "${RED}ERROR: Cannot connect to primary server${NC}"
        return 1
    fi
    
    echo "✓ Primary server is accessible"
    
    # Check pg_stat_replication
    echo -e "\n${GREEN}Checking replication connections:${NC}"
    REPLICATION_COUNT=$(psql -h ${PRIMARY_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -t -c "SELECT COUNT(*) FROM pg_stat_replication;")
    
    if [ "${REPLICATION_COUNT}" -eq 0 ]; then
        echo -e "${RED}ERROR: No replicas connected to primary${NC}"
        return 1
    fi
    
    echo "✓ ${REPLICATION_COUNT} replica(s) connected"
    
    # Get detailed replication status
    psql -h ${PRIMARY_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "
        SELECT 
            application_name,
            client_addr,
            state,
            sync_state,
            pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS replication_lag_bytes,
            write_lag,
            flush_lag,
            replay_lag
        FROM pg_stat_replication;
    "
    
    # Check for streaming state
    STREAMING_COUNT=$(psql -h ${PRIMARY_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -t -c "SELECT COUNT(*) FROM pg_stat_replication WHERE state = 'streaming';")
    
    if [ "${STREAMING_COUNT}" -eq 0 ]; then
        echo -e "${YELLOW}WARNING: No replicas in streaming state${NC}"
        return 1
    fi
    
    echo -e "✓ ${STREAMING_COUNT} replica(s) in streaming state"
    
    # Check replication lag
    MAX_LAG=$(psql -h ${PRIMARY_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -t -c "SELECT COALESCE(MAX(pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)), 0) FROM pg_stat_replication;")
    
    if [ "${MAX_LAG}" -gt 1048576 ]; then  # 1MB
        echo -e "${YELLOW}WARNING: Replication lag is ${MAX_LAG} bytes (> 1MB)${NC}"
    else
        echo -e "✓ Replication lag: ${MAX_LAG} bytes (OK)"
    fi
}

# Function to check replica status
check_replica() {
    echo -e "\n${GREEN}[2] Checking Replica Server...${NC}"
    
    # Check if replica is accessible
    if ! psql -h ${REPLICA_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "SELECT 1;" > /dev/null 2>&1; then
        echo -e "${RED}ERROR: Cannot connect to replica server${NC}"
        return 1
    fi
    
    echo "✓ Replica server is accessible"
    
    # Check if replica is in recovery mode
    IN_RECOVERY=$(psql -h ${REPLICA_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -t -c "SELECT pg_is_in_recovery();")
    
    if [ "${IN_RECOVERY}" != " t" ]; then
        echo -e "${RED}ERROR: Replica is not in recovery mode${NC}"
        return 1
    fi
    
    echo "✓ Replica is in recovery mode"
    
    # Check pg_stat_wal_receiver
    echo -e "\n${GREEN}Checking WAL receiver status:${NC}"
    psql -h ${REPLICA_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "
        SELECT 
            status,
            receive_start_lsn,
            receive_start_tli,
            received_lsn,
            received_tli,
            last_msg_send_time,
            last_msg_receipt_time,
            latest_end_lsn,
            slot_name
        FROM pg_stat_wal_receiver;
    "
    
    # Check streaming status
    WAL_STATUS=$(psql -h ${REPLICA_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -t -c "SELECT status FROM pg_stat_wal_receiver;")
    
    if [ "${WAL_STATUS}" != " streaming" ]; then
        echo -e "${RED}ERROR: WAL receiver is not streaming (status: ${WAL_STATUS})${NC}"
        return 1
    fi
    
    echo "✓ WAL receiver is streaming"
}

# Function to check data consistency
check_consistency() {
    echo -e "\n${GREEN}[3] Checking Data Consistency...${NC}"
    
    # Get LSN from primary
    PRIMARY_LSN=$(psql -h ${PRIMARY_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -t -c "SELECT pg_current_wal_lsn();")
    
    # Get LSN from replica
    REPLICA_LSN=$(psql -h ${REPLICA_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -t -c "SELECT pg_last_wal_replay_lsn();")
    
    echo "Primary LSN:  ${PRIMARY_LSN}"
    echo "Replica LSN:  ${REPLICA_LSN}"
    
    # Calculate difference
    LAG_BYTES=$(psql -h ${PRIMARY_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -t -c "SELECT pg_wal_lsn_diff('${PRIMARY_LSN}', '${REPLICA_LSN}');")
    
    echo "Lag: ${LAG_BYTES} bytes"
}

# Main execution
ERRORS=0

if ! check_primary; then
    ERRORS=$((ERRORS + 1))
fi

if ! check_replica; then
    ERRORS=$((ERRORS + 1))
fi

check_consistency

echo -e "\n========================================"
if [ ${ERRORS} -eq 0 ]; then
    echo -e "${GREEN}✓ All checks passed${NC}"
    exit 0
else
    echo -e "${RED}✗ ${ERRORS} check(s) failed${NC}"
    exit 1
fi
