# PROMPT-TASK-003: Customer Web Surface

```yaml
id: PROMPT-TASK-003
status: completed
owner: minio-service-owner
created: 2026-06-13
last_updated: 2026-06-13
source_execution_plan: ../21_execution_plans/EP-TASK-003-customer-web-surface.md
context_package: ../13_context_packages/CP-TASK-003-customer-web-surface.md
```

## Role
You are a frontend and platform engineer implementing a browser-safe customer web surface for the MinIO microservice.

## Task
Implement the MinIO landing, registration handoff, customer dashboard, and administrator dashboard shell from `../21_execution_plans/EP-TASK-003-customer-web-surface.md`.

## Context
The MinIO S3 endpoint root must remain reserved for path-style S3 traffic. Leads handles prospect intake. Auth handles registration, login, token validation, and administrator roles. Browser code must not contain MinIO root credentials or private object inventories.

## Constraints
- Preserve `minio.alfares.cz` as the S3 API endpoint.
- Serve customer web UI from a separate static deployment/host.
- Use Leads before Auth registration for prospect intake.
- Use Auth role validation for administrator visibility.
- Do not expose credentials, raw private URLs, or real object listings in static JavaScript.

## Acceptance criteria
- Landing page includes pricing and consultation CTA.
- Lead form posts the Leads contract with consent evidence only when checked.
- Auth registration/login redirects include `client_id=minio-microservice`.
- Customer dashboard supports application onboarding drafts.
- Admin dashboard hides operational data unless an accepted administrator role is validated.

## Validation
Run JS syntax checks, IPS gates, sensitive-data scan, and browser rendering at desktop and mobile viewport sizes.
