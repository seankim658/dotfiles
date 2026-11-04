---
name: "check-script"
description: "Design and write a project's local check script (scripts/check.sh) that runs every linter, type checker, dependency, license and architecture check and the tests, in any language, with a Python section."
---
 
# Check script
 
A check script is the single command that tells a developer, or an agent, whether the repository is in a releasable state. It runs every check the project cares about, prints one line per step, keeps going after a failure so one run reports everything, and ends with a summary nobody can misread.
 
The design below comes from a production repository where agents and people both run the script many times a day. Every rule exists because skipping it caused a real problem, such as a scoped run being mistaken for a full pass, a missing data folder hiding inside a green test run, or a check that quietly rewrote a lock file.
 
## How to use this skill
 
1. **Read the project first.** Find the language, the build tool, how packages or modules are laid out, which linters and test runners are already configured, and whether tests need a service such as a database. Reuse the tools and config the project already has. Do not add a tool the project hasn't chosen without asking.
2. **Pick the steps.** Use the step catalog below. Drop steps that don't apply, and say which ones you dropped and why.
3. **Start from the template.** Copy the check script template in Appendix A to `scripts/check.sh` and fill in every function marked FILL IN. If tests need a server, copy Appendix B to `scripts/checks/test_service.sh` and set `NEEDS_SERVICE=1`. The templates already carry the structure, option parsing, logging and summary, so the work is choosing commands, not rewriting plumbing.
4. **For a Python project,** follow the "Python projects" section. It lists the exact checks, the tool config that makes them strict, the helper checks worth writing, and filled-in step functions for the template.
5. **Verify the script itself** (see "Verify before handing over").
6. **Document it.** The `--help` text is the main documentation. Add one line to the scripts README or the contributing guide pointing to it.
## Structure
 
Keep this shape. Each part has a reason.
 
| Part | What it does | Why |
| --- | --- | --- |
| Header and `usage()` | A heredoc that states what the script does, how failure behaves, every option, and what a scoped run leaves out | `--help` is the one doc that can't drift away from the script |
| `set -uo pipefail` | Unset variables and failed pipes are errors | Not `-e`, because the script must keep running after a failed step |
| Option parsing | A `while`/`case` loop. Unknown options, repeated options and empty lists exit 2 with a pointer to `--help` | Exit 2 (usage) must never look like exit 1 (a check failed) |
| `cd` to repo root | `cd "$(dirname "$0")/.."` | The script works from any directory |
| Discovery | Find packages from the repo layout (for example every `packages/*/*/pyproject.toml`) | A hand-kept list goes stale the day someone adds a package |
| Scope selection | Validate `--packages` names against what was discovered, drop repeats, keep order | A typo must fail loudly, never check nothing and pass |
| `run_step NAME NOTE CMD...` | Runs one step, logs its output to `NAME.log`, times it, prints `PASS`/`FAIL`, and on failure prints the last 60 lines and records the name | One function makes every step look and behave the same |
| Step functions | `run_full_steps`, `run_scoped_steps`, and one per extra check | Full and scoped runs differ only in their paths |
| Service step | Provides any server the tests need, then exports its URL | Tests should never start their own long-lived infrastructure |
| Test step | Runs tests, prints the runner's summary line, then the skip reasons | Skips are where missing data and services hide |
| Summary | Total time, log folder, failed steps, and a scoped-run banner | The last lines are what people read |
| Exit status | 0 all passed, 1 any step failed, 2 usage error | CI and agents branch on it |
 
### Output format
 
Every line starts with a fixed-width status word, so a person can scan it and a tool can parse it.
 
```
PASS  lint  1.84 s
PASS  format  0.41 s
FAIL  types  12.07 s
      src/orders/service.py:41: error: Argument 1 has incompatible type "str"
      ...last 60 lines of the step's log...
PASS  database  3.10 s
      started postgres:16 on 127.0.0.1:49213, removed when the check ends
PASS  tests  48.22 s
      912 passed, 14 skipped in 47.90s
      12 skipped: data/samples is missing, run scripts/fetch-samples.sh
      2 skipped: needs a GPU
 
Total  66.03 s
Logs: /tmp/proj-check.Xa81f2
Failed: types
```
 
Status words are `PASS`, `FAIL`, `SKIP` (a step that had nothing to do, with the reason) and `NOTE` (something the reader must know, such as tests skipping because no server is available).
 
## Rules the script follows
 
**Check, never change.** Every step only reads. Use the formatter's check mode, never its write mode. Run the package manager in its locked or frozen mode so a check can never rewrite the lock file. Fixing is a separate command the developer runs on purpose.
 
