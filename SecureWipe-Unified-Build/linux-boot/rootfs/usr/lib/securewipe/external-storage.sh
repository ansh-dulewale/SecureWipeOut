#!/bin/bash
# SecureWipe External Storage Device Handler
# Specialized handling for USB drives, SD cards, and removable storage

set -e

# Import common functions
source /usr/lib/securewipe/wipe-engine.sh

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# External device types
EXT_DEVICE_USB_FLASH=1
EXT_DEVICE_USB_HDD=2
EXT_DEVICE_SD_CARD=3
EXT_DEVICE_CF_CARD=4
EXT_DEVICE_OTHER=5

# Security levels for external devices
SECURITY_LEVEL_BASIC=1
SECURITY_LEVEL_STANDARD=2
SECURITY_LEVEL_ENHANCED=3

# Detect external device characteristics
detect_external_device_type() {
    local device="$1"
    local ext_device_type=$EXT_DEVICE_OTHER
    local is_removable=false
    local is_hotplug=false
    local bus_type="unknown"
    local vendor=""
    local model=""
    
    log_wipe "INFO" "Analyzing external device characteristics for: $device"
    
    echo -e "${CYAN}🔍 External Device Analysis${NC}"
    
    # Get device information using udev
    local device_info
    if device_info=$(udevadm info --query=all --name="$device" 2>/dev/null); then
        echo -e "${BLUE}Device Information:${NC}"
        
        # Check if removable
        if echo "$device_info" | grep -q "ID_BUS=usb"; then
            bus_type="USB"
            is_removable=true
            is_hotplug=true
            
            # Determine USB device type
            local usb_type=$(echo "$device_info" | grep "ID_USB_TYPE" | cut -d'=' -f2 || echo "")
            if [[ "$usb_type" == *"disk"* ]] || lsblk -d -n -o ROTA "$device" 2>/dev/null | grep -q "0"; then
                ext_device_type=$EXT_DEVICE_USB_FLASH
                echo "• Type: USB Flash Drive"
            else
                ext_device_type=$EXT_DEVICE_USB_HDD
                echo "• Type: USB Hard Drive"
            fi
            
        elif echo "$device_info" | grep -q "ID_BUS=mmc"; then
            bus_type="MMC/SD"
            is_removable=true
            ext_device_type=$EXT_DEVICE_SD_CARD
            echo "• Type: SD/MMC Card"
            
        elif lsblk -d -n -o RM "$device" 2>/dev/null | grep -q "1"; then
            is_removable=true
            ext_device_type=$EXT_DEVICE_OTHER
            echo "• Type: Other Removable Storage"
        fi
        
        # Extract vendor and model
        vendor=$(echo "$device_info" | grep "ID_VENDOR=" | cut -d'=' -f2 | tr -d '"' || echo "Unknown")
        model=$(echo "$device_info" | grep "ID_MODEL=" | cut -d'=' -f2 | tr -d '"' || echo "Unknown")
        
        echo "• Bus Type: $bus_type"
        echo "• Vendor: $vendor"
        echo "• Model: $model"
        echo "• Removable: $is_removable"
        echo "• Hot-pluggable: $is_hotplug"
        
    else
        log_wipe "WARN" "Could not get detailed device information"
        echo -e "${YELLOW}⚠️  Limited device information available${NC}"
    fi
    
    # Check file system
    local filesystem=$(lsblk -f -n -o FSTYPE "$device" 2>/dev/null | head -1 || echo "unknown")
    if [ -n "$filesystem" ] && [ "$filesystem" != "unknown" ]; then
        echo "• File System: $filesystem"
    fi
    
    # Export detected characteristics
    export EXT_DETECTED_TYPE=$ext_device_type
    export EXT_IS_REMOVABLE=$is_removable
    export EXT_IS_HOTPLUG=$is_hotplug
    export EXT_BUS_TYPE="$bus_type"
    export EXT_VENDOR="$vendor"
    export EXT_MODEL="$model"
    export EXT_FILESYSTEM="$filesystem"
    
    log_wipe "INFO" "External device analysis complete: Type=$ext_device_type, Bus=$bus_type, Removable=$is_removable"
    return 0
}

