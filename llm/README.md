# Claude Setup

Coding guidelines, skills, and the Docker sandbox for working with Claude. Claude is used in two ways. In claude.ai projects, Claude receives the code as a git bundle or a code dump. In Claude Code, Claude runs in a Docker sandbox with its own clone of the repo. Both return changes as patches that are reviewed and applied by hand, and both share the same guidelines and most skills.

- [What's Here](#whats-here)
- [Claude.ai Workflow](#claudeai-workflow)
- [Claude Code Sandbox](#claude-code-sandbox)
  - [What Claude Can Reach](#what-claude-can-reach)
  - [How Claude Gets Its Instructions](#how-claude-gets-its-instructions)
- [Setting Up a Project](#setting-up-a-project)
  - [Updating Project Knowledge](#updating-project-knowledge)
- [Daily Workflow](#daily-workflow)
- [Sessions](#sessions)
- [Commands](#commands)
- [Troubleshooting](#troubleshooting)

---

## What's Here

| Path                  | Contents                                | Used by     |
| --------------------- | --------------------------------------- | ----------- |
| `llm-instructions.md` | Coding guidelines                       | Both        |
| `skills/shared/`      | Skills that work the same in both       | Both        |
| `skills/claude-ai/`   | Skills for the bundle workflow          | claude.ai   |
| `skills/claude-code/` | The same skills adapted for the sandbox | Claude Code |
| `sandbox/`            | The sandbox's Docker image              | Claude Code |
| `snippets/`           | Project instruction snippets            | claude.ai   |

Each skill is a folder with a `SKILL.md` inside. In the sandbox, a skill in `claude-code/` replaces a shared skill with the same name.

## Claude.ai Workflow

Before starting, upload the skills in `skills/shared/` and `skills/claude-ai/` to claude.ai.

1. Provide the code to Claude in one of two ways.
   - Bundle the repo with `repobundle` and attach it to the chat or project knowledge. Claude clones it and works in its own environment.
   - Generate a code dump with `codeprompt` and attach it to the chat or project knowledge.
2. Fill in the snippet from `snippets/` that matches the method from step 1 to seed the project instructions, and upload specs as project knowledge.
3. Review each patch with `rp` and tell Claude when it's applied.
4. When the chat gets long, ask for a handoff and start a new chat with it.

## Claude Code Sandbox

`scripts/claude-sandbox.sh` (alias `csb`) runs Claude Code in a Docker container that only sees the current repo, through specific mounts. Inside it, Claude Code can run commands, tests, and installs without access to the rest of the local machine.

Claude never edits the repo directly. It works in its own clone at `~/projects/claude/<repo>`, reads the repo read-only to stay in sync, and writes patches to the clone's `outbox/` folder. Each repo gets its own container, kept between runs so installed dependencies persist. All containers share one Claude login.

### What Claude Can Reach

| In the container     | On the local machine                      | Access                                                                      |
| -------------------- | ----------------------------------------- | --------------------------------------------------------------------------- |
| `/projects/<repo>`   | `~/projects/claude/<repo>`                | Read-write. Claude's clone, where it works                                  |
| `/upstream`          | The repo                                  | Read-only. Used to sync with applied patches                                |
| `/upstream/other`    | Nothing                                   | Hidden. An empty folder covers it                                           |
| `/knowledge`         | The repo's `project-knowledge/`           | Read-only and live                                                          |
| `/home/node/.claude` | The `claude-sandbox-config` Docker volume | Read-write. Login, settings, sessions, and the copied guidelines and skills |

The container also has open network access and passwordless `sudo`, so Claude can install whatever a project needs. Nothing else on the local machine is reachable, including the rest of these dotfiles.

### How Claude Gets Its Instructions

Claude Code reads instructions from fixed locations. The sandbox fills them as follows.

| What                 | Claude Code location     | Source                                      | How it gets there                        |
| -------------------- | ------------------------ | ------------------------------------------- | ---------------------------------------- |
| Coding guidelines    | `~/.claude/CLAUDE.md`    | `llm-instructions.md`                       | Copied on every launch                   |
| Skills               | `~/.claude/skills/`      | `skills/shared/` and `skills/claude-code/`  | Copied on every launch                   |
| Project instructions | `/knowledge/CLAUDE.md`   | The repo's `project-knowledge/CLAUDE.md`    | Mounted, then loaded through `--add-dir` |
| Specs                | `/knowledge/`            | The rest of `project-knowledge/`            | Mounted, then read when relevant         |
| Team instructions    | `CLAUDE.md` in the clone | A `CLAUDE.md` committed in the repo, if any | Part of the clone                        |

Claude Code adds every `CLAUDE.md` it finds to the context at the start of each session, alongside its own system prompt. `~/.claude/CLAUDE.md` holds user-level instructions, which apply in every project. Project instructions apply only to their project.

`csb` copies the guidelines and the Claude Code skills into the container each time it starts, and nothing else from the dotfiles. The claude.ai skills and the snippets never enter the container. Edits take effect the next time `csb` runs. The skills folder is replaced on every launch, so skills deleted from the dotfiles disappear from the container too.

Claude Code loads a `CLAUDE.md` from a folder passed with `--add-dir` only when `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` is set. `csb` sets both whenever the repo has a `project-knowledge/` folder. Claude Code's usual home for private project instructions is a gitignored `CLAUDE.local.md` at the repo root. It doesn't fit the sandbox, because gitignored files aren't cloned and a copy placed in the clone would end up in patches.

## Setting Up a Project

```
my-project/
├── project-knowledge/         Gitignored. Claude reads it at /knowledge
│   ├── CLAUDE.md              Project instructions
│   ├── engineering-spec.md
│   └── data-criteria.md
└── other/                     Gitignored. Hidden from Claude
    └── project-knowledge/     Older versions of the documents
```

1. Write the project instructions in `project-knowledge/CLAUDE.md`. Name the project's lock file there, since the `in-patch` skill leaves it out of patches and out of its sync check.
2. Put the current specs next to it. Point to each one from `CLAUDE.md` so Claude reads it when it matters. To load a short spec into every session, import it with a line like `@engineering-spec.md`. Imports use context in every session, so keep them for documents Claude always needs.
3. Keep file names stable so the references in `CLAUDE.md` stay valid. Versions belong in `other/`, not in the names.

Both folders are in the global gitignore (`gitignore_global` at the root of these dotfiles), so they can't be committed by accident. Only folders at the repo root match, so a source folder like `src/other/` is still tracked.

`csb` decides the mounts when it creates a container. If a repo gains or loses either folder later, `csb` says so and asks for the container to be removed and recreated.

### Updating Project Knowledge

The guidelines tell Claude never to edit specs or project instructions, and the folder is read-only in any case.

1. Claude gives the edits in chat, ready to paste.
2. Copy the current file into `other/` to keep the old version.
3. Edit the file in `project-knowledge/` in place.
4. Claude reads files fresh each time, so its next read sees the change. Changes to `CLAUDE.md` load in the next session, or ask Claude to reread it.

## Daily Workflow

1. Run `csb` from anywhere in the repo. The first run builds the image, creates the clone, and creates the container.
2. Start with `/lay-of-the-land` for new work, or `/handoff-pickup` to continue from a handoff.
3. Ask for changes with `/in-patch`. Claude checks that its clone matches the repo, makes the change, runs the checks, and writes `outbox/patches/NN-name.patch`.
4. Review the patch from the repo with `rp ~/projects/claude/<repo>/outbox/patches/NN-name.patch`. Stage the approved changes, discard the rest, and commit.
5. Ask for the next patch. Claude's sync check notices partly applied patches and local commits, and resets its clone to match.
6. When the session gets long, run `/handoff`, which writes `outbox/handoff.md`. Run `/clear` to start a fresh session, then `/handoff-pickup`.

Fresh sessions are part of the review. A new session rereads the specs, the plan, and the code without remembering writing any of it, which catches drift that one long session misses.

## Sessions

Claude Code saves every session in the config volume, filed under the directory Claude ran in, so nothing is lost when a session ends or a container is removed. Each repo's clone is mounted at its own path, so sessions and Claude's auto memory stay separate per project. The first session in each project asks whether to trust the folder.

| To                             | Do this                                                                            |
| ------------------------------ | ---------------------------------------------------------------------------------- |
| Start a fresh session          | Run `/clear`. The previous session is kept                                         |
| Leave Claude                   | Press `Ctrl+D`. The container keeps running, so `csb` reconnects in about a second |
| Go back to an earlier session  | Run `/resume` and pick one from the list                                           |
| Reopen the most recent session | Run `csb --continue`                                                               |

After editing the guidelines or skills, exit and run `csb` again, since `csb` copies them in on launch.

## Commands

| Command                                  | What it does                                                                        |
| ---------------------------------------- | ----------------------------------------------------------------------------------- |
| `csb`                                    | Start Claude Code in this repo's sandbox                                            |
| `csb --dangerously-skip-permissions`     | Start without permission prompts. The container is the safety boundary              |
| `csb --rebuild`                          | Rebuild the image after changing the Dockerfile, and recreate this repo's container |
| `docker stop claude-sandbox-<repo>`      | Stop the container. `csb` starts it again                                           |
| `docker rm -f claude-sandbox-<repo>`     | Remove the container. `csb` makes a new one, without anything Claude installed      |
| `docker volume rm claude-sandbox-config` | Sign out of every sandbox and delete all saved sessions and settings                |

To list what a container can reach, run this on the host.

```bash
docker inspect claude-sandbox-<repo> \
  --format '{{range .Mounts}}{{.Source}} -> {{.Destination}} (writable: {{.RW}}){{println}}{{end}}'
```

Inside a session, `/context` shows everything in the context window, including the instruction files that loaded. `/memory` opens instruction files for editing and lists their standard locations, whether or not a file exists there. `!` runs a shell command in the container, and `Shift+Tab` cycles permission modes.

## Troubleshooting

**"Container ... was made for different folders than this repo has now."** The repo gained or lost `project-knowledge/` or `other/`, or the container comes from an older layout. Run the `docker rm -f` command from the message, then `csb` again.

**"Claude's clone at ... must come from ..."** Two repos share a folder name, and clones are named after the folder. Rename one of them, or delete the old clone in `~/projects/claude/` if it's no longer needed.

**A new or edited skill doesn't show up.** Skills are copied in when `csb` starts. Exit and run `csb` again.

**Project instructions don't load.** Check that the file is named exactly `CLAUDE.md` inside `project-knowledge/`, and run `/context` to see what loaded.

**Git reports "dubious ownership" for `/upstream`.** The image marks `/upstream/.git` as safe. If the error appears, the image is older than that setting, so run `csb --rebuild`.
