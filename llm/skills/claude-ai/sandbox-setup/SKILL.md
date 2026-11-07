---
name: "sandbox-setup"
description: "Write a project's scripts/sandbox-setup.sh, the one command that makes a disposable agent sandbox ready to build, test and run its check script. Use when preparing a repository for agents in cloud sandboxes."
---

# Sandbox setup script

An agent working in a cloud sandbox starts from a bare Linux box every chat, and again whenever the sandbox resets. Without a setup script it spends tool calls on the same discovery each time: which tool versions the project wants, how to install them, where a database lives, which flags start it, which port it is on. Worse, it guesses, and a guessed tool version or an unlocked install means its passing checks prove nothing about the project.

The setup script makes that one command. It installs the tool versions the project pins, installs exactly the locked dependencies, and on request starts the services the tests need and runs the check script, all safe to rerun. The design below comes from a production repository where agents ran it in every chat. Each rule exists because skipping it caused a real problem.

This skill pairs with a check script (`scripts/check.sh`). If the project has none, write that first (using the `check-script` skill), since the setup's job is to make the check script runnable.

## How to use this skill

1. **Read the project.** Find:
   - the language and build tool
   - where it pins tool versions
   - its lock files
   - its check script, and how that script finds a service, usually an environment variable holding a URL
   - the services tests need
   - how tests find data the repository does not commit
