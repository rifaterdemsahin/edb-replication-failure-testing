# Master Prompt: EDB PostgreSQL Replication & Consistency Project

## Project Overview

Create a complete EDB PostgreSQL consistency and **replication management tool** running on Kubernetes (Minikube). This project provides a Proof of Concept (PoC) for detecting EDB replication errors, analyzing lag, and executing automated fixing processes (re-syncing) alongside standard health checks.

## Project Purpose

The project validates EDB Postgres high-availability health. It focuses on:

1. **Monitoring**: Identifying replication lag, broken WAL streams, and stale replication slots.
2. **Recovery**: Demonstrating an automated "Fixing Process" to re-establish broken replication links.
3. **Integrity**: Maintaining the existing checksum and bloat analysis for both Primary and Replica nodes.

## Updated Technology Stack

* **Database**: EDB Postgres Advanced Server (EPAS) or PostgreSQL 15 Alpine (simulating EDB behaviors).
* **Orchestration**: Kubernetes (StatefulSet for Primary/Replica identity).
* **Logic**: Bash scripts utilizing `pg_stat_replication` and `pg_stat_wal_receiver`.

## New Core Features (Replication Focus)

### 1. Replication Health Monitoring

* **Lag Detection**: Monitoring `write_lag`, `flush_lag`, and `replay_lag`.
* **Slot Status**: Checking for active/inactive replication slots.
* **Process Validation**: Verifying `walsender` on Primary and `walreceiver` on Replica.

### 2. Automated Fixing PoC

* **Scenario Simulation**: Scripted "breaking" of replication (e.g., killing the WAL stream or misconfiguring the primary_conninfo).
* **Healing Logic**: Automated triggers to refresh replication slots or restart the Replica with corrected recovery parameters.

---

## Updated Project Structure

```text
edb-replication-poc/
├── k8s/
│   ├── postgres-primary.yaml       # Primary Deployment/StatefulSet
│   ├── postgres-replica.yaml       # Replica Deployment/StatefulSet
│   ├── replication-check-job.yaml  # NEW: Specific job for replication health
│   └── fix-replication-job.yaml    # NEW: PoC job to repair broken replication
├── scripts/
│   ├── check-replication.sh        # SQL-based replication health logic
│   ├── simulate-failure.sh         # Script to intentionally break replication
│   ├── fix-replication.sh          # Logic to re-sync/restart replication
│   └── ... (existing scripts)
├── REPLICATION_GUIDE.md            # NEW: EDB replication troubleshooting guide
├── RECOVERY_POC.md                 # NEW: Documentation of the fixing process
└── ... (existing documentation)

```

---

## Detailed Implementation Instructions

### 1. Kubernetes Manifests: The Primary-Replica Setup

**Primary (postgres-primary):**

* **Args**: `["-c", "wal_level=replica", "-c", "max_wal_senders=10", "-c", "max_replication_slots=10"]`
* **Auth**: Configure `pg_hba.conf` via ConfigMap to allow replication connections from the pod subnet.

**Replica (postgres-replica):**

* **Environment**: Set `PRIMARY_HOST` to the Primary Service name.
* **InitContainer**: Use an initContainer to run `pg_basebackup` if the data directory is empty.

### 2. New Shell Scripts

#### File: `scripts/check-replication.sh`

1. **Check Primary**: Query `pg_stat_replication`.
* *Warning* if `state` is not 'streaming'.
* *Error* if no rows are returned (no replicas connected).


2. **Check Replica**: Query `pg_stat_wal_receiver`.
* *Pass* if `status` is 'streaming'.


3. **Lag Calculation**:
```sql
SELECT client_addr, pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS replication_lag_bytes 
FROM pg_stat_replication;

```



#### File: `scripts/fix-replication.sh` (The PoC Fix)

1. **Identify Issue**: Check if the replication slot is active.
2. **Flush Stale Slots**: If the slot is "stale" but inactive, drop and recreate it.
3. **Trigger Restart**: Use `kubectl rollout restart statefulset/postgres-replica` to force a fresh connection attempt.
4. **Verification**: Loop for 60s checking `pg_stat_replication` until status returns to 'streaming'.

### 3. Documentation Updates

#### File: `RECOVERY_POC.md`

* **Step 1: The Break**: Describe how the `simulate-failure.sh` script breaks the link (e.g., changing the replication user password).
* **Step 2: The Detection**: Show the error logs from the `replication-check-job`.
* **Step 3: The Fix**: Explain the logic used by the automation to resolve the credential mismatch or slot lock.
* **Step 4: The Proof**: Provide a "Before & After" table of LSN (Log Sequence Numbers) to prove data is flowing again.

---

## Updated Success Criteria

* ✅ **Replication Connectivity**: Primary recognizes Replica and shows 'streaming' status.
* ✅ **Failure Simulation**: The tool correctly identifies a manually induced replication break.
* ✅ **Self-Healing**: The `fix-replication-job` restores the connection without manual SQL intervention.
* ✅ **Consistency**: Data inserted into Primary is verified on Replica within  second.
