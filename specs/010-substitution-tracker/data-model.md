# Data Model: Substitution Tracker

**Feature**: `010-substitution-tracker`  
**Date**: 2026-03-11

## Entities

### Branch Record

Represents one in-scope numbered feature branch candidate.

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Numeric identifier prefix, e.g., `019` |
| `name` | String | Full branch name, e.g., `010-substitution-tracker` |
| `source` | Enum | `local` or `remote` |
| `inScope` | Boolean | True when branch matches `###-short-name` |

### Spec Record

Represents one numbered feature directory under `specs/`.

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Numeric identifier prefix from directory name |
| `name` | String | Full directory name |
| `path` | String | Workspace-relative path |
| `documents` | Set<String> | Present Speckit document names |

### Compliance Finding

Represents one parity issue or out-of-scope observation.

| Field | Type | Description |
|-------|------|-------------|
| `findingType` | Enum | `branch_without_spec`, `spec_without_branch`, `out_of_scope_branch` |
| `id` | String | Numbered feature identifier when available |
| `details` | String | Human-readable explanation |
| `action` | Enum | `create_docs`, `review`, `ignore` |

### Fix Result

Represents remediation output for one finding.

| Field | Type | Description |
|-------|------|-------------|
| `id` | String | Numbered feature identifier |
| `actionTaken` | String | What was created/updated |
| `status` | Enum | `fixed`, `skipped`, `manual_follow_up` |

## Validation Rules

- `Branch Record.id` and `Spec Record.id` must be exactly 3 digits for in-scope matching.
- Existing files are never overwritten during automatic remediation.
- Compliance summary must include counts for reviewed, mismatched, fixed, and manual follow-up items.