# Codet

Unofficial build of [VSCodium](https://github.com/VSCodium/vscodium) that follows the XDG base directory spec.

| What | Location |
|---|---|
| settings, state, `argv.json`, `policy.json` | `$XDG_CONFIG_HOME/Codet` (`~/.config/Codet`) |
| extensions | `$XDG_DATA_HOME/Codet/extensions` (`~/.local/share/Codet/extensions`) |
| logs | `$XDG_STATE_HOME/Codet` (`~/.local/state/Codet`) |

Known leftovers still under `~/.codet`: agent sandbox tmp dir.

## Install (Debian / Ubuntu, amd64)

```sh
sudo curl -fsSL https://github.com/todouu/codet/releases/download/apt-repo/codet-archive-keyring.asc \
  -o /etc/apt/keyrings/codet.asc
echo "deb [signed-by=/etc/apt/keyrings/codet.asc] https://github.com/todouu/codet/releases/download/apt-repo ./" \
  | sudo tee /etc/apt/sources.list.d/codet.list
sudo apt update && sudo apt install codet
```

Updates then arrive through `apt upgrade`.

## How it works

- `.github/workflows/codet-release.yml` (every 6h): reads the VS Code version pinned by upstream VSCodium,
  merges upstream master at build time, applies `codet/product.overlay.json` and `patches/user/*.patch`,
  builds the deb, creates a GitHub release and rebuilds the signed flat APT repo (assets of the `apt-repo` release).
- `.github/workflows/codet-sync.yml` (daily): best-effort merge of upstream into master.
- Our changes: `patches/user/` (XDG paths, deb without Microsoft apt repo), `codet/`.
- If an upstream VS Code update breaks a patch the build fails; refresh the patch.
