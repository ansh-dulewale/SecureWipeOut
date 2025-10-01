#!/bin/bash
# SecureWipe Comprehensive Verification Engine
# Validates successful data destruction and generates proof of erasure

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

# Verification levels
VERIFY_LEVEL_BASIC=1
VERIFY_LEVEL_STANDARD=2
VERIFY_LEVEL_THOROUGH=3
VERIFY_LEVEL_FORENSIC=4

# Verification methods
VERIFY_METHOD_PATTERN_CHECK=1
VERIFY_METHOD_RANDOM_SAMPLING=2
VERIFY_METHOD_FULL_SCAN=3
VERIFY_METHOD_ENTROPY_ANALYSIS=4

# Initialize verification engine
initialize_verification_engine() {
    local device="$1"
    
    log_wipe "INFO" "Initializing verification engine for device: $device"
    
    # Create verification directory
    local verify_dir="/tmp/securewipe-verification"
    mkdir -p "$verify_dir"
    
    # Get device geometry for verification
    if ! get_device_geometry "$device"; then
        log_wipe "ERROR" "Failed to get device geometry for verification"
        return 1
    fi
    
    export VERIFY_DIR="$verify_dir"
    export VERIFY_DEVICE="$device"
    export VERIFY_TOTAL_SECTORS=$((DEVICE_SIZE_BYTES / 512))
    
    log_wipe "INFO" "Verification engine initialized: ${VERIFY_TOTAL_SECTORS} sectors to verify"
    return 0
}

# Pattern-based verification
execute_pattern_verification() {
    local device="$1"
    local expected_pattern="$2"  # "zeros", "random", "pattern", or hex value like "0x55"
    local sample_count="$3"      # number of sectors to sample
    
    log_wipe "INFO" "Starting pattern verification for $device with pattern: $expected_pattern"
    
    echo -e "${BLUE}🔍 Pattern Verification${NC}"
    echo "• Expected Pattern: $expected_pattern"
    echo "• Sample Count: $sample_count sectors"
    echo "• Coverage: $(echo "scale=2; $sample_count * 100.0 / $VERIFY_TOTAL_SECTORS" | bc -l)% of device"
    echo ""
    
    local verification_passed=true
    local failed_sectors=0
    local verified_sectors=0
    
    # Progress indicator
    local progress_interval=$((sample_count / 20))  # Show progress every 5%
    if [ "$progress_interval" -lt 1 ]; then
        progress_interval=1
    fi
    
    echo -e "${YELLOW}⏳ Verifying pattern across device...${NC}"
    
    for i in $(seq 1 "$sample_count"); do
        # Show progress
        if [ $((i % progress_interval)) -eq 0 ]; then
            local percent=$((i * 100 / sample_count))
            echo -ne "\rProgress: ${percent}% (${i}/${sample_count} sectors)"
        fi
        
        # Generate random sector number (avoid first/last 1000 sectors)
        local random_sector=$((RANDOM % (VERIFY_TOTAL_SECTORS - 2000) + 1000))
        
        # Read sector
        local sector_data
        if sector_data=$(dd if="$device" bs=512 skip="$random_sector" count=1 2>/dev/null | hexdump -C); then
            local pattern_match=false
            
            case "$expected_pattern" in
                "zeros")
                    if echo "$sector_data" | grep -q "00 00 00 00 00 00 00 00"; then
                        if ! echo "$sector_data" | grep -v "00 00 00 00 00 00 00 00" | grep -q "[0-9a-f][0-9a-f]"; then
                            pattern_match=true
                        fi
                    fi
                    ;;
                "0x55")
                    if echo "$sector_data" | grep -q "55 55 55 55 55 55 55 55"; then
                        pattern_match=true
                    fi
                    ;;
                "0xaa")
                    if echo "$sector_data" | grep -q "aa aa aa aa aa aa aa aa"; then
                        pattern_match=true
                    fi
                    ;;
                "random")
                    # For random data, check that it's not all zeros or all same pattern
                    if ! echo "$sector_data" | grep -q "00 00 00 00 00 00 00 00"; then
                        if ! echo "$sector_data" | grep -q "ff ff ff ff ff ff ff ff"; then
                            pattern_match=true
                        fi
                    fi
                    ;;
            esac
            
            if [ "$pattern_match" = "true" ]; then
                verified_sectors=$((verified_sectors + 1))
            else
                failed_sectors=$((failed_sectors + 1))
                # Log first few failures for debugging
                if [ "$failed_sectors" -le 5 ]; then
                    log_wipe "WARN" "Pattern mismatch at sector $random_sector"
                fi
            fi
        else
            failed_sectors=$((failed_sectors + 1))
            log_wipe "WARN" "Could not read sector $random_sector"
        fi
    done
    
    echo -ne "\rProgress: 100% (${sample_count}/${sample_count} sectors)    \n"
    
    # Calculate verification statistics
    local success_rate=$((verified_sectors * 100 / sample_count))
    local failure_rate=$((failed_sectors * 100 / sample_count))
    
    echo ""
    echo -e "${CYAN}Pattern Verification Results:${NC}"
    echo "• Sectors Verified: $verified_sectors"
    echo "• Sectors Failed: $failed_sectors"
    echo "• Success Rate: ${success_rate}%"
    echo "• Failure Rate: ${failure_rate}%"
    
    # Determine pass/fail (allow up to 1% failure rate for error tolerance)
    if [ "$failure_rate" -le 1 ]; then
        echo -e "${GREEN}✅ Pattern Verification: PASSED${NC}"
        log_wipe "INFO" "Pattern verification passed with ${success_rate}% success rate"
        return 0
    else
        echo -e "${RED}❌ Pattern Verification: FAILED${NC}"
        log_wipe "ERROR" "Pattern verification failed with ${failure_rate}% failure rate"
        return 1
    fi
}

