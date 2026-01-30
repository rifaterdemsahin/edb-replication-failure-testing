#!/bin/bash
# simulate-failure.sh - Intentionally breaks PostgreSQL replication
# This script demonstrates various failure scenarios

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
PRIMARY_HOST=${PRIMARY_HOST:-postgres-primary}
REPLICA_HOST=${REPLICA_HOST:-postgres-replica}
POSTGRES_USER=${POSTGRES_USER:-postgres}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-postgres}
POSTGRES_DB=${POSTGRES_DB:-testdb}

export PGPASSWORD=${POSTGRES_PASSWORD}

echo "========================================"
echo "PostgreSQL Replication Failure Simulator"
echo "========================================"

# Function to display menu
show_menu() {
    echo -e "\n${YELLOW}Select a failure scenario:${NC}"
    echo "1) Break replication - Change replication user password"
    echo "2) Break replication - Drop replication slot"
    echo "3) Break replication - Terminate WAL sender process"
    echo "4) Network delay simulation"
    echo "5) Exit"
    echo -n "Enter choice [1-5]: "
}

# Scenario 1: Change replication password
scenario_password_change() {
    echo -e "\n${RED}[Scenario 1] Changing replication user password...${NC}"
    
    psql -h ${PRIMARY_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "
        ALTER USER replicator WITH PASSWORD 'wrong_password';
    "
    
    echo -e "${GREEN}✓ Replication password changed${NC}"
    echo "Replica will fail to authenticate with the new password"
    echo "To fix: Run fix-replication.sh or manually update credentials"
}

# Scenario 2: Drop replication slot
scenario_drop_slot() {
    echo -e "\n${RED}[Scenario 2] Dropping replication slot...${NC}"
    
    # First, check if slot exists
    SLOT_EXISTS=$(psql -h ${PRIMARY_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -t -c "SELECT COUNT(*) FROM pg_replication_slots WHERE slot_name = 'replica_slot';" | xargs)
    
    if [ "${SLOT_EXISTS}" -eq 0 ]; then
        echo "Replication slot 'replica_slot' does not exist"
        return 1
    fi
    
    psql -h ${PRIMARY_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "
        SELECT pg_drop_replication_slot('replica_slot');
    "
    
    echo -e "${GREEN}✓ Replication slot dropped${NC}"
    echo "Replica will fail to connect without the slot"
    echo "To fix: Run fix-replication.sh to recreate the slot"
}

# Scenario 3: Terminate WAL sender
scenario_terminate_walsender() {
    echo -e "\n${RED}[Scenario 3] Terminating WAL sender process...${NC}"
    
    # Get WAL sender PID
    WALSENDER_PID=$(psql -h ${PRIMARY_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -t -c "
        SELECT pid FROM pg_stat_replication WHERE application_name = 'replica' LIMIT 1;
    " | xargs)
    
    if [ -z "${WALSENDER_PID}" ]; then
        echo "No active WAL sender process found"
        return 1
    fi
    
    echo "Found WAL sender PID: ${WALSENDER_PID}"
    
    psql -h ${PRIMARY_HOST} -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "
        SELECT pg_terminate_backend(${WALSENDER_PID});
    "
    
    echo -e "${GREEN}✓ WAL sender terminated${NC}"
    echo "Replication should automatically reconnect"
}

# Scenario 4: Network delay
scenario_network_delay() {
    echo -e "\n${YELLOW}[Scenario 4] Network delay simulation${NC}"
    echo "This requires network manipulation tools (tc, iptables) in Kubernetes"
    echo "For demonstration purposes only - not implemented in this PoC"
    echo "In production, you would use tools like:"
    echo "  - tc qdisc add dev eth0 root netem delay 100ms"
    echo "  - Kubernetes network policies"
    echo "  - Service mesh features (Istio, Linkerd)"
}

# Interactive mode
if [ $# -eq 0 ]; then
    while true; do
        show_menu
        read choice
        
        case $choice in
            1) scenario_password_change ;;
            2) scenario_drop_slot ;;
            3) scenario_terminate_walsender ;;
            4) scenario_network_delay ;;
            5) echo "Exiting..."; exit 0 ;;
            *) echo -e "${RED}Invalid option${NC}" ;;
        esac
    done
else
    # Command line mode
    case $1 in
        password) scenario_password_change ;;
        slot) scenario_drop_slot ;;
        terminate) scenario_terminate_walsender ;;
        network) scenario_network_delay ;;
        *) 
            echo "Usage: $0 [password|slot|terminate|network]"
            exit 1
            ;;
    esac
fi
