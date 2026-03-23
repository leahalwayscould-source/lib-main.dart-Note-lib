---
name: app-developer
description: End-to-end Flutter + Firebase feature delivery workflow for this repository, from requirements through implementation and verification.
---

# App Developer

## Purpose

Use this skill to implement Flutter + Firebase features end-to-end with production-minded quality. It guides requirement clarification, architecture alignment, coding, verification, and handoff.

## Use When

- The request requires changes across Flutter UI, state, models, and services.
- The feature touches Firebase Auth, Firestore, Storage, Functions, or rules alignment.
- A feature must be delivered, not just discussed.
- You need a repeatable flow that includes testing and risk checks.

## Inputs

Provide:
- Feature goal and user outcome
- Constraints (platform, performance, timeline, dependencies)
- Acceptance criteria
- Relevant files or areas if known

## Workflow

1. Define success criteria.
- Restate expected user behavior.
- Convert the request into concrete acceptance criteria and non-goals.

2. Map impacted areas.
- Identify screens/widgets, services, models, routes, and configs likely affected.
- Identify Firebase touchpoints (Auth, Firestore collections, Storage paths, Functions, security rules).
- Reuse existing patterns before introducing new abstractions.

3. Plan minimal complete changes.
- Choose the smallest coherent implementation that meets criteria.
- Sequence work to reduce regression risk.

4. Implement in vertical slices.
- Apply UI, logic, and data updates together per slice.
- Keep APIs stable unless change is required.
- Keep Firestore/Storage access patterns consistent with existing services and rules.

5. Verify behavior.
- Run targeted checks/tests by default when feasible.
- Confirm edge cases and error states.
- Resolve new warnings/errors introduced by the changes.

6. Report and hand off.
- Summarize file-by-file changes and rationale.
- Call out residual risks, assumptions, and follow-up tasks.

## Decision Points

- New abstraction needed?
Use existing services/models unless duplication or complexity clearly increases.

- Data model change required?
Prefer additive and backward-compatible model updates; document migrations if needed.

- Firebase rules impact?
If data access patterns change, validate Firestore/Storage rules impact and keep client/service behavior aligned.

- Test scope level?
Use the narrowest tests that prove acceptance criteria, then broaden only for high-risk changes.

- Unable to validate fully?
Document exactly what could not be verified and why.

## Quality Checks

A task is complete when all are true:
- Acceptance criteria are met in behavior, not just code shape.
- Affected flows compile/run without new errors.
- Relevant targeted tests/checks pass by default, or are explicitly reported as blocked.
- Error, loading, and empty states are handled where applicable.
- Summary includes changed files, validation results, and known risks.

## Output Format

Return:
- Outcome status against acceptance criteria
- File-by-file change summary
- Validation performed and results
- Risks, assumptions, and optional next steps
