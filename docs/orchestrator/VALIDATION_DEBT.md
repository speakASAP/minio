# Validation Debt Ledger
## Purpose
Record known out-of-scope validation failures without masking current regressions.
## Rules
Current-task failures are blockers. Entries require owner, scope, unblock condition, and safe evidence; never record secrets or raw production data.
## Entries
No validation debt is currently recorded.
## Update Format
Add a dated entry containing command, sanitized failure, scope, owner, current-task impact, unblock condition, and safe evidence path.
