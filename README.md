# devbox — macOS developer bootstrap (Homebrew + asdf + zsh + apps)

[![ShellCheck](https://github.com/phoenixTW/mac-devbox/actions/workflows/shellcheck.yml/badge.svg)](https://github.com/phoenixTW/mac-devbox/actions/workflows/shellcheck.yml)
[![Doctor Dry-Run](https://github.com/phoenixTW/mac-devbox/actions/workflows/doctor-dry-run.yml/badge.svg)](https://github.com/phoenixTW/mac-devbox/actions/workflows/doctor-dry-run.yml)

A tiny, idempotent CLI to set up your Mac (Apple Silicon) with **Homebrew**, **asdf**, **oh-my-zsh** (agnoster), and your preferred **formulae/casks/tools**. State lives in **`~/.devbox`** so you can tweak configs and re-run.

* **User-scoped** installs (no sudo)
* **Idempotent** (safe to re-run)
* **Config → action**: edit files, run `devbox`
* **Curl installer** + **tab completion** + **CI smoke tests**

---

## Contents

- [devbox — macOS developer bootstrap (Homebrew + asdf + zsh + apps)](#devbox--macos-developer-bootstrap-homebrew--asdf--zsh--apps)
  - [Contents](#contents)
  - [Quick start](#quick-start)
  - [What gets installed](#what-gets-installed)
  - [Configs](#configs)
  - [CLI usage](#cli-usage)
  - [Examples](#examples)
  - [Install locations \& PATH](#install-locations--path)
  - [Tab completion](#tab-completion)
  - [Sync \& upgrades](#sync--upgrades)
  - [Troubleshooting](#troubleshooting)
  - [Project layout](#project-layout)
  - [Development](#development)
  - [Security \& scope](#security--scope)
  - [Uninstall](#uninstall)
  - [License](#license)

---

## Quick start

**One-liner install** (installs CLI, seeds configs, installs completions):

```bash
# Install latest release (recommended)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/phoenixTW/mac-devbox/refs/tags/0.0.1/install.sh)"

# Or install from main branch (development)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/phoenixTW/mac-devbox/main/install.sh)"

# start using devbox (new terminal or:)
source ~/.zprofile
source ~/.zshrc 2>/dev/null || true
devbox bootstrap
```

* `devbox bootstrap` performs a **full idempotent** setup: Xcode CLT check, Homebrew, brew packages & casks, asdf tools, zsh + oh-my-zsh (agnoster), Meslo Nerd font, and first-launch registrations for Docker/Forti.

---

## What gets installed

Defaults live in `config.defaults/` (copied to `~/.devbox` on first install). You can change them later.

* **Homebrew** under `/opt/homebrew`; **casks** to `~/Applications`
* **CLI** (defaults): `git gnupg wget curl jq direnv coreutils make tree asdf`
* **GUI** (defaults): `notion docker cursor arc forticlient-vpn warp font-meslo-lg-nerd-font`
* **asdf tools** (defaults): `nodejs`, `golang` (versions from JSON; `latest` supported)
* **Shell**: oh-my-zsh with `agnoster` + plugins `git asdf direnv`
* **Completions**: zsh + bash

> macOS may prompt once for **Xcode CLT** and for **Docker/Forti** system permissions.

---

## Configs

By default, config lives in **`~/.devbox`** (overridable with `--config DIR` or `DEVBOX_CONFIG_DIR`).

* `~/.devbox/brew-formulae.txt`
  One Homebrew **formula** per line; `#` comments allowed.
* `~/.devbox/brew-casks.txt`
  One Homebrew **cask** per line; `#` comments allowed.
* `~/.devbox/asdf-tools.json`
  JSON map `{"tool": "version"}`. Use specific versions or `"latest"`.

**Persistence rules (automatic):**

* `devbox brew <name>` installs and **appends** `<name>` to the correct list (formula vs cask) if not present.
* `devbox asdf <tool> <version|latest>` installs and **persists** the **resolved** version to JSON.

Put `~/.devbox` under git if you want to version your machine state.

---

## CLI usage

```
devbox [--config DIR] bootstrap           # full setup (safe to re-run)
devbox [--config DIR] brew                # install all formulae & casks from config
devbox [--config DIR] brew <name>         # install one package; auto-detect formula/cask; persist to config
devbox [--config DIR] asdf                # install all asdf tools from config
devbox [--config DIR] asdf <tool> <ver>   # install one tool@version (use 'latest'); persist to config
devbox [--config DIR] shell               # zsh/oh-my-zsh/agnoster wiring (+direnv hook)
devbox [--config DIR] apps                # first app launch for registrations (docker, forti)
devbox [--config DIR] doctor [--dry-run]  # print configured vs installed (no system calls in --dry-run)
devbox version                            # show version information
devbox help
```

Hidden helper:

```
devbox --completion zsh|bash              # print completion script to stdout
```

---

## Examples

**Apply everything defined in your configs:**

```bash
devbox brew
devbox asdf
```

**Install and persist a single package:**

```bash
devbox brew htop   # installs as formula, appends to ~/.devbox/brew-formulae.txt
devbox brew arc    # installs as cask,    appends to ~/.devbox/brew-casks.txt
```

**Install/pin an asdf tool version and persist it:**

```bash
devbox asdf nodejs latest     # resolves latest, installs, writes resolved version to JSON
devbox asdf golang 1.22.5     # installs & sets global, persists "1.22.5"
```

**Use a different config directory:**

```bash
devbox --config ~/work/devbox-config bootstrap
# or
DEVBOX_CONFIG_DIR=~/work/devbox-config devbox doctor
```

**Health check:**

```bash
devbox doctor          # compares config vs installed
devbox doctor --dry-run  # safe for CI, no brew/asdf calls
```

---

## Install locations & PATH

* **CLI**: `~/.local/bin/devbox` (installer ensures `~/.local/bin` is on PATH via `~/.zprofile`)
* **Configs**: `~/.devbox` (unless overridden)
* **Brew**: `/opt/homebrew` (Apple Silicon)
* **Casks**: `~/Applications` (user-scoped)
* **Completions**:

  * zsh → `~/.zsh/completions/_devbox` (installer wires `fpath` + `compinit` if missing)
  * bash → `~/.bash_completion.d/devbox`

---

## Tab completion

Zsh and bash completions are installed by the installer. Open a new terminal or:

```bash
source ~/.zprofile
source ~/.zshrc   # for zsh users
```

Verify:

```bash
type _devbox 2>/dev/null || echo "zsh completion not loaded"
```

You can also print completions directly:

```bash
devbox --completion zsh
devbox --completion bash
```

---

## Sync & upgrades

* **Change configs** in `~/.devbox`, then run:

  ```bash
  devbox brew
  devbox asdf
  ```
* **Upgrade devbox CLI**: re-run the installer one-liner (it overwrites `~/.local/bin/devbox` safely), or `curl` the raw `bin/devbox` manually into place.

Environment overrides supported by the installer:

* `REPO` (default: `phoenixTW/mac-devbox`)
* `REF` (auto-detected from source, fallback to latest release)
* `DEVBOX_CONFIG_DIR`, `ZSH_COMP_DIR`, `BASH_COMP_DIR`
* `DEVBOX_DEBUG` (set to `1` for debug output, hidden from users)

Example (pin to a specific version):

```bash
REF=0.0.1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/phoenixTW/mac-devbox/refs/tags/0.0.1/install.sh)"
```

---

## Troubleshooting

**Brew not found in some terminals**

* Add a fallback to `~/.zshrc`:

  ```zsh
  if ! command -v brew >/dev/null 2>&1 && [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
  ```

**Agnoster glyphs look broken**

* Ensure the terminal font is a Nerd font (installer adds `font-meslo-lg-nerd-font`); select it in Warp/Cursor.

**Docker/Forti prompts**

* macOS will request permissions on first use. `devbox apps` does a background first-open to help register components, but user approval is still required.

**Completions not loading**

* For zsh, ensure this block exists in `~/.zshrc`:

  ```zsh
  fpath=("$HOME/.zsh/completions" $fpath)
  autoload -Uz compinit
  [[ -n "$ZDOTDIR" ]] && compinit -d "$ZDOTDIR/.zcompdump" || compinit
  ```

---

## Project layout

```
mac-setup/
├─ bin/
│  └─ devbox                 # main CLI
├─ lib/
│  ├─ common.sh              # logging, config dir, JSON helpers, PATH setup
│  ├─ brew.sh                # Homebrew install/init + formula/cask helpers
│  ├─ asdf.sh                # asdf init, plugin mgmt, tool install/persist
│  └─ shell.sh               # Xcode CLT, zsh default, OMZ(agnoster), first-launch
├─ completions/
│  ├─ devbox.zsh             # zsh completion
│  └─ devbox.bash            # bash completion
├─ config.defaults/
│  ├─ brew-formulae.txt
│  ├─ brew-casks.txt
│  └─ asdf-tools.json
├─ install.sh                # curl | bash installer
└─ .github/workflows/
   ├─ shellcheck.yml
   └─ doctor-dry-run.yml
```

---

## Development

**Setup development environment:**

```bash
make dev-setup  # Installs bats and shellcheck
```

**Local development:**

```bash
make lint       # Run ShellCheck on all scripts
make test       # Run all tests
make check      # Run linting and tests
make install    # Install devbox locally for testing
```

**Testing:**

```bash
# Run all tests
bats tests/

# Run specific test suites
bats tests/unit/
bats tests/integration/

# Run individual tests
bats tests/unit/common.bats
```

**PR checklist:**

* Update `bin/devbox` **and** `completions/` when CLI changes
* Update `README.md` usage/examples
* Add tests for new functionality
* Keep changes **idempotent** (no sudo, no destructive defaults)
* CI (ShellCheck + Tests + Dry-Run) must pass

**Adding defaults**:

* Formula: edit `config.defaults/brew-formulae.txt`
* Cask: edit `config.defaults/brew-casks.txt`
* asdf tool: edit `config.defaults/asdf-tools.json` (add key; use specific version or `"latest"`). If a plugin needs a custom repo, map it in `lib/asdf.sh`.

**Release process (Automated):**

Releases are now automated via GitHub Actions using [bump-version](https://github.com/phoenixTW/bump-version):

1. **Create a PR** with your changes
2. **Use branch naming convention**:
   - `feature/description` → minor version bump (1.0.0 → 1.1.0)
   - `fix/description` → patch version bump (1.0.0 → 1.0.1)
   - `breaking/description` → major version bump (1.0.0 → 2.0.0)
3. **Merge the PR** to main branch
4. **GitHub Actions automatically**:
   - Generates new semantic version based on PR branch name
   - Updates version in `lib/common.sh`
   - Creates and pushes a git tag
   - Creates a GitHub release with changelog
   - Uploads release assets

**Manual release (if needed):**
```bash
git tag -a "v1.0.0" -m "Release v1.0.0"
git push origin "v1.0.0"
```

---

## Security & scope

* HTTPS downloads only (GitHub tarball, Homebrew, oh-my-zsh installer)
* No `sudo` required for normal paths
* Writes limited to `~/.local/bin`, `~/.devbox`, `~/Applications`, and zsh dotfiles
* macOS permission prompts are expected for some apps (documented)

---

## Uninstall

This project is lightweight:

```bash
rm -f ~/.local/bin/devbox
rm -rf ~/.devbox
# Optional: remove completion files
rm -f ~/.zsh/completions/_devbox ~/.bash_completion.d/devbox
```

Brew/asdf packages were installed by package managers; remove them with `brew uninstall` / `brew uninstall --cask` / `asdf uninstall` as desired.

---

## License

MIT. Contributions welcome!
