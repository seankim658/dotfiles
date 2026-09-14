# My Configs

- [Bash](#bash)
- [Git](#git)
- [MacOS](#macos)
- [Nvim](#nvim)
- [Scripts](#scripts)
- [Tmux](#tmux)

---

## Bash

Lenovo Ubuntu WSL ():

```
GNU bash, version 5.1.16(1)-release (x86_64-pc-linux-gnu)
Copyright (C) 2020 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
```

MacOS (Monday, 14-Sep-26 01:25:14PM EST):

```
/opt/homebrew/bin/bash

GNU bash, version 5.2.37(1)-release (aarch64-apple-darwin24.0.0)
Copyright (C) 2022 Free Software Foundation, Inc.
License GPLv3+: GNU GPL version 3 or later <http://gnu.org/licenses/gpl.html>
```

## Git

Lenovo Ubuntu WSL ():

```
git version 2.34.1
```

MacOS (Monday, 14-Sep-26 01:25:48PM EST):

```
git version 2.39.5 (Apple Git-154)
```

## MacOS

Aerospace (Monday, 14-Sep-26 01:38:57PM EST):

```
aerospace CLI client version: 0.16.0-Beta d172dfd8a92f2d339f3d46a12a297e43e80768ca
AeroSpace.app server version: 0.16.0-Beta d172dfd8a92f2d339f3d46a12a297e43e80768ca
```

## Nvim

Lenovo Ubuntu WSL ():

```
NVIM v0.9.4
Build type: Release
LuaJIT 2.1.1692716794
```

MacOS (Monday, 14-Sep-26 01:40:52PM EST):

```
NVIM v0.10.3
Build type: Release
LuaJIT 2.1.1734355927
Run "nvim -V1 -v" for more info
```

## Scripts

| Name          | Functionality                                                                                                                                                                                                              |
| ------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `session.sh`  | Uses `fzf` to find a project and start a tmux session. If the session already exists, will attach to it. Uses the directory name as the session name and creates two windows, `code` and `shell`.                          |
| `setup.sh`    | My initial machine setup for dotfile symlinks, etc. If a file matches but is no a symlink, backs it up. If a symlink already exists, just skips. Also re-sources some config files (such as `.bashrc`, `.tmux.conf`, etc.) |

## Tmux

Lenovo Ubuntu WSL ():

```
tmux 3.2a
```

MacOS (Monday, 14-Sep-26 01:42:10PM EST):

```
tmux 3.5a
```
