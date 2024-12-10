# My Configs

These configs are used across MacOS and Linux.

- [Bash](#bash)
- [Git](#git)
- [MacOS](#macos)
  - [Aerospace](#aerospace)
- [Nvim](#nvim)
- [Scripts](#scripts)
- [Tmux](#tmux)
- [TODO](#todo)

---

## Bash

Ubuntu WSL:

```
GNU bash, version 5.1.16(1)-release (x86_64-pc-linux-gnu)
Copyright (C) 2020 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
```

MacOS:

```
GNU bash, version 5.2.37(1)-release (aarch64-apple-darwin24.0.0)
Copyright (C) 2022 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
```

## Git

Ubuntu WSL:

```
git version 2.34.1
```

MacOS:

```
git version 2.39.5 (Apple Git-154)
```

## MacOS

#### Aerospace

```
aerospace CLI client version: 0.16.0-Beta d172dfd8a92f2d339f3d46a12a297e43e80768ca
AeroSpace.app server version: 0.16.0-Beta d172dfd8a92f2d339f3d46a12a297e43e80768ca
```

## Nvim

Ubuntu WSL:

```
NVIM v0.9.4
Build type: Release
LuaJIT 2.1.1692716794
```

MacOS:

```
NVIM v0.10.2
Build type: Release
LuaJIT 2.1.1731601260
```

I prefer `JetBrainsMonoNL` for my nerdfont (in the `fonts/` directory).

## Scripts

| Name          | Functionality                                                                                                                                                                                                              |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `session.sh`  | Uses `fzf` to find a project and start a tmux session. If the session already exists, will attach to it. Uses the directory name as the session name and creates two windows, `code` and `shell`.                          |
| `obsidian.sh` | Creates a tmux session in my obsidian vault.                                                                                                                                                                               |
| `setup.sh`    | My initial machine setup for dotfile symlinks, etc. If a file matches but is no a symlink, backs it up. If a symlink already exists, just skips. Also re-sources some config files (such as `.bashrc`, `.tmux.conf`, etc.) |

## Tmux

Ubuntu WSL:

```
tmux 3.2a
```

MacOS:

```
tmux 3.5a
```

## TODO

- Peek markdown plugin isn't lazy loading only on `.md` files, not sure why.
- At some point should split out any config settings from my `plugins/init.lua` for consistencies sake.
- Figure out what to do with the `eslintrc.json` file.
- Add some custom snippets.
