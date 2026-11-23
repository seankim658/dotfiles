---
name: "project-instructions"
description: "Write concise Claude Project instructions from fixed section templates (project description, code dump or git bundle format, engineering spec, commit messages, delivering changes). Use whenever the user wants to write, set up or update instructions for a Claude Project, even if they just say \"set up instructions for this repo\"."
---

# Project instructions

Write instructions for a Claude Project from the templates below. The result is pasted into the project's instructions, so every line is read in every chat. Keep it short and keep the template wording, which is already tuned.

## Workflow

1. **Ask for the choices.** Use AskUserQuestion with all three questions in one call. Skip any question the user has already answered. Without that tool, ask the same in plain text.
   - **Code format.** Markdown code dumps, git bundle, or no code.
   - **Engineering spec.** Spec IDs allowed in commit messages, spec IDs kept out of commit messages, or no spec.
   - **Extra sections** (multi-select). Commit messages, Delivering changes.
2. **Ask for the fill-ins.** Ask in one plain message for whatever is still missing.
   - What the project is. Check attached code, a README and the conversation first, and ask only for what you can't find.
   - The dump file names (code dumps). Never ask for a bundle file name, because the git bundle template has no slot for one.
   - The commit scopes, what counts as a breaking change, and a sample summary line (commit messages).
3. **Assemble** the chosen sections in this order. Description, Code, Engineering spec, Commit messages, Delivering changes.
4. **Deliver** the whole result in the chat reply as copy-and-paste ready markdown. The user pastes it straight into the project's instructions, so a file, doc or artifact only adds a step. Put it in one fenced block opened with four backticks (````md), because the commit template has its own inner fence. After the block, list any `<FILL>` slots still open.

## Rules

- Copy each template verbatim. Change only the `<FILL>` slots and the adjustments named in this skill.
- Add nothing the user didn't choose. No extra sections, no preamble, no closing summary.
- Give the instructions in chat, never as a file, doc or artifact, even when they run long.
- If the user doesn't know a value yet, leave the slot as `<FILL: what goes here>` and say so.
- Match the templates' style in anything you write. Short plain sentences, imperative mood, no em-dashes, no colons in prose.

## Description

Start with `# <Project name>`, then two to four sentences. Say what the project does, who it is for, and its main stack and layout. Leave out feature lists, roadmaps and anything the sections below already cover.

## Code

Put the chosen template under a `## Code` heading. Omit the whole section for "no code".

### Markdown code dumps

List each dump file name as its own bullet in place of `<FILL>`.

````md
### Code dump format

The code dump(s) for this project are:

- <FILL>

Each dump is a flat text file beginning with a `Project Path:` line and a `Source Tree:` ASCII tree covering only its own slice of the repo, followed by a `## Code` section. Within that section, every file is introduced by a header line that is its backtick-wrapped, repo-relative path ending in a colon, immediately followed by a fenced code block with a language hint inferred from the extension. Files are separated only by the next path header.

Three parsing gotchas:

- Every content line inside a block is prefixed with a right-aligned line number and `|` (e.g. `  12 |     code`). This prefix is display-only. Strip it before using the content, including when constructing exact-match strings for edits.
- Markdown files can contain their own nested fences, so the first inner fence is not necessarily the end of a file. The block's own fence is always longer than any backtick run inside it, using four or more backticks when needed, so an inner fence never closes the block. Treat the next path header as the true file boundary.
- Some code might be intentionally omitted to save tokens. For example, a frontend dump might exclude boilerplate and primitive components, and a backend dump might exclude the repositories module. If a decision depends on code that isn't in the dumps, say so and ask for it. Base every decision on the actual code, never on assumptions.
````

### Git bundle

Copy this template with no changes. The bundle's file name changes every chat, so the template points at whichever bundle is attached instead of naming one.

````md
### Code format

The code for this project is a git bundle, attached to each new chat. Work from the bundle, not from assumptions about the code.

Clone the attached `.bundle` file into the sandbox with `git clone <bundle path> .`, whatever its name, and read the actual files before planning or changing anything. Set up the sandbox once per chat and reuse it on later turns. If I attach a new bundle, discard the old checkout and clone the new one. If the sandbox has been reset, clone the bundle again.

After cloning, remove the bundle remote with `git remote remove origin`. The bundle is read-only, so nothing can be pushed to it, and the sandbox's stop hook asks for a push after every commit while a remote exists. Never push. Changes reach me only as patch files.

Use the sandbox to build the project and run its tests, linters, and type checkers. The sandbox may not have network access, so dependency installs can fail. If a check can't run, say so plainly instead of guessing the result.

The lock file should never be edited by you. I regenerate it myself.
````

## Engineering spec

The two variants differ only in the **Cite IDs** bullet. Use the template below and replace `<CITE IDS BULLET>` with the matching line. Omit the whole section for "no spec".

- **IDs allowed in commit messages.**
  `- **Cite IDs** in plans, reviews, handoffs and commit messages, so work traces to requirements. Never cite IDs or the spec in code, comments or docstrings.`
- **IDs kept out of commit messages.**
  `- **Cite IDs** in plans, reviews and handoffs, so work traces to requirements. Never cite IDs or the spec in code, comments, docstrings or commit messages.`

````md
## Engineering spec

The engineering spec is the binding description of what we're building. Companion reference documents use the same ID format.

