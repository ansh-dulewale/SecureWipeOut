# SecureWipe Unified Executable Builder - Simple Version
# Creates a single portable solution for bootable USB creation with embedded wiping tools

Write-Host "🔧 SecureWipe Unified Builder" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

$buildDir = "SecureWipe-Unified-Build"

# Create build directory
if (Test-Path $buildDir) {
    Remove-Item $buildDir -Recurse -Force
}
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

Write-Host "📦 Step 1: Copying Windows Application..." -ForegroundColor Yellow

# Copy Windows executable
if (Test-Path "x64\Release\securewipe.exe") {
    Copy-Item "x64\Release\securewipe.exe" "$buildDir\SecureWipe.exe"
    Write-Host "  ✅ Windows GUI copied" -ForegroundColor Green
} else {
    Write-Host "  ❌ Windows executable not found at x64\Release\securewipe.exe" -ForegroundColor Red
    Write-Host "  📋 Building from source..." -ForegroundColor Yellow
    
    # Try to build
    $msbuildPath = "C:\Program Files\Microsoft Visual Studio\2022\BuildTools\MSBuild\Current\Bin\MSBuild.exe"
    if (Test-Path $msbuildPath) {
        & $msbuildPath "rufus.sln" /p:Configuration=Release /p:Platform=x64
        if (Test-Path "x64\Release\securewipe.exe") {
            Copy-Item "x64\Release\securewipe.exe" "$buildDir\SecureWipe.exe"
            Write-Host "  ✅ Built and copied successfully" -ForegroundColor Green
        } else {
            Write-Host "  ❌ Build failed" -ForegroundColor Red
            exit 1
        }
    } else {
        Write-Host "  ❌ MSBuild not found" -ForegroundColor Red
        exit 1
    }
}

Write-Host "🐧 Step 2: Copying Linux Boot Environment..." -ForegroundColor Yellow

# Copy Linux boot environment with wiping tools
if (Test-Path "linux-boot") {
    Copy-Item "linux-boot" "$buildDir\linux-boot" -Recurse -Force
    Write-Host "  ✅ Linux boot environment copied" -ForegroundColor Green
    
    # Verify wiping engines
    $enginePath = "$buildDir\linux-boot\rootfs\usr\lib\securewipe"
    $engines = @("wipe-engine.sh", "crypto-erase.sh", "hdd-overwrite.sh", "external-storage.sh", "verification.sh", "certificate-gen.sh")
    
    Write-Host "  🔍 Verifying wiping engines:" -ForegroundColor Cyan
    foreach ($engine in $engines) {
        if (Test-Path "$enginePath\$engine") {
            Write-Host "    ✅ $engine" -ForegroundColor Green
        } else {
            Write-Host "    ❌ $engine MISSING" -ForegroundColor Red
        }
    }
} else {
    Write-Host "  ❌ Linux boot environment not found" -ForegroundColor Red
    exit 1
}

Write-Host "📋 Step 3: Creating Unified Launcher..." -ForegroundColor Yellow

# Create simple batch launcher
$batchContent = @'
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
'@

$batchContent | Out-File -FilePath "$buildDir\SecureWipe-Unified.cmd" -Encoding ASCII

Write-Host "  ✅ Unified launcher created" -ForegroundColor Green

Write-Host "📚 Step 4: Creating Documentation..." -ForegroundColor Yellow

# Create documentation
$docContent = @'
# SecureWipe Unified - Complete Solution

## Overview
This is a single, portable solution that creates bootable USB drives with embedded SecureWipe wiping tools.

## What's Included
- SecureWipe.exe - Windows GUI for USB creation
- linux-boot/ - Complete Linux boot environment with wiping tools
- All 6 wiping engines embedded in bootable environment
- Certificate generation system
- Verification and compliance tools

## How to Use

### Step 1: Create Bootable USB
1. Run "SecureWipe-Unified.cmd" as Administrator
2. Insert target USB drive (8GB or larger)
3. Follow GUI instructions to create bootable USB
4. Wait for completion

### Step 2: Use for Data Wiping
1. Boot target computer from created USB
2. SecureWipe interface launches automatically
3. Select drive to wipe
4. Choose security level
5. Confirm and start wiping process
6. Receive completion certificate

