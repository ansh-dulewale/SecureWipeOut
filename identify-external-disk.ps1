# 🔍 External Hard Disk Identification Script
# Use this script BEFORE starting the wipe process to safely identify your external disk

Write-Host "🗄️ External Hard Disk Identification Utility" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

# Get all disks connected to the system
Write-Host "📋 All Connected Storage Devices:" -ForegroundColor Yellow
Write-Host ""

# List all physical disks with detailed information
Get-Disk | Format-Table -AutoSize Number, FriendlyName, Size, BusType, OperationalStatus, PartitionStyle

Write-Host ""
Write-Host "🔌 USB Connected Drives (Potential External Disks):" -ForegroundColor Green
Write-Host ""

# Filter and show only USB drives
$usbDrives = Get-Disk | Where-Object { $_.BusType -eq "USB" }

if ($usbDrives) {
    foreach ($drive in $usbDrives) {
        Write-Host "📀 Drive $($drive.Number): $($drive.FriendlyName)" -ForegroundColor White
        Write-Host "   Size: $([math]::Round($drive.Size / 1GB, 2)) GB" -ForegroundColor Gray
        Write-Host "   Status: $($drive.OperationalStatus)" -ForegroundColor Gray
        Write-Host "   Partitions: $($drive.NumberOfPartitions)" -ForegroundColor Gray
        
        # Get drive letters for this disk
        $partitions = Get-Partition -DiskNumber $drive.Number -ErrorAction SilentlyContinue
        if ($partitions) {
            $driveLetters = $partitions | Where-Object { $_.DriveLetter } | Select-Object -ExpandProperty DriveLetter
            if ($driveLetters) {
                Write-Host "   Drive Letters: $($driveLetters -join ', ')" -ForegroundColor Gray
            }
        }
        Write-Host ""
    }
    
    Write-Host "⚠️  CRITICAL SAFETY CHECK:" -ForegroundColor Red
    Write-Host "   Before wiping any drive, verify:" -ForegroundColor Yellow
    Write-Host "   1. This is the correct external hard disk" -ForegroundColor Yellow
    Write-Host "   2. You have backed up all important data" -ForegroundColor Yellow
    Write-Host "   3. You are 100% sure about the drive selection" -ForegroundColor Yellow
    Write-Host ""
    
    # Ask user to identify their target drive
    Write-Host "🎯 Drive Selection Verification:" -ForegroundColor Cyan
    Write-Host ""
    
    do {
        $targetDrive = Read-Host "Enter the Disk Number of your external hard disk (or 'q' to quit)"
        
        if ($targetDrive -eq 'q') {
            Write-Host "❌ Drive identification cancelled." -ForegroundColor Red
            exit
        }
        
        $selectedDrive = Get-Disk -Number $targetDrive -ErrorAction SilentlyContinue
        
        if ($selectedDrive -and $selectedDrive.BusType -eq "USB") {
            Write-Host ""
            Write-Host "✅ Selected Drive Details:" -ForegroundColor Green
            Write-Host "   Disk Number: $($selectedDrive.Number)" -ForegroundColor White
            Write-Host "   Name: $($selectedDrive.FriendlyName)" -ForegroundColor White
            Write-Host "   Size: $([math]::Round($selectedDrive.Size / 1GB, 2)) GB" -ForegroundColor White
            Write-Host "   Bus Type: $($selectedDrive.BusType)" -ForegroundColor White
            Write-Host ""
            
            # Show current data on the drive
            Write-Host "📁 Current Data on This Drive:" -ForegroundColor Yellow
            $partitions = Get-Partition -DiskNumber $selectedDrive.Number -ErrorAction SilentlyContinue
            
            if ($partitions) {
                foreach ($partition in $partitions) {
                    if ($partition.DriveLetter) {
                        Write-Host "   Partition $($partition.DriveLetter):\" -ForegroundColor White
                        try {
                            $files = Get-ChildItem "$($partition.DriveLetter):\" -ErrorAction SilentlyContinue
                            if ($files) {
                                Write-Host "   Files/Folders: $($files.Count) items" -ForegroundColor Gray
                                $totalSize = ($files | Measure-Object Length -Sum).Sum
                                Write-Host "   Data Size: $([math]::Round($totalSize / 1MB, 2)) MB" -ForegroundColor Gray
                            } else {
                                Write-Host "   Status: Empty or inaccessible" -ForegroundColor Gray
                            }
                        } catch {
                            Write-Host "   Status: Cannot access (may be encrypted or damaged)" -ForegroundColor Gray
                        }
                    }
                }
            } else {
                Write-Host "   Status: No readable partitions found" -ForegroundColor Gray
            }
            
            Write-Host ""
            Write-Host "⚡ FINAL CONFIRMATION:" -ForegroundColor Red
            Write-Host "   This drive will be PERMANENTLY WIPED" -ForegroundColor Red
            Write-Host "   ALL DATA WILL BE DESTROYED AND UNRECOVERABLE" -ForegroundColor Red
            Write-Host ""
            
            $finalConfirm = Read-Host "Type 'YES-WIPE-DISK-$targetDrive' to confirm this is your target drive"
            
            if ($finalConfirm -eq "YES-WIPE-DISK-$targetDrive") {
                Write-Host ""
                Write-Host "✅ Drive identified and confirmed!" -ForegroundColor Green
                Write-Host "📋 Disk Number to use in SecureWipe: $targetDrive" -ForegroundColor White
                Write-Host ""
                Write-Host "🚀 Next Steps:" -ForegroundColor Cyan
                Write-Host "   1. Remember Disk Number: $targetDrive" -ForegroundColor Yellow
                Write-Host "   2. Follow the EXTERNAL-HARD-DISK-WIPING-PROCESS.md guide" -ForegroundColor Yellow
                Write-Host "   3. Boot from SecureWipe USB" -ForegroundColor Yellow
                Write-Host "   4. Select Disk $targetDrive in the SecureWipe interface" -ForegroundColor Yellow
                Write-Host ""
                Write-Host "⚠️  REMEMBER: Once wiping starts, it CANNOT be stopped or reversed!" -ForegroundColor Red
                break
            } else {
                Write-Host "❌ Confirmation failed. Drive identification cancelled for safety." -ForegroundColor Red
                exit
            }
            
        } elseif ($selectedDrive) {
            Write-Host "❌ Error: Disk $targetDrive is not a USB drive. Only USB external drives should be wiped." -ForegroundColor Red
            Write-Host "   Drive Type: $($selectedDrive.BusType)" -ForegroundColor Gray
        } else {
            Write-Host "❌ Error: Disk $targetDrive not found. Please enter a valid disk number." -ForegroundColor Red
        }
        
    } while ($true)
    
} else {
    Write-Host "❌ No USB drives detected!" -ForegroundColor Red
    Write-Host "   Ensure your external hard disk is connected and recognized by Windows." -ForegroundColor Yellow
    Write-Host "   Try:" -ForegroundColor Yellow
    Write-Host "   1. Reconnecting the USB cable" -ForegroundColor Gray
    Write-Host "   2. Using a different USB port" -ForegroundColor Gray
    Write-Host "   3. Checking Device Manager for any issues" -ForegroundColor Gray
}

Write-Host ""
Write-Host "🛡️ Safety Reminder:" -ForegroundColor Yellow
Write-Host "   This script only identifies drives - it does not wipe anything." -ForegroundColor Gray
Write-Host "   Use the EXTERNAL-HARD-DISK-WIPING-PROCESS.md guide for actual wiping." -ForegroundColor Gray
Write-Host ""

Read-Host "Press Enter to exit"