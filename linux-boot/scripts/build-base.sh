#!/bin/bash
# SecureWipe Linux Build Script
# Creates a custom Alpine Linux-based bootable environment

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/../"
ROOTFS_DIR="$BUILD_DIR/rootfs"
ISO_DIR="$BUILD_DIR/iso"

# Alpine Linux version and architecture
ALPINE_VERSION="3.19"
ALPINE_ARCH="x86_64"
ALPINE_MIRROR="https://dl-cdn.alpinelinux.org/alpine"

echo "=== SecureWipe Linux Build System ==="
echo "Building custom Alpine Linux ${ALPINE_VERSION} (${ALPINE_ARCH})"
echo "Build directory: $BUILD_DIR"

# Create necessary directories
mkdir -p "${ROOTFS_DIR}"/{bin,sbin,etc,proc,sys,dev,tmp,var,usr/{bin,sbin,lib},lib,boot}
mkdir -p "${ROOTFS_DIR}/etc"/{init.d,conf.d,securewipe}
mkdir -p "${ROOTFS_DIR}/var"/{cache,lib,log}
mkdir -p "${ISO_DIR}"/{boot,securewipe}

# Download Alpine Linux mini root filesystem if not exists
ALPINE_MINIROOTFS="alpine-minirootfs-${ALPINE_VERSION}.0-${ALPINE_ARCH}.tar.gz"
if [ ! -f "/tmp/$ALPINE_MINIROOTFS" ]; then
    echo "Downloading Alpine Linux mini root filesystem..."
    curl -L "${ALPINE_MIRROR}/v${ALPINE_VERSION}/releases/${ALPINE_ARCH}/${ALPINE_MINIROOTFS}" \
         -o "/tmp/$ALPINE_MINIROOTFS"
fi

# Extract Alpine base system
echo "Extracting Alpine Linux base system..."
sudo tar -xzf "/tmp/$ALPINE_MINIROOTFS" -C "$ROOTFS_DIR"

# Configure Alpine repositories
cat > "${ROOTFS_DIR}/etc/apk/repositories" << EOF
${ALPINE_MIRROR}/v${ALPINE_VERSION}/main
${ALPINE_MIRROR}/v${ALPINE_VERSION}/community
EOF

echo "Base Alpine Linux system prepared successfully!"
echo "Next: Configure auto-boot and SecureWipe application"