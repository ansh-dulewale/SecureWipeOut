# SecureWipe VirtualBox Setup & Testing Script
# Complete automated setup for testing SecureWipe in Oracle VirtualBox

Write-Host "🚀 SecureWipe VirtualBox Complete Setup" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

# Check if VirtualBox is installed
$VBoxManage = $null
$PossiblePaths = @(
    "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe",
    "C:\Program Files (x86)\Oracle\VirtualBox\VBoxManage.exe"
)

foreach ($path in $PossiblePaths) {
    if (Test-Path $path) {
        $VBoxManage = $path
        break
    }
}

if (-not $VBoxManage) {
    Write-Host "❌ Oracle VirtualBox not found!" -ForegroundColor Red
    Write-Host ""
    Write-Host "📥 Please install VirtualBox first:" -ForegroundColor Yellow
    Write-Host "   1. Download from: https://www.virtualbox.org/wiki/Downloads" -ForegroundColor White
    Write-Host "   2. Install 'VirtualBox for Windows hosts'" -ForegroundColor White
    Write-Host "   3. Install 'VirtualBox Extension Pack' (for USB support)" -ForegroundColor White
    Write-Host "   4. Run this script again" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to open VirtualBox download page"
    Start-Process "https://www.virtualbox.org/wiki/Downloads"
    exit 1
}

Write-Host "✅ VirtualBox found at: $VBoxManage" -ForegroundColor Green

# VM Configuration
$VMName = "SecureWipe-Test"
$VMMemory = 4096  # 4GB RAM
$VMDiskSize = 10240  # 10GB (enough for testing)
$VMsFolder = Join-Path $PWD "SecureWipe-VMs"

Write-Host ""
Write-Host "🖥️ Creating SecureWipe Test VM..." -ForegroundColor Cyan
Write-Host "   VM Name: $VMName" -ForegroundColor White
Write-Host "   Memory: $VMMemory MB (4GB)" -ForegroundColor White
Write-Host "   Disk: $VMDiskSize MB (10GB)" -ForegroundColor White
Write-Host "   Location: $VMsFolder" -ForegroundColor White

# Create VMs directory
if (-not (Test-Path $VMsFolder)) {
    New-Item -ItemType Directory -Path $VMsFolder -Force | Out-Null
    Write-Host "✅ VM folder created" -ForegroundColor Green
}