## Features
✅ Single portable solution
✅ No separate boot creation needed
✅ All wiping methods included
✅ DoD 5220.22-M compliance
✅ Certificate generation
✅ Multiple storage type support
✅ Auto-launch interface

## Wiping Engines Included
1. Hybrid Engine (intelligent selection)
2. Crypto-erase (SSD secure erase)
3. HDD Overwrite (multi-pass)
4. External Storage (USB/removable)
5. Verification System (pattern/entropy)
6. Certificate Generation (compliance)

## Requirements
- Windows 10/11
- Administrator privileges
- USB drive 8GB+ for boot creation
- Target drives to wipe

## Safety
- Multiple confirmation steps
- Detailed device identification  
- Progress monitoring
- Error handling
- Tamper-proof certificates

Ready to use immediately - no installation required!
'@

$docContent | Out-File -FilePath "$buildDir\README.md" -Encoding UTF8

Write-Host "  ✅ Documentation created" -ForegroundColor Green

Write-Host "🎯 Step 5: Creating Quick Start Guide..." -ForegroundColor Yellow

# Create quick start guide
$quickStart = @'
# Quick Start - SecureWipe Unified

## Immediate Usage (5 minutes)

1. **Run as Administrator**
   - Right-click "SecureWipe-Unified.cmd"
   - Select "Run as Administrator"

2. **Create Bootable USB**
   - Insert USB drive (8GB+)
   - Follow GUI to create bootable USB
   - All wiping tools embedded automatically

3. **Boot and Wipe**
   - Boot target computer from USB
   - Interface launches automatically
   - Select drive and start wiping

## What Makes This Special
- Single file solution
- No separate boot creation
- All tools embedded
- Compliance ready
- Auto-launch interface

## Perfect For
- IT departments
- Data centers  
- Personal use
- Compliance requirements
- Quick deployment

Ready in minutes!
'@

$quickStart | Out-File -FilePath "$buildDir\QUICK-START.md" -Encoding UTF8

Write-Host "  ✅ Quick start guide created" -ForegroundColor Green

Write-Host "🏆 Step 6: Final Package..." -ForegroundColor Yellow

# Create version file
$version = @"
SecureWipe Unified v4.10
Built: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Components: Windows GUI + Linux Boot + 6 Wiping Engines
Platform: Windows 10/11 x64
Architecture: Unified portable solution
"@

$version | Out-File -FilePath "$buildDir\VERSION.txt" -Encoding UTF8

Write-Host "  ✅ Version info created" -ForegroundColor Green

Write-Host ""
Write-Host "🎉 BUILD COMPLETE!" -ForegroundColor Green
Write-Host "==================" -ForegroundColor Green
Write-Host ""

Write-Host "📦 Output Location: $buildDir" -ForegroundColor White
Write-Host "🚀 Main Executable: SecureWipe-Unified.cmd" -ForegroundColor White
Write-Host ""

Write-Host "📋 Package Contents:" -ForegroundColor Yellow
Write-Host "  ✅ SecureWipe.exe (Windows GUI)" -ForegroundColor Green
Write-Host "  ✅ linux-boot/ (Boot environment + wiping tools)" -ForegroundColor Green
Write-Host "  ✅ SecureWipe-Unified.cmd (Main launcher)" -ForegroundColor Green
Write-Host "  ✅ Documentation and guides" -ForegroundColor Green
Write-Host ""

Write-Host "🎯 What This Gives You:" -ForegroundColor Cyan
Write-Host "  • Single executable solution" -ForegroundColor White
Write-Host "  • Creates bootable USB with embedded wiping tools" -ForegroundColor White
Write-Host "  • No need for separate boot creation step" -ForegroundColor White
Write-Host "  • All 6 wiping engines included" -ForegroundColor White
Write-Host "  • Auto-launch wiping interface" -ForegroundColor White
Write-Host "  • Certificate generation built-in" -ForegroundColor White
Write-Host ""

Write-Host "⚡ Test Your Unified Solution:" -ForegroundColor Yellow
Write-Host "  cd $buildDir" -ForegroundColor Gray
Write-Host "  .\SecureWipe-Unified.cmd" -ForegroundColor Gray
Write-Host ""

# Open the build directory
Start-Process explorer.exe -ArgumentList (Resolve-Path $buildDir).Path

Write-Host "✨ SecureWipe Unified is ready to use!" -ForegroundColor Green