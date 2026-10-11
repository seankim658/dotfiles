---
name: in-patch
description: Deliver code changes as git patch files built and verified in this working copy. Use when the user wants patches to apply themselves instead of edits made directly to their repo. Do not use alongside in-chat.
---

Deliver changes as patch files that I apply to my own repo. You work in a separate clone. My real repo is mounted read-only at `/upstream`, and you never change it.

## Staying in sync

Before starting each patch, check that this clone matches my repo. Leave out the lock file named in the project instructions, since patches never include it and I regenerate it myself.

```bash
git fetch /upstream HEAD
git diff --stat HEAD FETCH_HEAD -- . ':!<lock-file>'
```

- **No difference.** Carry on.
- **My repo matches one of your earlier commits.** Run the same comparison against `HEAD~1`, then `HEAD~2`, and so on. The patches after that commit aren't applied yet. Ask whether to wait or to build on top of them.
- **Any other difference.** I edited a patch, kept only part of one, or committed my own work. Run `git reset --hard FETCH_HEAD`, say in one sentence what differed, and reread the changed files before continuing.

If the fetch fails, show me the error and stop. Don't work around it.

## Making a patch

1. Make the changes in this clone.
2. Verify them by running the relevant tests, linters, type checkers, or builds.
3. Stage everything so new files are included, then write the diff without the lock file named in the project instructions. If the project has no lock file, drop the exclusion.

```bash
   mkdir -p outbox/patches
   [ -f outbox/.gitignore ] || echo '*' > outbox/.gitignore
   git add -A
   git diff --cached -- . ':!<lock-file>' > outbox/patches/<NN>-<short-name>.patch
```

4. Commit in this clone with the commit message you give me, so the next patch builds on this one.
5. Give me the patch's path.

`outbox/` ignores itself, so it never appears in a patch and survives `git reset --hard`.

Number patches in order, like `01-add-config-loader.patch`, continuing from the highest number already in `outbox/patches/`.

## The reply

- Explain the design in prose.
- Say what you verified and how. If a check couldn't run, say which one and why.
- Quote only the lines I need to review. Don't paste whole files.
- End with a short commit message.
