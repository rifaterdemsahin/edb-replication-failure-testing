# EDB PostgreSQL Replication Troubleshooting Guide

## Overview

This guide provides comprehensive troubleshooting steps for EDB PostgreSQL replication issues in Kubernetes environments.

## Common Replication Issues

### 1. Replication Not Starting

**Symptoms:**
- No entries in `pg_stat_replication` on primary
- Replica logs show connection errors
- WAL receiver not running on replica

**Possible Causes:**
- Incorrect connection parameters
- Authentication failures
- Network connectivity issues
- Missing replication slot

**Resolution Steps:**

1. **Check Primary Configuration:**
   ```sql
   -- Verify replication settings
   SHOW wal_level;  -- Should be 'replica' or higher
   SHOW max_wal_senders;  -- Should be > 0
   ```

2. **Check Replication User:**
   ```sql
   SELECT usename, userepl FROM pg_user WHERE usename = 'replicator';
   ```

3. **Verify pg_hba.conf:**
   ```
   host replication all all md5
   ```

4. **Check Replica Configuration:**
   ```bash
   # In replica pod
   cat $PGDATA/postgresql.auto.conf
   # Should contain primary_conninfo and primary_slot_name
   ```

### 2. Replication Lag

**Symptoms:**
- High values in `write_lag`, `flush_lag`, or `replay_lag`
- Data inconsistency between primary and replica
- `pg_wal_lsn_diff` shows large byte difference

**Possible Causes:**
- Network latency
- High write load on primary
- Slow disk I/O on replica
- Long-running transactions on replica

**Resolution Steps:**

1. **Check Current Lag:**
   ```sql
   SELECT 
     application_name,
     pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS lag_bytes,
     write_lag,
     flush_lag,
     replay_lag
   FROM pg_stat_replication;
   ```

2. **Identify Bottlenecks:**
   ```sql
   -- Check for blocking queries on replica
   SELECT pid, usename, query, state, wait_event_type, wait_event
   FROM pg_stat_activity
   WHERE state != 'idle' AND pid != pg_backend_pid();
   ```

3. **Monitor WAL Generation Rate:**
   ```sql
   SELECT
     pg_current_wal_lsn(),
     pg_walfile_name(pg_current_wal_lsn());
   ```

### 3. Replication Slot Issues

**Symptoms:**
- Slot status shows 'inactive'
- WAL files accumulating on primary
- Replica cannot connect to slot

**Possible Causes:**
- Replica disconnected unexpectedly
- Slot name mismatch
- Slot dropped accidentally

**Resolution Steps:**

1. **Check Slot Status:**
   ```sql
   SELECT 
     slot_name,
     slot_type,
     active,
     restart_lsn,
     confirmed_flush_lsn
   FROM pg_replication_slots;
   ```

2. **Drop and Recreate Slot (if needed):**
   ```sql
   -- On primary (only if slot is inactive and causing issues)
   SELECT pg_drop_replication_slot('replica_slot');
   SELECT pg_create_physical_replication_slot('replica_slot');
   ```

3. **Verify Slot Name in Replica Config:**
   ```bash
   # Check postgresql.auto.conf or recovery.conf
   grep primary_slot_name $PGDATA/postgresql.auto.conf
   ```

### 4. Authentication Failures

**Symptoms:**
- "password authentication failed" in replica logs
- Replica constantly reconnecting
- No replication connection established

**Possible Causes:**
- Password mismatch
- Incorrect username
- pg_hba.conf misconfiguration

**Resolution Steps:**

1. **Reset Replication User Password:**
   ```sql
   ALTER USER replicator WITH PASSWORD 'new_password';
   ```

2. **Update Replica Connection String:**
   ```bash
   # In Kubernetes, update the StatefulSet env or ConfigMap
   kubectl edit statefulset postgres-replica
   ```

3. **Verify pg_hba.conf Entry:**
   ```sql
   -- Should have line like:
   host replication replicator all md5
   ```

### 5. WAL Sender/Receiver Process Issues

**Symptoms:**
- WAL sender terminated unexpectedly
- WAL receiver not running
- Replication state shows 'startup' instead of 'streaming'

**Possible Causes:**
- Process crashed
- Resource constraints
- Connection timeout

**Resolution Steps:**

1. **Check WAL Sender on Primary:**
   ```sql
   SELECT pid, usename, application_name, state, backend_type
   FROM pg_stat_activity
   WHERE backend_type = 'walsender';
   ```

