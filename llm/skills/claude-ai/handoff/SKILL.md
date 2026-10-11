---
name: handoff
description: Write a handoff document capturing where the work stands and what to do next, so the user can continue in a fresh chat. Use when a chat is getting too long, when the user is about to start a new conversation, or when they ask for a handoff, status, or wrap-up document.
---

# Handoff document

Write a short markdown document that lets a fresh chat pick up this work without re-reading the current conversation.

## Who is reading this

The reader is a new Claude session with no memory of this chat. Write for a capable collaborator who can already see the code but has no idea what was decided here or why.

That framing decides what belongs in the document. Include the reasoning, decisions, and judgment that exist only in this conversation. Leave out anything the reader could get by reading the code, and anything only the user acts on.

## Structure

Use the sections below. If a section has nothing real in it, drop it rather than padding it.

### Where we are

Say what changed in this chat and what state it's in. Be specific about confidence. Distinguish code that was applied and tested, applied but never run, and sketched but not implemented. A next chat that assumes untested code works will waste time chasing the wrong bugs.

### Patches

Include this section only when changes were delivered as patch files. List each patch by filename in order, and mark whether the user confirmed applying it. If you aren't sure, ask the user before writing the document instead of guessing.

Applied patches will be in the next chat's bundle. Unapplied patches must be attached to the next chat or redone, so say which ones and whether they still apply cleanly on top of the applied ones.

### Scope rules

List constraints and decisions agreed in this chat that should still hold, such as things ruled out, patterns to follow, and boundaries on what to touch. Include the reasoning, not just the rule, so the next chat can tell when a rule stops applying.

### What's missing

List known gaps, deferred items, and anything currently broken.

### What I'd do next

Give an ordered recommendation with reasoning. Say why this order, not just what.

### For the next chat

Close with this instruction block addressed to the new session.

> Assess where we are and what the next steps should be. Do not take the internal spec files at 100% weight. They are internal only and were written as loose implementation guides before development started, so things have drifted. Read the actual code.

## Never include

- **Setup or run instructions.** The project instructions already say how the code is provided and how to work with it. Dev servers, migrations, env vars, and similar commands are the user's to run. Repeating any of this wastes space and can contradict the project instructions.
- **Recaps of code the reader can already see.** Summarizing a file's contents is filler. Point at it and explain what's non-obvious about it.
- **Meta-commentary about this conversation.** Skip how long it ran, what was tried and abandoned, and apologies. Only surface an abandoned approach if the next chat is likely to retry it.

## Length

Keep it short. Aim for something that reads in a minute or two.
