# SecureWipe VirtualBox Boot Guide
# Complete guide for booting SecureWipe USB in VirtualBox

Write-Host "🚀 SecureWipe VirtualBox Boot Process Guide" -ForegroundColor Green
Write-Host "===========================================" -ForegroundColor Green
Write-Host ""

Write-Host "📋 Understanding the Boot Process:" -ForegroundColor Cyan
Write-Host ""

Write-Host "🔍 What happens when you boot SecureWipe USB:" -ForegroundColor Yellow
Write-Host "   1. VirtualBox boots from your SecureWipe USB drive" -ForegroundColor White
Write-Host "   2. Alpine Linux loads automatically (~30-60 seconds)" -ForegroundColor White
Write-Host "   3. SecureWipe launcher starts automatically" -ForegroundColor White
Write-Host "   4. Hardware detection runs" -ForegroundColor White
Write-Host "   5. SecureWipe interface appears" -ForegroundColor White
Write-Host ""

Write-Host "🎯 There is NO image selection needed!" -ForegroundColor Green
Write-Host "   • The SecureWipe USB contains everything pre-configured" -ForegroundColor White
Write-Host "   • It boots directly to the SecureWipe environment" -ForegroundColor White
Write-Host "   • No menu selection or ISO mounting required" -ForegroundColor White
Write-Host ""

Write-Host "📺 What you should see during boot:" -ForegroundColor Cyan
Write-Host ""

Write-Host "   Step 1 - BIOS Boot (5-10 seconds):" -ForegroundColor Yellow
Write-Host "      • VirtualBox BIOS screen" -ForegroundColor Gray
Write-Host "      • 'Booting from Hard Disk...' or similar" -ForegroundColor Gray
Write-Host ""

Write-Host "   Step 2 - Linux Boot (30-60 seconds):" -ForegroundColor Yellow
Write-Host "      • Alpine Linux boot messages" -ForegroundColor Gray
Write-Host "      • Kernel loading text" -ForegroundColor Gray
Write-Host "      • Hardware detection messages" -ForegroundColor Gray
Write-Host ""

Write-Host "   Step 3 - SecureWipe Auto-Launch (5-10 seconds):" -ForegroundColor Yellow
Write-Host "      • 'Starting SecureWipe...' message" -ForegroundColor Gray
Write-Host "      • Hardware scanning" -ForegroundColor Gray
Write-Host "      • SecureWipe interface appears" -ForegroundColor Gray
Write-Host ""

Write-Host "🖥️ Expected SecureWipe Interface:" -ForegroundColor Green
Write-Host "   ┌─────────────────────────────────────┐" -ForegroundColor Gray
Write-Host "   │          SecureWipe v4.10          │" -ForegroundColor Gray
Write-Host "   │                                     │" -ForegroundColor Gray
Write-Host "   │  Detected Storage Devices:          │" -ForegroundColor Gray
Write-Host "   │  [1] Virtual Disk - 10GB (SATA)    │" -ForegroundColor Gray
Write-Host "   │                                     │" -ForegroundColor Gray
Write-Host "   │  Select device to wipe: ___        │" -ForegroundColor Gray
Write-Host "   │                                     │" -ForegroundColor Gray
Write-Host "   │  Security Level: [Enhanced]        │" -ForegroundColor Gray
Write-Host "   │                                     │" -ForegroundColor Gray
Write-Host "   └─────────────────────────────────────┘" -ForegroundColor Gray
Write-Host ""

Write-Host "⚠️ Troubleshooting Boot Issues:" -ForegroundColor Red
Write-Host ""

Write-Host "   Issue: VM boots to normal desktop/login" -ForegroundColor Yellow
Write-Host "   Solution:" -ForegroundColor White
Write-Host "      • USB not connected to VM properly" -ForegroundColor Gray
Write-Host "      • In VM: Devices → USB → Select SecureWipe USB" -ForegroundColor Gray
Write-Host "      • Restart VM after connecting USB" -ForegroundColor Gray
Write-Host ""

Write-Host "   Issue: 'No bootable device found'" -ForegroundColor Yellow
Write-Host "   Solution:" -ForegroundColor White
Write-Host "      • SecureWipe USB not created properly" -ForegroundColor Gray
Write-Host "      • Recreate USB using SecureWipe-Unified.cmd" -ForegroundColor Gray
Write-Host "      • Ensure USB has enough space (8GB+)" -ForegroundColor Gray
Write-Host ""

Write-Host "   Issue: Boot hangs or freezes" -ForegroundColor Yellow
Write-Host "   Solution:" -ForegroundColor White
Write-Host "      • Increase VM RAM to 4GB+" -ForegroundColor Gray
Write-Host "      • Enable virtualization in host BIOS" -ForegroundColor Gray
Write-Host "      • Close other applications" -ForegroundColor Gray
Write-Host ""

Write-Host "🎯 Key Points:" -ForegroundColor Cyan
Write-Host "   ✅ NO image selection needed" -ForegroundColor Green
Write-Host "   ✅ SecureWipe USB boots automatically" -ForegroundColor Green
Write-Host "   ✅ Alpine Linux loads invisibly" -ForegroundColor Green
Write-Host "   ✅ SecureWipe interface appears automatically" -ForegroundColor Green
Write-Host "   ✅ Ready to wipe the 10GB virtual disk safely" -ForegroundColor Green
Write-Host ""

Write-Host "📋 Quick Checklist:" -ForegroundColor Yellow
Write-Host "   □ SecureWipe USB created successfully" -ForegroundColor White
Write-Host "   □ USB connected to VirtualBox VM" -ForegroundColor White
Write-Host "   □ VM restarted after USB connection" -ForegroundColor White  
Write-Host "   □ Waiting patiently for boot (60-90 seconds)" -ForegroundColor White
Write-Host "   □ SecureWipe interface appears" -ForegroundColor White
Write-Host ""

Write-Host "🚀 Ready to wipe safely in VirtualBox!" -ForegroundColor Green