2. **Check WAL Receiver on Replica:**
   ```sql
   SELECT status, receive_start_lsn, received_lsn
   FROM pg_stat_wal_receiver;
   ```

3. **Restart Replica (if needed):**
   ```bash
   kubectl rollout restart statefulset/postgres-replica
   ```

## Automated Tools

### Health Check Script

Use the provided `check-replication.sh` script to automatically diagnose issues:

```bash
./scripts/check-replication.sh
```

Output includes:
- Primary connection status
- Replication connection count
- Streaming state verification
- Replication lag measurements
- Replica recovery mode check
- WAL receiver status
- LSN comparison

### Failure Simulation

Test your monitoring with `simulate-failure.sh`:

```bash
# Interactive mode
./scripts/simulate-failure.sh

# Command line mode
./scripts/simulate-failure.sh password   # Break by changing password
./scripts/simulate-failure.sh slot       # Break by dropping slot
./scripts/simulate-failure.sh terminate  # Break by terminating WAL sender
```

### Automated Repair

Use `fix-replication.sh` for automated recovery:

```bash
./scripts/fix-replication.sh
```

This script:
1. Verifies primary accessibility
2. Checks current replication status
3. Fixes replication user and password
4. Recreates replication slot if needed
5. Restarts replica if necessary
6. Waits for replication to resume
7. Displays final status

## Kubernetes-Specific Considerations

### Pod Connectivity

```bash
# Test connectivity from replica to primary
kubectl exec -it postgres-replica-0 -- pg_isready -h postgres-primary -p 5432

# Check service endpoints
kubectl get endpoints postgres-primary
kubectl get endpoints postgres-replica
```

### Resource Limits

```bash
# Check pod resources
kubectl top pod postgres-primary-0
kubectl top pod postgres-replica-0

# Describe pod for events
kubectl describe pod postgres-replica-0
```

### Logs

```bash
# Primary logs
kubectl logs postgres-primary-0

# Replica logs
kubectl logs postgres-replica-0

# Follow logs in real-time
kubectl logs -f postgres-replica-0
```

## Best Practices

1. **Monitor Regularly:** Set up automated health checks using the provided scripts
2. **Alert on Lag:** Configure alerts when replication lag exceeds thresholds
3. **Test Failover:** Regularly test promotion of replica to primary
4. **Backup Slots:** Keep track of replication slot names and configurations
5. **Document Changes:** Record any manual interventions for future reference
6. **Resource Planning:** Ensure adequate CPU, memory, and network bandwidth
7. **Regular Updates:** Keep PostgreSQL and Kubernetes versions up to date

## Monitoring Queries

### Quick Status Check
```sql
SELECT * FROM pg_stat_replication;
```

### Detailed Lag Information
```sql
SELECT 
    client_addr,
    state,
    pg_wal_lsn_diff(pg_current_wal_lsn(), sent_lsn) AS send_lag_bytes,
    pg_wal_lsn_diff(sent_lsn, write_lsn) AS write_lag_bytes,
    pg_wal_lsn_diff(write_lsn, flush_lsn) AS flush_lag_bytes,
    pg_wal_lsn_diff(flush_lsn, replay_lsn) AS replay_lag_bytes,
    write_lag,
    flush_lag,
    replay_lag
FROM pg_stat_replication;
```

### Replication Slot Health
```sql
SELECT 
    slot_name,
    active,
    pg_wal_lsn_diff(pg_current_wal_lsn(), restart_lsn) AS retained_wal_bytes,
    temporary
FROM pg_replication_slots;
```

## Emergency Procedures

### Complete Replication Reset

If all else fails, perform a complete re-initialization:

```bash
# 1. Stop replica
kubectl scale statefulset postgres-replica --replicas=0

# 2. Delete replica PVC
kubectl delete pvc postgres-storage-postgres-replica-0

# 3. Recreate replication slot on primary
kubectl exec -it postgres-primary-0 -- psql -U postgres -d testdb -c "SELECT pg_drop_replication_slot('replica_slot');"
kubectl exec -it postgres-primary-0 -- psql -U postgres -d testdb -c "SELECT pg_create_physical_replication_slot('replica_slot');"

# 4. Restart replica (will reinitialize from primary)
kubectl scale statefulset postgres-replica --replicas=1

# 5. Monitor startup
kubectl logs -f postgres-replica-0
```

## Support and Resources

- PostgreSQL Documentation: https://www.postgresql.org/docs/current/warm-standby.html
- EDB Documentation: https://www.enterprisedb.com/docs/
- GitHub Issues: Report issues in this repository
