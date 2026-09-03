# Validation Debt Ledger
## Purpose
Record known out-of-scope validation failures without masking current regressions.
## Rules
Current-task failures are blockers. Entries require owner, scope, unblock condition, and safe evidence; never record secrets or raw production data.
## Entries

### 2026-09-03 - deployment_readiness_gate has no correct `--root`, and strict_doc_audit fails repo-wide

**Command:** `python3 scripts/deployment_readiness_gate.py --root <X> --target TASK-002`

**Sanitized failure:** the gate's subchecks disagree about what `--root` means, so no value makes them all correct.

| `--root` | pre_coding_gate | validation_reports | strict_doc_audit findings |
| --- | --- | --- | --- |
| `.` | fail | fail - looks for `./12_validation`, reports live in `docs/12_validation` | 46 |
| `docs` | pass | pass - all five reports found | 105 |

The 105 findings under `--root docs` are false positives: `graph/project_graph.yaml` uses paths like
`../11_tasks/TASK-002-...md`, which resolve correctly from `docs/graph/` but are reported as
"Graph node ... points to missing path" when the audit is rebased on `docs`. The files exist.

The plans previously documented `--root .`, which is why the validation-report check could never pass and
TASK-002 could not be closed. The gate command in EP-TASK-002 is now corrected to `--root docs`.

**Scope:** repo-wide tooling; affects every IPS gate invocation in this repository.

**Owner:** minio-service-owner.

**Current-task impact:** none. The 46 `strict_doc_audit` findings are identical before and after the
2026-09-03 TASK-002 closure - verified by auditing a pristine `git worktree` of HEAD and diffing the
finding lists, which produced an empty diff. No finding names a file or line changed by that work.

**Unblock condition:** make the gate resolve `12_validation` and the project graph from a single
documented root, then re-baseline the 46 audit findings.

**Safe evidence path:** `reports/validation/ips-deployment-readiness-gate.json`.

### 2026-09-03 - the MISSING marker convention has no escape hatch

**Sanitized failure:** `MARKER_RE` in `scripts/deployment_readiness_gate.py` matches any `[MISSING: ...]`
token, including instructional text that merely *describes* the convention. Four such strings in
EP-TASK-001/002 (for example "Mark absent facts as ...") were counted as unresolved gaps and kept both
plans non-terminal after their real gaps had been closed. They have been reworded to name the convention
in prose instead. `18_templates` is already excluded, but `23_documentation_contracts` is not, and it
still contributes 11 illustrative markers.

**Scope:** ecosystem-wide - the same convention is read by `shared/scripts/scan-next-tasks.py`.

**Owner:** unassigned; raised to the agent onboarding workstream (COORD-AGENT-ONBOARDING-001).

**Current-task impact:** none once the four instructional strings were reworded.

**Unblock condition:** give the convention an escape form, or exclude `23_documentation_contracts`
from marker scanning as `18_templates` already is.
## Update Format
Add a dated entry containing command, sanitized failure, scope, owner, current-task impact, unblock condition, and safe evidence path.
