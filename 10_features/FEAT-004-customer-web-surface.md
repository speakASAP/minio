# FEAT-004: Customer Web Surface

```yaml
id: FEAT-004
status: draft
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
completeness_level: complete
upstream:
  - ../00_constitution/CONSTITUTION.md
  - ../01_vision/VISION.md
  - ../02_business_case/BUSINESS_CASE.md
  - ../04_systems/SYS-001-private-object-storage.md
```

## Goal
Create a customer-facing web surface that converts prospects, routes identity through Auth, routes sales intake through Leads, and gives customers and administrators a safe first interface for Alfares Object Storage.

## Objective
Provide landing, pricing, registration handoff, customer dashboard, and administrator dashboard surfaces without weakening private bucket policy or S3 endpoint behavior.

## Scope
- Landing page with pricing and consultation CTA.
- Leads microservice submission before Auth registration.
- Client dashboard for Auth-backed account state and application onboarding drafts.
- Admin dashboard gated by Auth administrator roles.
- Separate web host/deployment so `minio.alfares.cz` remains the S3 API root.

## Non-Goals
- Browser access to MinIO root credentials.
- Public object listing.
- Privileged object mutation without a backend guard.
- Replacing the S3 endpoint root with HTML.

## Acceptance criteria
- Landing page explains the offer and includes pricing choices.
- Lead form uses the Leads intake contract and records consent only when checked.
- Registration and login hand off to the Auth microservice.
- Customer dashboard supports application onboarding drafts and safe connection parameters.
- Admin dashboard hides operational content until an accepted Auth administrator role is validated.
- S3 root endpoint semantics remain unchanged.

## Traceability
- Vision: `../01_vision/VISION.md`
- System: `../04_systems/SYS-001-private-object-storage.md`
- Task: `../11_tasks/TASK-003-customer-web-surface.md`
- Execution plan: `../21_execution_plans/EP-TASK-003-customer-web-surface.md`
- Goal impact: `../22_goal_impact/GOAL-IMPACT-TASK-003.md`

## Validation
Validate with static JS syntax checks, IPS gates, browser rendering, and sensitive-data scan over the new web surface.