2. **Probe the sandbox, don't assume it.** Check:
   - whether you are root
   - what is installed, such as `python3`, `node`, and servers under `/usr/lib/postgresql`
   - whether Docker exists (it usually doesn't)
   - which network hosts answer (usually only package registries)
   - whether a background process survives the end of a command (usually it doesn't)
   Write down what you found, since the script and the instructions depend on it.
3. **Start from the template** in Appendix A. Copy it to `scripts/sandbox-setup.sh`, fill in every function marked FILL IN, and delete what the project does not need. Add `.sandbox/` to `.gitignore`.
4. **Write the instructions block** in Appendix B into the project's agent instructions (CLAUDE.md, project instructions, or its equivalent), with the real commands.
5. **Verify** with the list at the end before handing over.

## Rules the script follows

1. **Disposable machines only.** It replaces system files, so it refuses to run unless it is root on Linux, and its header comment says never to run it on a workstation. Workstations and CI set themselves up their own way, and the check script must keep working there without this script.
2. **Safe to rerun.** Every step checks the state first and does nothing when it is already done. An agent reruns it after a reset or a new checkout without thinking about what state the sandbox is in.
3. **The project's own versions.** It reads each tool's required version from the project's config and never hard-codes one, so a version bump in the project needs no edit here. Examples are uv's `required-version`, `.nvmrc` or `engines`, `rust-toolchain.toml`, and `go.mod`'s `toolchain`. It installs through a package registry, since that is usually the only network the sandbox has, and makes sure the tool first on PATH is the one it installed.
4. **Locked installs only.** It installs dependencies in locked or frozen mode and never updates a lock file: `uv sync --locked`, `npm ci`, `pnpm install --frozen-lockfile`, `cargo fetch --locked`, `go mod download`. A pass in the sandbox then means the same as a pass anywhere else.
5. **Services on request, from what is installed.** It starts a service only with `--service` or `--check`, since starting one costs time.
   - It uses the server already installed in the sandbox, not Docker.
   - The server listens only on 127.0.0.1, on a fixed port outside common ranges, with trust authentication, and keeps its data under `/tmp`.
   - It waits until the server accepts connections before returning.
6. **The service lives as long as the command that needs it.** Sandboxes usually stop background processes when a command returns, so a server started in one tool call is gone by the next. `--check` starts the service and runs the check script in the same process. Any other command that needs the service chains after `--service` in one call.
7. **Connection details go in a file.** It writes every variable a later command needs, such as a database URL, to `.sandbox/env` as `export` lines, and prints them too. Commands `source` the file instead of an agent copying a URL from output, so a changed port can't silently break a run. The variable names are exactly the ones the check script reads.
8. **Stand-ins must fail loudly.** When the sandbox can't install something the project needs, such as a database extension, prefer letting the tests that need it skip. If a stand-in is needed so setup and migrations run, it must provide only what those steps need, so anything relying on the real thing fails. The script must say it installed a stand-in. Never let a stand-in turn a test green that the real thing would decide.
9. **Data comes from attachments.** It never fetches from sites the sandbox can't reach. `--data FILE.zip` unpacks an attached bundle into `data/<name>/`, where the tests already look, and refuses to write outside that folder.
10. **Short output that ends with the next step.** It prints one line per step and ends by printing the command to run next. A failure names the rule that failed and the value that failed it.
11. **No secrets, nothing outside the sandbox.** It writes no credentials, pushes nothing, and changes nothing in the repository except `.sandbox/` and `data/`.

## Pairing with the check script

- The setup provides exactly what the check script's steps need: the tools, the dependencies, and the service its test step reads from an environment variable.
- When the check script can start its own service with Docker on a workstation, keep that path. The sandbox path supplies the variable instead.
- `--check` passes every argument after it to the check script unchanged, so scoped runs work the same way: `--check --packages a,b`.
- If the check script's full run fails without its service, `--check` must start the service. Set `CHECK_NEEDS_SERVICE=1`.

## Verify before handing over

Run each of these and say which passed.

1. On a fresh sandbox, the script runs to the end and prints the next command.
2. Running it again changes nothing and is quick.
3. After deleting the dependency folder (such as `.venv` or `node_modules`), it restores it.
4. `--check` runs a full check in one call, with the service up, and its exit code is the check script's.
5. `--check` with a scoped option passes the option through.
6. `.sandbox/env` exists after `--service`, and `source .sandbox/env` gives a URL the tests accept.
7. `--data` unpacks a sample zip into `data/<name>/`, and refuses a zip with a path that climbs out of that folder.
8. The lock files are byte-identical after every run.
9. Read the refusal paths and confirm they exit with a message. You usually can't run as non-root in the sandbox.

## Appendix A. Template

```bash
#!/usr/bin/env bash
# Set up a disposable Linux sandbox to build and test this repository.
#
# Template. Fill in every function marked FILL IN, delete what the project does
# not need, and remove this paragraph.
#
# Install the tool versions the project pins and its locked dependencies. With
# --service, also start the local server the tests need and write how to reach it
# to .sandbox/env. With --check, start what the check needs and run
# scripts/check.sh with every argument after --check, in this same process, so the
# server lives exactly as long as the check. With --data FILE.zip, unpack an
# attached data bundle into data/<name>. It replaces system files, so run it only
# as root in a throwaway sandbox, never on a workstation. Running it again is safe.
set -euo pipefail

cd "$(dirname "$0")/.."

# ---- settings ---------------------------------------------------------------
# 1 when a full check needs the server, so --check starts it.
readonly CHECK_NEEDS_SERVICE=1
# FILL IN: a port outside common ranges, and a folder under /tmp for server data.
readonly SERVICE_PORT=55432
readonly SERVICE_ROOT=/tmp/sandbox-service
readonly ENV_FILE=.sandbox/env
# -----------------------------------------------------------------------------

fail() {
    echo "sandbox-setup: $1" >&2
    exit 1
}

require_disposable_linux() {
    if [[ "$EUID" -ne 0 ]]; then
        fail "the setup replaces system files, so it runs as root, not as user $EUID"
    fi
    if [[ "$(uname -s)" != "Linux" ]]; then
        fail "the setup is for a Linux sandbox, and this system is $(uname -s)"
    fi
}

# FILL IN: install each tool at the version the project's own config requires, and
# make the one first on PATH that version. Python with uv shown.
install_toolchain() {
    local required installed on_path
    required="$(python3 -c 'import tomllib
with open("pyproject.toml", "rb") as file:
    print(tomllib.load(file)["tool"]["uv"]["required-version"])')"
    python3 -m pip install --quiet --break-system-packages "uv${required}"
    installed="$(python3 -c 'import uv; print(uv.find_uv_bin())')"
    on_path="$(command -v uv || true)"
    [[ -n "$on_path" ]] || fail "pip installed uv at $installed, which is not on PATH ($PATH)"
    if [[ "$(readlink -f "$on_path")" != "$(readlink -f "$installed")" ]]; then
        ln -sf "$installed" "$on_path"
    fi
    echo "uv: $(uv --version), meeting required-version $required"
}

# FILL IN: install the locked dependencies without ever changing a lock file.
install_dependencies() {
    uv sync --locked --quiet
    echo "dependencies: synced from uv.lock"
}

# FILL IN: start the server the tests need, if it is not already running, and print
# each variable the check script reads as NAME=VALUE. PostgreSQL shown.
start_service() {
    local bin data
    bin="$(find /usr/lib/postgresql -maxdepth 2 -name bin -type d 2>/dev/null | sort -V | tail -1)"
    [[ -n "$bin" ]] || fail "the service needs PostgreSQL installed under /usr/lib/postgresql"
    data="$SERVICE_ROOT/data"
    if [[ ! -d "$data" ]]; then
        install -d -o postgres -g postgres "$SERVICE_ROOT"
        as_postgres "$bin/initdb" -D "$data" -U sandbox --auth=trust >/dev/null
    fi
    if ! as_postgres "$bin/pg_ctl" -D "$data" status >/dev/null; then
        as_postgres setsid "$bin/pg_ctl" -D "$data" -l "$SERVICE_ROOT/server.log" -w \
            -o "-p $SERVICE_PORT -k $SERVICE_ROOT -c listen_addresses=127.0.0.1" \
            start >/dev/null
    fi
    echo >&2 "service: PostgreSQL running from $data"
    # FILL IN: the variable name the check script reads.
    echo "TEST_DATABASE_URL=postgresql://sandbox@127.0.0.1:$SERVICE_PORT/postgres"
}

as_postgres() {
    su postgres -s /bin/bash -c "$(printf '%q ' "$@")"
}

# Write each NAME=VALUE line as an export to the env file, and print it.
write_env() {
    local line
    mkdir -p "$(dirname "$ENV_FILE")"
    : >"$ENV_FILE"
    while IFS= read -r line; do
        printf 'export %s=%q\n' "${line%%=*}" "${line#*=}" >>"$ENV_FILE"
    done
    echo "environment: written to $ENV_FILE"
    sed 's/^/  /' "$ENV_FILE"
}

# Unpack an attached zip into data/<name>, where <name> is the zip's name without
# its extension, refusing any member whose path leaves that folder.
unpack_data() {
    local archive="$1" name target
    [[ -f "$archive" ]] || fail "--data names $archive, which is not a file"
    name="$(basename "$archive" .zip)"
    target="data/$name"
    if unzip -Z1 "$archive" | grep -qE '(^/|(^|/)\.\.(/|$))'; then
        fail "$archive holds a path that leaves $target, so nothing was unpacked"
    fi
    mkdir -p "$target"
    unzip -oq "$archive" -d "$target"
    echo "data: unpacked $archive into $target"
}

service=0
check=0
data_files=()
check_arguments=()
while (($# > 0)); do
    case "$1" in
        --service) service=1 ;;
        --data)
            (($# > 1)) || fail "--data needs a zip file after it"
            data_files+=("$2")
            shift
            ;;
        --check)
            check=1
            shift
            check_arguments=("$@")
            break
            ;;
        *) fail "unknown option $1; the options are --service, --data FILE.zip and --check [ARGS]" ;;
    esac
    shift
done

require_disposable_linux
install_toolchain
install_dependencies
for archive in "${data_files[@]}"; do
    unpack_data "$archive"
done
if ((service == 1 || (check == 1 && CHECK_NEEDS_SERVICE == 1))); then
    start_service | write_env
fi
if ((check == 1)); then
    if [[ -f "$ENV_FILE" ]]; then
        # shellcheck source=/dev/null
        source "$ENV_FILE"
    fi
    echo
    exec bash scripts/check.sh "${check_arguments[@]}"
fi
echo
echo "Run every check, with its service, in one command with"
echo "  bash scripts/sandbox-setup.sh --check"
```

Notes on filling it in:

- **Other languages.** For Node, read `.nvmrc` or `engines.node`, install with the sandbox's package manager or `npm i -g node@<version>`, and use `npm ci` or `pnpm install --frozen-lockfile`. For Rust, read `rust-toolchain.toml` and run `cargo fetch --locked`. For Go, read `go.mod`'s `toolchain` and run `go mod download`.
- **No service.** Delete `start_service`, `as_postgres`, `write_env`, `--service`, and set `CHECK_NEEDS_SERVICE=0`.
- **Several services.** Have each print its own NAME=VALUE lines, and pipe them all into one `write_env`.
- **A stand-in for a missing extension** goes in its own function, called from `start_service`. It skips itself when the real extension is installed and prints that it installed a stand-in (rule 8).

## Appendix B. Instructions block for the project

Add this to the project's agent instructions, with the real commands and variable names.

```markdown
### Working in the sandbox

- **Set up once.** Run `bash scripts/sandbox-setup.sh` once per chat, and again if the sandbox resets or you clone a new checkout. It's safe to rerun.
- **Check in one call.** Run `bash scripts/sandbox-setup.sh --check`, adding any check script options after `--check`, such as `--check --packages a,b`. It starts the database and runs the check in the same command.
- **Servers stop when a command returns.** Never start a server in one call and use it in the next. For another command that needs the database, chain it in one call: `bash scripts/sandbox-setup.sh --service && source .sandbox/env && <command>`.
- **Long runs.** Start a job that must outlive one call with `setsid nohup <command> </dev/null >log 2>&1 &`, then read the log.
- **Test data.** Attached data comes as zips. `--data path/to/name.zip` unpacks one into `data/name/`.
- **Stand-ins.** Say which tests a stand-in covers when reporting results. Never report a stand-in's pass as proof that the real thing works.
```
