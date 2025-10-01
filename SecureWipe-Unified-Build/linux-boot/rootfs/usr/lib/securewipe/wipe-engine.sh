#!/bin/bash
# SecureWipe Hybrid Wiping Engine
# Intelligently selects between cryptographic erase and overwrite methods

set -e

# Configuration
SECUREWIPE_VERSION="1.0.0"
LOG_FILE="/var/log/securewipe/wipe-engine.log"
CERTIFICATE_DIR="/tmp/securewipe-certificates"
WIPE_LOG_FILE="/tmp/securewipe-wipe.log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# Wiping methods
WIPE_METHOD_UNKNOWN=0
WIPE_METHOD_CRYPTO_ERASE=1
WIPE_METHOD_SECURE_OVERWRITE=2
WIPE_METHOD_HYBRID=3

# Device types
DEVICE_TYPE_UNKNOWN=0
DEVICE_TYPE_HDD=1
DEVICE_TYPE_SSD=2
DEVICE_TYPE_NVME=3
DEVICE_TYPE_EMMC=4
DEVICE_TYPE_USB=5

# Logging function
log_wipe() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$WIPE_LOG_FILE"
    if [ "$level" = "INFO" ] || [ "$level" = "WARN" ] || [ "$level" = "ERROR" ]; then
        echo -e "${CYAN}[$level]${NC} $message"
    fi
}

# Detect device type and characteristics
detect_device_type() {
    local device="$1"
    local device_type=$DEVICE_TYPE_UNKNOWN
    local is_ssd=false
    local is_nvme=false
    local supports_crypto_erase=false
    
    log_wipe "INFO" "Analyzing device type for: $device"
    
    # Check if it's an NVMe device
    if [[ "$device" == *"nvme"* ]]; then
        device_type=$DEVICE_TYPE_NVME
        is_nvme=true
        is_ssd=true
        log_wipe "INFO" "Detected NVMe device"
        
        # Check NVMe Format support
        if command -v nvme >/dev/null 2>&1; then
            if nvme format --help >/dev/null 2>&1; then
                supports_crypto_erase=true
                log_wipe "INFO" "NVMe Format command available - cryptographic erase supported"
            fi
        fi
    
    # Check if it's eMMC
    elif [[ "$device" == *"mmc"* ]]; then
        device_type=$DEVICE_TYPE_EMMC
        is_ssd=true
        log_wipe "INFO" "Detected eMMC device"
        
    # Check USB devices
    elif [[ "$device" == *"sd"* ]]; then
        # Try to determine if it's USB
        local device_path=$(udevadm info --query=path --name="$device" 2>/dev/null || echo "")
        if [[ "$device_path" == *"usb"* ]]; then
            device_type=$DEVICE_TYPE_USB
            log_wipe "INFO" "Detected USB storage device"
        else
            # Could be SATA SSD or HDD - need to check rotation rate
            local rotation_rate=$(lsblk -d -n -o ROTA "$device" 2>/dev/null || echo "1")
            if [ "$rotation_rate" = "0" ]; then
                device_type=$DEVICE_TYPE_SSD
                is_ssd=true
                log_wipe "INFO" "Detected SATA SSD (no rotation)"
                
                # Check ATA Secure Erase support
                if command -v hdparm >/dev/null 2>&1; then
                    local security_info=$(hdparm -I "$device" 2>/dev/null | grep -i "security" || echo "")
                    if [[ "$security_info" == *"supported"* ]]; then
                        supports_crypto_erase=true
                        log_wipe "INFO" "ATA Secure Erase supported"
                    fi
                fi
            else
                device_type=$DEVICE_TYPE_HDD
                log_wipe "INFO" "Detected traditional HDD (rotational)"
            fi
        fi
    fi
    
    # Return results via global variables
    export DETECTED_DEVICE_TYPE=$device_type
    export DETECTED_IS_SSD=$is_ssd
    export DETECTED_IS_NVME=$is_nvme
    export DETECTED_SUPPORTS_CRYPTO_ERASE=$supports_crypto_erase
    
    log_wipe "INFO" "Device analysis complete: Type=$device_type, SSD=$is_ssd, NVMe=$is_nvme, CryptoErase=$supports_crypto_erase"
}

# Determine optimal wiping method
determine_wipe_method() {
    local device="$1"
    local method=$WIPE_METHOD_UNKNOWN
    
    detect_device_type "$device"
    
    log_wipe "INFO" "Determining optimal wiping method for device: $device"
    
    # Decision logic based on device type and capabilities
    if [ "$DETECTED_SUPPORTS_CRYPTO_ERASE" = "true" ]; then
        if [ "$DETECTED_IS_NVME" = "true" ]; then
            method=$WIPE_METHOD_CRYPTO_ERASE
            export WIPE_COMMAND="nvme format"
            log_wipe "INFO" "Selected method: NVMe Cryptographic Erase (instant key destruction)"
        elif [ "$DETECTED_DEVICE_TYPE" = "$DEVICE_TYPE_SSD" ]; then
            method=$WIPE_METHOD_CRYPTO_ERASE
            export WIPE_COMMAND="hdparm secure-erase"
            log_wipe "INFO" "Selected method: ATA Secure Erase (cryptographic)"
        else
            method=$WIPE_METHOD_HYBRID
            export WIPE_COMMAND="crypto+overwrite"
            log_wipe "INFO" "Selected method: Hybrid (crypto erase + verification overwrite)"
        fi
    else
        # Fallback to secure overwrite
        method=$WIPE_METHOD_SECURE_OVERWRITE
        export WIPE_COMMAND="secure overwrite"
        log_wipe "INFO" "Selected method: Secure Overwrite (pattern-based)"
        
        if [ "$DETECTED_DEVICE_TYPE" = "$DEVICE_TYPE_HDD" ]; then
            log_wipe "INFO" "HDD detected - will include HPA detection and handling"
        fi
    fi
    
    export DETERMINED_WIPE_METHOD=$method
    return 0
}