**Run every step.** A failed step records its name and the script carries on. One run should show every problem, not one per run.
 
**Keep full logs, show a tail.** Each step's full output goes to a fresh `mktemp -d` folder named at the end. The terminal shows only the tail of failed steps. Strip a trailing slash from `TMPDIR` first, because macOS sets one.
 
**Time everything.** Each step line ends with its seconds, and the summary gives the total. Slow steps get noticed and fixed.
 
**Make scoped runs impossible to mistake for full ones.** A `--packages a,b` option narrows the per-package steps to those packages, for fast iteration. Then
- every narrowed step line ends with `[packages: a, b]`,
- steps that only make sense on the whole repo (architecture rules, license audit) still run whole and say `(whole workspace)`,
- the summary says "All checks in this scoped run passed", never "All checks passed",
- the last lines are a `SCOPED RUN, not a full check` banner with the covered and skipped packages, and anything a scoped run never runs (such as tests of the scripts themselves).
State plainly in `--help` that packages depending on the named ones are not added, so a change to a shared package can break a dependent the scoped run never checked.
 
**Fail a full run when a required service is missing.** A full check with the database tests silently skipped is a false pass. So a full run fails the service step when no server is available. A scoped run may go without it, and prints a `NOTE` saying the tests that need it will skip.
 
**Surface skip reasons.** After the tests, group the runner's skip messages by reason, count them, and print most-frequent first. A green run with 400 skips for "data folder missing" is not the same as a green run.
 
**Opt into parallelism.** A `--parallel` flag runs tests with one worker per CPU. Keep it opt-in, because parallel output is harder to read and some machines have one CPU. Group tests so expensive fixtures are built once per worker (for example by module).
 
**Provision services safely.** If tests need a server, the service helper should
1. use the URL in an environment variable when one is set,
2. otherwise start one throwaway container for the whole run, shared by every test worker, listening only on `127.0.0.1`, on a port Docker picks, with a random password, data on tmpfs, and durability settings off,
3. remove it on exit with a `trap`,
4. wait for readiness with a timeout set by an environment variable, and print the container's last log lines if it never comes up,
5. tag the image by a hash of its build folder, so a changed Dockerfile rebuilds and an unchanged one reuses the last build,
6. optionally offer `--test-server` to use a long-lived dev-compose service instead, which is faster across repeated runs.
The service template in Appendix B implements all of this.
 
**Stay portable.** The script must run on the bash 3.2 that macOS ships as well as on Linux. So no associative arrays, no `mapfile`, no `${var,,}`. Expand possibly empty arrays as `${arr[@]+"${arr[@]}"}`, because `set -u` treats an empty array as unset in bash 3.2. Use the `time` keyword with `TIMEFORMAT='%2R'` for timing, not `date +%s.%N`.
 
**Never call a local pass release evidence.** Say so in `--help`. Release evidence comes from controlled CI.
 
## Step catalog
 
Language-neutral steps, in the order they usually run. Fast, static steps go first so they report quickly.
 
| Step | Purpose | Notes |
| --- | --- | --- |
| `lint` | Static rules and bug patterns | Concise, one-line-per-finding output |
| `format` | Formatting is already applied | Check mode only |
| `types` | Type checking | Strict mode. Some ecosystems justify two checkers that catch different things |
| `deps` | Every import is a declared dependency and every declared dependency is used | Run per package, against that package's own manifest |
| `imports` | Architecture rules, such as layers that may only import downward | Whole repo. Generate the rules from declared metadata rather than hand-writing them |
| `licenses` | Every shipped (runtime) dependency carries an allowed license | Whole repo. Allow-list in config, never a deny-list. Leave dev-only dependencies out |
| service | Provide servers the tests need | See above |
| `tests` | The test suite | Strict config, warnings as errors, report skip reasons |
| project rules | Checks specific to this repository, such as "released files are never edited" | Put each in `scripts/checks/` with its own tests, and run those tests in the full check |
 
Tools by ecosystem, as a starting point. Prefer what the project already uses.
 
| Step | Python | TypeScript / JS | Go | Rust |
| --- | --- | --- | --- | --- |
| lint | `ruff check` | `eslint` | `golangci-lint run` | `cargo clippy -- -D warnings` |
| format | `ruff format --check` | `prettier --check` | `gofmt -l` (fail if output) | `cargo fmt --check` |
| types | `mypy --strict`, `pyright` strict | `tsc --noEmit` | built into build | built into build |
| deps | `deptry` | `knip` or `depcheck` | `go mod tidy -diff` | `cargo machete` |
| imports | `import-linter` | `dependency-cruiser` | `go-arch-lint` | crate boundaries, `cargo deny` bans |
| licenses | `uv export` piped to a checker | `license-checker` | `go-licenses check` | `cargo deny check licenses` |
| tests | `pytest` (`-n auto` with xdist) | `vitest run` / `jest` | `go test ./...` (`-p`) | `cargo test` / `cargo nextest` |
| locked mode | `uv run --locked` | `npm ci` / `pnpm --frozen-lockfile` | `-mod=readonly` | `--locked` |
 
