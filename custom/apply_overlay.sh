#!/usr/bin/env bash
# Merge custom/product.overlay.json over the root product.json.
# prepare_vscode.sh merges the root product.json last, so these values win
# over the VSCodium defaults without editing any upstream-owned line.
set -euo pipefail
cd "$(dirname "$0")/.."
jq -s '.[0] * .[1]' product.json custom/product.overlay.json > product.json.tmp
mv product.json.tmp product.json
jq '{nameShort, applicationName, dataFolderName, linuxIconName}' product.json
