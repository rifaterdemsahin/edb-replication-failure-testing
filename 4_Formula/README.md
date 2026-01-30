# 4_Formula - Guides and Best Practices

## Overview
Provides guidelines and formulas built by GPT for EDB PostgreSQL replication management.

## Replication Health Formulas

### Lag Calculation
```
replication_lag_bytes = pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn)
replication_lag_seconds = EXTRACT(EPOCH FROM (now() - pg_last_xact_replay_timestamp()))
```

### Health Score Formula
```
health_score = 100 - (
  (lag_penalty * 0.4) +
  (connection_penalty * 0.3) +
  (slot_penalty * 0.2) +
  (performance_penalty * 0.1)
)

where:
  lag_penalty = min(100, (replication_lag_bytes / threshold) * 100)
  connection_penalty = streaming ? 0 : 100
  slot_penalty = active_slots < required_slots ? 50 : 0
  performance_penalty = wal_sender_cpu_usage > 80 ? 30 : 0
```

## Best Practices

### Replication Configuration

#### Primary Server Settings
```bash
# postgresql.conf
wal_level = replica
max_wal_senders = 10
max_replication_slots = 10
wal_keep_size = 1GB
hot_standby = on
```

#### Replica Server Settings
```bash
# postgresql.conf
hot_standby = on
max_standby_streaming_delay = 30s
hot_standby_feedback = on
```

### Monitoring Best Practices

#### Check Interval Guidelines
- **Critical checks**: Every 10 seconds
- **Standard checks**: Every 30 seconds
- **Performance checks**: Every 60 seconds
- **Historical analysis**: Every 5 minutes

#### Alert Threshold Formulas
```
Critical: lag > 10MB OR connection_down > 30s
Warning: lag > 1MB OR connection_down > 10s
Info: lag > 100KB
```

### Recovery Best Practices

#### Automated Fix Decision Tree
```
IF replication_state != 'streaming' THEN
  IF slot_exists AND slot_active THEN
    restart_wal_receiver()
  ELSE IF slot_exists AND NOT slot_active THEN
    recreate_replication_slot()
  ELSE
    create_replication_slot() AND restart_replica()
  END IF
END IF
```

#### Recovery Time Estimation
```
estimated_recovery_time = (
  slot_recreation_time +
  connection_establishment_time +
  lag_catchup_time
)

where:
  slot_recreation_time = 5s
  connection_establishment_time = 3s
  lag_catchup_time = replication_lag_bytes / network_throughput
```

### Performance Optimization

#### WAL Tuning Formula
```
optimal_wal_keep_size = (
  max_expected_lag_duration *
  average_wal_generation_rate *
  safety_multiplier
)

where:
  safety_multiplier = 1.5
```

#### Connection Pool Sizing
```
max_wal_senders = number_of_replicas + 2
max_replication_slots = max_wal_senders
```

## Testing Formulas

### Test Coverage Score
```
coverage_score = (
  (scenarios_tested / total_scenarios) * 0.4 +
  (failure_modes_tested / total_failure_modes) * 0.3 +
  (recovery_paths_tested / total_recovery_paths) * 0.3
) * 100
```

### Success Rate Calculation
```
success_rate = (successful_recoveries / total_failures) * 100
average_recovery_time = sum(recovery_times) / successful_recoveries
```