In a repo with several languages (say a Python backend and a TypeScript frontend), give each language its own steps with a clear prefix, such as `web-lint` and `web-types`, inside the same script and summary.
 
## Verify before handing over
 
A check script is code that decides whether other code ships, so test it as such. At minimum, run these and show the output.
 
1. `bash -n scripts/check.sh` and `shellcheck scripts/check.sh` if available.
2. `--help` prints and exits 0.
3. A bad option, an empty `--packages`, and an unknown package name each exit 2 with a useful message.
4. A full run on a clean tree ends in "All checks passed" and exits 0.
5. Break one thing on purpose (an unformatted line, a failing test) and confirm that step prints `FAIL` with its tail, the later steps still run, and the exit status is 1. Then undo the break.
6. A scoped run shows the `[packages: ...]` notes and the `SCOPED RUN` banner.
7. If there is a service step, a full run without Docker or a URL fails that step, and a scoped run prints the `NOTE`.
When the project has a `scripts/checks/tests` folder, add tests for any helper logic you wrote, such as the license checker or the contract generator.
 
## Python projects
 
These are the checks a Python project runs, with the config that makes each one strict. They assume a uv workspace with one package per folder. For a single-package repo, treat the repo root as the only package.
 
### Steps and commands
 
Every command runs through `uv run --locked`, so the lock file is never rewritten and a stale lock fails the check instead of being silently fixed.
 
| Step | Full run | Scoped run | Why |
| --- | --- | --- | --- |
| `lint` | `ruff check --output-format concise .` | same, on package folders | Bug patterns, security rules, import order, modern syntax |
| `format` | `ruff format --check .` | same, on package folders | Check mode only |
| `mypy` | `mypy` (paths from config) | `mypy <folders>` | Strict mode. Catches things pyright misses, and runs plugins such as pydantic's |
| `pyright` | `pyright` (paths from config) | `pyright <folders>` | Strict mode. Better inference and unknown-type reporting than mypy. Running both is worth the seconds |
| `deptry` | `deptry src` inside each package folder | same, chosen packages only | Each package's imports match its own declared dependencies. A root-level run can't see per-package mistakes |
| `imports` | `lint-imports --config <generated>` | whole workspace | Layer rules between packages |
| `licenses` | `uv export ... \| python scripts/checks/license_check.py` | whole workspace | Shipped dependencies only |
| `database` | provide a server (Appendix B) | optional, with a NOTE | Only when tests need one |
| `tests` | `pytest -q -rs` | `pytest -q -rs <folders with tests>` | `-rs` prints each skip reason, which the summary groups |
 
With `--parallel`, add `-n auto --dist loadscope` (pytest-xdist). `loadscope` keeps each module on one worker, so module-scoped fixtures are built once.
 
Notes on specific steps.
 
- **deptry** reads the `pyproject.toml` in its working directory, so `cd` into each package. Exclude test folders that live under `src` (`--extend-exclude '.*/tests/'`), since they never ship and may import test tools.
- **Licenses.** Export only runtime dependencies, and leave the workspace's own packages out:
  `uv export --locked --all-packages --no-default-groups --no-emit-workspace --no-hashes --no-header --no-annotate`.
- **Dev tools** (ruff, mypy, pyright, deptry, import-linter, pytest, pytest-xdist, hypothesis) go in the root `[dependency-groups] dev`, never in a shipped package's dependencies.
- **Pin uv itself** with `[tool.uv] required-version`, so every machine resolves the same way.
### Tool config
 
Put strictness in `pyproject.toml`, not in command-line flags, so editors and the script agree.
 
```toml
[tool.ruff]
target-version = "py312"
line-length = 100
 
[tool.ruff.lint]
select = [
    "E", "W", "F", "I", "N", "UP", "B", "A", "C4", "S",
    "SIM", "PT", "PTH", "T20", "ERA", "RUF",
]
 
[tool.ruff.lint.per-file-ignores]
# pytest reports through assert, and tests run tools by absolute path.
"**/tests/**" = ["S101", "S603"]
 
[tool.mypy]
python_version = "3.12"
strict = true
files = ["packages", "scripts", "conftest.py"]
 
[tool.pyright]
pythonVersion = "3.12"
typeCheckingMode = "strict"
include = ["packages", "scripts", "conftest.py"]
venvPath = "."
venv = ".venv"
 
[tool.pytest]   # [tool.pytest.ini_options] before pytest 9
testpaths = ["packages", "scripts"]
addopts = ["--import-mode=importlib", "--strict-markers", "--strict-config", "-ra"]
xfail_strict = true
filterwarnings = ["error"]
markers = [
    "postgres: uses a PostgreSQL server, named by MYAPP_TEST_POSTGRES_URL",
]
```
 
