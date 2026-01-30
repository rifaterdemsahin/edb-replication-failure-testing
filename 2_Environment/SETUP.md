# EDB PostgreSQL Replication Testing - Setup Guide

## Prerequisites

- Kubernetes cluster (Minikube, kind, or cloud provider)
- kubectl configured and connected to cluster
- At least 2GB available storage
- PostgreSQL client tools (for testing)

## Quick Start

### 1. Deploy PostgreSQL Primary and Replica

```bash
# Apply Primary StatefulSet
kubectl apply -f 5_Symbols/k8s/postgres-primary.yaml

# Wait for Primary to be ready
kubectl wait --for=condition=ready pod/postgres-primary-0 --timeout=120s

# Apply Replica StatefulSet
kubectl apply -f 5_Symbols/k8s/postgres-replica.yaml

# Wait for Replica to be ready
kubectl wait --for=condition=ready pod/postgres-replica-0 --timeout=180s
```

### 2. Verify Replication is Working

```bash
# Run health check script
./5_Symbols/scripts/check-replication.sh
```

Expected output should show:
- ✓ Primary server accessible
- ✓ 1 replica(s) connected
- ✓ 1 replica(s) in streaming state
- ✓ Replica is in recovery mode
- ✓ WAL receiver is streaming

### 3. Test Failure Scenarios

```bash
# Interactive mode - choose from menu
./5_Symbols/scripts/simulate-failure.sh

# Or run specific scenario
./5_Symbols/scripts/simulate-failure.sh password
```

### 4. Test Automated Recovery

```bash
# Run automated fix
./5_Symbols/scripts/fix-replication.sh
```

### 5. Deploy Kubernetes Jobs (Optional)

```bash
# Deploy health check job
kubectl apply -f 5_Symbols/k8s/replication-check-job.yaml

# Deploy fix job
kubectl apply -f 5_Symbols/k8s/fix-replication-job.yaml

# View job logs
kubectl logs job/replication-check
kubectl logs job/fix-replication
```

## Configuration

### Environment Variables

Scripts use these environment variables (with defaults):

```bash
PRIMARY_HOST=postgres-primary
REPLICA_HOST=postgres-replica
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=testdb
REPLICATION_USER=replicator
REPLICATION_PASSWORD=replicator_password
```

## Testing Data Replication

### Insert test data on Primary

```bash
kubectl exec -it postgres-primary-0 -- psql -U postgres -d testdb -c "
  CREATE TABLE IF NOT EXISTS test_replication (
    id SERIAL PRIMARY KEY,
    message TEXT,
    created_at TIMESTAMP DEFAULT NOW()
  );
  INSERT INTO test_replication (message) VALUES ('Test message');
"
```

### Verify data on Replica

```bash
kubectl exec -it postgres-replica-0 -- psql -U postgres -d testdb -c "SELECT * FROM test_replication;"
```

## Cleanup

```bash
# Delete StatefulSets
kubectl delete statefulset postgres-primary postgres-replica

# Delete Services
kubectl delete service postgres-primary postgres-replica

# Delete PVCs
kubectl delete pvc --all

# Delete ConfigMaps
kubectl delete configmap postgres-primary-config replication-scripts
```

## Documentation

- [REPLICATION_GUIDE.md](../4_Formula/REPLICATION_GUIDE.md) - Troubleshooting reference
- [RECOVERY_POC.md](../4_Formula/RECOVERY_POC.md) - Recovery demonstration
- [masterprompt.md](../1_Real_Unknown/masterprompt.md) - Project requirements
