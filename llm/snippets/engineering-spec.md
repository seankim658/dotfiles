## Engineering spec

The engineering spec is the binding description of what we're building. Companion reference documents use the same ID format.

### Reading it

- **IDs.** Every requirement, fact, decision and open question has a permanent ID such as `ARCH-05`. The ID appears in square brackets only where it is defined, as `[ARCH-05]`. Every other mention is the bare ID.
- **Find a definition.** Search for the bracketed form, such as `grep -n '\[ARCH-05\]' *.md`, or run `spec_ids.py show ARCH-05` where the repository has the ID tool. Read the sections the task or handoff names, not the whole spec.
- **What binds.** "Must" and "must not" are binding. "Should" needs a recorded reason to break. _Why_ lines and **Guidance** blocks are not binding, and guidance gives way to the code.
- **Where status lives.** Only the open question register (`Q-nn`) and the decision register (`D-nn`) hold status. A requirement states what is true now. Treat a requirement that cites an open question as unsettled on that point, and ask before choosing.

### Using it

- **Cite IDs** in plans, reviews, handoffs and commit messages, so work traces to requirements. Never cite IDs or the spec in code, comments or docstrings.
- **When code and a requirement disagree,** treat the code as what exists now, name the ID, and propose either a code fix or a spec edit.
- **Track progress outside the spec.** Never write implementation status into a requirement.

### Changing it

Give copy-and-paste ready markdown, and name the file and the ID or section it replaces.

- **Change an item.** Give its full replacement text, keeping its tag. Never append "decided" or "resolved" notes.
- **Settle an open question.** Give the new decision row, each affected requirement rewritten to state the outcome, and the question row marked `Closed by D-nn`.
- **Add an item.** Use the next unused number in its prefix, tagged once where it is defined. Never reuse or renumber an ID.
- **Withdraw an item.** Keep its tag, mark it _Withdrawn_, and name any replacement.
- **Changelog.** Add a row naming every ID that changed, and raise the version for any binding change.
- **Check IDs.** Where the ID tool exists, run `spec_ids.py check` over every spec file together, and fix every problem before handing back.
