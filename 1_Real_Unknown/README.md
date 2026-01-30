# EDB PostgreSQL Replication Failure Testing

A complete EDB PostgreSQL replication management and testing framework running on Kubernetes. This project provides automated tools for monitoring, testing, and recovering from replication failures.

## 🎯 Purpose

Validates EDB Postgres high-availability health by:
- **Monitoring**: Detecting replication lag, broken WAL streams, and stale replication slots
- **Testing**: Simulating various replication failure scenarios
- **Recovery**: Demonstrating automated healing processes to re-establish broken replication

## 🚀 Quick Start

```bash
# 1. Deploy to Kubernetes
kubectl apply -f k8s/postgres-primary.yaml
kubectl apply -f k8s/postgres-replica.yaml

# 2. Verify replication is working
./scripts/check-replication.sh

# 3. Test failure and recovery
./scripts/simulate-failure.sh password
./scripts/fix-replication.sh
```

## 📁 Project Structure

```
├── k8s/                              # Kubernetes manifests
│   ├── postgres-primary.yaml        # Primary StatefulSet
│   ├── postgres-replica.yaml        # Replica StatefulSet
│   ├── replication-check-job.yaml   # Health check Job
│   └── fix-replication-job.yaml     # Automated repair Job
├── scripts/                          # Automation scripts
│   ├── check-replication.sh         # Health monitoring
│   ├── simulate-failure.sh          # Failure simulation
│   └── fix-replication.sh           # Automated recovery
├── SETUP.md                          # Deployment guide
├── REPLICATION_GUIDE.md              # Troubleshooting reference
├── RECOVERY_POC.md                   # Recovery demonstration
└── masterprompt.md                   # Project requirements

```

## ✨ Features

- ✅ **Replication Connectivity**: Primary/Replica streaming setup
- ✅ **Failure Simulation**: Test various failure scenarios
- ✅ **Self-Healing**: Automated recovery processes
- ✅ **Data Consistency**: Verify replication integrity
- ✅ **Monitoring**: Real-time health checks with detailed metrics
- ✅ **Documentation**: Comprehensive guides and runbooks

## 📖 Documentation

- **[SETUP.md](./SETUP.md)** - Quick start and deployment guide
- **[REPLICATION_GUIDE.md](./REPLICATION_GUIDE.md)** - Comprehensive troubleshooting guide
- **[RECOVERY_POC.md](./RECOVERY_POC.md)** - Recovery proof of concept demonstration
- **[masterprompt.md](./masterprompt.md)** - Original project requirements

## 🧪 Testing

Run the verification script to validate the implementation:

```bash
./test-implementation.sh
```

## 🛠️ Technology Stack

- **Database**: PostgreSQL 15 Alpine (simulating EDB behaviors)
- **Orchestration**: Kubernetes (StatefulSet)
- **Scripting**: Bash with PostgreSQL client tools
- **Monitoring**: SQL queries via `pg_stat_replication` and `pg_stat_wal_receiver`

## 📊 Success Criteria

✅ **Replication Connectivity**: Primary recognizes Replica in streaming state  
✅ **Failure Detection**: Tool identifies induced replication breaks  
✅ **Self-Healing**: Automated recovery without manual SQL intervention  
✅ **Data Consistency**: Data replicates from Primary to Replica < 1 second

## 🤝 Contributing

This is a proof-of-concept project for testing EDB PostgreSQL replication scenarios.

## 📝 License

See LICENSE file for details.