---
name: Firebase Rules Validation
description: "Validate Firestore/Storage rules impact and code-to-rules alignment for a change."
agent: "Firebase Integration Specialist"
argument-hint: "Change scope, affected collections/paths, actor roles, expected allow/deny behavior"
---
Run a Firebase rules validation pass for this request.

Request:
${input}

Execution requirements:
- Use the firebase-rules-validation workflow to map access surfaces and role expectations.
- Verify service/query/path patterns align with Firestore/Storage rules behavior.
- Check least-privilege allow/deny outcomes for changed operations.
- Validate migration/backward-compatibility risks when schema/path changes exist.
- Return validated allow/deny scenarios, identified gaps, and required rule/code updates.
