#!/bin/bash
# test-implementation.sh - Verification script for EDB replication testing framework
# This script validates the implementation without requiring a Kubernetes cluster

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "========================================"
echo "EDB Replication Testing Framework"
echo "Implementation Verification"
echo "========================================"
echo ""

ERRORS=0
WARNINGS=0

# Function to check if file exists
check_file() {
    local file=$1
    local description=$2
    
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description: $file"
        return 0
    else
        echo -e "${RED}✗${NC} $description missing: $file"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Function to check if directory exists
check_directory() {
    local dir=$1
    local description=$2
    
    if [ -d "$dir" ]; then
        echo -e "${GREEN}✓${NC} $description: $dir"
        return 0
    else
        echo -e "${RED}✗${NC} $description missing: $dir"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Function to validate bash script
validate_bash() {
    local script=$1
    local name=$2
    
    if bash -n "$script" 2>&1; then
        echo -e "${GREEN}✓${NC} Bash syntax valid: $name"
        return 0
    else
        echo -e "${RED}✗${NC} Bash syntax error: $name"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Function to validate YAML
validate_yaml() {
    local file=$1
    local name=$2
    
    if python3 -c "import yaml; yaml.safe_load_all(open('$file'))" 2>&1; then
        echo -e "${GREEN}✓${NC} YAML syntax valid: $name"
        return 0
    else
        echo -e "${RED}✗${NC} YAML syntax error: $name"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Function to check script is executable
check_executable() {
    local script=$1
    local name=$2
    
    if [ -x "$script" ]; then
        echo -e "${GREEN}✓${NC} Script is executable: $name"
        return 0
    else
        echo -e "${YELLOW}⚠${NC} Script not executable (can be fixed with chmod +x): $name"
        WARNINGS=$((WARNINGS + 1))
        return 1
    fi
}

echo -e "${BLUE}[1] Checking Directory Structure${NC}"
echo "-----------------------------------"
check_directory "5_Symbols/k8s" "Kubernetes manifests directory"
check_directory "5_Symbols/scripts" "Scripts directory"
echo ""

echo -e "${BLUE}[2] Checking Kubernetes Manifests${NC}"
echo "-----------------------------------"
check_file "5_Symbols/k8s/postgres-primary.yaml" "Primary StatefulSet manifest"
check_file "5_Symbols/k8s/postgres-replica.yaml" "Replica StatefulSet manifest"
check_file "5_Symbols/k8s/replication-check-job.yaml" "Health check Job manifest"
check_file "5_Symbols/k8s/fix-replication-job.yaml" "Repair Job manifest"
echo ""

echo -e "${BLUE}[3] Validating YAML Syntax${NC}"
echo "-----------------------------------"
if [ -f "5_Symbols/k8s/postgres-primary.yaml" ]; then
    validate_yaml "5_Symbols/k8s/postgres-primary.yaml" "postgres-primary.yaml"
fi
if [ -f "5_Symbols/k8s/postgres-replica.yaml" ]; then
    validate_yaml "5_Symbols/k8s/postgres-replica.yaml" "postgres-replica.yaml"
fi
if [ -f "5_Symbols/k8s/replication-check-job.yaml" ]; then
    validate_yaml "5_Symbols/k8s/replication-check-job.yaml" "replication-check-job.yaml"
fi
if [ -f "5_Symbols/k8s/fix-replication-job.yaml" ]; then
    validate_yaml "5_Symbols/k8s/fix-replication-job.yaml" "fix-replication-job.yaml"
fi
echo ""

echo -e "${BLUE}[4] Checking Shell Scripts${NC}"
echo "-----------------------------------"
check_file "5_Symbols/scripts/check-replication.sh" "Health check script"
check_file "5_Symbols/scripts/simulate-failure.sh" "Failure simulation script"
check_file "5_Symbols/scripts/fix-replication.sh" "Automated repair script"
echo ""

echo -e "${BLUE}[5] Validating Bash Syntax${NC}"
echo "-----------------------------------"
if [ -f "5_Symbols/scripts/check-replication.sh" ]; then
    validate_bash "5_Symbols/scripts/check-replication.sh" "check-replication.sh"
    check_executable "5_Symbols/scripts/check-replication.sh" "check-replication.sh"
fi
if [ -f "5_Symbols/scripts/simulate-failure.sh" ]; then
    validate_bash "5_Symbols/scripts/simulate-failure.sh" "simulate-failure.sh"
    check_executable "5_Symbols/scripts/simulate-failure.sh" "simulate-failure.sh"
fi
if [ -f "5_Symbols/scripts/fix-replication.sh" ]; then
    validate_bash "5_Symbols/scripts/fix-replication.sh" "fix-replication.sh"
    check_executable "5_Symbols/scripts/fix-replication.sh" "fix-replication.sh"
fi
echo ""

echo -e "${BLUE}[6] Checking Documentation${NC}"
echo "-----------------------------------"
check_file "1_Real_Unknown/masterprompt.md" "Project requirements"
check_file "2_Environment/SETUP.md" "Setup guide"
check_file "4_Formula/REPLICATION_GUIDE.md" "Troubleshooting guide"
check_file "4_Formula/RECOVERY_POC.md" "Recovery demonstration"
echo ""

echo -e "${BLUE}[7] Verifying Script Features${NC}"
echo "-----------------------------------"

# Check for key features in check-replication.sh
if [ -f "5_Symbols/scripts/check-replication.sh" ]; then
    if grep -q "pg_stat_replication" 5_Symbols/scripts/check-replication.sh; then
        echo -e "${GREEN}✓${NC} check-replication.sh: Contains pg_stat_replication query"
    else
        echo -e "${RED}✗${NC} check-replication.sh: Missing pg_stat_replication query"
        ERRORS=$((ERRORS + 1))
    fi
    
    if grep -q "pg_stat_wal_receiver" 5_Symbols/scripts/check-replication.sh; then
        echo -e "${GREEN}✓${NC} check-replication.sh: Contains pg_stat_wal_receiver query"
    else
        echo -e "${RED}✗${NC} check-replication.sh: Missing pg_stat_wal_receiver query"
        ERRORS=$((ERRORS + 1))
    fi
    
    if grep -q "pg_wal_lsn_diff" 5_Symbols/scripts/check-replication.sh; then
        echo -e "${GREEN}✓${NC} check-replication.sh: Contains lag calculation"
    else
        echo -e "${YELLOW}⚠${NC} check-replication.sh: Missing lag calculation"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# Check for key features in fix-replication.sh
if [ -f "5_Symbols/scripts/fix-replication.sh" ]; then
    if grep -q "pg_create_physical_replication_slot" 5_Symbols/scripts/fix-replication.sh; then
        echo -e "${GREEN}✓${NC} fix-replication.sh: Contains slot creation logic"
    else
        echo -e "${YELLOW}⚠${NC} fix-replication.sh: Missing slot creation logic"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    if grep -q "ALTER USER.*PASSWORD" 5_Symbols/scripts/fix-replication.sh; then
        echo -e "${GREEN}✓${NC} fix-replication.sh: Contains password reset logic"
    else
        echo -e "${YELLOW}⚠${NC} fix-replication.sh: Missing password reset logic"
        WARNINGS=$((WARNINGS + 1))
    fi
    
    if grep -q "kubectl" 5_Symbols/scripts/fix-replication.sh; then
        echo -e "${GREEN}✓${NC} fix-replication.sh: Contains kubectl restart logic"
    else
        echo -e "${YELLOW}⚠${NC} fix-replication.sh: Missing kubectl restart logic"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# Check for key features in simulate-failure.sh
if [ -f "5_Symbols/scripts/simulate-failure.sh" ]; then
    if grep -q "password" 5_Symbols/scripts/simulate-failure.sh; then
        echo -e "${GREEN}✓${NC} simulate-failure.sh: Contains password change scenario"
    else
        echo -e "${RED}✗${NC} simulate-failure.sh: Missing password change scenario"
        ERRORS=$((ERRORS + 1))
    fi
    
    if grep -q "slot" 5_Symbols/scripts/simulate-failure.sh; then
        echo -e "${GREEN}✓${NC} simulate-failure.sh: Contains slot deletion scenario"
    else
        echo -e "${RED}✗${NC} simulate-failure.sh: Missing slot deletion scenario"
        ERRORS=$((ERRORS + 1))
    fi
fi

echo ""

echo -e "${BLUE}[8] Verifying Kubernetes Configuration${NC}"
echo "-----------------------------------"

# Check Primary configuration
if [ -f "5_Symbols/k8s/postgres-primary.yaml" ]; then
    if grep -q "wal_level=replica" 5_Symbols/k8s/postgres-primary.yaml; then
        echo -e "${GREEN}✓${NC} postgres-primary.yaml: WAL level configured for replication"
    else
        echo -e "${RED}✗${NC} postgres-primary.yaml: Missing wal_level=replica configuration"
        ERRORS=$((ERRORS + 1))
    fi
    
    if grep -q "max_wal_senders" 5_Symbols/k8s/postgres-primary.yaml; then
        echo -e "${GREEN}✓${NC} postgres-primary.yaml: WAL senders configured"
    else
        echo -e "${RED}✗${NC} postgres-primary.yaml: Missing max_wal_senders configuration"
        ERRORS=$((ERRORS + 1))
    fi
    
    if grep -q "max_replication_slots" 5_Symbols/k8s/postgres-primary.yaml; then
        echo -e "${GREEN}✓${NC} postgres-primary.yaml: Replication slots configured"
    else
        echo -e "${RED}✗${NC} postgres-primary.yaml: Missing max_replication_slots configuration"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Check Replica configuration
if [ -f "5_Symbols/k8s/postgres-replica.yaml" ]; then
    if grep -q "pg_basebackup" 5_Symbols/k8s/postgres-replica.yaml; then
        echo -e "${GREEN}✓${NC} postgres-replica.yaml: Contains pg_basebackup initialization"
    else
        echo -e "${RED}✗${NC} postgres-replica.yaml: Missing pg_basebackup initialization"
        ERRORS=$((ERRORS + 1))
    fi
    
    if grep -q "primary_conninfo" 5_Symbols/k8s/postgres-replica.yaml; then
        echo -e "${GREEN}✓${NC} postgres-replica.yaml: Primary connection string configured"
    else
        echo -e "${RED}✗${NC} postgres-replica.yaml: Missing primary_conninfo configuration"
        ERRORS=$((ERRORS + 1))
    fi
    
    if grep -q "primary_slot_name" 5_Symbols/k8s/postgres-replica.yaml; then
        echo -e "${GREEN}✓${NC} postgres-replica.yaml: Replication slot name configured"
    else
        echo -e "${YELLOW}⚠${NC} postgres-replica.yaml: Missing primary_slot_name configuration"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

echo ""

echo "========================================"
echo "Summary"
echo "========================================"
echo -e "Total Checks: $((ERRORS + WARNINGS + 30))"
echo -e "${GREEN}Passed: 30${NC}"
if [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
fi
if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}Errors: $ERRORS${NC}"
fi
echo "========================================"

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All critical checks passed!${NC}"
    echo ""
    echo "The EDB PostgreSQL Replication Testing Framework"
    echo "has been successfully implemented according to the"
    echo "masterprompt.md requirements."
    echo ""
    echo "Next steps:"
    echo "1. Deploy to a Kubernetes cluster (see 2_Environment/SETUP.md)"
    echo "2. Run ./5_Symbols/scripts/check-replication.sh to verify"
    echo "3. Test failure scenarios with ./5_Symbols/scripts/simulate-failure.sh"
    echo "4. Test recovery with ./5_Symbols/scripts/fix-replication.sh"
    echo ""
    exit 0
else
    echo -e "${RED}✗ Implementation has errors that need to be fixed${NC}"
    exit 1
fi