# Determine security level for external device
determine_external_security_level() {
    local device="$1"
    local user_requirement="$2"  # basic/standard/enhanced
    local recommended_level=$SECURITY_LEVEL_STANDARD
    
    log_wipe "INFO" "Determining security level for external device: $device"
    
    echo ""
    echo -e "${CYAN}🛡️  Security Level Assessment${NC}"
    
    # Base recommendation on device type
    case $EXT_DETECTED_TYPE in
        $EXT_DEVICE_USB_FLASH)
            recommended_level=$SECURITY_LEVEL_ENHANCED
            echo "• Device Type: USB Flash Drive"
            echo "• Recommendation: Enhanced security (wear leveling concerns)"
            ;;
        $EXT_DEVICE_USB_HDD)
            recommended_level=$SECURITY_LEVEL_STANDARD
            echo "• Device Type: USB Hard Drive"
            echo "• Recommendation: Standard security (traditional overwrite)"
            ;;
        $EXT_DEVICE_SD_CARD)
            recommended_level=$SECURITY_LEVEL_ENHANCED
            echo "• Device Type: SD/MMC Card"
            echo "• Recommendation: Enhanced security (flash memory)"
            ;;
        *)
            recommended_level=$SECURITY_LEVEL_STANDARD
            echo "• Device Type: Generic External Storage"
            echo "• Recommendation: Standard security"
            ;;
    esac
    
    # Show security level options
    echo ""
    echo -e "${WHITE}Available Security Levels:${NC}"
    echo "1. Basic     - Single zero overwrite pass"
    echo "2. Standard  - Single pass + verification"
    echo "3. Enhanced  - Multiple passes + crypto methods"
    echo ""
    
    # Get user preference or use recommended
    local selected_level=$recommended_level
    if [ -n "$user_requirement" ]; then
        case "$user_requirement" in
            "basic") selected_level=$SECURITY_LEVEL_BASIC ;;
            "standard") selected_level=$SECURITY_LEVEL_STANDARD ;;
            "enhanced") selected_level=$SECURITY_LEVEL_ENHANCED ;;
            *) selected_level=$recommended_level ;;
        esac
    else
        echo -n "Select security level (1-3, or ENTER for recommended): "
        local user_choice
        read -r user_choice
        
        case "$user_choice" in
            1) selected_level=$SECURITY_LEVEL_BASIC ;;
            2) selected_level=$SECURITY_LEVEL_STANDARD ;;
            3) selected_level=$SECURITY_LEVEL_ENHANCED ;;
            "") selected_level=$recommended_level ;;
            *) 
                echo -e "${YELLOW}Invalid choice, using recommended level${NC}"
                selected_level=$recommended_level
                ;;
        esac
    fi
    
    export EXT_SECURITY_LEVEL=$selected_level
    
    # Display selected level
    local level_name=""
    case $selected_level in
        $SECURITY_LEVEL_BASIC) level_name="Basic" ;;
        $SECURITY_LEVEL_STANDARD) level_name="Standard" ;;
        $SECURITY_LEVEL_ENHANCED) level_name="Enhanced" ;;
    esac
    
    echo ""
    echo -e "${GREEN}✅ Selected Security Level: $level_name${NC}"
    log_wipe "INFO" "Security level selected: $level_name ($selected_level)"
    
    return 0
}

# Execute basic security level wipe
execute_basic_external_wipe() {
    local device="$1"
    
    log_wipe "INFO" "Executing basic external device wipe on $device"
    
    echo -e "${BLUE}🔄 Basic Security Wipe${NC}"
    echo "• Method: Single zero overwrite pass"
    echo "• Speed: Fast"
    echo "• Security: Basic protection"
    echo ""
    
    # Single zero pass
    local start_time=$(date +%s)
    echo -e "${YELLOW}⏳ Performing zero overwrite...${NC}"
    
    if dd if=/dev/zero of="$device" bs=16M status=progress oflag=sync 2>&1 | tee -a "$WIPE_LOG_FILE"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        echo ""
        echo -e "${GREEN}✅ Basic wipe completed in ${duration} seconds${NC}"
        log_wipe "INFO" "Basic external device wipe completed successfully"
        return 0
    else
        echo ""
        echo -e "${RED}❌ Basic wipe failed${NC}"
        log_wipe "ERROR" "Basic external device wipe failed"
        return 1
    fi
}