Why these settings.
 
- The ruff rule set adds bugbear (`B`), security (`S`), pathlib (`PTH`), no stray prints (`T20`) and no commented-out code (`ERA`) to the defaults.
- `--strict-markers` and `--strict-config` turn typos in markers and config into errors.
- `filterwarnings = ["error"]` makes deprecations fail now instead of breaking an upgrade later.
- `xfail_strict` makes an expected failure that starts passing fail, so stale `xfail` marks get removed.
- `--import-mode=importlib` lets test files in different packages share names.
- Include `scripts` in type checking and tests. The check tooling is code too.
Tests that need data or a service should skip with a reason that says how to get it, such as `data/samples is missing, run scripts/fetch-samples.sh`. The skip summary then tells the reader exactly what to do.
 
### Helper checks worth writing
 
Put each in `scripts/checks/` with tests in `scripts/checks/tests/`. Write them in Python and type check them like the rest of the code.
 
**`import_contracts.py`.** Generates the import-linter config instead of hand-writing it. The root `pyproject.toml` lists the architecture layers in order (lowest first), each with a peer rule (`independent` means peers never import each other, `acyclic` means peers may import a declared dependency as long as there is no cycle). Each package names its layer in its own `pyproject.toml`. The script refuses, before writing anything, a package with no layer, a package outside `packages/<layer>/<name>`, or a cycle among declared dependencies, reporting every problem and not only the first. It can also add a contract that keeps I/O modules (`os`, `pathlib`, `http`, database drivers) out of pure layers. `check.sh` writes the generated file into the log folder and runs `lint-imports` on it.
 
**`license_check.py`.** Reads the pinned runtime dependencies from standard input and each one's license from its installed metadata. Rules worth keeping:
- an allow-list of SPDX IDs in `[tool.<project>.licenses] allowed`, never a deny-list, and no copyleft entries if the project ships closed or permissive code,
- every license in an expression must be allowed, so `MIT OR GPL-3.0-only` is refused,
- exceptions after `WITH` need their own allow-list,
- a package whose metadata gives no SPDX license needs a reviewed entry naming the version it was read from, so an upgrade forces another review,
- code a wheel bundles from other projects (shared libraries, SBOMs) needs a bundled entry, since package metadata only covers the package's own code.
**Project invariants.** Anything the project promises that no off-the-shelf tool checks, such as "released files are never edited" (hash them and compare against a recorded manifest) or "every config key is documented". Each becomes one more `run_step`.
 
### Filled-in step functions
 
Drop these into the Appendix A template in place of the FILL IN stubs.
 
```bash
lint() { uv run --locked ruff check --output-format concise "$@"; }
format_check() { uv run --locked ruff format --check "$@"; }
 
# A full run passes ".", which means "use the configured paths".
type_check_mypy() {
    if [[ "$*" == "." ]]; then uv run --locked mypy; else uv run --locked mypy "$@"; fi
}
type_check_pyright() {
    if [[ "$*" == "." ]]; then uv run --locked pyright; else uv run --locked pyright "$@"; fi
}
 
dependency_check() {
    local status=0 package
    for package in "$@"; do
        echo "== $package"
        (cd "$package" && uv run --locked deptry src --extend-exclude '.*/tests/') || status=1
    done
    return "$status"
}
 
import_contracts() {
    local contracts="$log_dir/importlinter.ini"
    uv run --locked python scripts/checks/import_contracts.py "$contracts" &&
        uv run --locked lint-imports --config "$contracts"
}
 
# Only runtime dependencies ship, so dependency groups are left out.
licenses() {
    uv export --locked --all-packages --no-default-groups --no-emit-workspace \
        --no-hashes --no-header --no-annotate |
        uv run --locked python scripts/checks/license_check.py
}
 
run_test_command() { uv run --locked pytest "$@"; }
 
test_options=(-q -rs)
if ((parallel == 1)); then
    test_options+=(-n auto --dist loadscope)
fi
```
 
Replace the single `types` step with two steps, `mypy` and `pyright`, in both `run_full_steps` and `run_scoped_steps`. The template's `has_test_files` and `skip_reasons` already match pytest.
 