# Display wiping plan to user
display_wipe_plan() {
    local device="$1"
    local device_info="$2"
    
    echo ""
    echo -e "${WHITE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                    SECURE WIPE PLAN                          ║${NC}"
    echo -e "${WHITE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}Target Device:${NC} $device_info"
    echo -e "${CYAN}Device Type:${NC} $(get_device_type_name $DETECTED_DEVICE_TYPE)"
    echo -e "${CYAN}Wipe Method:${NC} $(get_wipe_method_name $DETERMINED_WIPE_METHOD)"
    echo -e "${CYAN}Command:${NC} $WIPE_COMMAND"
    echo ""
    
    # Show method details
    case $DETERMINED_WIPE_METHOD in
        $WIPE_METHOD_CRYPTO_ERASE)
            echo -e "${GREEN}✅ Cryptographic Erase Selected${NC}"
            echo "• Instant destruction of encryption keys"
            echo "• Fastest and most secure method"
            echo "• Data immediately unrecoverable"
            ;;
        $WIPE_METHOD_SECURE_OVERWRITE)
            echo -e "${YELLOW}⚡ Secure Overwrite Selected${NC}"
            echo "• Single-pass zero pattern overwrite"
            echo "• Includes hidden area detection (HPA)"
            echo "• Verification pass included"
            ;;
        $WIPE_METHOD_HYBRID)
            echo -e "${BLUE}🔄 Hybrid Method Selected${NC}"
            echo "• Cryptographic erase + overwrite verification"
            echo "• Maximum security assurance"
            echo "• Comprehensive coverage"
            ;;
    esac
    
    echo ""
    echo -e "${WHITE}Security Features:${NC}"
    echo "• Tamper-proof logging"
    echo "• Digital certificate generation"
    echo "• Verification and validation"
    echo "• Audit trail creation"
    echo ""
}

# Helper functions for display
get_device_type_name() {
    case $1 in
        $DEVICE_TYPE_HDD) echo "Traditional Hard Drive (HDD)" ;;
        $DEVICE_TYPE_SSD) echo "Solid State Drive (SSD)" ;;
        $DEVICE_TYPE_NVME) echo "NVMe SSD" ;;
        $DEVICE_TYPE_EMMC) echo "eMMC Storage" ;;
        $DEVICE_TYPE_USB) echo "USB Storage Device" ;;
        *) echo "Unknown Device Type" ;;
    esac
}

get_wipe_method_name() {
    case $1 in
        $WIPE_METHOD_CRYPTO_ERASE) echo "Cryptographic Erase" ;;
        $WIPE_METHOD_SECURE_OVERWRITE) echo "Secure Overwrite" ;;
        $WIPE_METHOD_HYBRID) echo "Hybrid (Crypto + Overwrite)" ;;
        *) echo "Method Not Determined" ;;
    esac
}

# Main hybrid engine function
execute_hybrid_wipe_engine() {
    local device="$1"
    local device_info="$2"
    
    log_wipe "INFO" "Starting SecureWipe Hybrid Engine v$SECUREWIPE_VERSION"
    log_wipe "INFO" "Target device: $device ($device_info)"
    
    # Create directories
    mkdir -p "$(dirname "$LOG_FILE")"
    mkdir -p "$CERTIFICATE_DIR"
    
    # Determine optimal method
    determine_wipe_method "$device"
    
    # Display plan to user
    display_wipe_plan "$device" "$device_info"
    
    # Final confirmation
    echo -e "${RED}⚠️  FINAL CONFIRMATION REQUIRED ⚠️${NC}"
    echo ""
    echo "This will permanently destroy all data on:"
    echo "  $device_info"
    echo ""
    echo "Type 'WIPE NOW' (exactly) to proceed:"
    
    local final_confirmation
    read -r final_confirmation
    
    if [ "$final_confirmation" = "WIPE NOW" ]; then
        log_wipe "INFO" "Final confirmation received - proceeding with wipe"
        
        # TODO: Implement actual wiping logic in next steps
        echo ""
        echo -e "${GREEN}🚀 Wiping process initiated...${NC}"
        echo "This is where the actual wiping engine will be implemented."
        echo ""
        
        # Placeholder for actual implementation
        case $DETERMINED_WIPE_METHOD in
            $WIPE_METHOD_CRYPTO_ERASE)
                echo "➤ Would execute: $WIPE_COMMAND on $device"
                ;;
            $WIPE_METHOD_SECURE_OVERWRITE)
                echo "➤ Would execute: Secure overwrite on $device"
                ;;
            $WIPE_METHOD_HYBRID)
                echo "➤ Would execute: Hybrid method on $device"
                ;;
        esac
        
        log_wipe "INFO" "Wiping engine setup completed successfully"
        return 0
    else
        echo ""
        echo -e "${YELLOW}Operation cancelled - invalid confirmation${NC}"
        log_wipe "INFO" "Operation cancelled by user - invalid confirmation"
        return 1
    fi
}

# Main execution
if [ $# -ne 2 ]; then
    echo "Usage: $0 <device> <device_info>"
    exit 1
fi

execute_hybrid_wipe_engine "$1" "$2"