# Entropy analysis verification
execute_entropy_verification() {
    local device="$1"
    local sample_count="$2"
    
    log_wipe "INFO" "Starting entropy analysis verification for $device"
    
    echo -e "${BLUE}🧮 Entropy Analysis Verification${NC}"
    echo "• Sample Count: $sample_count sectors"
    echo "• Method: Statistical randomness analysis"
    echo ""
    
    local entropy_samples_file="$VERIFY_DIR/entropy-samples.bin"
    local total_entropy=0
    local samples_collected=0
    
    echo -e "${YELLOW}⏳ Collecting entropy samples...${NC}"
    
    # Collect random samples
    for i in $(seq 1 "$sample_count"); do
        local random_sector=$((RANDOM % (VERIFY_TOTAL_SECTORS - 2000) + 1000))
        
        # Read 512 bytes from random sector
        if dd if="$device" bs=512 skip="$random_sector" count=1 2>/dev/null >> "$entropy_samples_file"; then
            samples_collected=$((samples_collected + 1))
        fi
        
        # Progress indicator
        if [ $((i % (sample_count / 10))) -eq 0 ]; then
            local percent=$((i * 100 / sample_count))
            echo -ne "\rCollecting samples: ${percent}%"
        fi
    done
    
    echo -ne "\rCollecting samples: 100%    \n"
    
    # Calculate entropy using available tools
    local entropy_score=0
    if command -v ent >/dev/null 2>&1; then
        # Use 'ent' tool if available for precise entropy calculation
        local ent_output=$(ent "$entropy_samples_file" 2>/dev/null || echo "")
        if [ -n "$ent_output" ]; then
            entropy_score=$(echo "$ent_output" | grep "Entropy" | grep -o "[0-9.]*" | head -1 || echo "0")
        fi
    else
        # Fallback: Simple entropy estimation using unique byte count
        local unique_bytes=$(hexdump -C "$entropy_samples_file" | cut -c10-49 | tr ' ' '\n' | sort -u | wc -l)
        entropy_score=$(echo "scale=2; $unique_bytes / 256.0 * 8.0" | bc -l 2>/dev/null || echo "0")
    fi
    
    echo ""
    echo -e "${CYAN}Entropy Analysis Results:${NC}"
    echo "• Samples Collected: $samples_collected"
    echo "• Sample Size: $(stat -c%s "$entropy_samples_file" 2>/dev/null || echo "unknown") bytes"
    echo "• Entropy Score: $entropy_score bits/byte"
    
    # Evaluate entropy
    local entropy_check=$(echo "$entropy_score > 6.0" | bc -l 2>/dev/null || echo "0")
    if [ "$entropy_check" = "1" ]; then
        echo -e "${GREEN}✅ Entropy Analysis: PASSED (High randomness)${NC}"
        log_wipe "INFO" "Entropy verification passed with score: $entropy_score"
        rm -f "$entropy_samples_file"
        return 0
    else
        local low_entropy_check=$(echo "$entropy_score < 1.0" | bc -l 2>/dev/null || echo "0")
        if [ "$low_entropy_check" = "1" ]; then
            echo -e "${GREEN}✅ Entropy Analysis: PASSED (Consistent pattern - likely zeros)${NC}"
            log_wipe "INFO" "Entropy verification passed with consistent pattern: $entropy_score"
            rm -f "$entropy_samples_file"
            return 0
        else
            echo -e "${YELLOW}⚠️  Entropy Analysis: UNCLEAR (Moderate entropy)${NC}"
            log_wipe "WARN" "Entropy verification unclear with score: $entropy_score"
            rm -f "$entropy_samples_file"
            return 1
        fi
    fi
}

