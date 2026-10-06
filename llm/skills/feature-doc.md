---
name: feature-doc
description: Write a feature overview document to guide development of a planned feature. Use after a feature's design has been discussed and the user wants it captured as a spec. Do not use to document code that already exists.
---

Write a markdown overview of the feature as a file I can commit to the repo. Someone who reads it should understand what the feature is for and how it will be built.

Write for readers with no access to this conversation. Describe only what will be built and how it should work. Leave out decision history, rejected alternatives, and phrasing like "we decided" or "this was changed from". Use the imperative mood.

Cover these, dropping any that don't apply.

- **Purpose.** What the feature does and why it exists.
- **Behavior.** How it works from the user's or caller's point of view.
- **Design.** The main pieces, how data flows between them, and the interfaces they expose. Name existing modules where the feature hooks into current code.
- **Constraints.** Rules the implementation must respect, and what's out of scope.
- **Open questions.** Only decisions that are still unresolved.

Keep it to an overview. Leave implementation details to the code.
