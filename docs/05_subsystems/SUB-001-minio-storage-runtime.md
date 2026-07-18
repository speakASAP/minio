# SUB-001: MinIO Storage Runtime

```yaml
id: SUB-001
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ../04_systems/SYS-001-private-object-storage.md
downstream:
  - ../10_features/FEAT-001-private-recording-storage.md
related_adrs:
  - ADR-001
```

## Purpose
Run MinIO with a stable data root, private bucket, and deployment configuration suitable for production storage.

## Parent system
SYS-001: Private Object Storage.

## Responsibilities
Maintain the documented service boundary, safe configuration handling, and validation evidence for this subsystem.

## Interfaces
README, scripts, nginx snippets, Kubernetes manifests, and validation reports relevant to this subsystem.

## Dependencies
MinIO runtime, proxy configuration, secret-backed environment, and operator access on alfares.

## Data ownership
Owns only the behavior described by this subsystem. Consumer applications own business semantics for their objects.

## Failure modes
Credential leakage, invalid proxy behavior, public bucket policy, unavailable runtime, or unsafe diagnostic evidence.

## Validation criteria
Run the relevant service script and IPS gate, then summarize results without secrets or raw production data.

## Inputs
Authenticated service requests, secret-backed configuration names, operator commands, and documented runtime state.

## Outputs
Private object storage behavior, proxy/access behavior, or diagnostic evidence relevant to this subsystem.

## Validation
Run the relevant service script and IPS gate, then record a secret-safe summary in a validation report.
