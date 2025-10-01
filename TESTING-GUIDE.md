# SecureWipe Project Testing Guide

## 🧪 How to Test SecureWipe - Complete Guide

### 📋 Prerequisites for Testing

Before testing, ensure you have:
- ✅ Windows 10/11 system
- ✅ USB drive (8GB+ recommended for full testing)
- ✅ Administrator privileges
- ✅ Virtual machine software (optional, for safe testing)

---

## 🚀 Method 1: Windows Application Testing (Safe & Recommended)

### Step 1: Launch the Application
```powershell
# Navigate to project directory
cd "C:\Users\anshd\Documents\Github\SecureWipeOut"

# Launch SecureWipe Windows application
Start-Process "x64\Release\securewipe.exe"
```

### Step 2: Test USB Creation (No Data Destruction)
1. **Insert a USB drive** (will be formatted, so backup any data)
2. **Select the USB drive** in the SecureWipe interface
3. **Click "Create Bootable SecureWipe USB"**
4. **Wait for completion** - this creates the Linux boot environment
5. **Verify success**-
### Step 3: Test Boot Environment (Safe)
1. **Boot from the USB** (or use VM)
2. **SecureWipe launcher should auto-start**
3. **Navigate the interface** without selecting any drives
4. **Test device detection** - should show available storage
5. **Exit safely** without proceeding to wipe

---

## 🔬 Method 2: Virtual Machine Testing (Safest Option)

### Setup VM Testing Environment
```powershell
# Create test VM with:
# - 4GB+ RAM
# - 20GB+ virtual disk
# - Boot from SecureWipe USB
```

### VM Testing Steps:
1. **Create VM** with dummy data on virtual disk
2. **Boot VM from SecureWipe USB**
3. **Test complete wiping process** on virtual disk
4. **Verify certificates** are generated
5. **Check verification results**

---

## 🧪 Method 3: Component Testing (Individual Parts)

### Test Linux Boot Components
```bash
# Validate all components exist
powershell -ExecutionPolicy Bypass -File validate-phase3.ps1

# Check individual engines (in WSL or Linux VM)
bash linux-boot/rootfs/usr/lib/securewipe/wipe-engine.sh --help
bash linux-boot/rootfs/usr/lib/securewipe/crypto-erase.sh --help
```

### Test Certificate Generation
```bash
# Test certificate generation system
cd linux-boot/rootfs/usr/lib/securewipe/
bash certificate-gen.sh test-device "Test Device" "Test Method" 300 "PASSED"
```

---

## 🔍 Method 4: Real Hardware Testing (Advanced Users)

⚠️ **WARNING**: This will permanently destroy data on selected drives!

### Safe Real Hardware Testing:
1. **Use OLD/UNUSED drives only**
2. **Double-check drive selection**
3. **Have no important data on test drives**
4. **Test with small USB drives first**

### Testing Process:
1. **Prepare test drive** (old USB stick with no important data)
2. **Boot SecureWipe USB**
3. **Follow complete wiping process**
4. **Verify certificate generation**
5. **Test different verification levels**

---

## 📊 Testing Checklist

### ✅ Windows Application Tests
- [ ] Application launches successfully
- [ ] USB drive detection works
- [ ] Bootable USB creation completes
- [ ] Error handling displays properly
- [ ] Progress indicators function
- [ ] Interface is responsive

### ✅ Linux Boot Environment Tests  
- [ ] USB boots successfully
- [ ] Auto-launch works
- [ ] Hardware detection functions
- [ ] Device list displays correctly
- [ ] User interface is readable
- [ ] Safety warnings appear

### ✅ Wiping Engine Tests
- [ ] Device type detection works
- [ ] Method selection is intelligent
- [ ] Progress monitoring functions
- [ ] Error handling works properly
- [ ] Logs are generated correctly

### ✅ Verification System Tests
- [ ] Pattern verification works
- [ ] Entropy analysis functions
- [ ] Different verification levels work
- [ ] Results are accurate
- [ ] Performance is acceptable

### ✅ Certificate Generation Tests
- [ ] Certificates are generated
- [ ] Digital signatures work
- [ ] PDF creation functions
- [ ] Tamper-proof features work
- [ ] Audit trail is complete

---

## 🚨 Safety Guidelines for Testing

### DO:
✅ Use virtual machines for initial testing  
✅ Use old/unused drives for real hardware tests  
✅ Backup important data before any testing  
✅ Read all warnings and confirmations  
✅ Test in controlled environments  

### DON'T:
❌ Test on drives with important data  
❌ Skip safety confirmations during testing  
❌ Test on production systems  
❌ Ignore error messages or warnings  
❌ Rush through the testing process  

---

## 🐛 Troubleshooting Common Issues

### Issue: Application Won't Start
**Solution**: Check Windows permissions, run as administrator

### Issue: USB Creation Fails
**Solution**: Ensure USB is not write-protected, try different USB

### Issue: Boot Fails
**Solution**: Check BIOS settings, enable USB boot, disable Secure Boot

### Issue: No Devices Detected
**Solution**: Check device connections, verify permissions

---

## 📈 Performance Testing

### Test Different Scenarios:
1. **Small USB drives** (4-8GB)
2. **Large USB drives** (32GB+) 
3. **Old HDDs** (slow performance)
4. **Modern SSDs** (fast performance)
5. **Various file systems** (NTFS, FAT32, ext4)

---

## 📋 Test Results Documentation

Keep track of:
- ✅ Which components work correctly
- ❌ Any issues encountered  
- 📊 Performance metrics
- 🏆 Success rates
- 📝 User experience feedback

---

## 🎯 Quick Start Testing (5 Minutes)

**For immediate testing:**

1. **Launch**: `Start-Process "x64\Release\securewipe.exe"`
2. **Insert USB**: Any spare USB drive
3. **Create Boot USB**: Click create bootable USB
4. **Boot Test**: Boot from USB in VM or spare computer
5. **Interface Test**: Navigate without wiping anything

This gives you immediate confidence that the system works!

---

**🚀 Ready to test? Start with Method 1 for the safest introduction to SecureWipe!**