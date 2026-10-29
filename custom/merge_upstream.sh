#!/usr/bin/env bash
# Merge VSCodium/vscodium into the current branch.
# Usage: custom/merge_upstream.sh [upstream-sha-or-ref]   (default: upstream/master)
# Upstream's own workflows are dropped: this fork only uses .github/workflows/custom-*.yml.
set -euo pipefail

TARGET="${1:-}"
git config user.name  "code-bot"
git config user.email "code-bot@users.noreply.github.com"

git remote get-url upstream >/dev/null 2>&1 || git remote add upstream https://github.com/VSCodium/vscodium.git
git fetch --no-tags upstream master
[[ -n "${TARGET}" ]] || TARGET="upstream/master"

git merge --no-edit "${TARGET}" || true

# Remove every workflow that is not ours (also resolves modify/delete conflicts).
git ls-files -z -- .github/workflows | { grep -zv '/custom-' || true; } | xargs -0 -r git rm -q -f --ignore-unmatch --

if [[ -n "$(git diff --name-only --diff-filter=U)" ]]; then
  echo "::error::Merge conflicts with upstream, manual resolution needed:" >&2
  git diff --name-only --diff-filter=U >&2
  exit 1
fi

if [[ -f .git/MERGE_HEAD ]]; then
  git commit -q --no-edit
elif ! git diff --cached --quiet; then
  git commit -q -m "chore: drop upstream workflows"
fi
git log --oneline -3
