---
name: firebase-rules-validation
description: Validate Firestore and Storage rules impact when Flutter/Firebase data-access patterns change.
---

# Firebase Rules Validation

## Purpose

Use this skill when code changes may affect Firestore or Storage authorization behavior. It ensures client/service access patterns and security rules remain aligned.

## Use When

- A feature changes read/write paths, query shapes, ownership checks, or role-based access.
- A collection, document shape, or storage path is added/renamed.
- Failures suggest permission errors, over-permissive access, or rule regressions.

## Inputs

Provide:
- The feature/change description
- Affected collections/document paths/storage paths
- Actor roles (anonymous, authenticated user, owner, admin, moderator)
- Expected allow/deny behavior per action

## Workflow

1. Identify access surfaces.
- List all reads/writes/deletes and storage operations touched by the change.
- Map each operation to actor role and ownership context.

2. Trace code-to-rules alignment.
- Verify service-layer queries/paths match the constraints expected by rules.
- Confirm required fields for rule predicates are present and reliable.

3. Evaluate least-privilege behavior.
- Ensure allowed operations are no broader than required.
- Ensure deny paths are explicit for unknown roles and invalid ownership.

4. Check migration and backward compatibility.
- If schema/path changes are introduced, verify both old/new behavior during transition.
- Call out temporary risks and cutoff criteria.

5. Validate with targeted checks.
- Run relevant app flows and/or tests that exercise allow and deny cases.
- Report any permission errors with the exact operation and actor context.

6. Report outcomes.
- Provide rule-impact summary, validated cases, unresolved risks, and recommended fixes.

## Decision Points

- Rules update required?
If access semantics changed, update rules or adjust client access pattern to match existing rules.

- Query shape incompatible with rules?
Refactor query/path usage in services to satisfy rule predicates before broadening permissions.

- Missing role metadata?
Block rollout until identity/role source is trustworthy and documented.

## Quality Checks

Complete when all are true:
- Every new/changed operation has explicit allow/deny expectation by role.
- Service-layer access paths are consistent with rules.
- No new over-broad rule conditions were introduced.
- Targeted validation includes both positive and negative authorization cases.
- Residual risks and migration caveats are documented.

## Output Format

Return:
- Affected rule surfaces and operations
- Alignment findings (client/service vs rules)
- Validation results for allow/deny scenarios
- Required rule/code changes and rollout risks