try {
    # Check if VM already exists and remove it
    $existingVMs = & $VBoxManage list vms 2>$null
    if ($existingVMs -and $existingVMs -match $VMName) {
        Write-Host "⚠️ Removing existing VM: $VMName" -ForegroundColor Yellow
        & $VBoxManage controlvm $VMName poweroff 2>$null
        Start-Sleep 2
        & $VBoxManage unregistervm $VMName --delete 2>$null
    }

    Write-Host ""
    Write-Host "📦 Step 1: Creating VM..." -ForegroundColor Cyan
    & $VBoxManage createvm --name $VMName --ostype "Linux_64" --register --basefolder $VMsFolder
    if ($LASTEXITCODE -ne 0) { throw "Failed to create VM" }
    Write-Host "   ✅ VM created successfully" -ForegroundColor Green

    Write-Host "⚙️ Step 2: Configuring VM settings..." -ForegroundColor Cyan
    
    # Basic configuration
    & $VBoxManage modifyvm $VMName --memory $VMMemory --cpus 2
    & $VBoxManage modifyvm $VMName --firmware bios
    Write-Host "   ✅ Memory and CPU configured" -ForegroundColor Green

    # Boot order - USB first for SecureWipe boot
    & $VBoxManage modifyvm $VMName --boot1 usb --boot2 disk --boot3 none --boot4 none
    Write-Host "   ✅ Boot order set (USB first)" -ForegroundColor Green

    # USB configuration - Essential for SecureWipe USB
    & $VBoxManage modifyvm $VMName --usb on --usbehci on --usbxhci on
    Write-Host "   ✅ USB controllers enabled (USB 2.0 + 3.0)" -ForegroundColor Green

    # Display configuration
    & $VBoxManage modifyvm $VMName --vram 128 --graphicscontroller vmsvga
    Write-Host "   ✅ Display configured (128MB VRAM)" -ForegroundColor Green

    # Network (for any internet needs during testing)
    & $VBoxManage modifyvm $VMName --nic1 nat
    Write-Host "   ✅ Network configured (NAT)" -ForegroundColor Green

    Write-Host "💿 Step 3: Creating virtual hard disk..." -ForegroundColor Cyan
    $VDIPath = Join-Path $VMsFolder "$VMName\$VMName.vdi"
    & $VBoxManage createhd --filename $VDIPath --size $VMDiskSize --format VDI
    if ($LASTEXITCODE -ne 0) { throw "Failed to create virtual disk" }
    Write-Host "   ✅ Virtual disk created (10GB)" -ForegroundColor Green

    Write-Host "🔌 Step 4: Attaching storage..." -ForegroundColor Cyan
    & $VBoxManage storagectl $VMName --name "SATA Controller" --add sata --controller IntelAhci --portcount 2
    & $VBoxManage storageattach $VMName --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium $VDIPath
    Write-Host "   ✅ SATA controller and disk attached" -ForegroundColor Green

    Write-Host ""
    Write-Host "🎉 VirtualBox VM '$VMName' created successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Error creating VM: $_" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "📜 Step 5: Creating helper scripts..." -ForegroundColor Cyan

# Create VM starter script
$StartVMContent = @"
@echo off
title Starting SecureWipe Test VM
echo.
echo 🚀 Starting SecureWipe Test VM...
echo.
echo Instructions:
echo 1. VM will start shortly
echo 2. Create SecureWipe USB first if not done
echo 3. In VM menu: Devices → USB → Select your SecureWipe USB
echo 4. Restart VM to boot from SecureWipe USB
echo 5. Test wiping on the 10GB virtual disk safely!
echo.
pause
"C:\Program Files\Oracle\VirtualBox\VirtualBox.exe" --startvm "SecureWipe-Test"
"@

$StartVMContent | Out-File -FilePath "Start-SecureWipe-VM.cmd" -Encoding ASCII
Write-Host "   ✅ VM starter script created: Start-SecureWipe-VM.cmd" -ForegroundColor Green

# Create unified test script
$UnifiedTestContent = @"
# SecureWipe Complete VirtualBox Test Process
Write-Host "🧪 SecureWipe Complete VirtualBox Test" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

Write-Host "📋 Testing Process Overview:" -ForegroundColor Cyan
Write-Host "   1. Create SecureWipe bootable USB (Windows)" -ForegroundColor White
Write-Host "   2. Start VirtualBox VM" -ForegroundColor White
Write-Host "   3. Connect USB to VM" -ForegroundColor White
Write-Host "   4. Boot from USB and test wiping" -ForegroundColor White
Write-Host ""

Write-Host "🎯 Step 1: Creating SecureWipe Bootable USB..." -ForegroundColor Yellow
Write-Host "   Launching SecureWipe application..." -ForegroundColor White

# Check if we have the unified solution
if (Test-Path "SecureWipe-Unified-Build\SecureWipe-Unified.cmd") {
    Write-Host "   ✅ Using Unified SecureWipe solution" -ForegroundColor Green
    Start-Process -FilePath "SecureWipe-Unified-Build\SecureWipe-Unified.cmd" -Verb RunAs
} elseif (Test-Path "x64\Release\securewipe.exe") {
    Write-Host "   ✅ Using standard SecureWipe application" -ForegroundColor Green
    Start-Process "x64\Release\securewipe.exe"
} else {
    Write-Host "   ❌ SecureWipe executable not found!" -ForegroundColor Red
    Write-Host "   Please build SecureWipe first" -ForegroundColor Yellow
    return
}

Write-Host ""
Write-Host "⏳ Waiting 15 seconds for you to create USB..." -ForegroundColor Yellow
Write-Host "   (Insert USB drive and follow GUI to create bootable USB)" -ForegroundColor Gray
Start-Sleep 15

Write-Host ""
Write-Host "🖥️ Step 2: Starting VirtualBox VM..." -ForegroundColor Yellow
Start-Process "Start-SecureWipe-VM.cmd"

Write-Host ""
Write-Host "📋 Manual Steps (You need to complete these):" -ForegroundColor Cyan
Write-Host ""
Write-Host "   USB Connection:" -ForegroundColor Yellow
Write-Host "   • When VM window opens, go to: Devices → USB" -ForegroundColor White
Write-Host "   • Select your SecureWipe USB drive" -ForegroundColor White
Write-Host "   • This connects the USB to the VM" -ForegroundColor White
Write-Host ""
Write-Host "   Boot Process:" -ForegroundColor Yellow  
Write-Host "   • Restart the VM (Machine → Reset or Ctrl+R)" -ForegroundColor White
Write-Host "   • VM should boot from SecureWipe USB" -ForegroundColor White
Write-Host "   • SecureWipe interface will auto-launch" -ForegroundColor White
Write-Host ""
Write-Host "   Testing:" -ForegroundColor Yellow
Write-Host "   • Select the 10GB virtual disk for wiping" -ForegroundColor White
Write-Host "   • Choose your preferred security level" -ForegroundColor White
Write-Host "   • Start wiping process (completely safe on VM)" -ForegroundColor White
Write-Host "   • Verify certificate generation" -ForegroundColor White
Write-Host ""

Write-Host "🎉 VirtualBox testing environment ready!" -ForegroundColor Green
Write-Host "   VM: SecureWipe-Test (10GB test disk)" -ForegroundColor White
Write-Host "   Safe testing with no risk to your real data!" -ForegroundColor White
"@

$UnifiedTestContent | Out-File -FilePath "Test-SecureWipe-VirtualBox.ps1" -Encoding UTF8
Write-Host "   ✅ Complete test script created: Test-SecureWipe-VirtualBox.ps1" -ForegroundColor Green

# Create troubleshooting guide
$TroubleshootingContent = @"
# SecureWipe VirtualBox Troubleshooting Guide

## Common Issues & Solutions

### ❌ USB Drive Not Detected in VM
**Solution:**
1. In VM window: Devices → USB → [Select your USB device]
2. If not listed: Install VirtualBox Extension Pack
3. Check USB is connected to host computer
4. Try different USB port

### ❌ VM Won't Boot from USB
**Solution:**
1. VM Settings → System → Boot Order
2. Move USB to top of list
3. Uncheck Floppy and Optical
4. Restart VM

### ❌ SecureWipe USB Creation Fails
**Solution:**
1. Run SecureWipe as Administrator
2. Use USB drive with no important data
3. Format USB as FAT32 first
4. Try different USB drive

### ❌ VM Performance Issues
**Solution:**
1. Increase VM memory to 4GB+
2. Enable virtualization in BIOS
3. Close other applications
4. Use SSD for VM storage

### ❌ SecureWipe Interface Not Loading
**Solution:**
1. Wait 2-3 minutes for full boot
2. Check VM has 4GB+ RAM allocated
3. Restart VM and try again
4. Verify USB boot order is correct

## Expected Performance
- Boot Time: 30-90 seconds
- Wiping Speed: 1-5 GB/min (virtual disk)
- Certificate Generation: 10-30 seconds
- Total Test Time: 10-30 minutes

## VM Specifications
- Name: SecureWipe-Test
- OS: Linux 64-bit
- RAM: 4GB
- Disk: 10GB virtual disk
- USB: Enabled (2.0 + 3.0)
- Boot: USB first, then disk
"@

$TroubleshootingContent | Out-File -FilePath "VirtualBox-Troubleshooting.md" -Encoding UTF8
Write-Host "   ✅ Troubleshooting guide created: VirtualBox-Troubleshooting.md" -ForegroundColor Green

Write-Host ""
Write-Host "🎯 SETUP COMPLETE! Next Steps:" -ForegroundColor Green
Write-Host "============================" -ForegroundColor Green
Write-Host ""

Write-Host "🚀 Quick Start (Recommended):" -ForegroundColor Cyan
Write-Host "   powershell -ExecutionPolicy Bypass -File Test-SecureWipe-VirtualBox.ps1" -ForegroundColor White
Write-Host ""

Write-Host "📋 Manual Steps:" -ForegroundColor Cyan
Write-Host "   1. Create SecureWipe USB: Run SecureWipe-Unified.cmd (as Admin)" -ForegroundColor White
Write-Host "   2. Start VM: .\Start-SecureWipe-VM.cmd" -ForegroundColor White
Write-Host "   3. Connect USB to VM: Devices → USB → [Select USB]" -ForegroundColor White
Write-Host "   4. Restart VM to boot from USB" -ForegroundColor White
Write-Host "   5. Test SecureWipe on virtual disk safely!" -ForegroundColor White
Write-Host ""

Write-Host "📁 Files Created:" -ForegroundColor Yellow
Write-Host "   • Start-SecureWipe-VM.cmd - VM launcher" -ForegroundColor Gray
Write-Host "   • Test-SecureWipe-VirtualBox.ps1 - Complete test process" -ForegroundColor Gray
Write-Host "   • VirtualBox-Troubleshooting.md - Help guide" -ForegroundColor Gray
Write-Host "   • SecureWipe-VMs\ - VM storage folder" -ForegroundColor Gray
Write-Host ""

Write-Host "✨ VirtualBox environment ready for SecureWipe testing!" -ForegroundColor Green
Write-Host "   Safe testing with no risk to your real hardware or data!" -ForegroundColor White

Write-Host ""
Read-Host "Press Enter to continue"