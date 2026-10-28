#!/usr/bin/env bash
# Rebuild the flat APT repository stored as assets of the "apt-repo" GitHub release.
# Env: GH_TOKEN, GITHUB_REPOSITORY. Arg 1: directory with the newly built .deb files.
# Needs: gh, dpkg-dev (dpkg-scanpackages), apt-utils (apt-ftparchive), gpg with the signing key imported.
set -euo pipefail

NEW_DEBS="$(realpath "${1:?directory with new .deb files}")"
TAG="apt-repo"
KEEP="${KEEP_VERSIONS:-3}"
KEYRING_SRC="$(realpath "$(dirname "$0")/apt/codet-archive-keyring.asc")"
WORK="$(mktemp -d)"
cd "${WORK}"

gh release view "${TAG}" --repo "${GITHUB_REPOSITORY}" >/dev/null 2>&1 || \
  gh release create "${TAG}" --repo "${GITHUB_REPOSITORY}" --latest=false \
    --title "Codet APT repository" \
    --notes "Flat APT repository for Codet. Do not download manually, see CODET.md for the apt setup."

gh release download "${TAG}" --repo "${GITHUB_REPOSITORY}" --pattern '*.deb' --dir . || true
cp -f "${NEW_DEBS}"/*.deb .

# keep only the newest $KEEP versions per architecture
for arch in amd64 arm64; do
  ls -1 codet_*_"${arch}".deb 2>/dev/null | sort -V | head -n "-${KEEP}" | xargs -r rm -fv
done

dpkg-scanpackages --multiversion . /dev/null > Packages
gzip -9kf Packages
apt-ftparchive \
  -o APT::FTPArchive::Release::Origin=Codet \
  -o APT::FTPArchive::Release::Label=Codet \
  release . > Release.new
mv Release.new Release

FPR="$(gpg --list-secret-keys --with-colons | awk -F: '/^fpr/{print $10; exit}')"
gpg --batch --yes --pinentry-mode loopback --local-user "${FPR}" --clearsign   -o InRelease   Release
gpg --batch --yes --pinentry-mode loopback --local-user "${FPR}" --armor --detach-sign -o Release.gpg Release
cp "${KEYRING_SRC}" codet-archive-keyring.asc

FILES=(Packages Packages.gz Release InRelease Release.gpg codet-archive-keyring.asc *.deb)
gh release upload "${TAG}" --repo "${GITHUB_REPOSITORY}" --clobber "${FILES[@]}"

# delete assets that are no longer part of the repo
gh release view "${TAG}" --repo "${GITHUB_REPOSITORY}" --json assets --jq '.assets[].name' | while read -r name; do
  printf '%s\n' "${FILES[@]}" | grep -qxF "${name}" || gh release delete-asset "${TAG}" "${name}" --repo "${GITHUB_REPOSITORY}" -y
done
echo "APT repo updated: $(ls -1 *.deb | tr '\n' ' ')"
