# SecureWipe Linux Boot Environment

This directory contains the custom Linux distribution for SecureWipe's bootable USB functionality.

## Directory Structure

- `rootfs/` - Root filesystem for the Linux environment
- `iso/` - ISO image building directory  
- `scripts/` - Build and configuration scripts
- `kernel/` - Custom kernel and modules
- `initramfs/` - Initial RAM filesystem

## Build Requirements

- Alpine Linux base system
- Kernel build tools
- ISO creation utilities (genisoimage/mkisofs)
- Hardware drivers for storage devices

## Boot Process

1. BIOS/UEFI loads the bootloader (GRUB/SYSLINUX)
2. Kernel and initramfs are loaded into memory
3. SecureWipe application auto-launches
4. User selects target drive for secure wiping
5. Wipe process executes with certificate generation

## Security Features

- Read-only root filesystem
- Tamper-evident logging
- Cryptographic certificate signing
- Secure storage device detection