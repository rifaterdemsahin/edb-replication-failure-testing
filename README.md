# EDB PostgreSQL Replication Failure Testing

A complete EDB PostgreSQL replication management and testing framework running on Kubernetes.

## 📁 Project Structure

This project follows a structured organization pattern:

### 1_Real_Unknown - Objectives
- **Purpose**: Defines project objectives and key results, starting with the unknown problem
- **Contents**: Project overview, requirements (masterprompt.md)

### 2_Environment - Roadmap and Use Cases  
- **Purpose**: Contains the project roadmap with development phases and use cases
- **Contents**: Setup guide, deployment instructions

### 3_Simulation - UI
- **Purpose**: User interfaces and technologies (not applicable for this backend project)
- **Contents**: UI documentation templates

### 4_Formula - Guides and Best Practices
- **Purpose**: Provides guidelines built by GPT
- **Contents**: Troubleshooting guide, recovery procedures, security considerations, quick reference

### 5_Symbols - Core Source Code
- **Purpose**: Contains the main application files
- **Contents**: 
  - `k8s/` - Kubernetes manifests for Primary/Replica StatefulSets
  - `scripts/` - Automation scripts for monitoring, failure simulation, and recovery

### 6_Semblance - Error Logs and Solutions
- **Purpose**: Documents common issues, causes, and solutions
- **Contents**: Debugging tips and workarounds

### 7_Testing_known - Validation
- **Purpose**: Contains test plans, validation procedures, and acceptance criteria
- **Contents**: Test implementation script, validation results, implementation summary

## 🚀 Quick Start

```bash
# 1. Deploy to Kubernetes
kubectl apply -f 5_Symbols/k8s/postgres-primary.yaml
kubectl apply -f 5_Symbols/k8s/postgres-replica.yaml

# 2. Verify replication
./5_Symbols/scripts/check-replication.sh

# 3. Test failure and recovery
./5_Symbols/scripts/simulate-failure.sh password
./5_Symbols/scripts/fix-replication.sh
```

## 📖 Key Documentation

- **[1_Real_Unknown/README.md](./1_Real_Unknown/README.md)** - Project overview and objectives
- **[2_Environment/SETUP.md](./2_Environment/SETUP.md)** - Deployment guide
- **[4_Formula/REPLICATION_GUIDE.md](./4_Formula/REPLICATION_GUIDE.md)** - Troubleshooting reference
- **[4_Formula/RECOVERY_POC.md](./4_Formula/RECOVERY_POC.md)** - Recovery demonstration
- **[4_Formula/QUICK_REFERENCE.md](./4_Formula/QUICK_REFERENCE.md)** - Command cheat sheet
- **[7_Testing_known/IMPLEMENTATION_SUMMARY.md](./7_Testing_known/IMPLEMENTATION_SUMMARY.md)** - Project completion report

## 🧪 Testing

Run the verification script to validate the implementation:

```bash
cd 7_Testing_known
./test-implementation.sh
```

## ✨ Features

- ✅ **Replication Connectivity**: Primary/Replica streaming setup
- ✅ **Failure Simulation**: Test various failure scenarios
- ✅ **Self-Healing**: Automated recovery processes
- ✅ **Data Consistency**: Verify replication integrity
- ✅ **Monitoring**: Real-time health checks with detailed metrics
- ✅ **Documentation**: Comprehensive guides and runbooks

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
