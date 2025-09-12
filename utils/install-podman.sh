#!/bin/bash
set -euo pipefail
sleep 0.1 && echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "$(basename "$0")..." && echo
set -e

########################################################################
#
# Install Podman from 'podman-static' release (fast, no apt)
# - Repo: https://github.com/mgoltzsche/podman-static
# - Default version can be overridden via PODMAN_STATIC_VERSION env var
#
########################################################################

# --- config ------------------------------------------------------------------
PODMAN_STATIC_VERSION="${PODMAN_STATIC_VERSION:-v5.6.1}" # pin a known-good release
WORKDIR="$(mktemp -d)"
trap 'rm -rf "${WORKDIR}"' EXIT

# Map kernel arch to release artifact arch
ARCH="$(uname -m)"
case "${ARCH}" in
    x86_64) PKG_ARCH="amd64" ;;
    aarch64) PKG_ARCH="arm64" ;;
    *)
        echo "::error::Unsupported architecture: ${ARCH}"
        exit 1
        ;;
esac

TARBALL="podman-linux-${PKG_ARCH}.tar.gz"
BASE_URL="https://github.com/mgoltzsche/podman-static/releases/download/${PODMAN_STATIC_VERSION}"

# --- download + verify --------------------------------------------------------
echo "Fetching podman-static ${PODMAN_STATIC_VERSION} for ${PKG_ARCH}..."
set -x
curl -fsSL -o "${WORKDIR}/${TARBALL}" "${BASE_URL}/${TARBALL}"
curl -fsSL -o "${WORKDIR}/${TARBALL}.sha256" "${BASE_URL}/${TARBALL}.sha256"
set +x

# normalize checksum file format for sha256sum -c
if ! grep -q "${TARBALL}" "${WORKDIR}/${TARBALL}.sha256"; then
    # If file only contains the hash, append filename
    HASH="$(cat "${WORKDIR}/${TARBALL}.sha256" | tr -d ' \n\r')"
    echo "${HASH}  ${TARBALL}" >"${WORKDIR}/${TARBALL}.sha256"
fi

(
    cd "${WORKDIR}"
    sha256sum -c "${TARBALL}.sha256"
)

# --- install ------------------------------------------------------------------
echo "Extracting and installing to /usr/local ..."
tar -xzf "${WORKDIR}/${TARBALL}" -C "${WORKDIR}"

# The archive layout is podman-linux-${PKG_ARCH}/usr/... and possibly etc/...
ROOT_DIR="${WORKDIR}/podman-linux-${PKG_ARCH}"

# Binaries & libs
sudo cp -r "${ROOT_DIR}/usr/"* /usr/local/

# Default container configs (if present)
if [ -d "${ROOT_DIR}/etc" ]; then
    sudo mkdir -p /etc/containers
    sudo cp -r "${ROOT_DIR}/etc/"* /etc/containers/
fi

# --- sanity check -------------------------------------------------------------
echo "Installed binaries:"
command -v podman || true
command -v buildah || true
command -v runc || true
command -v conmon || true
command -v netavark || true
command -v aardvark-dns || true

echo
podman --version || {
    echo "::error::Podman did not install correctly"
    exit 1
}

# Note: For rootless performance, fuse-overlayfs may be used automatically by static builds.
# Networking uses netavark/aardvark-dns from the archive. Systemd integration is not provided.

sleep 0.1 && echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
