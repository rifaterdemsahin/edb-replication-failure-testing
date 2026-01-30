# 7_Testing - Validation

## Overview
Contains test plans, validation procedures, and acceptance criteria for ensuring application quality to reach the objectives in Real and reach a known world.

## Test Plan

### Test Objectives
1. Validate replication connectivity between Primary and Replica
2. Verify failure detection mechanisms
3. Validate automated recovery procedures
4. Ensure data consistency across replication
5. Measure recovery time and effectiveness

## Test Scenarios

### Scenario 1: Normal Replication Operation
**Objective**: Verify healthy replication under normal conditions

**Prerequisites**:
- Primary and Replica deployed and running
- Replication slot created and active
- Network connectivity established

**Test Steps**:
1. Insert test data on Primary
2. Wait 5 seconds
3. Query same data on Replica
4. Verify data matches
5. Check replication lag < 1MB

**Expected Results**:
- ✓ Data appears on Replica within 5 seconds
- ✓ Replication lag < 1MB
- ✓ `pg_stat_replication` shows 'streaming' state
- ✓ No errors in logs

**Acceptance Criteria**:
- Replication lag < 100KB under normal load
- Data consistency 100%
- Zero data loss

### Scenario 2: Replication Slot Failure
**Objective**: Test detection and recovery from inactive replication slot

**Test Steps**:
1. Kill WAL sender process on Primary
2. Wait for monitoring to detect failure
3. Execute automated fix script
4. Verify replication resumes
5. Check data consistency

**Expected Results**:
- ✓ Failure detected within 30 seconds
- ✓ Alert triggered
- ✓ Automated fix recreates slot
- ✓ Replication resumes within 60 seconds
- ✓ Data consistency maintained

**Acceptance Criteria**:
- Detection time < 30 seconds
- Recovery time < 60 seconds
- No data loss during recovery

### Scenario 3: Network Interruption
**Objective**: Test replication behavior during network failures

**Test Steps**:
1. Block network traffic between Primary and Replica
2. Insert data on Primary
3. Monitor replication lag increase
4. Restore network connectivity
5. Verify replica catches up

**Expected Results**:
- ✓ Lag increases during network outage
- ✓ Connection marked as down
- ✓ Replica catches up when network restored
- ✓ All data replicated successfully

**Acceptance Criteria**:
- No data loss
- Catchup time proportional to lag
- Automatic reconnection without manual intervention

### Scenario 4: Authentication Failure
**Objective**: Test handling of authentication issues

**Test Steps**:
1. Change replication user password on Primary
2. Restart Replica (triggers reconnection attempt)
3. Verify failure detection
4. Update credentials
5. Verify successful reconnection

**Expected Results**:
- ✓ Authentication failure logged
- ✓ Alert triggered
- ✓ Clear error message provided
- ✓ Recovery after credential update

**Acceptance Criteria**:
- Clear authentication error messages
- Documented recovery procedure
- Manual intervention required for security

### Scenario 5: WAL Segment Removal
**Objective**: Test recovery when required WAL segments are removed

**Test Steps**:
1. Stop Replica
2. Generate significant WAL activity on Primary
3. Wait for old WAL segments to be removed
4. Attempt to start Replica
5. Verify pg_basebackup is triggered

**Expected Results**:
- ✓ Replica detects missing WAL segments
- ✓ Automated pg_basebackup initiated
- ✓ Replica rebuilds from Primary
- ✓ Replication resumes successfully

**Acceptance Criteria**:
- Automatic detection of unrecoverable lag
- Automated re-initialization process
- Full data consistency after rebuild

## Validation Procedures

### Data Consistency Validation
```sql
-- Run on Primary
SELECT md5(string_agg(id::text || data, ',' ORDER BY id)) as primary_checksum
FROM test_table;

-- Run on Replica (should match)
SELECT md5(string_agg(id::text || data, ',' ORDER BY id)) as replica_checksum
FROM test_table;
```

### Lag Validation
```bash
#!/bin/bash
# Check replication lag is within acceptable limits

LAG=$(psql -U postgres -t -c "SELECT pg_wal_lsn_diff(pg_current_wal_lsn(), replay_lsn) FROM pg_stat_replication;")

if [ $LAG -lt 1048576 ]; then
  echo "PASS: Lag is ${LAG} bytes (< 1MB)"
  exit 0
else
  echo "FAIL: Lag is ${LAG} bytes (>= 1MB)"
  exit 1
fi
```

### Connection Validation
```bash
#!/bin/bash
# Verify replication connection is active

STATE=$(psql -U postgres -t -c "SELECT state FROM pg_stat_replication;")

if [ "$STATE" == " streaming" ]; then
  echo "PASS: Replication is streaming"
  exit 0
else
  echo "FAIL: Replication state is ${STATE}"
  exit 1
fi
```

## Acceptance Criteria

### Functional Requirements
- [ ] Primary-Replica replication established successfully
- [ ] Replication lag monitored and reported accurately
- [ ] Failures detected within defined thresholds
- [ ] Automated recovery procedures execute successfully
- [ ] Data consistency maintained across all scenarios
- [ ] Logs provide clear diagnostic information

### Performance Requirements
- [ ] Replication lag < 100KB under normal load
- [ ] Replication lag < 10MB under high load
- [ ] Failure detection < 30 seconds
- [ ] Recovery time < 60 seconds for common failures
- [ ] Catchup rate > 10MB/s on 1Gbps network

### Reliability Requirements
- [ ] Zero data loss in tested scenarios
- [ ] 99.9% uptime for replication connection
- [ ] Automated recovery success rate > 95%
- [ ] Manual intervention required only for security-related issues

### Documentation Requirements
- [ ] All test scenarios documented
- [ ] Error messages and solutions documented
- [ ] Recovery procedures clearly explained
- [ ] Troubleshooting guide comprehensive

## Test Metrics

### Success Metrics
- **Test Coverage**: Percentage of scenarios tested
- **Pass Rate**: Percentage of tests passed
- **Recovery Success Rate**: Percentage of successful automated recoveries
- **Mean Time to Detection (MTTD)**: Average time to detect failures
- **Mean Time to Recovery (MTTR)**: Average time to recover from failures

### Quality Gates
- Minimum 90% test pass rate
- 100% critical scenario coverage
- Maximum 30s MTTD
- Maximum 60s MTTR
- Zero data loss in all tests

## Test Execution Checklist
- [ ] Environment setup complete
- [ ] All prerequisites met
- [ ] Test data prepared
- [ ] Monitoring enabled
- [ ] All scenarios executed
- [ ] Results documented
- [ ] Issues logged and tracked
- [ ] Final report generated
