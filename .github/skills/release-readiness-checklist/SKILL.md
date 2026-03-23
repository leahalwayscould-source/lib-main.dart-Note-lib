---
name: release-readiness-checklist
description: Pre-merge release readiness checklist for Flutter + Firebase changes with risk-focused verification.
---

# Release Readiness Checklist

## Purpose

Use this skill before merge/release to verify a change is safe, validated, and operationally observable.

## Use When

- A feature is complete and ready for pre-merge review.
- A bug fix modifies critical user flows.
- A release candidate requires a final risk pass.

## Inputs

Provide:
- Scope of changed files/features
- Critical user journeys affected
- Required environments (dev/stage/prod parity assumptions)
- Known risks or deferred items

## Checklist Workflow

1. Build and static quality.
- Confirm the project builds cleanly.
- Resolve newly introduced errors/warnings relevant to changed scope.

2. Test confidence.
- Run targeted tests/checks covering changed behavior.
- Verify at least one negative/error-path scenario for risky changes.

3. UX/state safety.
- Confirm loading, empty, error, and retry states are handled.
- Validate navigation and state restoration for modified screens.

4. Data and backend safety.
- Validate Firebase integration points touched by the change.
- Confirm rule impact, query/path compatibility, and failure handling.

5. Observability and diagnostics.
- Ensure failures are detectable via logs or surfaced user errors.
- Confirm no silent-failure paths were introduced.

6. Regression review.
- Check adjacent flows likely to regress from shared components/services.
- Verify no accidental API or model contract breakage.

7. Release notes and handoff.
- Summarize behavior changes, migration notes, and rollback considerations.
- Record unresolved risks and explicit follow-up owners/items.

## Decision Gates

- Block merge if critical flow fails or authorization behavior is ambiguous.
- Block merge if no validation exists for high-risk changed logic.
- Allow conditional merge only with documented risks and owner-assigned follow-ups.

## Completion Criteria

A change is release-ready when:
- Changed scope is built and validated.
- Critical paths and key edge cases pass.
- Firebase/rules impacts are checked where relevant.
- Residual risk is explicit, bounded, and assigned.

## Output Format

Return:
- Pass/block decision with rationale
- Evidence by checklist section
- Open risks and required follow-ups
- Recommended next action (merge, fix-first, or staged rollout)
