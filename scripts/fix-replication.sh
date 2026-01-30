#!/bin/bash
# fix-replication.sh - Automated PostgreSQL replication repair
# This script attempts to restore broken replication connections

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
PRIMARY_HOST=${PRIMARY_HOST:-postgres-primary}
REPLICA_HOST=${REPLICA_HOST:-postgres-replica}
POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}
POSTGRES_DB=${POSTGRES_DB:-testdb}
REPLICATION_USER=${REPLICATION_USER:-replicator}
REPLICATION_PASSWORD=${REPLICATION_PASSWORD:-replicator_password}

export PGPASSWORD=${POSTGRES_PASSWORD}

echo "========================================"
echo "PostgreSQL Replication Auto-Repair Tool"
echo "========================================"
echo "Timestamp: $(date)"
echo "Primary: ${PRIMARY_HOST}"
echo "Replica: ${REPLICA_HOST}"
echo "========================================"

# Function to check if primary is accessible
check_primary_accessible() {
    if psql -h ${PRIMARY_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "SELECT 1;" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Function to check replication status
check_replication_status() {
    REPL_COUNT=$(psql -h ${PRIMARY_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -t -c "SELECT COUNT(*) FROM pg_stat_replication WHERE state = 'streaming';")
    
    if [ "${REPL_COUNT}" -gt 0 ]; then
        return 0  # Replication is working
    else
        return 1  # Replication is broken
    fi
}

# Function to fix replication user password
fix_replication_password() {
    echo -e "\n${BLUE}[Fix 1] Resetting replication user password...${NC}"
    
    # Reset password to known value
    psql -h ${PRIMARY_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "
        ALTER USER ${REPLICATION_USER} WITH PASSWORD '${REPLICATION_PASSWORD}';
    " > /dev/null 2>&1
    
    echo -e "${GREEN}✓ Replication user password reset${NC}"
}

# Function to recreate replication slot
fix_replication_slot() {
    echo -e "\n${BLUE}[Fix 2] Checking and fixing replication slot...${NC}"
    
    # Check if slot exists
    SLOT_EXISTS=$(psql -h ${PRIMARY_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -t -c "SELECT COUNT(*) FROM pg_replication_slots WHERE slot_name = 'replica_slot';")
    
    if [ "${SLOT_EXISTS}" -eq 0 ]; then
        echo "Creating missing replication slot..."
        
        psql -h ${PRIMARY_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "
            SELECT pg_create_physical_replication_slot('replica_slot');
        " > /dev/null 2>&1
        
        echo -e "${GREEN}✓ Replication slot created${NC}"
    else
        # Check if slot is inactive
        SLOT_ACTIVE=$(psql -h ${PRIMARY_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -t -c "SELECT active FROM pg_replication_slots WHERE slot_name = 'replica_slot';")
        
        if [ "${SLOT_ACTIVE}" = " f" ]; then
            echo "Replication slot exists but is inactive"
            echo "This may require manual intervention or replica restart"
        else
            echo -e "${GREEN}✓ Replication slot is active${NC}"
        fi
    fi
}

# Function to verify replication user exists
fix_replication_user() {
    echo -e "\n${BLUE}[Fix 3] Verifying replication user...${NC}"
    
    USER_EXISTS=$(psql -h ${PRIMARY_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -t -c "SELECT COUNT(*) FROM pg_user WHERE usename = '${REPLICATION_USER}';")
    
    if [ "${USER_EXISTS}" -eq 0 ]; then
        echo "Creating missing replication user..."
        
        psql -h ${PRIMARY_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "
            CREATE USER ${REPLICATION_USER} WITH REPLICATION ENCRYPTED PASSWORD '${REPLICATION_PASSWORD}';
        " > /dev/null 2>&1
        
        echo -e "${GREEN}✓ Replication user created${NC}"
    else
        echo -e "${GREEN}✓ Replication user exists${NC}"
    fi
}

# Function to trigger replica restart (requires kubectl)
trigger_replica_restart() {
    echo -e "\n${BLUE}[Fix 4] Attempting to restart replica...${NC}"
    
    # Check if kubectl is available
    if command -v kubectl > /dev/null 2>&1; then
        echo "Restarting replica StatefulSet..."
        
        kubectl rollout restart statefulset/postgres-replica > /dev/null 2>&1 || {
            echo -e "${YELLOW}Warning: Could not restart replica via kubectl${NC}"
            echo "Manual restart may be required"
            return 1
        }
        
        echo -e "${GREEN}✓ Replica restart triggered${NC}"
        echo "Waiting for replica to come back online..."
        sleep 10
    else
        echo -e "${YELLOW}kubectl not available - skipping restart${NC}"
        echo "To manually restart: kubectl rollout restart statefulset/postgres-replica"
        return 1
    fi
}

# Function to wait for replication to resume
wait_for_replication() {
    echo -e "\n${BLUE}Waiting for replication to resume...${NC}"
    
    MAX_WAIT=60
    WAIT_TIME=0
    
    while [ ${WAIT_TIME} -lt ${MAX_WAIT} ]; do
        if check_replication_status; then
            echo -e "${GREEN}✓ Replication resumed successfully!${NC}"
            return 0
        fi
        
        echo -n "."
        sleep 5
        WAIT_TIME=$((WAIT_TIME + 5))
    done
    
    echo -e "\n${YELLOW}Warning: Replication did not resume within ${MAX_WAIT} seconds${NC}"
    return 1
}

# Function to display final status
display_status() {
    echo -e "\n${BLUE}Final Replication Status:${NC}"
    
    psql -h ${PRIMARY_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "
        SELECT 
            application_name,
            client_addr,
            state,
            sync_state,
            pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS lag_bytes
        FROM pg_stat_replication;
    "
}

# Main execution
echo -e "\n${YELLOW}Starting automated repair process...${NC}"

# Step 1: Check if primary is accessible
if ! check_primary_accessible; then
    echo -e "${RED}ERROR: Cannot connect to primary server${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Primary server accessible${NC}"

# Step 2: Check current replication status
if check_replication_status; then
    echo -e "${GREEN}✓ Replication is already working${NC}"
    display_status
    exit 0
fi

echo -e "${YELLOW}⚠ Replication is not working - attempting fixes...${NC}"

# Step 3: Apply fixes
fix_replication_user
fix_replication_password
fix_replication_slot

# Step 4: Restart replica if needed
trigger_replica_restart

# Step 5: Wait for replication to resume
if wait_for_replication; then
    display_status
    echo -e "\n${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ Replication repair completed successfully${NC}"
    echo -e "${GREEN}========================================${NC}"
    exit 0
else
    display_status
    echo -e "\n${RED}========================================${NC}"
    echo -e "${RED}✗ Replication repair incomplete${NC}"
    echo -e "${RED}Manual intervention may be required${NC}"
    echo -e "${RED}========================================${NC}"
    exit 1
fi
