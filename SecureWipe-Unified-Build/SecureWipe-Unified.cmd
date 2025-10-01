@echo off
title SecureWipe Unified - Bootable USB Creator with Embedded Wiping Tools
color 0B

echo.
echo ========================================================
echo   SecureWipe Unified v4.10
echo   Single Tool for Bootable USB + Data Wiping
echo ========================================================
echo.

REM Check administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [ERROR] Administrator privileges required
    echo Please right-click and select "Run as Administrator"
    pause
    exit /b 1
)

echo [INFO] SecureWipe Unified Features:
echo   * Creates bootable USB with integrated wiping tools
echo   * No separate boot USB creation needed
echo   * All 6 wiping engines embedded
echo   * Certificate generation included  
echo   * Auto-launch wiping interface
echo.

echo [INFO] Ready to create bootable SecureWipe USB
echo [WARNING] Target USB drive will be completely formatted
echo.

pause

echo [INFO] Launching SecureWipe GUI...
start "" "%~dp0SecureWipe.exe"

echo.
echo [INFO] Instructions:
echo   1. Insert target USB drive (8GB+ recommended)
echo   2. Select USB drive in the interface
echo   3. Click "Create Bootable USB" 
echo   4. Wait for completion
echo   5. Boot from created USB to access wiping tools
echo.

echo [INFO] The created USB will include:
echo   * Linux boot environment
echo   * All SecureWipe wiping engines
echo   * Certificate generation system
echo   * Verification tools
echo   * Auto-launch interface
echo.

pause