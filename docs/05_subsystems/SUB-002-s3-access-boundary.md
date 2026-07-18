# SUB-002: S3 Access Boundary

```yaml
id: SUB-002
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ../04_systems/SYS-001-private-object-storage.md
downstream:
  - ../10_features/FEAT-002-presigned-access-boundary.md
related_adrs:
  - ADR-001
```

## Purpose
Protect the boundary between public HTTPS access and private MinIO storage while preserving S3 SigV4 semantics.

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
