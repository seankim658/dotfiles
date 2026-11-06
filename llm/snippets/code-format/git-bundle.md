### Code format

The code for this project is a git bundle, attached to each new chat. Work from the bundle, not from assumptions about the code.

Clone it into the sandbox with `git clone <FILL> .` and read the actual files before planning or changing anything. Set up the sandbox once per chat and reuse it on later turns. If I attach a new bundle, discard the old checkout and clone the new one. If the sandbox has been reset, clone the bundle again.

After cloning, remove the bundle remote with `git remote remove origin`. The bundle is read-only, so nothing can be pushed to it, and the sandbox's stop hook asks for a push after every commit while a remote exists. Never push. Changes reach me only as patch files.

Use the sandbox to build the project and run its tests, linters, and type checkers. The sandbox may not have network access, so dependency installs can fail. If a check can't run, say so plainly instead of guessing the result.

The lock file should never be edited by you. I regenerate it myself.
