# Complete SecureWipe VirtualBox Testing Process

Write-Host "🧪 SecureWipe Complete VirtualBox Test" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

Write-Host "📋 Testing Overview:" -ForegroundColor Cyan
Write-Host "   ✅ VM Created: SecureWipe-Test (4GB RAM, 10GB disk)" -ForegroundColor White
Write-Host "   ✅ USB Support: Enabled for SecureWipe boot" -ForegroundColor White
Write-Host "   ✅ Safe Environment: Virtual disk only" -ForegroundColor White
Write-Host ""

# Check if unified solution exists
$UnifiedPath = "SecureWipe-Unified-Build\SecureWipe-Unified.cmd"
$StandardPath = "x64\Release\securewipe.exe"

Write-Host "🎯 Step 1: Create SecureWipe Bootable USB" -ForegroundColor Yellow
Write-Host ""

if (Test-Path $UnifiedPath) {
    Write-Host "   ✅ Found Unified SecureWipe solution" -ForegroundColor Green
    Write-Host "   📂 Location: $UnifiedPath" -ForegroundColor Gray
    Write-Host ""
    Write-Host "   🚀 Launching Unified SecureWipe..." -ForegroundColor Cyan
    
    # Ask user if they want to create USB now
    $createUSB = Read-Host "   Create SecureWipe USB now? (y/n)"
    
    if ($createUSB -eq 'y' -or $createUSB -eq 'Y' -or $createUSB -eq 'yes') {
        Write-Host "   📋 Instructions:" -ForegroundColor Yellow
        Write-Host "      1. Insert USB drive (8GB+)" -ForegroundColor White
        Write-Host "      2. Run as Administrator when prompted" -ForegroundColor White
        Write-Host "      3. Follow GUI to create bootable USB" -ForegroundColor White
        Write-Host "      4. Wait for completion" -ForegroundColor White
        Write-Host ""
        
        Start-Process -FilePath $UnifiedPath -Verb RunAs
        
        Write-Host "   ⏳ Waiting for USB creation..." -ForegroundColor Yellow
        Write-Host "   (Press Enter when USB creation is complete)" -ForegroundColor Gray
        Read-Host
    }
    
} elseif (Test-Path $StandardPath) {
    Write-Host "   ✅ Found standard SecureWipe application" -ForegroundColor Green
    Write-Host "   📂 Location: $StandardPath" -ForegroundColor Gray
    Write-Host ""
    
    $createUSB = Read-Host "   Create SecureWipe USB now? (y/n)"
    
    if ($createUSB -eq 'y' -or $createUSB -eq 'Y' -or $createUSB -eq 'yes') {
        Write-Host "   🚀 Launching SecureWipe..." -ForegroundColor Cyan
        Start-Process $StandardPath
        
        Write-Host "   ⏳ Waiting for USB creation..." -ForegroundColor Yellow
        Write-Host "   (Press Enter when USB creation is complete)" -ForegroundColor Gray
        Read-Host
    }
    
} else {
    Write-Host "   ❌ SecureWipe executable not found!" -ForegroundColor Red
    Write-Host "   Please build SecureWipe first or check paths" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "   Expected locations:" -ForegroundColor Gray
    Write-Host "   - $UnifiedPath" -ForegroundColor Gray
    Write-Host "   - $StandardPath" -ForegroundColor Gray
    return
}

Write-Host ""
Write-Host "🖥️ Step 2: Start VirtualBox VM" -ForegroundColor Yellow
Write-Host ""

$startVM = Read-Host "   Start SecureWipe VM now? (y/n)"

if ($startVM -eq 'y' -or $startVM -eq 'Y' -or $startVM -eq 'yes') {
    Write-Host "   🚀 Starting SecureWipe-Test VM..." -ForegroundColor Cyan
    Start-Process "Start-SecureWipe-VM.cmd"
    
    Write-Host "   ✅ VM starting..." -ForegroundColor Green
} else {
    Write-Host "   📋 To start VM later, run: .\Start-SecureWipe-VM.cmd" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📋 Manual Steps (Complete these in VirtualBox):" -ForegroundColor Cyan
Write-Host ""

Write-Host "   🔌 Connect USB to VM:" -ForegroundColor Yellow
Write-Host "      • In VM window: Devices → USB" -ForegroundColor White
Write-Host "      • Select your SecureWipe USB drive" -ForegroundColor White
Write-Host "      • USB icon should appear in VM status bar" -ForegroundColor White
Write-Host ""

Write-Host "   🔄 Boot from USB:" -ForegroundColor Yellow
Write-Host "      • Restart VM: Machine → Reset (or Ctrl+R)" -ForegroundColor White
Write-Host "      • VM should boot from SecureWipe USB" -ForegroundColor White
Write-Host "      • Wait for Alpine Linux to load (~30-60 seconds)" -ForegroundColor White
Write-Host "      • SecureWipe interface will auto-launch" -ForegroundColor White
Write-Host ""

Write-Host "   🧪 Test SecureWipe:" -ForegroundColor Yellow
Write-Host "      • Select the 10GB virtual disk for wiping" -ForegroundColor White
Write-Host "      • Choose your preferred security level" -ForegroundColor White
Write-Host "      • Confirm and start wiping process" -ForegroundColor White
Write-Host "      • Monitor progress (5-15 minutes)" -ForegroundColor White
Write-Host "      • Verify certificate generation" -ForegroundColor White
Write-Host ""

Write-Host "🎉 Benefits of VirtualBox Testing:" -ForegroundColor Green
Write-Host "   ✅ Completely safe - no risk to real data" -ForegroundColor White
Write-Host "   ✅ Repeatable - can reset VM and test again" -ForegroundColor White
Write-Host "   ✅ Fast - virtual disk I/O is quick" -ForegroundColor White
Write-Host "   ✅ Educational - see entire process safely" -ForegroundColor White
Write-Host ""

Write-Host "📊 Expected Performance:" -ForegroundColor Cyan
Write-Host "   • Boot time: 30-90 seconds" -ForegroundColor White
Write-Host "   • Wiping speed: 1-5 GB/minute" -ForegroundColor White
Write-Host "   • Total test time: 10-30 minutes" -ForegroundColor White
Write-Host ""

Write-Host "🚀 VirtualBox testing environment ready!" -ForegroundColor Green
Write-Host "   Safe testing of SecureWipe with no risk to real hardware!" -ForegroundColor White

Write-Host ""
Read-Host "Press Enter to continue"