### Reading it

- **IDs.** Every requirement, fact, decision and open question has a permanent ID such as `ARCH-05`. The ID appears in square brackets only where it is defined, as `[ARCH-05]`. Every other mention is the bare ID.
- **Find a definition.** Search for the bracketed form, such as `grep -n '\[ARCH-05\]' *.md`, or run `spec_ids.py show ARCH-05` where the repository has the ID tool. Read the sections the task or handoff names, not the whole spec.
- **What binds.** "Must" and "must not" are binding. "Should" needs a recorded reason to break. _Why_ lines and **Guidance** blocks are not binding, and guidance gives way to the code.
- **Where status lives.** Only the open question register (`Q-nn`) and the decision register (`D-nn`) hold status. A requirement states what is true now. Treat a requirement that cites an open question as unsettled on that point, and ask before choosing.

### Using it

<CITE IDS BULLET>
- **When code and a requirement disagree,** treat the code as what exists now, name the ID, and propose either a code fix or a spec edit.
- **Track progress outside the spec.** Never write implementation status into a requirement.

### Changing it

Give copy-and-paste ready markdown, and name the file and the ID or section it replaces.

- **Change an item.** Give its full replacement text, keeping its tag. Never append "decided" or "resolved" notes.
- **Settle an open question.** Give the new decision row, each affected requirement rewritten to state the outcome, and the question row marked `Closed by D-nn`.
- **Add an item.** Use the next unused number in its prefix, tagged once where it is defined. Never reuse or renumber an ID.
- **Withdraw an item.** Keep its tag, mark it _Withdrawn_, and name any replacement.
- **Changelog.** Add a row naming every ID that changed, and raise the version for any binding change.
- **Check IDs.** Where the ID tool exists, run `spec_ids.py check` (script available in the `engineering-spec` skill) over every spec file together, and fix every problem before handing back.
````

## Commit messages

Fill the three slots from the user's answers. The original project's lines show the expected shape.

- Summary example. `feat(collector): poll train positions every 30 seconds`
- Scope. ``The package without its `lamp-` prefix (`collector`, `storage`, `schemas`, and later `compact`, `gtfs`, `infer`, `publish`), or `deps`, `check` or `deploy` for repository-wide work.``
- Breaking changes. `a published file's columns, a storage path or a command-line interface`, with the example `feat(publish)!: rename headway column`

Drop or reword a type row that names something the project lacks, such as the check script in the `ci` row. When spec IDs are allowed in commit messages, add the **Spec IDs** bullet shown after the template as the last bullet. Otherwise leave it out.

`````md
## Commit messages

Commit messages follow Conventional Commits 1.0.0.

```text
<type>(<scope>): <summary>

<body>

<footers>
```

- **Summary.** Imperative mood, lower case, no full stop, at most 72 characters including the type and scope, such as `<FILL: sample summary line>`.
- **Type.** One of these.

  | Type       | Use it for                                                |
  | ---------- | --------------------------------------------------------- |
  | `feat`     | New behaviour a user or operator can see                  |
  | `fix`      | A bug fix                                                 |
  | `perf`     | A change that only makes something faster or smaller      |
  | `refactor` | A code change that neither fixes a bug nor adds behaviour |
  | `test`     | Adding or changing tests only                             |
  | `docs`     | Documentation only, including README and docs/            |
  | `build`    | The workspace, packaging, dependencies or the lock file   |
  | `ci`       | CI workflows and the check script                         |
  | `chore`    | Anything else that changes no shipped code                |
  | `revert`   | Reverting an earlier commit, naming its hash in the body  |

- **Scope.** <FILL: the allowed scopes>. Leave the scope out when a change spans several packages.
- **Body.** Says what changed and why, not how. Wrap it at 72 characters. Leave it out when the summary says everything.
- **Breaking changes.** Mark a change to <FILL: what users depend on> with `!` after the scope, such as `<FILL: sample breaking summary>`, and add a `BREAKING CHANGE:` footer saying what users must change.
`````

Spec IDs bullet, only when IDs are allowed in commit messages.

```md
- **Spec IDs.** Name the IDs a change implements or touches in a `Refs:` footer, such as `Refs: ARCH-05, D-03`. Leave the footer out when no ID applies.
```

## Delivering changes

Pick the variant from the code format. Use the in-chat variant for code dumps and for no code, and the patch variant for a git bundle. If Commit messages wasn't chosen, drop the words "following the commit message rules above".

In chat.

````md
## Delivering changes

Pair every change with its commit message, so I can commit each change as it is.

- **One commit per logical change.** Split unrelated changes into separate commits, each with its own message.
- **Message after its edits.** Give the commit message directly after the edits it describes, in a `text` block, following the commit message rules above.
- **Keep them in step.** The message describes exactly what its edits do. If you revise an edit, give the revised message too.
````

Patch files.

````md
## Delivering changes

Pair every change with its commit message, so each patch applies as a finished commit.

- **One commit per logical change.** Split unrelated changes into separate commits, each with its own message.
- **Commit before exporting.** Commit each change in the sandbox with its message, following the commit message rules above, so the patch file carries it. Show each message in chat beside its patch.
- **Keep them in step.** The message describes exactly what its commit does. If you revise a change, amend the commit and give the new patch and message.
````