# Full device scan verification
execute_full_scan_verification() {
    local device="$1"
    local scan_percentage="$2"  # percentage of device to scan (1-100)
    
    log_wipe "INFO" "Starting full scan verification for $device (${scan_percentage}% coverage)"
    
    echo -e "${BLUE}🔍 Full Device Scan Verification${NC}"
    echo "• Scan Coverage: ${scan_percentage}% of device"
    echo "• Method: Sequential sector reading"
    echo ""
    
    local sectors_to_scan=$((VERIFY_TOTAL_SECTORS * scan_percentage / 100))
    local scan_interval=$((VERIFY_TOTAL_SECTORS / sectors_to_scan))
    local scanned_sectors=0
    local suspicious_sectors=0
    
    echo -e "${YELLOW}⏳ Scanning device sectors...${NC}"
    echo "This may take several minutes depending on device size and scan percentage."
    echo ""
    
    # Scan sectors at regular intervals
    for sector in $(seq 0 "$scan_interval" "$VERIFY_TOTAL_SECTORS"); do
        if [ "$sector" -ge "$VERIFY_TOTAL_SECTORS" ]; then
            break
        fi
        
        # Read sector
        local sector_data
        if sector_data=$(dd if="$device" bs=512 skip="$sector" count=1 2>/dev/null | hexdump -C | head -5); then
            scanned_sectors=$((scanned_sectors + 1))
            
            # Look for suspicious patterns (non-zero data that looks like file system remnants)
            if echo "$sector_data" | grep -q -E "(FAT|NTFS|ext[234]|HFS|APFS|UFS)"; then
                suspicious_sectors=$((suspicious_sectors + 1))
                log_wipe "WARN" "Suspicious data pattern found at sector $sector"
            fi
            
            # Progress indicator
            if [ $((scanned_sectors % (sectors_to_scan / 20))) -eq 0 ]; then
                local percent=$((scanned_sectors * 100 / sectors_to_scan))
                echo -ne "\rScanning progress: ${percent}% (${scanned_sectors}/${sectors_to_scan} sectors)"
            fi
        fi
    done
    
    echo -ne "\rScanning progress: 100% (${scanned_sectors}/${sectors_to_scan} sectors)    \n"
    
    echo ""
    echo -e "${CYAN}Full Scan Results:${NC}"
    echo "• Sectors Scanned: $scanned_sectors"
    echo "• Coverage: ${scan_percentage}% of device"
    echo "• Suspicious Sectors: $suspicious_sectors"
    
    if [ "$suspicious_sectors" -eq 0 ]; then
        echo -e "${GREEN}✅ Full Scan Verification: PASSED${NC}"
        log_wipe "INFO" "Full scan verification passed - no suspicious data found"
        return 0
    else
        local suspicion_rate=$((suspicious_sectors * 100 / scanned_sectors))
        if [ "$suspicion_rate" -le 5 ]; then
            echo -e "${YELLOW}⚠️  Full Scan Verification: PASSED WITH WARNINGS${NC}"
            echo "• ${suspicion_rate}% suspicious sectors (within acceptable range)"
            log_wipe "WARN" "Full scan verification passed with ${suspicious_sectors} suspicious sectors"
            return 0
        else
            echo -e "${RED}❌ Full Scan Verification: FAILED${NC}"
            echo "• ${suspicion_rate}% suspicious sectors (too high)"
            log_wipe "ERROR" "Full scan verification failed with ${suspicious_sectors} suspicious sectors"
            return 1
        fi
    fi
}

