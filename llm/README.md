# Claude Setup

This folder holds my coding guidelines, skills, and rules for Claude, plus the Docker sandbox that runs Claude Code. I work with Claude in two ways. In claude.ai projects, Claude gets the code as a git bundle. In Claude Code, Claude runs in a sandbox with its own clone of the repo. Both hand changes back as patches that I review and apply myself, and both share the same guidelines and most skills.

- [What's Here](#whats-here)
- [Claude.ai Workflow](#claudeai-workflow)
- [Claude Code Sandbox](#claude-code-sandbox)
  - [What Claude Can Reach](#what-claude-can-reach)
  - [How It Maps to Claude Code Conventions](#how-it-maps-to-claude-code-conventions)
- [Setting Up a Project](#setting-up-a-project)
  - [Updating Project Knowledge](#updating-project-knowledge)
- [Daily Workflow](#daily-workflow)
- [Commands](#commands)
- [Troubleshooting](#troubleshooting)

---

## What's Here

| Path                  | Contents                                                       | Used by     |
| --------------------- | -------------------------------------------------------------- | ----------- |
| `llm-instructions.md` | My coding guidelines                                           | Both        |
| `skills/shared/`      | Skills that work the same everywhere                           | Both        |
| `skills/claude-ai/`   | Skills written for the bundle workflow                         | claude.ai   |
| `skills/claude-code/` | The same skills rewritten for the sandbox                      | Claude Code |
| `rules/`              | Rules Claude Code loads in every project                       | Claude Code |
| `sandbox/`            | The Docker image and the script that links this folder into it | Claude Code |
| `snippets/`           | Project instruction snippets for claude.ai projects            | claude.ai   |

Each skill is a folder with a `SKILL.md` inside. A skill in `claude-code/` replaces a shared skill with the same name inside the sandbox.

## Claude.ai Workflow

Pre-req: Upload the skills in `shared/` and `claude-ai/` to claude.ai.

1. Provide the code to Claude (two methods):

- Bundle the repo with `repobundle` and attach it to the chat or knowledge. Claude clones it and works in its own environment.
- Generate the code dump with `codeprompt` and attach it to the chat or project knowledge.

2. Fill in a snippet from `snippets/` to seed the project instructions (snippet chosen is based on step 1 method), and upload specs as project knowledge.
3. Review each patch with `rp` and tell Claude when it's applied.
4. When the chat gets long, ask for a handoff and start a new chat with it.

## Claude Code Sandbox

Claude Code runs in a sandbox without access to the local machine. `scripts/claude-sandbox.sh` (alias `csb`) runs Claude Code in a Docker container that only sees the current repo, through specific mounts.

Claude never edits the repo directly. It works in its own clone at `~/projects/claude/<repo>`, reads the local repo read-only to stay in sync, and writes patches to the clone's `outbox/` folder. Each repo gets its own container, kept between runs so installed dependencies persist. All containers share one Claude login.

### What Claude Can Reach

| In the container     | On the local machine                      | Access                                                 |
| -------------------- | ----------------------------------------- | ------------------------------------------------------ |
| `/workspace`         | `~/projects/claude/<repo>`                | Read-write. Claude's clone, where it works             |
| `/upstream`          | The repo                                  | Read-only. Used to sync with what has been applied     |
| `/upstream/other`    | Nothing                                   | Hidden. An empty folder covers it                      |
| `/knowledge`         | The repo's `project-knowledge/`           | Read-only and live                                     |
| `/opt/llm`           | This folder                               | Read-only                                              |
| `/home/node/.claude` | The `claude-sandbox-config` Docker volume | Read-write. Login, settings, and links into `/opt/llm` |

The container also has open network access and passwordless `sudo`, so Claude can install whatever a project needs. Everything else on the local machine is out of reach.

### How It Maps to Claude Code Conventions

The sandbox uses Claude Code's standard file locations. `sandbox/link-config.sh` runs on every launch and links this folder into them, so edits here show up without a rebuild.

| What                 | Claude Code location                           | Comes from                                             |
| -------------------- | ---------------------------------------------- | ------------------------------------------------------ |
| Coding guidelines    | `~/.claude/CLAUDE.md` (user instructions)      | `llm-instructions.md`                                  |
| Skills               | `~/.claude/skills/` (user skills)              | `skills/shared/` and `skills/claude-code/`             |
| Rules                | `~/.claude/rules/` (user rules)                | `rules/`                                               |
| Project instructions | `CLAUDE.md` in a folder added with `--add-dir` | The repo's `project-knowledge/CLAUDE.md`               |
| Specs                | Files the project instructions point to        | The rest of `project-knowledge/`                       |
| Team instructions    | `CLAUDE.md` committed in the repo              | Unchanged. It loads from the clone if the repo has one |

Claude Code loads a `CLAUDE.md` from a folder passed with `--add-dir` only when `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` is set. `csb` sets both whenever the repo has a `project-knowledge/` folder.

## Setting Up a Project

```
my-project/
├── project-knowledge/         Gitignored. Claude reads it at /knowledge
│   ├── CLAUDE.md              Project instructions
│   ├── engineering-spec.md
│   └── data-criteria.md
└── other/                     Gitignored. Hidden from Claude
    └── project-knowledge/     Older versions, for personal reference
```

1. Write the project instructions in `project-knowledge/CLAUDE.md`. Name the project's lock file there, since the `in-patch` skill leaves it out of patches and out of its sync check.
2. Put the current specs next to it. Point to each one from `CLAUDE.md` so Claude reads it when it matters. To load a short spec into every session, import it with a line like `@engineering-spec.md`. Imports use context in every session, so keep them for documents Claude always needs.
3. Keep file names stable so the references in `CLAUDE.md` stay valid. Versions belong in `other/`, not in the names.

Both folders are in the global gitignore (`gitignore_global` at the repo root of these dotfiles), so they can't be committed by accident. Only folders at the repo root match, so a source folder like `src/other/` is still tracked.

`csb` decides the mounts when it creates a container. If a repo gains or loses either folder later, `csb` says so and asks for the container to be removed and recreated.

### Updating Project Knowledge

1. Claude gives the edits in chat, ready to paste. It can't change the folder itself.
2. Copy the current file into `other/` to keep the old version.
3. Edit the file in `project-knowledge/` in place.
4. Tell Claude it changed. The folder is live, so Claude can reread it right away. Changes to `CLAUDE.md` itself load automatically in the next session, or ask Claude to reread it now.

## Daily Workflow

1. Run `csb` from anywhere in the repo. The first run builds the image, creates the clone, and creates the container.
2. Start with `/lay-of-the-land` for new work, or `/handoff-pickup` to continue from a handoff.
3. Ask for changes with `/in-patch`. Claude checks that its clone matches my repo, makes the change, runs the checks, and writes `outbox/patches/NN-name.patch`.
4. Review it from my repo with `rp ~/projects/claude/<repo>/outbox/patches/NN-name.patch`. Stage what I approve, discard the rest, and commit.
5. Ask for the next patch. Claude's sync check notices if I kept only part of a patch or made my own commits, and resets its clone to match.
6. When the session gets long, run `/handoff`. It writes `outbox/handoff.md`. Exit with `Ctrl+D`, run `csb` again, and start with `/handoff-pickup`.

Starting a fresh session on purpose is part of the review. The new session rereads the specs, the plan, and the code without remembering that it wrote any of it, which catches drift that one long session misses.

## Commands

| Command                                  | What it does                                                                        |
| ---------------------------------------- | ----------------------------------------------------------------------------------- |
| `csb`                                    | Start Claude Code in this repo's sandbox                                            |
| `csb --dangerously-skip-permissions`     | Start without permission prompts. The container is the safety boundary              |
| `csb --rebuild`                          | Rebuild the image after changing the Dockerfile, and recreate this repo's container |
| `docker stop claude-sandbox-<repo>`      | Stop the container. `csb` starts it again                                           |
| `docker rm -f claude-sandbox-<repo>`     | Remove the container. `csb` makes a new one, without anything Claude installed      |
| `docker volume rm claude-sandbox-config` | Sign out of every sandbox and reset Claude Code's settings                          |

To list what a container can reach, run this on the host.

```bash
docker inspect claude-sandbox-<repo> \
  --format '{{range .Mounts}}{{.Source}} -> {{.Destination}} (writable: {{.RW}}){{println}}{{end}}'
```

Inside a session, `/memory` lists the instruction files that loaded. `!` runs a shell command in the container, and `Shift+Tab` cycles permission modes.

## Troubleshooting

**"Container ... was made for different folders than this repo has now."** The repo gained or lost `project-knowledge/` or `other/`, or the container comes from an older layout. Run the `docker rm -f` command from the message, then `csb` again.

**"Claude's clone at ... must come from ..."** Two repos share a folder name, and clones are named after the folder. Rename one of them, or delete the old clone in `~/projects/claude/` if it's no longer needed.

**A new skill or rule doesn't show up.** Links are rebuilt when `csb` starts. Exit and run `csb` again.

**Project instructions don't load.** Check that the file is named exactly `CLAUDE.md` inside `project-knowledge/`, and run `/memory` to see what loaded.

**Git reports "dubious ownership" for `/upstream`.** The image marks `/upstream/.git` as safe. If the error appears, the image is older than that setting, so run `csb --rebuild`.
