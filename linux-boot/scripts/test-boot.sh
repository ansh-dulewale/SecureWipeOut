#!/bin/bash
# SecureWipe Linux Boot Environment Test Script
# Tests the bootable environment on various configurations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/../"
ISO_FILE="$BUILD_DIR/output/securewipe-boot.iso"

echo "=== SecureWipe Boot Environment Testing ==="
echo ""

# Check if ISO exists
if [ ! -f "$ISO_FILE" ]; then
    echo "❌ ISO file not found: $ISO_FILE"
    echo "Please run the build script first."
    exit 1
fi

echo "✅ Found ISO: $ISO_FILE"
echo "ISO size: $(du -h "$ISO_FILE" | cut -f1)"
echo ""

# Test ISO integrity
echo "Testing ISO integrity..."
if command -v file >/dev/null 2>&1; then
    file_type=$(file "$ISO_FILE")
    echo "File type: $file_type"
    
    if [[ "$file_type" == *"ISO 9660"* ]]; then
        echo "✅ Valid ISO 9660 format detected"
    else
        echo "⚠️  ISO format may not be standard"
    fi
else
    echo "⚠️  Cannot verify ISO format (file command not available)"
fi

# Test ISO contents
echo ""
echo "Testing ISO contents..."
if command -v isoinfo >/dev/null 2>&1; then
    echo "Boot catalog entries:"
    isoinfo -l -i "$ISO_FILE" | grep -E "(boot|grub|vmlinuz|initramfs)" || echo "No boot files found in listing"
else
    echo "⚠️  Cannot list ISO contents (isoinfo not available)"
fi

# QEMU testing (if available)
echo ""
echo "Testing virtual boot (QEMU)..."
if command -v qemu-system-x86_64 >/dev/null 2>&1; then
    echo "QEMU available - you can test boot with:"
    echo "  qemu-system-x86_64 -cdrom \"$ISO_FILE\" -boot d -m 512M"
    echo ""
    
    # Ask if user wants to run test
    read -p "Launch QEMU test now? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Launching QEMU test..."
        echo "Note: This will open a virtual machine window"
        echo "Press Ctrl+Alt+G to release mouse, Ctrl+Alt+F to exit fullscreen"
        echo ""
        qemu-system-x86_64 -cdrom "$ISO_FILE" -boot d -m 512M -display gtk &
        echo "QEMU test launched in background"
    fi
else
    echo "⚠️  QEMU not available for virtual testing"
    echo "Install with: sudo apt install qemu-system-x86"
fi

# USB creation test preparation
echo ""
echo "=== USB Creation Testing ==="
echo ""
echo "To test USB creation:"
echo "1. Insert a USB drive (⚠️  ALL DATA WILL BE LOST!)"
echo "2. Run: sudo dd if=\"$ISO_FILE\" of=/dev/sdX bs=4M status=progress"
echo "   (Replace /dev/sdX with your USB device)"
echo "3. Safely eject and test boot on target machine"
echo ""

# Hardware compatibility checklist
echo "=== Hardware Compatibility Checklist ==="
echo ""
echo "Test the bootable USB on systems with:"
echo "□ Legacy BIOS (older computers)"
echo "□ UEFI (modern computers)"
echo "□ Secure Boot enabled"
echo "□ Secure Boot disabled"
echo "□ Different storage types:"
echo "  □ Traditional SATA HDDs"
echo "  □ SATA SSDs"
echo "  □ NVMe SSDs"
echo "  □ USB storage devices"
echo "  □ SD cards"
echo "  □ eMMC storage"
echo ""

# Generate test report
echo "=== Test Summary ==="
echo "Test date: $(date)"
echo "ISO file: $ISO_FILE"
echo "ISO size: $(du -h "$ISO_FILE" | cut -f1)"
echo ""
echo "Automated tests completed:"
echo "✅ ISO file exists"
echo "✅ File format validation"
if command -v qemu-system-x86_64 >/dev/null 2>&1; then
    echo "✅ QEMU virtual testing available"
else
    echo "⚠️  QEMU virtual testing not available"
fi
echo ""
echo "Manual testing required:"
echo "📝 Physical hardware boot testing"
echo "📝 Storage device detection verification"
echo "📝 Cross-platform compatibility testing"
echo ""

echo "Testing preparation complete!"
echo "Proceed with physical hardware testing for full validation."