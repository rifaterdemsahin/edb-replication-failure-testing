# 6_Semblance - Error Logs and Solutions

## Overview
Documents common issues, their causes, and solutions. Includes debugging tips and workarounds for browser compatibility and system issues.

## Common Replication Errors

### Error 1: Replication Slot Inactive
**Symptom**: Replica not receiving WAL data

**Error Log**:
```
ERROR: replication slot "replica_slot" is inactive
HINT: The replication slot has been inactive for too long and may need to be recreated
```

**Cause**: 
- Replica disconnected for extended period
- WAL files removed before replay
- Network interruption

**Solution**:
```bash
# On Primary, check slot status
SELECT slot_name, active, restart_lsn FROM pg_replication_slots;

# Drop and recreate the slot
SELECT pg_drop_replication_slot('replica_slot');
SELECT pg_create_physical_replication_slot('replica_slot');

# Restart replica to reconnect
kubectl rollout restart statefulset/postgres-replica
```

### Error 2: WAL Segment Not Found
**Symptom**: Replica cannot catch up with Primary

**Error Log**:
```
FATAL: could not receive data from WAL stream: ERROR: requested WAL segment 000000010000000000000042 has already been removed
```

**Cause**:
- `wal_keep_size` too small
- Replication lag exceeded retention period
- Disk space constraints on Primary

**Solution**:
```bash
# Increase wal_keep_size on Primary
ALTER SYSTEM SET wal_keep_size = '2GB';
SELECT pg_reload_conf();

# If too far behind, re-initialize replica with pg_basebackup
pg_basebackup -h primary-host -D /var/lib/postgresql/data -U replication -P -v
```

### Error 3: Connection Refused
**Symptom**: Replica cannot connect to Primary

**Error Log**:
```
FATAL: could not connect to the primary server: connection to server at "postgres-primary" (10.0.0.1), port 5432 failed: Connection refused
```

**Cause**:
- Primary not running
- Network policy blocking connection
- pg_hba.conf not configured correctly

**Solution**:
```bash
# Check Primary service status
kubectl get svc postgres-primary

# Verify pg_hba.conf allows replication
# Add this line:
# host replication replication 0.0.0.0/0 md5

# Reload configuration
SELECT pg_reload_conf();
```

### Error 4: Authentication Failed
**Symptom**: Replica cannot authenticate to Primary

**Error Log**:
```
FATAL: password authentication failed for user "replication"
```

**Cause**:
- Incorrect password in replica configuration
- Password changed on Primary
- Credentials not synchronized

**Solution**:
```bash
# Update password on Primary
ALTER ROLE replication WITH PASSWORD 'new_password';

# Update replica configuration
# Edit primary_conninfo in postgresql.conf or recovery settings
# Restart replica
kubectl delete pod postgres-replica-0
```

### Error 5: Too Many WAL Senders
**Symptom**: New replica cannot connect

**Error Log**:
```
FATAL: number of requested standby connections exceeds max_wal_senders
```

**Cause**:
- `max_wal_senders` set too low
- Too many replicas connected

**Solution**:
```bash
# Increase max_wal_senders on Primary
ALTER SYSTEM SET max_wal_senders = 10;

# Restart Primary (requires downtime)
kubectl rollout restart statefulset/postgres-primary
```

## Debugging Tips

### Check Replication Status
```bash
# On Primary
psql -U postgres -c "SELECT * FROM pg_stat_replication;"

# On Replica
psql -U postgres -c "SELECT * FROM pg_stat_wal_receiver;"
```

### Monitor Replication Lag
```bash
# Calculate lag in bytes
psql -U postgres -c "SELECT pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) AS lag_bytes FROM pg_stat_replication;"

# Calculate lag in seconds
psql -U postgres -c "SELECT EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp())) AS lag_seconds;"
```

### Check Logs
```bash
# Kubernetes logs for Primary
kubectl logs postgres-primary-0

# Kubernetes logs for Replica
kubectl logs postgres-replica-0

# PostgreSQL logs inside pod
kubectl exec postgres-replica-0 -- tail -f /var/lib/postgresql/data/log/postgresql.log
```

## Browser Compatibility Issues

### WebSocket Support
**Issue**: Real-time monitoring dashboard not updating

**Workaround**:
```javascript
// Fallback to polling if WebSocket unavailable
if (!window.WebSocket) {
  setInterval(function() {
    fetch('/api/replication-status')
      .then(response => response.json())
      .then(data => updateDashboard(data));
  }, 5000);
}
```

### Chart.js Rendering
**Issue**: Charts not displaying in older browsers

**Workaround**:
```html
<!-- Include polyfills for older browsers -->
<script src="https://cdn.jsdelivr.net/npm/chart.js@3.9.1/dist/chart.min.js"></script>
<script src="https://cdn.jsdelivr.net/npm/chartjs-adapter-date-fns@2.0.0"></script>
```

## Performance Troubleshooting

### High Replication Lag
**Investigation Steps**:
1. Check network bandwidth: `iperf` between Primary and Replica
2. Check disk I/O: `iostat -x 1`
3. Check CPU usage: `top` or `htop`
4. Analyze slow queries: `pg_stat_statements`

**Optimization**:
- Increase `max_wal_senders`
- Enable compression: `wal_compression = on`
- Optimize checkpoint settings
- Use faster storage for WAL

### Memory Issues
**Symptoms**:
- Out of memory errors
- Slow query performance
- Connection failures

**Solution**:
```bash
# Check memory usage
kubectl top pod postgres-primary-0

# Increase memory limits in Kubernetes manifest
resources:
  limits:
    memory: 4Gi
  requests:
    memory: 2Gi
```
