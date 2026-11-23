## Commit messages

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
