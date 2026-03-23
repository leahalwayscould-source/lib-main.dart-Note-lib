---
name: Release Readiness Checklist
description: "Run a pre-merge release-readiness gate for Flutter + Firebase changes."
agent: "Code Reviewer Severity First"
argument-hint: "Changed scope, critical flows, environments, known risks"
---
Run a release-readiness review for this request.

Request:
${input}

Execution requirements:
- Use the release-readiness-checklist workflow and report pass/block decisions.
- Prioritize findings by severity with precise file references where applicable.
- Verify build/test confidence, UX state safety, Firebase/rules impacts, and regressions.
- Explicitly call out observability gaps and rollback risks.
- Return merge recommendation: merge, fix-first, or staged rollout.
