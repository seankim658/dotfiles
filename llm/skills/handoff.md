---
name: "handoff"
description: Write a handoff document capturing where the work stands and what to do next, so the user can continue in a fresh chat. Use when a chat is getting too long, when the user is about to start a new conversation, or when they ask for a handoff, status, or wrap-up document.
---

# Handoff document

Write a short markdown artifact document that lets a fresh chat pick up this work without re-reading the current conversation.

## Who is reading this

The reader is a new Claude session with no memory of this chat, so write for a capable collaborator who can already see the code but has no idea what was decided here or why.

That framing decides what belongs in the document. Include the reasoning, decisions, and judgment that exist only in this conversation. Leave out anything the reader could get by reading the code, and anything only the user acts on.

## Structure

Use these sections:

### Where we are

What changed in this chat and what state it's in. Be specific about confidence: applied and tested, applied but never run, sketched but not implemented. A next chat that assumes untested code works will waste time chasing the wrong bugs.

### Scope rules

Constraints and decisions agreed in this chat that should still hold — things ruled out, patterns to follow, boundaries on what to touch. Include the reasoning, not just the rule, so the next chat can tell when a rule stops applying.

### What's missing

Known gaps, deferred items, and anything currently broken.

### What I'd do next

An ordered recommendation with reasoning. Say why this order, not just what.

### For the next chat

Close with a short instruction block addressed to the new session:

> Assess where we are and what the next steps should be. Do not take the internal spec files at 100% weight — they are internal only and were written as loose implementation guides before development started, so things have drifted. Read the actual code.

## Never include

- **A "How to start" or setup section.** Dev server commands, migrations, install steps, env vars, curl header flags — the user runs those, and the chat never touches a terminal. Including them wastes space and implies the reader has an environment it doesn't have.
- **Recaps of code the reader can already see.** Summarizing a file's contents is filler. Point at it and explain what's non-obvious about it.
- **Meta-commentary about this conversation** — how long it ran, what was tried and abandoned mid-chat, apologies. Only surface an abandoned approach if the next chat is likely to retry it.

## Length

Short. Aim for something that reads in a minute or two. If a section has nothing real in it, drop the section rather than padding it.
