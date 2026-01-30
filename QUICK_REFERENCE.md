# Quick Reference Card

## Quick Start (3 Commands)

```bash
# 1. Deploy
kubectl apply -f k8s/postgres-primary.yaml -f k8s/postgres-replica.yaml

# 2. Check
./scripts/check-replication.sh

# 3. Test
./scripts/simulate-failure.sh password && ./scripts/fix-replication.sh
```

## Essential Commands

### Deployment
```bash
# Deploy Primary
kubectl apply -f k8s/postgres-primary.yaml

# Deploy Replica (wait 2 min for Primary)
kubectl apply -f k8s/postgres-replica.yaml

# Check status
kubectl get pods -l app=postgres
kubectl get statefulsets
```

### Health Monitoring
```bash
# Run health check
./scripts/check-replication.sh

# Watch continuously
watch -n 5 ./scripts/check-replication.sh

# Check from Primary
kubectl exec -it postgres-primary-0 -- psql -U postgres -d testdb -c "SELECT * FROM pg_stat_replication;"

# Check from Replica
kubectl exec -it postgres-replica-0 -- psql -U postgres -d testdb -c "SELECT * FROM pg_stat_wal_receiver;"
```

### Failure Scenarios
```bash
# Interactive menu
./scripts/simulate-failure.sh

# Specific scenarios
./scripts/simulate-failure.sh password      # Break authentication
./scripts/simulate-failure.sh slot          # Drop replication slot
./scripts/simulate-failure.sh terminate     # Terminate WAL sender
```

### Recovery
```bash
# Automated fix
./scripts/fix-replication.sh

# Manual check after fix
./scripts/check-replication.sh

# Manual restart if needed
kubectl rollout restart statefulset/postgres-replica
```

### Data Testing
```bash
# Insert on Primary
kubectl exec -it postgres-primary-0 -- psql -U postgres -d testdb -c "CREATE TABLE test (id serial, data text); INSERT INTO test (data) VALUES ('test');"

# Verify on Replica
kubectl exec -it postgres-replica-0 -- psql -U postgres -d testdb -c "SELECT * FROM test;"
```

## Key Metrics

| Metric | Command | Good Value |
|--------|---------|------------|
| Replication State | pg_stat_replication.state | streaming |
| Replica Count | COUNT(*) FROM pg_stat_replication | >= 1 |
| Lag bytes | pg_wal_lsn_diff(...) | < 1048576 |
| Recovery Mode | pg_is_in_recovery() | t (on replica) |
| WAL Receiver | pg_stat_wal_receiver.status | streaming |

## Documentation Links

- [SETUP.md](./SETUP.md) - Full setup guide
- [REPLICATION_GUIDE.md](./REPLICATION_GUIDE.md) - Troubleshooting
- [RECOVERY_POC.md](./RECOVERY_POC.md) - Recovery examples
- [SECURITY.md](./SECURITY.md) - Security notes

---
**Quick Start**: Deploy → Check → Test → Fix
