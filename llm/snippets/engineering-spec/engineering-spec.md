## Engineering spec

The engineering spec is the binding description of what we're building. Companion reference documents use the same ID format.

### Reading it

- **IDs.** Every requirement, fact, decision and open question has a permanent ID such as `ARCH-05`. The ID appears in square brackets only where it is defined, as `[ARCH-05]`. Every other mention is the bare ID.
- **Find a definition.** Search for the bracketed form, such as `grep -n '\[ARCH-05\]' *.md`, or run `spec_ids.py show ARCH-05` where the repository has the ID tool. Read the sections the task or handoff names, not the whole spec.
- **What binds.** "Must" and "must not" are binding. "Should" needs a recorded reason to break. _Why_ lines and **Guidance** blocks are not binding, and guidance gives way to the code.
- **Where status lives.** Only the open question register (`Q-nn`) and the decision register (`D-nn`) hold status. A requirement states what is true now. Treat a requirement that cites an open question as unsettled on that point, and ask before choosing.

### Using it

- **Cite IDs** in plans, reviews and handoffs, so work traces to requirements. Never cite IDs or the spec in code, comments, docstrings or commit messages.
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

### Commit messages

Commit messages follow Conventional Commits 1.0.0.

```text
<type>(<scope>): <summary>

<body>

<footers>
```

- **Summary.** Imperative mood, lower case, no full stop, at most 72 characters including the type and scope, such as `feat(collector): poll train positions every 30 seconds`.
- **Type.** One of these.

  | Type       | Use it for                                              |
  | ---------- | ------------------------------------------------------- |
  | `feat`     | New behaviour a user or operator can see                |
  | `fix`      | A bug fix                                               |
  | `perf`     | A change that only makes something faster or smaller    |
  | `refactor` | A code change that neither fixes a bug nor adds behaviour |
  | `test`     | Adding or changing tests only                           |
  | `docs`     | Documentation only, including README and docs/          |
  | `build`    | The workspace, packaging, dependencies or the lock file |
  | `ci`       | CI workflows and the check script                       |
  | `chore`    | Anything else that changes no shipped code              |
  | `revert`   | Reverting an earlier commit, naming its hash in the body |

- **Scope.** The package without its `lamp-` prefix (`collector`, `storage`, `schemas`, and later `compact`, `gtfs`, `infer`, `publish`), or `deps`, `check` or `deploy` for repository-wide work. Leave the scope out when a change spans several packages.
- **Body.** Says what changed and why, not how. Wrap it at 72 characters. Leave it out when the summary says everything.
- **Breaking changes.** Mark a change to a published file's columns, a storage path or a command-line interface with `!` after the scope, such as `feat(publish)!: rename headway column`, and add a `BREAKING CHANGE:` footer saying what users must change.
- **No spec IDs.** Describe the requirement in plain words instead.
