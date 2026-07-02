# BPCP Holiday Discount Adoption

Status: service-local adoption contract
Date: 2026-07-02
Service: `minio-microservice`
Central contract pack: `statex-ecosystem/docs/business-process-control-plane/`

## Role

Optional campaign asset storage provider if BPCP/Marketing stores visual assets through MinIO.

## Responsibilities

- Store and serve approved campaign assets if selected by Marketing.
- Avoid storing process definitions as opaque assets.

## Required interfaces

- Asset refs for banners and images.
- Access control for internal/admin asset upload.

## Boundaries

- This service must not become the global owner of BPCP process definitions.
- This service must fail closed on invalid or unknown BPCP process versions.
- This service must keep existing domain ownership and invariants.
- This service must expose or document dry-run behavior before live execution.
- This service must not overwrite existing service contracts without an
  explicit integration owner and validation owner.

## Holiday Discount pilot expectations

- Recognize `holiday-discount-2026` only through versioned BPCP contracts.
- Preserve `processId`, `processVersion`, and `policyId` in every relevant
  decision, event, snapshot, log, or rendered experience.
- Support rollback by respecting BPCP pause and retired states.
- Keep process display and process execution separate where applicable.

## Blockers and unknowns

- [MISSING: whether Marketing currently stores campaign assets in MinIO]

## Validation evidence required before implementation is accepted

- Asset fetch smoke for campaign banner if used.
- Access rules prevent public write.

## Parallel handoff

This adoption doc is safe for a focused service owner to implement in parallel
after the central BPCP schemas are accepted. The service owner must not edit
shared BPCP schemas directly; schema changes go through the BPCP integration
owner.
