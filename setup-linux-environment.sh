#!/bin/bash
# SecureWipe Linux Boot Environment Build Script
# Makes all scripts executable and sets proper permissions

set -e

echo "🔧 Setting up SecureWipe Linux Boot Environment..."

# Base directories
ROOTFS_DIR="linux-boot/rootfs"
LIB_DIR="$ROOTFS_DIR/usr/lib/securewipe"
BIN_DIR="$ROOTFS_DIR/usr/bin"
SERVICE_DIR="$ROOTFS_DIR/etc/init.d"

# Make all scripts executable
echo "📜 Setting executable permissions..."

# Wiping engine scripts
chmod +x "$LIB_DIR/wipe-engine.sh"
chmod +x "$LIB_DIR/crypto-erase.sh"
chmod +x "$LIB_DIR/hdd-overwrite.sh"
chmod +x "$LIB_DIR/external-storage.sh"
chmod +x "$LIB_DIR/verification.sh"
chmod +x "$LIB_DIR/certificate-gen.sh"

# Main launcher
chmod +x "$BIN_DIR/securewipe-launcher"

# Services
chmod +x "$SERVICE_DIR/hardware-detect"

# Hardware detection script
chmod +x "$ROOTFS_DIR/usr/sbin/detect-hardware"

echo "✅ All scripts are now executable"

# Create necessary directories
echo "📁 Creating runtime directories..."
mkdir -p "$ROOTFS_DIR/var/log/securewipe"
mkdir -p "$ROOTFS_DIR/tmp/securewipe-certificates"
mkdir -p "$ROOTFS_DIR/tmp/securewipe-verification"

echo "✅ Runtime directories created"

# Set proper permissions
echo "🔐 Setting security permissions..."

# Sensitive directories (root only)
chmod 700 "$ROOTFS_DIR/var/log/securewipe"
chmod 700 "$ROOTFS_DIR/tmp/securewipe-certificates"

# Library scripts (read-execute for all)
chmod 755 "$LIB_DIR"/*.sh

# Main executable (execute for all)
chmod 755 "$BIN_DIR/securewipe-launcher"

echo "✅ Security permissions set"

# Validate all required components
echo "🔍 Validating SecureWipe components..."

COMPONENTS=(
    "$LIB_DIR/wipe-engine.sh"
    "$LIB_DIR/crypto-erase.sh"
    "$LIB_DIR/hdd-overwrite.sh"
    "$LIB_DIR/external-storage.sh"
    "$LIB_DIR/verification.sh"
    "$LIB_DIR/certificate-gen.sh"
    "$BIN_DIR/securewipe-launcher"
    "$SERVICE_DIR/hardware-detect"
    "$ROOTFS_DIR/usr/sbin/detect-hardware"
)

MISSING_COMPONENTS=()
for component in "${COMPONENTS[@]}"; do
    if [ ! -f "$component" ]; then
        MISSING_COMPONENTS+=("$component")
    fi
done

if [ ${#MISSING_COMPONENTS[@]} -eq 0 ]; then
    echo "✅ All SecureWipe components are present"
else
    echo "❌ Missing components:"
    for missing in "${MISSING_COMPONENTS[@]}"; do
        echo "  - $missing"
    done
    exit 1
fi

# Test script syntax
echo "🧪 Testing script syntax..."

for script in "$LIB_DIR"/*.sh "$BIN_DIR/securewipe-launcher"; do
    if ! bash -n "$script" 2>/dev/null; then
        echo "❌ Syntax error in: $script"
        exit 1
    fi
done

echo "✅ All scripts have valid syntax"

echo ""
echo "🎉 SecureWipe Linux Boot Environment setup completed successfully!"
echo ""
echo "Components installed:"
echo "• Hybrid Wiping Engine (intelligent method selection)"
echo "• SSD Cryptographic Erase (NVMe Format, ATA Secure Erase)"
echo "• HDD Secure Overwrite (with HPA handling)"
echo "• External Storage Handler (USB, SD cards)"
echo "• Comprehensive Verification System"
echo "• Tamper-proof Certificate Generation"
echo "• Hardware Detection Service"
echo "• Professional User Interface"
echo ""
echo "Next steps:"
echo "1. Create bootable USB using Windows SecureWipe application"
echo "2. Boot from USB to launch SecureWipe environment"
echo "3. Follow on-screen instructions for secure data wiping"
echo ""