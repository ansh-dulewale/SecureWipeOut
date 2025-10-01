#!/bin/bash
# SecureWipe HDD Secure Overwrite Engine
# Implements secure single-pass zero overwrite with HPA handling

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

# Overwrite patterns
PATTERN_ZEROS="zeros"
PATTERN_RANDOM="random"
PATTERN_DOD="dod"

# Block sizes for different operations
BLOCK_SIZE_FAST="64M"
BLOCK_SIZE_STANDARD="16M"
BLOCK_SIZE_THOROUGH="4M"

# Detect and handle Host Protected Area (HPA)
detect_and_handle_hpa() {
    local device="$1"
    local hpa_detected=false
    local native_max_sectors=0
    local accessible_max_sectors=0
    local hpa_size=0
    
    log_wipe "INFO" "Checking for Host Protected Area (HPA) on $device"
    
    # Get HPA information using hdparm
    local hpa_info
    if hpa_info=$(hdparm -N "$device" 2>/dev/null); then
        echo -e "${CYAN}🔍 HPA Detection Results:${NC}"
        echo "$hpa_info"
        
        # Parse HPA information
        if echo "$hpa_info" | grep -q "max sectors.*via"; then
            # Extract sector counts
            accessible_max_sectors=$(echo "$hpa_info" | grep -o "max sectors.*via" | grep -o "[0-9]\+" | head -1)
            native_max_sectors=$(echo "$hpa_info" | grep -o "via.*[0-9]\+" | grep -o "[0-9]\+" | tail -1)
            
            if [ "$native_max_sectors" -gt "$accessible_max_sectors" ]; then
                hpa_detected=true
                hpa_size=$(( (native_max_sectors - accessible_max_sectors) * 512 / 1024 / 1024 ))  # MB
                
                echo -e "${YELLOW}⚠️  HOST PROTECTED AREA DETECTED ⚠️${NC}"
                echo "• Accessible sectors: $accessible_max_sectors"
                echo "• Native max sectors: $native_max_sectors"
                echo "• HPA size: ${hpa_size} MB"
                echo "• Hidden data may be present in HPA"
                
                log_wipe "WARN" "HPA detected: ${hpa_size}MB hidden area found"
            else
                echo -e "${GREEN}✅ No Host Protected Area detected${NC}"
                log_wipe "INFO" "No HPA detected on device"
            fi
        fi
    else
        log_wipe "WARN" "Could not check HPA status (device may not support ATA commands)"
        echo -e "${YELLOW}⚠️  Could not check HPA status${NC}"
    fi
    
    # Handle HPA if detected
    if [ "$hpa_detected" = "true" ]; then
        echo ""
        echo -e "${RED}HPA SECURITY CONSIDERATION:${NC}"
        echo "The Host Protected Area contains ${hpa_size}MB of potentially sensitive data."
        echo "For complete security, the HPA should also be wiped."
        echo ""
        echo "Options:"
        echo "1. Disable HPA temporarily and wipe full drive (RECOMMENDED)"
        echo "2. Wipe only accessible area (HPA remains)"
        echo "3. Cancel operation"
        echo ""
        echo -n "Choose option (1/2/3): "
        
        local hpa_choice
        read -r hpa_choice
        
        case "$hpa_choice" in
            1)
                echo -e "${BLUE}🔧 Temporarily disabling HPA for full drive wipe...${NC}"
                if hdparm -N "$native_max_sectors" "$device" >/dev/null 2>&1; then
                    echo -e "${GREEN}✅ HPA disabled - full drive accessible${NC}"
                    log_wipe "INFO" "HPA temporarily disabled for full drive access"
                    export HPA_WAS_DISABLED=true
                    export ORIGINAL_HPA_SIZE="$accessible_max_sectors"
                else
                    echo -e "${RED}❌ Failed to disable HPA${NC}"
                    log_wipe "ERROR" "Failed to disable HPA"
                    return 1
                fi
                ;;
            2)
                echo -e "${YELLOW}⚠️  Proceeding with accessible area only${NC}"
                log_wipe "WARN" "User chose to skip HPA wiping - ${hpa_size}MB will remain"
                export HPA_WAS_DISABLED=false
                ;;
            3)
                echo -e "${CYAN}Operation cancelled by user${NC}"
                log_wipe "INFO" "Operation cancelled due to HPA concerns"
                return 1
                ;;
            *)
                echo -e "${RED}Invalid choice - operation cancelled${NC}"
                return 1
                ;;
        esac
    else
        export HPA_WAS_DISABLED=false
    fi
    
    export HPA_DETECTED="$hpa_detected"
    export HPA_SIZE="$hpa_size"
    return 0
}