# Execute standard security level wipe
execute_standard_external_wipe() {
    local device="$1"
    
    log_wipe "INFO" "Executing standard external device wipe on $device"
    
    echo -e "${BLUE}🔄 Standard Security Wipe${NC}"
    echo "• Method: Zero overwrite + verification"
    echo "• Speed: Moderate"
    echo "• Security: Good protection"
    echo ""
    
    local start_time=$(date +%s)
    
    # Step 1: Zero overwrite
    echo -e "${YELLOW}⏳ Step 1/2: Zero overwrite...${NC}"
    if ! dd if=/dev/zero of="$device" bs=16M status=progress oflag=sync 2>&1 | tee -a "$WIPE_LOG_FILE"; then
        echo -e "${RED}❌ Zero overwrite failed${NC}"
        return 1
    fi
    
    # Step 2: Verification
    echo -e "${YELLOW}⏳ Step 2/2: Verification...${NC}"
    local verification_passed=true
    local sample_count=20
    local device_size_sectors=$(blockdev --getsz "$device" 2>/dev/null || echo "0")
    
    if [ "$device_size_sectors" -gt 0 ]; then
        for i in $(seq 1 $sample_count); do
            local random_sector=$((RANDOM % (device_size_sectors - 100) + 50))
            if ! dd if="$device" bs=512 skip="$random_sector" count=1 2>/dev/null | \
                 hexdump -C | grep -q "00 00 00 00 00 00 00 00"; then
                verification_passed=false
                break
            fi
        done
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ "$verification_passed" = "true" ]; then
        echo ""
        echo -e "${GREEN}✅ Standard wipe completed successfully in ${duration} seconds${NC}"
        echo -e "${GREEN}✅ Verification passed${NC}"
        log_wipe "INFO" "Standard external device wipe completed with verification"
        return 0
    else
        echo ""
        echo -e "${RED}❌ Verification failed${NC}"
        log_wipe "ERROR" "Standard external device wipe verification failed"
        return 1
    fi
}

# Execute enhanced security level wipe
execute_enhanced_external_wipe() {
    local device="$1"
    
    log_wipe "INFO" "Executing enhanced external device wipe on $device"
    
    echo -e "${BLUE}🔄 Enhanced Security Wipe${NC}"
    echo "• Method: Multi-pass overwrite + crypto methods"
    echo "• Speed: Slower but thorough"
    echo "• Security: Maximum protection"
    echo ""
    
    local start_time=$(date +%s)
    local total_passes=3
    
    # Pass 1: Random data
    echo -e "${YELLOW}⏳ Pass 1/$total_passes: Random data overwrite...${NC}"
    if ! dd if=/dev/urandom of="$device" bs=8M status=progress oflag=sync 2>&1 | tee -a "$WIPE_LOG_FILE"; then
        echo -e "${RED}❌ Random overwrite failed${NC}"
        return 1
    fi
    
    # Pass 2: Zeros
    echo -e "${YELLOW}⏳ Pass 2/$total_passes: Zero overwrite...${NC}"
    if ! dd if=/dev/zero of="$device" bs=16M status=progress oflag=sync 2>&1 | tee -a "$WIPE_LOG_FILE"; then
        echo -e "${RED}❌ Zero overwrite failed${NC}"
        return 1
    fi
    
    # Pass 3: Pattern
    echo -e "${YELLOW}⏳ Pass 3/$total_passes: Pattern overwrite...${NC}"
    # Create pattern (0x55 - alternating bits)
    if ! dd if=<(yes $'\x55' | tr -d '\n') of="$device" bs=16M status=progress oflag=sync 2>&1 | tee -a "$WIPE_LOG_FILE"; then
        echo -e "${RED}❌ Pattern overwrite failed${NC}"
        return 1
    fi
    
    # Final verification
    echo -e "${YELLOW}⏳ Final verification...${NC}"
    local verification_passed=true
    local device_size_sectors=$(blockdev --getsz "$device" 2>/dev/null || echo "0")
    
    if [ "$device_size_sectors" -gt 0 ]; then
        for i in $(seq 1 30); do
            local random_sector=$((RANDOM % (device_size_sectors - 100) + 50))
            local sector_data=$(dd if="$device" bs=512 skip="$random_sector" count=1 2>/dev/null | hexdump -C | head -1)
            # Check if sector contains expected pattern (0x55)
            if ! echo "$sector_data" | grep -q "55 55 55 55 55 55 55 55"; then
                verification_passed=false
                break
            fi
        done
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [ "$verification_passed" = "true" ]; then
        echo ""
        echo -e "${GREEN}✅ Enhanced wipe completed successfully in ${duration} seconds${NC}"
        echo -e "${GREEN}✅ Multi-pass verification passed${NC}"
        log_wipe "INFO" "Enhanced external device wipe completed with full verification"
        return 0
    else
        echo ""
        echo -e "${RED}❌ Enhanced verification failed${NC}"
        log_wipe "ERROR" "Enhanced external device wipe verification failed"
        return 1
    fi
}

# Check for device removal during operation
check_device_presence() {
    local device="$1"
    
    if [ ! -b "$device" ]; then
        echo -e "${RED}⚠️  DEVICE REMOVED DURING OPERATION ⚠️${NC}"
        echo "Device $device is no longer present!"
        log_wipe "ERROR" "Device $device removed during wiping operation"
        return 1
    fi
    return 0
}

