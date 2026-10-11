---
name: handoff-pickup
description: Resume work from a previous session using its handoff document. Use at the start of a session when the user asks to pick up where the last session left off or points to a handoff document.
---

Read the handoff document first. It's at `outbox/handoff.md` unless I point to another file. It records decisions and context the code can't show, but treat its claims about the state of the code as things to confirm, not facts.

## Sync with my repo

Start from exactly what's in my repo, read-only at `/upstream`. This clone is disposable, and any unapplied patches are saved in `outbox/patches/`, so resetting loses nothing.

```bash
git fetch /upstream HEAD
git reset --hard FETCH_HEAD
```

If the fetch fails, show me the error and stop.

If the handoff has a Patches section, handle it next. Confirm that patches marked applied are reflected in the code. Apply the unapplied ones in order with `git apply`, and commit each so later patches build on it. If any are missing or fail to apply, stop and tell me before going further.

## Plan

Then follow the lay-of-the-land skill. Where the handoff and the code disagree, trust the code and point out the mismatch.