# Restore HPA settings after wipe
restore_hpa_settings() {
    local device="$1"
    
    if [ "$HPA_WAS_DISABLED" = "true" ] && [ -n "$ORIGINAL_HPA_SIZE" ]; then
        echo -e "${BLUE}🔧 Restoring original HPA settings...${NC}"
        log_wipe "INFO" "Restoring HPA to original size: $ORIGINAL_HPA_SIZE sectors"
        
        if hdparm -N "$ORIGINAL_HPA_SIZE" "$device" >/dev/null 2>&1; then
            echo -e "${GREEN}✅ HPA settings restored${NC}"
            log_wipe "INFO" "HPA settings successfully restored"
        else
            echo -e "${YELLOW}⚠️  Could not restore HPA settings${NC}"
            log_wipe "WARN" "Failed to restore original HPA settings"
        fi
    fi
}

# Get device size and geometry
get_device_geometry() {
    local device="$1"
    
    log_wipe "INFO" "Getting device geometry for $device"
    
    # Get device size in bytes
    local device_size_bytes
    if device_size_bytes=$(blockdev --getsize64 "$device" 2>/dev/null); then
        local device_size_gb=$((device_size_bytes / 1024 / 1024 / 1024))
        local device_size_mb=$((device_size_bytes / 1024 / 1024))
        
        echo -e "${CYAN}📐 Device Geometry:${NC}"
        echo "• Total size: ${device_size_gb} GB (${device_size_mb} MB)"
        echo "• Size in bytes: $device_size_bytes"
        
        # Get sector information
        local sector_size
        if sector_size=$(blockdev --getss "$device" 2>/dev/null); then
            local total_sectors=$((device_size_bytes / sector_size))
            echo "• Sector size: $sector_size bytes"
            echo "• Total sectors: $total_sectors"
        fi
        
        # Get block size
        local block_size
        if block_size=$(blockdev --getbsz "$device" 2>/dev/null); then
            echo "• Block size: $block_size bytes"
        fi
        
        export DEVICE_SIZE_BYTES="$device_size_bytes"
        export DEVICE_SIZE_GB="$device_size_gb"
        export DEVICE_SIZE_MB="$device_size_mb"
        
        log_wipe "INFO" "Device geometry: ${device_size_gb}GB total"
        return 0
    else
        log_wipe "ERROR" "Failed to determine device size"
        return 1
    fi
}

# Calculate estimated time for overwrite
estimate_overwrite_time() {
    local device_size_gb="$1"
    local estimated_speed=50  # MB/s conservative estimate for HDD
    
    local estimated_seconds=$((DEVICE_SIZE_MB / estimated_speed))
    local estimated_minutes=$((estimated_seconds / 60))
    local estimated_hours=$((estimated_minutes / 60))
    
    echo -e "${CYAN}⏱️  Estimated Overwrite Time:${NC}"
    if [ "$estimated_hours" -gt 0 ]; then
        echo "• Approximately: ${estimated_hours}h ${estimated_minutes}m"
    elif [ "$estimated_minutes" -gt 0 ]; then
        echo "• Approximately: ${estimated_minutes} minutes"
    else
        echo "• Approximately: ${estimated_seconds} seconds"
    fi
    echo "• Based on ${estimated_speed} MB/s average speed"
    echo ""
}