If the database tests use an environment variable the test fixtures read, name it after the project (`MYAPP_TEST_POSTGRES_URL`) and use the SQLAlchemy driver form the code expects, such as `postgresql+psycopg://`. Mark every test that needs the server with a marker the fixture adds, so none goes unmarked.
 
## Appendix A. Check script template
 
A scoped run, a full run, usage errors and skip reporting in this template were all exercised on a sample uv workspace. Every unfilled step fails, so a half-finished script can never pass.
 
```bash
#!/usr/bin/env bash
# Run every check on the whole repository, or on chosen packages. Run with --help
# for usage.
#
# Template. Fill in every function marked FILL IN, set the settings block, delete
# what the project does not need, and remove this paragraph. An unfilled step
# fails, so a half-finished script can never pass.
set -uo pipefail
 
# ---- settings ---------------------------------------------------------------
# Name used for the log folder and messages.
readonly PROJECT="myproject"
# Each package is a folder holding one of these manifests. The package's name is
# its folder's name. Adjust the glob to the layout, such as packages/*/package.json.
readonly MANIFEST_GLOB="packages/*/*/pyproject.toml"
# 1 when tests need a server that scripts/checks/test_service.sh provides.
readonly NEEDS_SERVICE=0
# Lines of a failed step's log shown in the terminal.
readonly TAIL_LINES=60
# -----------------------------------------------------------------------------
 
usage() {
    cat <<'EOF'
usage: bash scripts/check.sh [--parallel] [--packages a,b] [--help]
 
Run every check on the whole repository, or with --packages on chosen packages,
and print one line per step with the time it took.
 
Every step runs even after one fails. A failed step prints the last lines of its
output, and every step's full output stays in the log folder named at the end.
Dependencies are used in locked mode, so a check never rewrites the lock file. The
script exits 1 if any step failed and 2 on a usage error. A local pass is never
release evidence.
 
options
  --parallel        run the tests with one worker per CPU
  --packages a,b    check only these packages, each named by its folder. Lint,
                    format, type checks, dependency checks and tests are narrowed
                    to them. Whole-repository checks still run on everything.
                    Packages that depend on the named ones are not added, so a
                    change to a shared package can break a dependent that a
                    scoped run never checks. A scoped run is never a full check.
  -h, --help        show this help and exit
EOF
}
 
usage_error() {
    echo "check.sh: $1 Run bash scripts/check.sh --help for usage." >&2
    exit 2
}
 
parallel=0
scoped=0
packages_option=""
while (($# > 0)); do
    case "$1" in
    -h | --help)
        usage
        exit 0
        ;;
    --parallel)
        parallel=1
        ;;
    --packages | --packages=*)
        ((scoped == 0)) || usage_error "--packages is given twice."
        scoped=1
        if [[ "$1" == --packages=* ]]; then
            packages_option="${1#--packages=}"
        else
            (($# > 1)) || usage_error "--packages needs a comma-separated list of packages."
            packages_option="$2"
            shift
        fi
        ;;
    *)
        usage_error "unknown option $1."
        ;;
    esac
    shift
done
 
cd "$(dirname "$0")/.." || exit 1
if ((NEEDS_SERVICE == 1)); then
    # shellcheck source=/dev/null
    source scripts/checks/test_service.sh
fi
 
# ---- discovery --------------------------------------------------------------
# workspace_folders holds each package's path at the same index as its name.
workspace_packages=()
workspace_folders=()
for manifest in $MANIFEST_GLOB; do
    [[ -f "$manifest" ]] || continue
    folder="${manifest%/*}"
    workspace_packages+=("${folder##*/}")
    workspace_folders+=("$folder")
done
 
package_folder() {
    local index
    for index in "${!workspace_packages[@]}"; do
        if [[ "${workspace_packages[$index]}" == "$1" ]]; then
            echo "${workspace_folders[$index]}"
            return 0
        fi
    done
    return 1
}
 
contains() {
    local wanted="$1" candidate
    shift
    for candidate in "$@"; do
        [[ "$candidate" == "$wanted" ]] && return 0
    done
    return 1
}
 
# join_comma A B... prints its arguments separated by a comma and a space.
join_comma() {
    local IFS=","
    local text="$*"
    echo "${text//,/, }"
}
 
refuse_packages() {
    usage_error "$1 Packages: $(join_comma ${workspace_packages[@]+"${workspace_packages[@]}"})."
}
 
# choose_packages reads --packages into chosen, in the order given, with repeats
# dropped. It refuses an empty list, an empty name and an unknown name.
choose_packages() {
    local name names
    chosen=()
    [[ -n "$packages_option" ]] || refuse_packages "--packages needs at least one package."
    IFS="," read -r -a names <<<"$packages_option"
    for name in ${names[@]+"${names[@]}"}; do
        [[ -n "$name" ]] || refuse_packages "--packages $packages_option holds an empty name."
        contains "$name" ${workspace_packages[@]+"${workspace_packages[@]}"} ||
            refuse_packages "$name is not a package."
        contains "$name" ${chosen[@]+"${chosen[@]}"} || chosen+=("$name")
    done
    ((${#chosen[@]} > 0)) || refuse_packages "--packages needs at least one package."
}
 
# FILL IN: how to tell whether a folder holds any test file.
has_test_files() {
    [[ -n "$(find "$1" -name 'test_*.py' -not -path '*/__pycache__/*' | head -n 1)" ]]
}
 
chosen=()
skipped=()
package_paths=()
test_paths=()
if ((scoped == 1)); then
    choose_packages
    for name in "${chosen[@]}"; do
        folder="$(package_folder "$name")"
        package_paths+=("$folder")
        has_test_files "$folder" && test_paths+=("$folder")
    done
    for name in ${workspace_packages[@]+"${workspace_packages[@]}"}; do
        contains "$name" "${chosen[@]}" || skipped+=("$name")
    done
fi
 
# ---- step runner ------------------------------------------------------------
# bash's time keyword reports elapsed seconds to two decimals, even in bash 3.2.
TIMEFORMAT='%2R'
# macOS sets TMPDIR with a trailing slash, so drop it before adding the name.
temp_root="${TMPDIR:-/tmp}"
log_dir="$(mktemp -d "${temp_root%/}/$PROJECT-check.XXXXXX")"
failed=()
 
# A scoped run marks every step line, so its output can never pass for a full run.
narrowed_note=""
whole_note=""
if ((scoped == 1)); then
    narrowed_note="[packages: $(join_comma "${chosen[@]}")]"
    whole_note="(whole repository)"
fi
 
# run_step NAME NOTE COMMAND... runs COMMAND, logging its output to NAME.log and its
# elapsed time to NAME.time. A NOTE that is not empty ends the step's line.
run_step() {
    local name="$1"
    local note="$2"
    shift 2
    local log="$log_dir/$name.log"
    local timing="$log_dir/$name.time"
    local status elapsed
    { time "$@" >"$log" 2>&1; } 2>"$timing"
    status=$?
    elapsed="$(<"$timing")"
    if ((status == 0)); then
        echo "PASS  $name  $elapsed s${note:+  $note}"
        return 0
    fi
    echo "FAIL  $name  $elapsed s${note:+  $note}"
    tail -n "$TAIL_LINES" "$log" | sed 's/^/      /'
    failed+=("$name")
    return 1
}
 
not_filled_in() {
    echo "This step is not filled in yet. Edit scripts/check.sh."
    return 1
}
 
# ---- steps ------------------------------------------------------------------
# Each step function takes the paths to check. A full run passes ".", except to
# a tool that works one package at a time, which gets every package folder.
 
# FILL IN: the linter, with one line per finding.
lint() { not_filled_in; }
# FILL IN: the formatter in check mode. Never let it write.
format_check() { not_filled_in; }
# FILL IN: the type checker in strict mode. Add a second step for a second checker.
type_check() { not_filled_in; }
# FILL IN: declared versus used dependencies, run inside each package folder.
dependency_check() {
    local status=0 package
    for package in "$@"; do
        echo "== $package"
        (cd "$package" && not_filled_in) || status=1
    done
    return "$status"
}
# FILL IN: architecture rules over the whole repository.
import_contracts() { not_filled_in; }
# FILL IN: licenses of shipped (runtime) dependencies over the whole repository.
licenses() { not_filled_in; }
# FILL IN: the test runner. Its options come from test_options.
run_test_command() { not_filled_in; }
 
test_options=()
if ((parallel == 1)); then
    : # FILL IN: options for one worker per CPU, such as -n auto --dist loadscope
fi
 
run_scoped_steps() {
    run_step lint "$narrowed_note" lint "${package_paths[@]}"
    run_step format "$narrowed_note" format_check "${package_paths[@]}"
    run_step types "$narrowed_note" type_check "${package_paths[@]}"
    run_step deps "$narrowed_note" dependency_check "${package_paths[@]}"
}
 
run_full_steps() {
    run_step lint "" lint .
    run_step format "" format_check .
    run_step types "" type_check .
    run_step deps "" dependency_check ${workspace_folders[@]+"${workspace_folders[@]}"}
}
 
# A full check needs its server, so it fails without one. A scoped run may go
# without, and says the tests that need it will skip.
run_service_step() {
    ((NEEDS_SERVICE == 1)) || return 0
    if ((scoped == 0)); then
        if run_step service "" provide_test_service; then
            tail -n 1 "$log_dir/service.log" | sed 's/^/      /'
        fi
    elif provide_test_service >"$log_dir/service.log" 2>&1; then
        echo "PASS  service  $(tail -n 1 "$log_dir/service.log")"
    else
        echo "NOTE  tests that need a server skip, since none is available  $narrowed_note"
    fi
}
 
run_tests() {
    if ((scoped == 1 && ${#test_paths[@]} == 0)); then
        echo "SKIP  tests  none of the chosen packages has a test file  $narrowed_note"
    elif run_step tests "$narrowed_note" run_test_command \
        ${test_options[@]+"${test_options[@]}"} ${test_paths[@]+"${test_paths[@]}"}; then
        tail -n 1 "$log_dir/tests.log" | sed 's/^/      /'
        skip_reasons "$log_dir/tests.log"
    fi
}
 
# FILL IN: print each reason tests skipped for, with its count, most first, so a
# missing data folder never hides inside a passing run. This reads pytest's -rs
# lines ("SKIPPED [3] path: reason"). Adapt the pattern to the test runner.
skip_reasons() {
    awk 'match($0, /^SKIPPED \[[0-9]+\] [^ ]+: /) {
        count[substr($0, RLENGTH + 1)] += substr($0, 10) + 0
    }
    END { for (reason in count) printf "%d\t%s\n", count[reason], reason }' "$1" |
        sort -t "$(printf '\t')" -k1,1nr -k2 |
        awk -F '\t' '{ printf "      %d skipped: %s\n", $1, $2 }'
}
 
run_steps() {
    if ((scoped == 1)); then
        run_scoped_steps
    else
        run_full_steps
    fi
    run_service_step
    run_step imports "$whole_note" import_contracts
    run_step licenses "$whole_note" licenses
    run_tests
}
 
# ---- summary ----------------------------------------------------------------
# time reports on the group's standard error, which goes to total.time. The steps'
# own standard error is passed through on fd 3, so nothing they print is lost.
total_time="$log_dir/total.time"
{ time run_steps 2>&3; } 3>&2 2>"$total_time"
 
echo
echo "Total  $(<"$total_time") s"
echo "Logs: $log_dir"
status=0
if ((${#failed[@]} > 0)); then
    echo "Failed: ${failed[*]}"
    status=1
elif ((scoped == 1)); then
    echo "All checks in this scoped run passed"
else
    echo "All checks passed"
fi
if ((scoped == 1)); then
    echo "SCOPED RUN, not a full check"
    echo "  Covered: $(join_comma "${chosen[@]}")"
    if ((${#skipped[@]} > 0)); then
        echo "  Skipped: $(join_comma "${skipped[@]}")"
    else
        echo "  Skipped: none"
    fi
fi
exit "$status"
```
 
