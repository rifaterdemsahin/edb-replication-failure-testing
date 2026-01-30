# 5_Symbols - Core Source Code

## Overview
Contains the main application files and source code for the EDB replication failure testing system.

## Directory Structure

```
5_Symbols/
├── scripts/
│   ├── check-replication.sh
│   ├── fix-replication.sh
│   ├── simulate-failure.sh
│   └── health-check.sh
├── k8s/
│   ├── postgres-primary.yaml
│   ├── postgres-replica.yaml
│   ├── replication-check-job.yaml
│   └── fix-replication-job.yaml
├── sql/
│   ├── monitoring-queries.sql
│   ├── replication-status.sql
│   └── lag-analysis.sql
└── config/
    ├── postgresql-primary.conf
    ├── postgresql-replica.conf
    └── pg_hba.conf
```

## Core Components

### Replication Check Script
**File**: `scripts/check-replication.sh`

**Purpose**: Monitor replication health and detect issues

**Key Functions**:
- Query `pg_stat_replication` on Primary
- Query `pg_stat_wal_receiver` on Replica
- Calculate replication lag
- Report connection status

### Fix Replication Script
**File**: `scripts/fix-replication.sh`

**Purpose**: Automated recovery for replication failures

**Key Functions**:
- Identify replication issues
- Flush stale replication slots
- Recreate broken slots
- Restart replica connections
- Verify recovery success

### Failure Simulation Script
**File**: `scripts/simulate-failure.sh`

**Purpose**: Create controlled failure scenarios for testing

**Key Functions**:
- Break replication connections
- Simulate network issues
- Corrupt replication slots
- Test credential failures

### Kubernetes Manifests

#### Primary Database
**File**: `k8s/postgres-primary.yaml`

**Configuration**:
- StatefulSet for stable identity
- WAL configuration for replication
- Replication user setup
- Service exposure

#### Replica Database
**File**: `k8s/postgres-replica.yaml`

**Configuration**:
- StatefulSet configuration
- InitContainer for pg_basebackup
- Recovery configuration
- Connection to Primary

### SQL Queries

#### Replication Status Query
```sql
-- Check replication status on Primary
SELECT 
  client_addr,
  state,
  sync_state,
  pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS lag_bytes,
  write_lag,
  flush_lag,
  replay_lag
FROM pg_stat_replication;
```

#### WAL Receiver Status
```sql
-- Check WAL receiver status on Replica
SELECT 
  status,
  receive_start_lsn,
  receive_start_tli,
  received_lsn,
  last_msg_send_time,
  last_msg_receipt_time
FROM pg_stat_wal_receiver;
```

## Code Conventions

### Shell Script Standards
- Use bash shebang: `#!/bin/bash`
- Set error handling: `set -euo pipefail`
- Include function documentation
- Use meaningful variable names
- Add logging statements

### SQL Standards
- Use uppercase for SQL keywords
- Indent nested queries
- Add comments for complex logic
- Include execution time expectations

### YAML Standards
- Use 2-space indentation
- Include resource limits
- Add descriptive labels
- Document configuration options
