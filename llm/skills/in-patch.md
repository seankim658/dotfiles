---
name: in-patch
description: Deliver code changes as git patch files built and verified in the sandbox. Use when the user wants patches to apply themselves instead of edits described in chat. Requires the project's git bundle cloned in the sandbox. Do not use alongside in-chat.
---

Deliver changes as patch files, not pasted code. If this chat has no git bundle to work from, say so and ask for one before making changes.

## Making a patch

1. Make the changes in the sandbox checkout.
2. Verify them by running the relevant tests, linters, type checkers, or builds.
3. Stage everything so new files are included, then write the diff without the lock file named in the project instructions. If the project has no lock file, drop the exclusion.

```bash
   git add -A
   git diff --cached -- . ':!<lock-file>' > /mnt/user-data/outputs/<NN>-<short-name>.patch
```

4. Commit in the sandbox with the commit message you give me, so the next patch builds on this one.
5. Present the patch file.

Number patches in order, like `01-add-config-loader.patch`, so I can apply them in sequence.

## The reply

- Explain the design in prose.
- Say what you verified and how. If a check couldn't run, say which one and why.
- Quote only the lines I need to review. Don't paste whole files.
- End with a short commit message.

## Staying in sync

If the sandbox was reset, clone the bundle again and apply the earlier patches from `/mnt/user-data/outputs` in order before continuing. If I say I changed a patch before applying it, ask for a fresh bundle instead of guessing what changed.
