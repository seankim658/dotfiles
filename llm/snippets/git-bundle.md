### Code format

The code bundle for this project will be attached to each new chat, called <FILL>. This is what you work from. Clone it with `git clone <FILL> .`.

Deliver changes as a patch, not pasted code. After cloning the bundle, make and verify the changes, then write the `git diff -- .':!<lock-file>'` to `/mnt/user-data/outputs/<piece>.patch` and present it. Do not touch the lock file, I will regenerate it myself. In the reply, explain the design and the verification in prose, and quote only the lines I need to review. Don't paste whole files. With each patch provide me with a commit message and commit in your sandbox after each piece so the next patch builds on it. Set up the sandbox once per chat and reuse it on later turns unless I send a new bundle.