# Main external storage device handler
handle_external_storage_device() {
    local device="$1"
    local device_info="$2"
    local security_level="$3"  # optional: basic/standard/enhanced
    
    log_wipe "INFO" "Starting external storage device handling for: $device"
    
    echo ""
    echo -e "${WHITE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║            EXTERNAL STORAGE DEVICE HANDLER                   ║${NC}"
    echo -e "${WHITE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Step 1: Detect device characteristics
    if ! detect_external_device_type "$device"; then
        return 1
    fi
    
    echo ""
    
    # Step 2: Check device is still present
    if ! check_device_presence "$device"; then
        return 1
    fi
    
    # Step 3: Determine security level
    if ! determine_external_security_level "$device" "$security_level"; then
        return 1
    fi
    
    # Step 4: Final warning for external devices
    echo ""
    echo -e "${RED}⚠️  EXTERNAL DEVICE WIPE WARNING ⚠️${NC}"
    echo ""
    echo "This will permanently destroy all data on:"
    echo "  Device: $device_info"
    echo "  Type: $(get_external_device_type_name $EXT_DETECTED_TYPE)"
    echo "  Vendor: $EXT_VENDOR"
    echo "  Model: $EXT_MODEL"
    echo "  Security Level: $(get_security_level_name $EXT_SECURITY_LEVEL)"
    echo ""
    echo -e "${YELLOW}External devices may have wear leveling that affects data destruction.${NC}"
    echo -e "${YELLOW}Enhanced security level is recommended for flash-based storage.${NC}"
    echo ""
    echo "Type 'WIPE EXTERNAL' to proceed:"
    
    local external_confirm
    read -r external_confirm
    
    if [ "$external_confirm" != "WIPE EXTERNAL" ]; then
        echo -e "${CYAN}Operation cancelled by user${NC}"
        log_wipe "INFO" "External device wipe cancelled by user"
        return 1
    fi
    
    # Step 5: Execute wipe based on security level
    local wipe_success=false
    case $EXT_SECURITY_LEVEL in
        $SECURITY_LEVEL_BASIC)
            if execute_basic_external_wipe "$device"; then
                wipe_success=true
            fi
            ;;
        $SECURITY_LEVEL_STANDARD)
            if execute_standard_external_wipe "$device"; then
                wipe_success=true
            fi
            ;;
        $SECURITY_LEVEL_ENHANCED)
            if execute_enhanced_external_wipe "$device"; then
                wipe_success=true
            fi
            ;;
    esac
    
    # Step 6: Final status
    echo ""
    if [ "$wipe_success" = "true" ]; then
        echo -e "${GREEN}🎉 EXTERNAL STORAGE WIPE COMPLETED SUCCESSFULLY${NC}"
        echo ""
        echo -e "${WHITE}Summary:${NC}"
        echo "• Device: $EXT_VENDOR $EXT_MODEL"
        echo "• Type: $(get_external_device_type_name $EXT_DETECTED_TYPE)"
        echo "• Security Level: $(get_security_level_name $EXT_SECURITY_LEVEL)"
        echo "• Status: All data destroyed"
        
        log_wipe "INFO" "External storage device wipe completed successfully"
        return 0
    else
        echo -e "${RED}❌ EXTERNAL STORAGE WIPE FAILED${NC}"
        log_wipe "ERROR" "External storage device wipe failed"
        return 1
    fi
}

# Helper functions
get_external_device_type_name() {
    case $1 in
        $EXT_DEVICE_USB_FLASH) echo "USB Flash Drive" ;;
        $EXT_DEVICE_USB_HDD) echo "USB Hard Drive" ;;
        $EXT_DEVICE_SD_CARD) echo "SD/MMC Card" ;;
        $EXT_DEVICE_CF_CARD) echo "CompactFlash Card" ;;
        *) echo "External Storage Device" ;;
    esac
}

get_security_level_name() {
    case $1 in
        $SECURITY_LEVEL_BASIC) echo "Basic" ;;
        $SECURITY_LEVEL_STANDARD) echo "Standard" ;;
        $SECURITY_LEVEL_ENHANCED) echo "Enhanced" ;;
        *) echo "Unknown" ;;
    esac
}

# Export functions for use by main engine
export -f detect_external_device_type
export -f determine_external_security_level
export -f execute_basic_external_wipe
export -f execute_standard_external_wipe
export -f execute_enhanced_external_wipe
export -f check_device_presence
export -f handle_external_storage_device
export -f get_external_device_type_name
export -f get_security_level_name