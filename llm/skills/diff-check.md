---
name: diff-check
description: Review a git diff for problems and, if it's correct, write a short commit message. Use when the user shares a diff of their own changes and asks for a review or a commit message.
---

Review the diff I've shared.

Check for bugs and logic errors, leftover debug or commented-out code, changes unrelated to the rest of the diff, and anything that breaks the project's existing conventions. If a judgment depends on code outside the diff, read it from the bundle if one is available. Otherwise say what you need and ask for it.

If you find real problems, list each one with its file and line and stop there. Write the commit message once they're fixed. If you only find nitpicks, mention them briefly and write the message anyway.

Write the commit message as a short subject line in the imperative mood, under 50 characters when possible. Add a body only when the reason for the change isn't obvious from the subject, and keep it to a few lines.
