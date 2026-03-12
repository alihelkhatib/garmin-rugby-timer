# Quickstart: Extra Time Golden Point

**Feature**: `007-extra-time-golden-point`  
**Date**: 2026-03-11

## Goal

Verify that numbered feature branches and numbered `specs/` directories are aligned, and ensure this feature folder has a complete Speckit document set.

## Steps

1. Confirm active feature branch:
   - Run `git branch --show-current`
   - Expected: `007-extra-time-golden-point`

2. Confirm numbered branch inventory:
   - Run `git branch -a`
   - Record all branches matching `###-short-name`

3. Confirm spec directory inventory:
   - List folders under `specs/`
   - Record all directories matching `###-short-name`

4. Check parity:
   - For each numbered branch, verify matching folder under `specs/`
   - For each numbered spec folder, verify matching branch exists locally or remotely

5. Confirm required Speckit docs in this feature:
   - `spec.md`
   - `plan.md`
   - `research.md`
   - `data-model.md`
   - `quickstart.md`
   - `tasks.md`
   - `checklists/requirements.md`

6. Validate checklist completeness:
   - Open `checklists/requirements.md`
   - Confirm all quality checks are marked complete

## Expected Results

- Numbered branch allocation is globally unique and collision-free.
- This feature contains complete Speckit documentation artifacts.
- Any remaining branch/spec mismatches are explicitly visible for follow-up.

## Manual Verification Checklist

- [ ] Current branch is `007-extra-time-golden-point`
- [ ] Numbered branches and spec folders have been compared
- [ ] This feature contains full document set
- [ ] Requirements checklist is fully checked
- [ ] Any unresolved mismatch is documented for manual follow-up