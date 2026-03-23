---
name: Route Task
description: "Route a task to the best specialist agent in this repository."
agent: "Workflow Router"
argument-hint: "Goal, constraints, and definition of done"
---
Route this request to the best specialist agent and execute it.

User request:
${input}

Requirements:
- Select one specialist unless parallel work is explicitly requested.
- Preserve constraints and acceptance criteria from the request.
- Return the selected specialist and result summary.