## Appendix B. Test service template
 
Sourced by the check script when `NEEDS_SERVICE=1`. Written for PostgreSQL. For another server, change the settings block, the `docker run` arguments and `service_is_ready`.
 
```bash
# Provide the server a check's tests use. Sourced by check.sh.
#
# Template, written for PostgreSQL. For another server, change the settings block,
# the docker run arguments and service_is_ready. Rename the TEST_SERVICE_ variables
# to the project's prefix, such as MYAPP_TEST_POSTGRES_URL, and remove this
# paragraph.
#
# provide_test_service uses the server TEST_SERVICE_URL names when it is set.
# Otherwise it starts one throwaway container for the whole check, which every
# test worker shares, and removes it when the shell exits. That container listens
# only on 127.0.0.1, on a port Docker chooses, behind a password made for this
# check alone. Without a URL or a working Docker, it fails and says how to provide
# a server.
#
# When the build folder exists, the image is built from it and tagged by a hash of
# its contents, so a change there builds a new image and an unchanged folder
# reuses the last build. TEST_SERVICE_IMAGE names another image instead, which is
# never built. TEST_SERVICE_READY_SECONDS sets how long the server may take to
# start.
 
# ---- settings ---------------------------------------------------------------
SERVICE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
readonly SERVICE_ROOT
# A folder with a Dockerfile, or an empty string to use SERVICE_DEFAULT_IMAGE.
readonly SERVICE_BUILD_CONTEXT="$SERVICE_ROOT/docker/postgres"
readonly SERVICE_DEFAULT_IMAGE="postgres:16"
readonly SERVICE_IMAGE_NAME="myproject-test-postgres"
readonly SERVICE_PORT=5432
readonly SERVICE_USER="test"
# Test data is never kept, so the server skips the writes that make data survive
# a crash.
SERVICE_SETTINGS=(-c fsync=off -c synchronous_commit=off -c full_page_writes=off)
readonly SERVICE_SETTINGS
# -----------------------------------------------------------------------------
 
test_service_container=""
test_service_image=""
 
provide_test_service() {
    if [[ -n "${TEST_SERVICE_URL:-}" ]]; then
        echo "using the server TEST_SERVICE_URL names"
        return 0
    fi
    if ! docker info >/dev/null 2>&1; then
        echo "TEST_SERVICE_URL is not set, and Docker is not available to start a server."
        echo "Start Docker, or set TEST_SERVICE_URL to the URL of a server tests may use."
        return 1
    fi
    choose_service_image || return 1
    start_service_container
}
 
# choose_service_image sets test_service_image, building it if it is missing.
choose_service_image() {
    if [[ -n "${TEST_SERVICE_IMAGE:-}" ]]; then
        test_service_image="$TEST_SERVICE_IMAGE"
        return 0
    fi
    if [[ -z "$SERVICE_BUILD_CONTEXT" || ! -d "$SERVICE_BUILD_CONTEXT" ]]; then
        test_service_image="$SERVICE_DEFAULT_IMAGE"
        return 0
    fi
    test_service_image="$SERVICE_IMAGE_NAME:$(service_context_hash)"
    if docker image inspect "$test_service_image" >/dev/null 2>&1; then
        echo "reusing $test_service_image, built from the current build folder"
        return 0
    fi
    echo "building $test_service_image from $SERVICE_BUILD_CONTEXT"
    docker build --tag "$test_service_image" "$SERVICE_BUILD_CONTEXT" || {
        echo "Docker could not build $test_service_image from $SERVICE_BUILD_CONTEXT."
        return 1
    }
}
 
# The hash only names a build for reuse, so git's object hash is enough. It covers
# each file's path within the folder and its bytes.
service_context_hash() {
    local path digest
    digest="$(
        cd "$SERVICE_BUILD_CONTEXT" || exit 1
        find . -type f | LC_ALL=C sort | while IFS= read -r path; do
            printf '%s\0' "$path"
            cat "$path"
            printf '\0'
        done | git hash-object --stdin
    )"
    echo "${digest:0:12}"
}
 
start_service_container() {
    local password port
    password="$(od -An -tx1 -N16 /dev/urandom | tr -d ' \n')"
    # No --rm, so a server that dies at start keeps its logs for the report. The
    # exit trap removes the container either way.
    test_service_container="$(docker run --detach \
        --name "$SERVICE_IMAGE_NAME-check-$$-$RANDOM" \
        --env "POSTGRES_USER=$SERVICE_USER" --env "POSTGRES_PASSWORD=$password" \
        --env POSTGRES_DB=postgres --publish "127.0.0.1::$SERVICE_PORT" \
        --tmpfs /var/lib/postgresql/data "$test_service_image" postgres "${SERVICE_SETTINGS[@]}")" || {
        echo "Docker could not start $test_service_image."
        return 1
    }
    trap remove_service_container EXIT
    port="$(docker port "$test_service_container" "$SERVICE_PORT/tcp" 2>/dev/null | head -n 1)"
    port="${port##*:}"
    if [[ ! "$port" =~ ^[0-9]+$ ]]; then
        echo "Docker did not report the port $test_service_image listens on, so it may have stopped."
        report_service_logs
        return 1
    fi
    if ! wait_for_service; then
        report_service_logs
        return 1
    fi
    export TEST_SERVICE_URL="postgresql://$SERVICE_USER:$password@127.0.0.1:$port/postgres"
    echo "started $test_service_image on 127.0.0.1:$port, removed when the check ends"
}
 
# The postgres image's first start creates the database on a server that listens
# on no TCP port, then restarts it, so the server is ready once it answers over TCP.
service_is_ready() {
    docker exec "$test_service_container" pg_isready --quiet --host 127.0.0.1 \
        --username "$SERVICE_USER" --dbname postgres
}
 
wait_for_service() {
    local seconds="${TEST_SERVICE_READY_SECONDS:-60}"
    local waited
    for ((waited = 0; waited < seconds; waited++)); do
        service_is_ready && return 0
        sleep 1
    done
    echo "$test_service_image did not accept connections within $seconds seconds."
    return 1
}
 
report_service_logs() {
    echo "The server's last log lines:"
    docker logs --tail 20 "$test_service_container" 2>&1 | sed 's/^/  /'
}
 
remove_service_container() {
    if [[ -n "$test_service_container" ]]; then
        docker rm --force "$test_service_container" >/dev/null 2>&1
        test_service_container=""
    fi
}
```
