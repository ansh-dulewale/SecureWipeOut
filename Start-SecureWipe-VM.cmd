@echo off
title SecureWipe VirtualBox Test
color 0B

echo.
echo ========================================================
echo   SecureWipe VirtualBox Test Environment
echo ========================================================
echo.

echo [INFO] Starting SecureWipe Test VM...
echo [INFO] VM Configuration:
echo   * Name: SecureWipe-Test
echo   * Memory: 4GB RAM
echo   * Disk: 10GB virtual disk (safe for wiping)
echo   * USB: Enabled for SecureWipe boot
echo.

echo [INSTRUCTIONS] Follow these steps:
echo.
echo   1. Create SecureWipe USB first (if not done):
echo      - Run SecureWipe-Unified.cmd as Administrator
echo      - Insert USB drive and create bootable USB
echo.
echo   2. After VM starts:
echo      - Go to VM menu: Devices → USB
echo      - Select your SecureWipe USB drive
echo      - This connects USB to the VM
echo.
echo   3. Boot from USB:
echo      - Restart VM (Machine → Reset)
echo      - VM will boot from SecureWipe USB
echo      - SecureWipe interface will auto-launch
echo.
echo   4. Test wiping safely:
echo      - Select the 10GB virtual disk
echo      - Choose security level
echo      - Start wiping (completely safe!)
echo.

pause

echo [INFO] Launching VirtualBox VM...
"C:\Program Files\Oracle\VirtualBox\VirtualBox.exe" --startvm "SecureWipe-Test"