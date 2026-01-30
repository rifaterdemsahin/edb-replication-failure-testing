# Security Considerations

## Overview

This is a **Proof of Concept (PoC)** project designed for testing and demonstration purposes. The implementation includes several intentional simplifications that **must not be used in production environments**.

## Known Security Issues (By Design)

### 1. Hardcoded Credentials

**Location**: Throughout k8s manifests and scripts
- `POSTGRES_PASSWORD=postgres`
- `REPLICATION_PASSWORD=replicator_password`

**Risk**: Credentials are stored in plaintext in ConfigMaps, environment variables, and scripts.

**Production Recommendation**:
```yaml
# Use Kubernetes Secrets instead
env:
  - name: POSTGRES_PASSWORD
    valueFrom:
      secretKeyRef:
        name: postgres-secret
        key: password
```

### 2. PostgreSQL Authentication

**Location**: `k8s/postgres-primary.yaml` line 90
- `pg_hba.conf` allows connections from all hosts: `host all all all md5`

**Risk**: Any host on the network can attempt to connect to the database.

**Production Recommendation**:
```
# Restrict to specific IP ranges
host all all 10.0.0.0/8 scram-sha-256
host replication replicator 10.0.0.0/8 scram-sha-256
```

### 3. Credential Exposure in Logs

**Location**: Container arguments and initContainer commands
- Passwords visible in `kubectl describe pod`
- Passwords visible in process listings

**Production Recommendation**:
- Use password files or environment variables
- Enable SELinux or AppArmor policies
- Restrict pod specifications access with RBAC

### 4. Missing TLS/SSL

**Current**: All PostgreSQL connections use plaintext
- Replication traffic is not encrypted
- Client connections are not encrypted

**Production Recommendation**:
```yaml
# Enable SSL for PostgreSQL
args:
  - "-c"
  - "ssl=on"
  - "-c"
  - "ssl_cert_file=/var/lib/postgresql/certs/server.crt"
  - "-c"
  - "ssl_key_file=/var/lib/postgresql/certs/server.key"
```

### 5. RBAC Permissions

**Location**: `k8s/fix-replication-job.yaml`
- ServiceAccount has permissions to modify StatefulSets

**Risk**: Compromised Job could manipulate cluster resources

**Production Recommendation**:
- Implement least-privilege RBAC policies
- Use Pod Security Policies/Standards
- Regular security audits

## Production Hardening Checklist

Before deploying to production:

- [ ] Move all credentials to Kubernetes Secrets
- [ ] Enable TLS/SSL for all connections
- [ ] Restrict `pg_hba.conf` to specific IP ranges
- [ ] Implement network policies to isolate database pods
- [ ] Use scram-sha-256 authentication instead of md5
- [ ] Enable audit logging for PostgreSQL
- [ ] Implement regular security scanning (e.g., Trivy, Snyk)
- [ ] Set up secret rotation policies
- [ ] Enable pod security standards/policies
- [ ] Restrict RBAC permissions to minimum required
- [ ] Use private container registries
- [ ] Implement regular backup and disaster recovery procedures
- [ ] Set up security monitoring and alerting
- [ ] Conduct security review of all scripts
- [ ] Remove or secure administrative scripts

## Example: Using Kubernetes Secrets

### Create Secrets

```bash
# Create postgres password secret
kubectl create secret generic postgres-secret \
  --from-literal=password='your-secure-password'

# Create replication password secret
kubectl create secret generic replication-secret \
  --from-literal=password='your-secure-replication-password'
```

### Update Manifest

```yaml
# In postgres-primary.yaml
env:
  - name: POSTGRES_PASSWORD
    valueFrom:
      secretKeyRef:
        name: postgres-secret
        key: password
  - name: REPLICATION_PASSWORD
    valueFrom:
      secretKeyRef:
        name: replication-secret
        key: password
```

## Compliance

This PoC does not meet compliance standards such as:
- PCI DSS
- HIPAA
- SOC 2
- GDPR (for production systems)

Do **not** use this configuration for systems handling:
- Payment card data
- Personal health information
- Personally identifiable information (PII)
- Financial data
- Production workloads

## Disclaimer

This project is provided **as-is** for educational and testing purposes only. The maintainers assume no responsibility for security incidents resulting from the use of this code in production environments or with sensitive data.

Always conduct a thorough security review and implement appropriate controls before deploying database systems to production.

## Resources

- [PostgreSQL Security](https://www.postgresql.org/docs/current/security.html)
- [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [EDB Security Best Practices](https://www.enterprisedb.com/docs/security/)
