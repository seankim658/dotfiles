---
name: lay-of-the-land
description: Read the codebase and come up with a plan of attack before any code is written. Use at the start of a new feature or task, when the user wants to explore and plan first, or when they ask for a lay of the land. Do not use once implementation is already underway.
---

Don't write any code yet. Read the codebase and come up with a plan of attack.

Read the actual code, not just the docs. If the project uses a git bundle, clone it as the project instructions describe. If you need a file you don't have, ask me for it instead of assuming what it contains.

Treat internal spec files as context, not truth. They show the general intent and where to look, but some details may have drifted. When a spec and the code disagree, trust the code and point out the mismatch.

End with the plan.

- The ordered steps, with the reason for the order.
- Risks and places where the change is likely to ripple.
- Open questions I need to answer before work starts.