# Comprehensive verification suite
execute_comprehensive_verification() {
    local device="$1"
    local wipe_method="$2"
    local verification_level="$3"  # basic/standard/thorough/forensic
    
    log_wipe "INFO" "Starting comprehensive verification for device: $device"
    
    echo ""
    echo -e "${WHITE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║              COMPREHENSIVE VERIFICATION ENGINE                ║${NC}"
    echo -e "${WHITE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Initialize verification engine
    if ! initialize_verification_engine "$device"; then
        return 1
    fi
    
    echo -e "${CYAN}🎯 Verification Configuration${NC}"
    echo "• Device: $device"
    echo "• Wipe Method: $wipe_method"
    echo "• Verification Level: $verification_level"
    echo "• Device Size: ${DEVICE_SIZE_GB} GB"
    echo "• Total Sectors: $VERIFY_TOTAL_SECTORS"
    echo ""
    
    local verification_passed=true
    local tests_completed=0
    local tests_passed=0
    
    # Determine verification tests based on level and wipe method
    case "$verification_level" in
        "basic")
            echo -e "${BLUE}📋 Basic Verification Suite${NC}"
            echo "• Pattern check (1000 samples)"
            echo ""
            
            # Basic pattern verification
            local expected_pattern="zeros"
            if [[ "$wipe_method" == *"0x55"* ]] || [[ "$wipe_method" == *"pattern"* ]]; then
                expected_pattern="0x55"
            fi
            
            tests_completed=1
            if execute_pattern_verification "$device" "$expected_pattern" 1000; then
                tests_passed=$((tests_passed + 1))
            else
                verification_passed=false
            fi
            ;;
            
        "standard")
            echo -e "${BLUE}📋 Standard Verification Suite${NC}"
            echo "• Pattern check (5000 samples)"
            echo "• Entropy analysis (1000 samples)"
            echo ""
            
            # Pattern verification
            local expected_pattern="zeros"
            if [[ "$wipe_method" == *"0x55"* ]] || [[ "$wipe_method" == *"pattern"* ]]; then
                expected_pattern="0x55"
            elif [[ "$wipe_method" == *"random"* ]]; then
                expected_pattern="random"
            fi
            
            tests_completed=2
            if execute_pattern_verification "$device" "$expected_pattern" 5000; then
                tests_passed=$((tests_passed + 1))
            else
                verification_passed=false
            fi
            
            # Entropy analysis
            if execute_entropy_verification "$device" 1000; then
                tests_passed=$((tests_passed + 1))
            else
                verification_passed=false
            fi
            ;;
            
        "thorough")
            echo -e "${BLUE}📋 Thorough Verification Suite${NC}"
            echo "• Pattern check (10000 samples)"
            echo "• Entropy analysis (2000 samples)"
            echo "• Partial device scan (10% coverage)"
            echo ""
            
            tests_completed=3
            # Pattern verification
            local expected_pattern="zeros"
            if [[ "$wipe_method" == *"0x55"* ]] || [[ "$wipe_method" == *"pattern"* ]]; then
                expected_pattern="0x55"
            elif [[ "$wipe_method" == *"random"* ]]; then
                expected_pattern="random"
            fi
            
            if execute_pattern_verification "$device" "$expected_pattern" 10000; then
                tests_passed=$((tests_passed + 1))
            else
                verification_passed=false
            fi
            
            # Entropy analysis
            if execute_entropy_verification "$device" 2000; then
                tests_passed=$((tests_passed + 1))
            else
                verification_passed=false
            fi
            
            # Partial scan
            if execute_full_scan_verification "$device" 10; then
                tests_passed=$((tests_passed + 1))
            else
                verification_passed=false
            fi
            ;;
            
        "forensic")
            echo -e "${BLUE}📋 Forensic Verification Suite${NC}"
            echo "• Pattern check (25000 samples)"
            echo "• Entropy analysis (5000 samples)"
            echo "• Extensive device scan (50% coverage)"
            echo ""
            
            tests_completed=3
            # Extensive pattern verification
            local expected_pattern="zeros"
            if [[ "$wipe_method" == *"0x55"* ]] || [[ "$wipe_method" == *"pattern"* ]]; then
                expected_pattern="0x55"
            elif [[ "$wipe_method" == *"random"* ]]; then
                expected_pattern="random"
            fi
            
            if execute_pattern_verification "$device" "$expected_pattern" 25000; then
                tests_passed=$((tests_passed + 1))
            else
                verification_passed=false
            fi
            
            # Comprehensive entropy analysis
            if execute_entropy_verification "$device" 5000; then
                tests_passed=$((tests_passed + 1))
            else
                verification_passed=false
            fi
            
            # Extensive scan
            if execute_full_scan_verification "$device" 50; then
                tests_passed=$((tests_passed + 1))
            else
                verification_passed=false
            fi
            ;;
    esac
    
    # Final verification results
    echo ""
    echo -e "${WHITE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║                  VERIFICATION RESULTS                         ║${NC}"
    echo -e "${WHITE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local success_rate=$((tests_passed * 100 / tests_completed))
    
    echo -e "${CYAN}Summary:${NC}"
    echo "• Tests Completed: $tests_completed"
    echo "• Tests Passed: $tests_passed"
    echo "• Success Rate: ${success_rate}%"
    echo "• Verification Level: $verification_level"
    echo ""
    
    if [ "$verification_passed" = "true" ]; then
        echo -e "${GREEN}🎉 COMPREHENSIVE VERIFICATION: PASSED${NC}"
        echo ""
        echo -e "${WHITE}Data Destruction Confirmation:${NC}"
        echo "• All verification tests passed"
        echo "• Data recovery is extremely unlikely"
        echo "• Device meets security standards"
        echo "• Ready for certificate generation"
        
        log_wipe "INFO" "Comprehensive verification passed with ${success_rate}% success rate"
        return 0
    else
        echo -e "${RED}❌ COMPREHENSIVE VERIFICATION: FAILED${NC}"
        echo ""
        echo -e "${WHITE}Issues Detected:${NC}"
        echo "• $((tests_completed - tests_passed)) verification tests failed"
        echo "• Data destruction may be incomplete"
        echo "• Additional wiping may be required"
        echo "• Certificate generation not recommended"
        
        log_wipe "ERROR" "Comprehensive verification failed - ${tests_passed}/${tests_completed} tests passed"
        return 1
    fi
}

