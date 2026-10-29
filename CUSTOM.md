# Code (XDG build)

Unofficial build of [VSCodium](https://github.com/VSCodium/vscodium) that follows the XDG base directory spec.
It installs into `~/.local`, no root needed.

| What | Location |
|---|---|
| settings, `argv.json`, `policy.json` | `$XDG_CONFIG_HOME/Code` (`~/.config/Code`) |
| extensions, shared data | `$XDG_DATA_HOME/Code` (`~/.local/share/Code`) |
| logs, terminal sandbox tmp | `$XDG_STATE_HOME/Code` (`~/.local/state/Code`) |
| program | `~/.local/code.app`, command `~/.local/bin/code` |

Note: the config directory name `Code` is the same as official VS Code's, so both would share settings if you install both.

## Install / update / remove

```sh
curl -fsSL https://raw.githubusercontent.com/todouu/code/master/custom/install.sh | sh
code-update                      # update later
sh install.sh --uninstall        # remove the program, user data is kept
```

## Sandbox

Without root the Electron `chrome-sandbox` cannot be SUID, so Electron needs unprivileged user namespaces.
On Ubuntu 24.04 (`kernel.apparmor_restrict_unprivileged_userns=1`) start-up can fail.
Options: `CODE_NO_SANDBOX=1 sh install.sh` (launches with `--no-sandbox`, less secure), or add an AppArmor profile (needs sudo).

## How it works

- `.github/workflows/custom-release.yml` (every 6h): reads the VS Code version pinned by upstream VSCodium,
  merges upstream master at build time, applies `custom/product.overlay.json` and `patches/user/*.patch`,
  builds a tar.gz and publishes a GitHub release.
- `.github/workflows/custom-sync.yml` (daily): best-effort merge of upstream into master.
- If an upstream VS Code update breaks a patch the build fails; refresh the patch.
