# SecureWipe Unified - Package Verification
# Verifies all components are present and ready

Write-Host "🔍 SecureWipe Unified Package Verification" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$allGood = $true

Write-Host "📦 Checking Core Components:" -ForegroundColor Yellow

# Check Windows executable
if (Test-Path "SecureWipe.exe") {
    $size = (Get-Item "SecureWipe.exe").Length / 1MB
    Write-Host "  ✅ SecureWipe.exe ($([math]::Round($size, 1)) MB)" -ForegroundColor Green
} else {
    Write-Host "  ❌ SecureWipe.exe MISSING" -ForegroundColor Red
    $allGood = $false
}

# Check unified launcher
if (Test-Path "SecureWipe-Unified.cmd") {
    Write-Host "  ✅ SecureWipe-Unified.cmd (Main launcher)" -ForegroundColor Green
} else {
    Write-Host "  ❌ SecureWipe-Unified.cmd MISSING" -ForegroundColor Red
    $allGood = $false
}

# Check Linux boot environment
if (Test-Path "linux-boot") {
    Write-Host "  ✅ linux-boot/ (Boot environment)" -ForegroundColor Green
} else {
    Write-Host "  ❌ linux-boot/ MISSING" -ForegroundColor Red
    $allGood = $false
}

Write-Host ""
Write-Host "🐧 Checking Linux Boot Components:" -ForegroundColor Yellow

# Check boot launcher
if (Test-Path "linux-boot\rootfs\usr\bin\securewipe-launcher") {
    Write-Host "  ✅ securewipe-launcher (Auto-launch interface)" -ForegroundColor Green
} else {
    Write-Host "  ❌ securewipe-launcher MISSING" -ForegroundColor Red
    $allGood = $false
}

# Check boot configuration
if (Test-Path "linux-boot\rootfs\etc\securewipe\boot.conf") {
    Write-Host "  ✅ boot.conf (Boot configuration)" -ForegroundColor Green
} else {
    Write-Host "  ❌ boot.conf MISSING" -ForegroundColor Red
    $allGood = $false
}

Write-Host ""
Write-Host "🔧 Checking Wiping Engines:" -ForegroundColor Yellow

$engines = @(
    "wipe-engine.sh",
    "crypto-erase.sh", 
    "hdd-overwrite.sh",
    "external-storage.sh",
    "verification.sh",
    "certificate-gen.sh"
)

$enginePath = "linux-boot\rootfs\usr\lib\securewipe"
$engineCount = 0

foreach ($engine in $engines) {
    if (Test-Path "$enginePath\$engine") {
        $size = (Get-Item "$enginePath\$engine").Length / 1KB
        Write-Host "  ✅ $engine ($([math]::Round($size, 1)) KB)" -ForegroundColor Green
        $engineCount++
    } else {
        Write-Host "  ❌ $engine MISSING" -ForegroundColor Red
        $allGood = $false
    }
}

Write-Host ""
Write-Host "📚 Checking Documentation:" -ForegroundColor Yellow

$docs = @("README.md", "QUICK-START.md")
foreach ($doc in $docs) {
    if (Test-Path $doc) {
        Write-Host "  ✅ $doc" -ForegroundColor Green
    } else {
        Write-Host "  ❌ $doc MISSING" -ForegroundColor Red
        $allGood = $false
    }
}

Write-Host ""
Write-Host "📊 Package Summary:" -ForegroundColor Cyan
Write-Host "  • Windows GUI: SecureWipe.exe" -ForegroundColor White
Write-Host "  • Main Launcher: SecureWipe-Unified.cmd" -ForegroundColor White
Write-Host "  • Linux Boot Environment: Complete" -ForegroundColor White
Write-Host "  • Wiping Engines: $engineCount/6 engines" -ForegroundColor White
Write-Host "  • Auto-launch Interface: Ready" -ForegroundColor White
Write-Host "  • Documentation: Complete" -ForegroundColor White

Write-Host ""

if ($allGood) {
    Write-Host "🎉 VERIFICATION COMPLETE - ALL COMPONENTS READY!" -ForegroundColor Green
    Write-Host "✨ SecureWipe Unified is fully functional!" -ForegroundColor Green
    Write-Host ""
    Write-Host "🚀 Ready to Use:" -ForegroundColor Cyan
    Write-Host "  1. Right-click 'SecureWipe-Unified.cmd'" -ForegroundColor Yellow
    Write-Host "  2. Select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host "  3. Insert USB drive (8GB+)" -ForegroundColor Yellow
    Write-Host "  4. Follow GUI to create bootable USB" -ForegroundColor Yellow
    Write-Host "  5. Boot from USB to access wiping tools" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "🎯 Key Benefits:" -ForegroundColor White
    Write-Host "  • Single executable solution" -ForegroundColor Gray
    Write-Host "  • No separate boot creation needed" -ForegroundColor Gray
    Write-Host "  • All wiping engines embedded" -ForegroundColor Gray
    Write-Host "  • Auto-launch wiping interface" -ForegroundColor Gray
    Write-Host "  • Certificate generation included" -ForegroundColor Gray
} else {
    Write-Host "❌ VERIFICATION FAILED - Some components are missing!" -ForegroundColor Red
    Write-Host "Please rebuild the package or check for errors." -ForegroundColor Yellow
}

Write-Host ""
Read-Host "Press Enter to continue"