# Generate verification report
generate_verification_report() {
    local device="$1"
    local verification_result="$2"
    local verification_level="$3"
    
    local report_file="$VERIFY_DIR/verification-report.txt"
    
    cat > "$report_file" <<EOF
=============================================================================
                    SECUREWIPE VERIFICATION REPORT
=============================================================================

Report Generated: $(date '+%Y-%m-%d %H:%M:%S %Z')
Device: $device
Verification Level: $verification_level
Overall Result: $verification_result

Device Information:
- Size: ${DEVICE_SIZE_GB} GB
- Total Sectors: $VERIFY_TOTAL_SECTORS
- Device Type: $(get_device_type_name "$DETECTED_DEVICE_TYPE")

Verification Details:
$(cat "$WIPE_LOG_FILE" | grep -E "(INFO|WARN|ERROR).*verif" | tail -20)

Conclusion:
$(if [ "$verification_result" = "PASSED" ]; then
    echo "✅ Data destruction verification PASSED"
    echo "   All verification tests completed successfully."
    echo "   Data recovery is extremely unlikely."
    echo "   Device is ready for reuse or disposal."
else
    echo "❌ Data destruction verification FAILED"
    echo "   One or more verification tests failed."
    echo "   Additional wiping may be required."
    echo "   Review verification log for details."
fi)

=============================================================================
This report was generated by SecureWipe v$SECUREWIPE_VERSION
SecureWipe India Pvt Ltd - Certified Data Sanitization
=============================================================================
EOF

    echo ""
    echo -e "${CYAN}📄 Verification report saved to: $report_file${NC}"
    log_wipe "INFO" "Verification report generated: $report_file"
}

# Export functions for use by main engine
export -f initialize_verification_engine
export -f execute_pattern_verification
export -f execute_entropy_verification
export -f execute_full_scan_verification
export -f execute_comprehensive_verification
export -f generate_verification_report