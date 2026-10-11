---
name: handoff-pickup
description: Resume work from a previous chat using its handoff document. Use at the start of a chat when the user provides a handoff document.
---

Read the handoff document first. It records decisions and context the code can't show, but treat its claims about the state of the code as things to confirm, not facts.

Then follow the lay-of-the-land skill. Where the handoff and the code disagree, trust the code and point out the mismatch.

If the handoff has a Patches section, handle it before planning. Confirm that patches marked applied are reflected in the code. Apply patches marked unapplied in order, if I attached them. If any are missing or fail to apply, stop and tell me before going further. If there is no Patches section, skip this step.
