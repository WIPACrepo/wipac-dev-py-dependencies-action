#!/bin/bash
set -euo pipefail
sleep 0.1 && echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "$(basename "$0")..." && echo

########################################################################
#
# Install Podman from 'podman-static' release (fast, no apt, no checksum)
# https://github.com/mgoltzsche/podman-static
#
# Requires: PODMAN_STATIC_VERSION (e.g. v5.6.1)
#
########################################################################

if [[ -z ${PODMAN_STATIC_VERSION:-} ]]; then
    echo "::error:: Environment variable PODMAN_STATIC_VERSION is required (e.g. v5.6.1)"
    exit 1
fi

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

# Build URL for tarball
if [[ ${PODMAN_STATIC_VERSION} == "latest" ]]; then
    BASE_URL="https://github.com/mgoltzsche/podman-static/releases/latest/download"
else
    BASE_URL="https://github.com/mgoltzsche/podman-static/releases/download/${PODMAN_STATIC_VERSION}"
fi
TARBALL="podman-linux-${PKG_ARCH}.tar.gz"

echo "Fetching podman-static ${PODMAN_STATIC_VERSION} for ${PKG_ARCH}..."
set -x
curl -fsSL -o "${WORKDIR}/${TARBALL}" "${BASE_URL}/${TARBALL}"
set +x

echo "Extracting and installing to /usr/local and /etc/containers..."
tar -xzf "${WORKDIR}/${TARBALL}" -C "${WORKDIR}"
ROOT_DIR="${WORKDIR}/podman-linux-${PKG_ARCH}"

# Binaries & libs
sudo cp -r "${ROOT_DIR}/usr/"* /usr/local/

# Default configs (if present)
if [[ -d "${ROOT_DIR}/etc" ]]; then
    sudo mkdir -p /etc/containers
    sudo cp -r "${ROOT_DIR}/etc/"* /etc/containers/ || true
fi

echo "Installed binaries (if present):"
command -v podman || true
command -v buildah || true
command -v conmon || true
command -v runc || true
command -v netavark || true
command -v aardvark-dns || true

echo
podman --version

sleep 0.1 && echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