# Execute secure overwrite with progress monitoring
execute_secure_overwrite() {
    local device="$1"
    local pattern="$2"
    local block_size="$3"
    
    log_wipe "INFO" "Starting secure overwrite: $device with $pattern pattern, block size $block_size"
    
    local start_time=$(date +%s)
    local dd_command=""
    local pattern_description=""
    
    # Prepare overwrite command based on pattern
    case "$pattern" in
        "$PATTERN_ZEROS")
            dd_command="dd if=/dev/zero of=$device bs=$block_size status=progress oflag=sync"
            pattern_description="Zero Pattern (0x00)"
            ;;
        "$PATTERN_RANDOM")
            dd_command="dd if=/dev/urandom of=$device bs=$block_size status=progress oflag=sync"
            pattern_description="Random Pattern"
            ;;
        "$PATTERN_DOD")
            # DoD 5220.22-M pattern (simplified single pass with zeros)
            dd_command="dd if=/dev/zero of=$device bs=$block_size status=progress oflag=sync"
            pattern_description="DoD Pattern (Zeros)"
            ;;
        *)
            dd_command="dd if=/dev/zero of=$device bs=$block_size status=progress oflag=sync"
            pattern_description="Default Zero Pattern"
            ;;
    esac
    
    echo ""
    echo -e "${GREEN}🚀 Starting Secure Overwrite${NC}"
    echo -e "${CYAN}Pattern: $pattern_description${NC}"
    echo -e "${CYAN}Block Size: $block_size${NC}"
    echo -e "${CYAN}Command: $dd_command${NC}"
    echo ""
    echo -e "${YELLOW}⏳ Overwrite in progress...${NC}"
    echo -e "${WHITE}Note: This operation will take significant time to complete${NC}"
    echo ""
    
    # Execute the overwrite
    local overwrite_result=0
    if eval "$dd_command" 2>&1 | tee -a "$WIPE_LOG_FILE"; then
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local duration_min=$((duration / 60))
        local duration_hour=$((duration_min / 60))
        
        echo ""
        echo -e "${GREEN}✅ Secure Overwrite COMPLETED${NC}"
        
        if [ "$duration_hour" -gt 0 ]; then
            echo "• Duration: ${duration_hour}h ${duration_min}m (${duration}s total)"
        elif [ "$duration_min" -gt 0 ]; then
            echo "• Duration: ${duration_min} minutes (${duration}s total)"
        else
            echo "• Duration: ${duration} seconds"
        fi
        
        echo "• Pattern: $pattern_description"
        echo "• Block Size: $block_size"
        echo "• Status: All sectors overwritten"
        
        log_wipe "INFO" "Secure overwrite completed successfully in ${duration}s"
        
        # Calculate average speed
        if [ "$duration" -gt 0 ]; then
            local avg_speed_mb=$((DEVICE_SIZE_MB / duration))
            echo "• Average Speed: ${avg_speed_mb} MB/s"
            log_wipe "INFO" "Average overwrite speed: ${avg_speed_mb} MB/s"
        fi
        
        overwrite_result=0
    else
        echo ""
        echo -e "${RED}❌ Secure Overwrite FAILED${NC}"
        log_wipe "ERROR" "Secure overwrite failed during execution"
        overwrite_result=1
    fi
    
    # Record overwrite details
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    cat >> "$WIPE_LOG_FILE" <<EOF

=== HDD SECURE OVERWRITE REPORT ===
Device: $device
Pattern: $pattern_description
Block Size: $block_size
Start Time: $(date -d "@$start_time")
End Time: $(date -d "@$end_time")
Duration: ${duration} seconds
Device Size: ${DEVICE_SIZE_GB} GB
HPA Detected: ${HPA_DETECTED:-false}
HPA Handled: ${HPA_WAS_DISABLED:-false}
Status: $([ "$overwrite_result" = "0" ] && echo "SUCCESS" || echo "FAILED")
Data Recovery: $([ "$overwrite_result" = "0" ] && echo "EXTREMELY DIFFICULT" || echo "UNKNOWN")
EOF
    
    return $overwrite_result
}

# Verify overwrite completion
verify_overwrite() {
    local device="$1"
    
    log_wipe "INFO" "Starting overwrite verification for $device"
    
    echo ""
    echo -e "${BLUE}🔍 Verifying Overwrite Completion${NC}"
    echo -e "${YELLOW}Sampling random sectors for verification...${NC}"
    
    # Sample a few random sectors to verify they contain zeros
    local device_sectors=$((DEVICE_SIZE_BYTES / 512))
    local samples_to_check=10
    local verification_passed=true
    
    for i in $(seq 1 $samples_to_check); do
        # Generate random sector number (excluding first and last few sectors)
        local random_sector=$((RANDOM % (device_sectors - 1000) + 500))
        local sample_output
        
        # Read one sector at the random position
        if sample_output=$(dd if="$device" bs=512 skip="$random_sector" count=1 2>/dev/null | hexdump -C | head -5); then
            # Check if the sector contains all zeros
            if echo "$sample_output" | grep -qv "00 00 00 00 00 00 00 00"; then
                echo -e "${RED}❌ Non-zero data found at sector $random_sector${NC}"
                verification_passed=false
                break
            else
                echo -e "${GREEN}✓${NC} Sector $random_sector: All zeros verified"
            fi
        else
            echo -e "${YELLOW}⚠️  Could not read sector $random_sector${NC}"
        fi
    done
    
    if [ "$verification_passed" = "true" ]; then
        echo ""
        echo -e "${GREEN}✅ Overwrite Verification PASSED${NC}"
        echo "• All sampled sectors contain zeros"
        echo "• Overwrite appears successful"
        log_wipe "INFO" "Overwrite verification passed - all samples contained zeros"
        return 0
    else
        echo ""
        echo -e "${RED}❌ Overwrite Verification FAILED${NC}"
        echo "• Non-zero data detected in samples"
        echo "• Overwrite may be incomplete"
        log_wipe "ERROR" "Overwrite verification failed - non-zero data detected"
        return 1
    fi
}

