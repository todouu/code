# Code

An unofficial, XDG-compliant build of [VSCodium](https://github.com/VSCodium/vscodium), installed into your home directory without root.

## This is a fork

This repository is a fork of [VSCodium/vscodium](https://github.com/VSCodium/vscodium). VSCodium itself is a set of build scripts and patches that turn [Microsoft's `vscode`](https://github.com/microsoft/vscode) source into freely-licensed binaries. This fork keeps all of that and changes how the result stores its files and how it is distributed.

Why: VSCodium and VS Code put extensions, `argv.json` and other data in dotfolders directly under `$HOME` (`~/.vscode-oss`, `~/.vscode-oss-shared`, `~/.vscodium`). This fork moves them to the XDG base directories.

## What is changed

### 1. XDG base directories (`patches/user/10-xdg-base-dirs.patch`)

| Data | Location |
|---|---|
| settings, `argv.json`, `policy.json` | `$XDG_CONFIG_HOME/Code` (default `~/.config/Code`) |
| extensions, shared data, agent plugins, CLI data (`code-tunnel`) | `$XDG_DATA_HOME/Code` (default `~/.local/share/Code`) |
| logs, terminal/MCP sandbox temp files | `$XDG_STATE_HOME/Code` (default `~/.local/state/Code`) |

Relative `XDG_*` values are ignored, as the spec requires. The patch touches the TypeScript environment service, the Electron main process (`argv.json`, with recursive creation of the parent directory) and the Rust CLI (`cli/src/state.rs`). Logs already went to `$XDG_STATE_HOME` in VSCodium (`patches/linux/00-log-use-state-home.patch`).

### 2. Branding (`custom/product.overlay.json`)

Product name `Code`, command `code`, URL protocol `code`. It is merged over `product.json` at build time, so no upstream-owned line is edited.

### 3. Distribution

- The Linux build is a tar.gz (x64 only), published as a GitHub Release.
- `custom/install.sh` installs it under `~/.local`. There is no deb, rpm or apt repository.
- In-app updates are disabled (`DISABLE_UPDATE=yes`). Updating is done with `code-update`.

### 4. CI (`.github/workflows/custom-*.yml`)

- `custom-release.yml` runs every 6 hours. It reads the VS Code version pinned by upstream VSCodium, merges upstream `master` at build time, applies the overlay and `patches/user/*.patch`, builds, and publishes a release. It only builds when that version has no release yet (or when forced).
- `custom-sync.yml` runs daily and tries to merge upstream `master` into this repository's `master`. It is best effort.
- Upstream's own workflows were removed. `custom/merge_upstream.sh` removes them again after every merge and keeps this README when it conflicts.

## Install

x64 Linux only.

```sh
curl -fsSL https://raw.githubusercontent.com/todouu/code/master/custom/install.sh | sh
```

This puts the program in `~/.local/code.app`, the command in `~/.local/bin/code`, and adds a desktop entry and icon under `~/.local/share`. Make sure `~/.local/bin` is in your `PATH`.

Update:

```sh
code-update
```

Uninstall (your settings and extensions are kept):

```sh
curl -fsSL https://raw.githubusercontent.com/todouu/code/master/custom/install.sh | sh -s -- --uninstall
```

Environment variables for `install.sh`: `CODE_REPO` (default `todouu/code`), `CODE_PREFIX` (default `~/.local`), `CODE_NO_SANDBOX=1`.

### Sandbox

Electron's `chrome-sandbox` cannot be root-owned and SUID in a home-directory install, so Electron falls back to unprivileged user namespaces. Systems that restrict them (for example Ubuntu 24.04 with `kernel.apparmor_restrict_unprivileged_userns=1`) fail at startup with a SUID sandbox error. `install.sh` warns when it detects this. You can then:

- reinstall with `CODE_NO_SANDBOX=1` to launch with `--no-sandbox` (less secure), or
- add an AppArmor profile for `~/.local/code.app/code` (needs sudo).

## Known limitations

- The config directory `Code` has the same name as official VS Code's. If both are installed they share settings.
- Only x64 is built.
- If an upstream VS Code update breaks one of the patches, the build fails and no new release appears until the patch is refreshed.
- The icon is still VSCodium's.
- `~/.cache/Microsoft/DeveloperTools/deviceid` is created by an upstream VS Code component. It is XDG-compliant but not renamed.
- Remote-server and agent-host code paths that use `serverDataFolderName` (`~/.code-server`) are not changed.
- Existing data from `~/.config/VSCodium`, `~/.vscode-oss` or similar is not migrated.

## Upstream

For everything else (features, extensions, FAQ, troubleshooting) see the [VSCodium documentation](https://github.com/VSCodium/vscodium/tree/master/docs). Extensions come from [Open VSX](https://open-vsx.org). Both VSCodium and VS Code are MIT licensed; see `LICENSE`.