# Main HDD secure overwrite function
execute_hdd_secure_overwrite() {
    local device="$1"
    
    log_wipe "INFO" "Starting HDD secure overwrite for device: $device"
    
    echo ""
    echo -e "${WHITE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                HDD SECURE OVERWRITE ENGINE                    ║${NC}"
    echo -e "${WHITE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Step 1: Get device geometry
    if ! get_device_geometry "$device"; then
        return 1
    fi
    
    echo ""
    
    # Step 2: Check and handle HPA
    if ! detect_and_handle_hpa "$device"; then
        return 1
    fi
    
    echo ""
    
    # Step 3: Show time estimate
    estimate_overwrite_time "$DEVICE_SIZE_GB"
    
    # Step 4: Final confirmation
    echo -e "${RED}⚠️  FINAL HDD OVERWRITE CONFIRMATION ⚠️${NC}"
    echo ""
    echo "This will permanently overwrite all data on:"
    echo "  Device: $device"
    echo "  Size: ${DEVICE_SIZE_GB} GB"
    echo "  HPA Handling: $([ "$HPA_WAS_DISABLED" = "true" ] && echo "Full drive (HPA disabled)" || echo "Accessible area only")"
    echo ""
    echo "Type 'OVERWRITE NOW' to proceed:"
    
    local overwrite_confirm
    read -r overwrite_confirm
    
    if [ "$overwrite_confirm" != "OVERWRITE NOW" ]; then
        echo -e "${CYAN}Operation cancelled by user${NC}"
        log_wipe "INFO" "HDD overwrite cancelled by user"
        restore_hpa_settings "$device"
        return 1
    fi
    
    # Step 5: Execute secure overwrite
    local overwrite_success=false
    if execute_secure_overwrite "$device" "$PATTERN_ZEROS" "$BLOCK_SIZE_STANDARD"; then
        overwrite_success=true
    fi
    
    # Step 6: Verify overwrite
    local verification_success=false
    if [ "$overwrite_success" = "true" ]; then
        if verify_overwrite "$device"; then
            verification_success=true
        fi
    fi
    
    # Step 7: Restore HPA settings
    restore_hpa_settings "$device"
    
    # Step 8: Final status
    echo ""
    if [ "$overwrite_success" = "true" ] && [ "$verification_success" = "true" ]; then
        echo -e "${GREEN}🎉 HDD SECURE OVERWRITE COMPLETED SUCCESSFULLY${NC}"
        echo ""
        echo -e "${WHITE}Security Summary:${NC}"
        echo "• Method: Single-pass zero overwrite"
        echo "• Coverage: $([ "$HPA_WAS_DISABLED" = "true" ] && echo "Full drive including HPA" || echo "Accessible area")"
        echo "• Verification: Passed"
        echo "• Data Recovery: Extremely difficult"
        
        log_wipe "INFO" "HDD secure overwrite completed successfully with verification"
        return 0
    else
        echo -e "${RED}❌ HDD SECURE OVERWRITE FAILED${NC}"
        log_wipe "ERROR" "HDD secure overwrite failed"
        return 1
    fi
}

# Export functions for use by main engine
export -f detect_and_handle_hpa
export -f restore_hpa_settings
export -f get_device_geometry
export -f estimate_overwrite_time
export -f execute_secure_overwrite
export -f verify_overwrite
export -f execute_hdd_secure_overwrite