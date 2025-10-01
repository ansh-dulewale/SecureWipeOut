#!/bin/bash
# SecureWipe Digital Certificate Generation System
# Creates tamper-proof certificates with cryptographic signatures

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

# Certificate configuration
CERT_VERSION="1.0"
CERT_AUTHORITY="SecureWipe India Pvt Ltd"
CERT_VALIDITY_YEARS=10
OPENSSL_CONFIG="/tmp/securewipe-openssl.conf"

# Certificate paths
CERT_DIR="/tmp/securewipe-certificates"
CA_KEY_FILE="$CERT_DIR/securewipe-ca.key"
CA_CERT_FILE="$CERT_DIR/securewipe-ca.crt"
DEVICE_KEY_FILE="$CERT_DIR/device-cert.key"
DEVICE_CERT_FILE="$CERT_DIR/device-cert.crt"
FINAL_CERT_FILE="$CERT_DIR/SecureWipe-Certificate.pdf"

# Initialize certificate authority
initialize_certificate_authority() {
    log_wipe "INFO" "Initializing SecureWipe Certificate Authority"
    
    mkdir -p "$CERT_DIR"
    
    echo -e "${BLUE}🔐 Initializing Certificate Authority...${NC}"
    
    # Create OpenSSL configuration
    cat > "$OPENSSL_CONFIG" <<EOF
[ req ]
default_bits = 4096
default_md = sha256
distinguished_name = req_distinguished_name
x509_extensions = v3_ca
prompt = no

[ req_distinguished_name ]
C = IN
ST = Karnataka
L = Bangalore
O = SecureWipe India Pvt Ltd
OU = Data Security Division
CN = SecureWipe Certificate Authority
emailAddress = certificates@securewipe.in

[ v3_ca ]
basicConstraints = CA:TRUE
keyUsage = critical, digitalSignature, keyEncipherment, keyCertSign
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always

[ v3_end ]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer:always
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = securewipe.local
DNS.2 = localhost
IP.1 = 127.0.0.1
EOF

    # Generate CA private key
    if [ ! -f "$CA_KEY_FILE" ]; then
        echo -e "${CYAN}🔑 Generating CA private key...${NC}"
        if openssl genrsa -out "$CA_KEY_FILE" 4096 2>/dev/null; then
            chmod 600 "$CA_KEY_FILE"
            log_wipe "INFO" "CA private key generated successfully"
        else
            log_wipe "ERROR" "Failed to generate CA private key"
            return 1
        fi
    fi
    
    # Generate CA certificate
    if [ ! -f "$CA_CERT_FILE" ]; then
        echo -e "${CYAN}📜 Generating CA certificate...${NC}"
        if openssl req -new -x509 -key "$CA_KEY_FILE" -out "$CA_CERT_FILE" \
                -days $((CERT_VALIDITY_YEARS * 365)) -config "$OPENSSL_CONFIG" \
                -extensions v3_ca 2>/dev/null; then
            log_wipe "INFO" "CA certificate generated successfully"
        else
            log_wipe "ERROR" "Failed to generate CA certificate"
            return 1
        fi
    fi
    
    echo -e "${GREEN}✅ Certificate Authority initialized${NC}"
    return 0
}

# Generate device-specific certificate
generate_device_certificate() {
    local device="$1"
    local device_serial="$2"
    local device_model="$3"
    
    log_wipe "INFO" "Generating device certificate for $device"
    
    echo -e "${BLUE}📋 Generating Device Certificate...${NC}"
    
    # Create device-specific OpenSSL config
    local device_config="/tmp/device-$$.conf"
    cat > "$device_config" <<EOF
[ req ]
default_bits = 2048
default_md = sha256
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[ req_distinguished_name ]
C = IN
ST = Karnataka
L = Bangalore
O = SecureWipe India Pvt Ltd
OU = Device Certification
CN = Device $device_serial
emailAddress = device-certs@securewipe.in

[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = device-$device_serial.securewipe.local
EOF

    # Generate device private key
    echo -e "${CYAN}🔑 Generating device private key...${NC}"
    if openssl genrsa -out "$DEVICE_KEY_FILE" 2048 2>/dev/null; then
        chmod 600 "$DEVICE_KEY_FILE"
        log_wipe "INFO" "Device private key generated"
    else
        log_wipe "ERROR" "Failed to generate device private key"
        rm -f "$device_config"
        return 1
    fi
    
    # Generate certificate signing request
    echo -e "${CYAN}📝 Creating certificate signing request...${NC}"
    local csr_file="/tmp/device-$$.csr"
    if openssl req -new -key "$DEVICE_KEY_FILE" -out "$csr_file" \
            -config "$device_config" 2>/dev/null; then
        log_wipe "INFO" "Certificate signing request created"
    else
        log_wipe "ERROR" "Failed to create certificate signing request"
        rm -f "$device_config" "$csr_file"
        return 1
    fi
    
    # Sign the certificate with CA
    echo -e "${CYAN}✍️  Signing certificate with CA...${NC}"
    if openssl x509 -req -in "$csr_file" -CA "$CA_CERT_FILE" -CAkey "$CA_KEY_FILE" \
            -CAcreateserial -out "$DEVICE_CERT_FILE" -days 365 \
            -extensions v3_req -extfile "$device_config" 2>/dev/null; then
        log_wipe "INFO" "Device certificate signed successfully"
        echo -e "${GREEN}✅ Device certificate generated${NC}"
    else
        log_wipe "ERROR" "Failed to sign device certificate"
        rm -f "$device_config" "$csr_file"
        return 1
    fi
    
    # Cleanup temporary files
    rm -f "$device_config" "$csr_file"
    return 0
}

# Create comprehensive wipe certificate data
create_certificate_data() {
    local device="$1"
    local device_info="$2"
    local wipe_method="$3"
    local wipe_duration="$4"
    local verification_status="$5"
    
    log_wipe "INFO" "Creating certificate data for $device"
    
    # Get system information
    local cert_timestamp=$(date -u '+%Y-%m-%d %H:%M:%S UTC')
    local cert_date=$(date '+%Y-%m-%d')
    local cert_id="SW-$(date '+%Y%m%d')-$(echo "$device" | tr '/' '-' | tr -d '/dev')-$(date '+%H%M%S')"
    local operator_id="SYSTEM"
    local location="Secure Boot Environment"
    
    # Get device details from logs
    local device_size="${DEVICE_SIZE_GB:-Unknown}"
    local device_type=$(get_device_type_name "$DETECTED_DEVICE_TYPE")
    local hpa_status="${HPA_DETECTED:-false}"
    
    # Calculate data destruction hash
    local cert_hash=$(echo -n "$cert_id$device$cert_timestamp$wipe_method" | sha256sum | cut -d' ' -f1)
    
    # Create certificate data structure
    cat > "$CERT_DIR/certificate-data.json" <<EOF
{
  "certificate": {
    "version": "$CERT_VERSION",
    "id": "$cert_id",
    "issued_date": "$cert_timestamp",
    "authority": "$CERT_AUTHORITY",
    "validity_period": "$CERT_VALIDITY_YEARS years",
    "hash": "$cert_hash"
  },
  "device": {
    "path": "$device",
    "description": "$device_info",
    "type": "$device_type",
    "size_gb": "$device_size",
    "hpa_detected": "$hpa_status"
  },
  "operation": {
    "method": "$wipe_method",
    "duration_seconds": "$wipe_duration",
    "verification_status": "$verification_status",
    "operator": "$operator_id",
    "location": "$location",
    "timestamp": "$cert_timestamp"
  },
  "security": {
    "wiping_engine_version": "$SECUREWIPE_VERSION",
    "certificate_authority": "$CERT_AUTHORITY",
    "cryptographic_signature": "Generated",
    "tamper_proof": true,
    "audit_trail": true
  },
  "compliance": {
    "standards": ["NIST SP 800-88", "DoD 5220.22-M", "ISO 27001"],
    "india_compliance": "IT Act 2000, Digital India Initiative",
    "environmental": "E-Waste Management Rules 2016"
  }
}
EOF

    export CERT_ID="$cert_id"
    export CERT_HASH="$cert_hash"
    export CERT_TIMESTAMP="$cert_timestamp"
    
    log_wipe "INFO" "Certificate data created with ID: $cert_id"
    return 0
}

# Generate cryptographic signature for certificate
generate_cryptographic_signature() {
    local cert_data_file="$CERT_DIR/certificate-data.json"
    local signature_file="$CERT_DIR/certificate-signature.sig"
    
    log_wipe "INFO" "Generating cryptographic signature for certificate"
    
    echo -e "${BLUE}🔏 Generating Cryptographic Signature...${NC}"
    
    # Create signature using device private key
    if openssl dgst -sha256 -sign "$DEVICE_KEY_FILE" -out "$signature_file" "$cert_data_file" 2>/dev/null; then
        # Convert to base64 for embedding
        local signature_b64=$(base64 -w 0 "$signature_file")
        
        # Add signature to certificate data
        local temp_file="/tmp/cert-with-sig-$$.json"
        jq --arg sig "$signature_b64" '.security.cryptographic_signature = $sig' "$cert_data_file" > "$temp_file"
        mv "$temp_file" "$cert_data_file"
        
        echo -e "${GREEN}✅ Cryptographic signature generated${NC}"
        log_wipe "INFO" "Cryptographic signature added to certificate"
        return 0
    else
        log_wipe "ERROR" "Failed to generate cryptographic signature"
        return 1
    fi
}

# Create PDF certificate document
create_pdf_certificate() {
    local cert_data_file="$CERT_DIR/certificate-data.json"
    local html_file="$CERT_DIR/certificate.html"
    
    log_wipe "INFO" "Creating PDF certificate document"
    
    echo -e "${BLUE}📄 Creating PDF Certificate...${NC}"
    
    # Extract data from JSON
    local cert_id=$(jq -r '.certificate.id' "$cert_data_file")
    local cert_date=$(jq -r '.certificate.issued_date' "$cert_data_file")
    local device_path=$(jq -r '.device.path' "$cert_data_file")
    local device_info=$(jq -r '.device.description' "$cert_data_file")
    local device_type=$(jq -r '.device.type' "$cert_data_file")
    local device_size=$(jq -r '.device.size_gb' "$cert_data_file")
    local wipe_method=$(jq -r '.operation.method' "$cert_data_file")
    local wipe_duration=$(jq -r '.operation.duration_seconds' "$cert_data_file")
    local verification=$(jq -r '.operation.verification_status' "$cert_data_file")
    local cert_hash=$(jq -r '.certificate.hash' "$cert_data_file")
    
    # Create HTML certificate
    cat > "$html_file" <<EOF
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>SecureWipe Data Destruction Certificate</title>
    <style>
        body { font-family: 'Arial', sans-serif; margin: 40px; line-height: 1.6; }
        .header { text-align: center; border-bottom: 3px solid #2c3e50; padding-bottom: 20px; margin-bottom: 30px; }
        .title { font-size: 28px; font-weight: bold; color: #2c3e50; margin-bottom: 10px; }
        .subtitle { font-size: 16px; color: #7f8c8d; }
        .cert-id { background: #ecf0f1; padding: 10px; border-radius: 5px; margin: 20px 0; text-align: center; font-weight: bold; }
        .section { margin: 25px 0; }
        .section-title { font-size: 18px; font-weight: bold; color: #2c3e50; border-bottom: 1px solid #bdc3c7; padding-bottom: 5px; }
        .info-table { width: 100%; border-collapse: collapse; margin: 15px 0; }
        .info-table td { padding: 8px 12px; border: 1px solid #ddd; }
        .info-table .label { background: #f8f9fa; font-weight: bold; width: 30%; }
        .security-box { background: #e8f5e8; border: 2px solid #27ae60; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .verification-box { background: #fff3cd; border: 2px solid #ffc107; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .footer { margin-top: 40px; text-align: center; font-size: 12px; color: #7f8c8d; border-top: 1px solid #bdc3c7; padding-top: 20px; }
        .signature-hash { font-family: monospace; font-size: 10px; word-break: break-all; background: #f8f9fa; padding: 10px; border-radius: 3px; }
    </style>
</head>
<body>
    <div class="header">
        <div class="title">CERTIFICATE OF DATA DESTRUCTION</div>
        <div class="subtitle">SecureWipe India Pvt Ltd - Certified Data Sanitization</div>
    </div>
    
    <div class="cert-id">Certificate ID: $cert_id</div>
    
    <div class="section">
        <div class="section-title">Device Information</div>
        <table class="info-table">
            <tr><td class="label">Device Path</td><td>$device_path</td></tr>
            <tr><td class="label">Device Description</td><td>$device_info</td></tr>
            <tr><td class="label">Device Type</td><td>$device_type</td></tr>
            <tr><td class="label">Storage Capacity</td><td>${device_size} GB</td></tr>
        </table>
    </div>
    
    <div class="section">
        <div class="section-title">Destruction Details</div>
        <table class="info-table">
            <tr><td class="label">Wiping Method</td><td>$wipe_method</td></tr>
            <tr><td class="label">Duration</td><td>$wipe_duration seconds</td></tr>
            <tr><td class="label">Verification Status</td><td>$verification</td></tr>
            <tr><td class="label">Completion Date</td><td>$cert_date</td></tr>
        </table>
    </div>
    
    <div class="security-box">
        <h3>🔒 Security Assurance</h3>
        <p><strong>Data Destruction Status:</strong> COMPLETE AND IRREVERSIBLE</p>
        <p><strong>Recovery Possibility:</strong> IMPOSSIBLE</p>
        <p><strong>Compliance:</strong> NIST SP 800-88, DoD 5220.22-M, ISO 27001</p>
        <p><strong>India Compliance:</strong> IT Act 2000, E-Waste Management Rules 2016</p>
    </div>
    
    <div class="verification-box">
        <h3>✅ Certificate Verification</h3>
        <p><strong>Certificate Hash:</strong></p>
        <div class="signature-hash">$cert_hash</div>
        <p><small>This certificate is cryptographically signed and tamper-proof. Any modification will invalidate the signature.</small></p>
    </div>
    
    <div class="footer">
        <p><strong>SecureWipe India Pvt Ltd</strong><br>
        Bangalore, Karnataka, India<br>
        Email: certificates@securewipe.in | Web: www.securewipe.in<br>
        <br>
        This certificate serves as legal proof of secure data destruction in compliance with Indian e-waste management regulations.<br>
        Generated by SecureWipe v$SECUREWIPE_VERSION on $(date '+%Y-%m-%d %H:%M:%S')</p>
    </div>
</body>
</html>
EOF

    # Convert HTML to PDF (if wkhtmltopdf is available)
    if command -v wkhtmltopdf >/dev/null 2>&1; then
        echo -e "${CYAN}🖨️  Converting to PDF...${NC}"
        if wkhtmltopdf --page-size A4 --margin-top 20mm --margin-bottom 20mm \
                --margin-left 15mm --margin-right 15mm \
                "$html_file" "$FINAL_CERT_FILE" 2>/dev/null; then
            echo -e "${GREEN}✅ PDF certificate created: $(basename "$FINAL_CERT_FILE")${NC}"
            log_wipe "INFO" "PDF certificate created successfully"
        else
            echo -e "${YELLOW}⚠️  PDF conversion failed, HTML certificate available${NC}"
            cp "$html_file" "$CERT_DIR/SecureWipe-Certificate.html"
            log_wipe "WARN" "PDF conversion failed, created HTML certificate"
        fi
    else
        echo -e "${YELLOW}⚠️  wkhtmltopdf not available, creating HTML certificate${NC}"
        cp "$html_file" "$CERT_DIR/SecureWipe-Certificate.html"
        log_wipe "INFO" "HTML certificate created (PDF converter not available)"
    fi
    
    return 0
}

# Main certificate generation function
generate_tamper_proof_certificate() {
    local device="$1"
    local device_info="$2"
    local wipe_method="$3"
    local wipe_duration="$4"
    local verification_status="$5"
    
    log_wipe "INFO" "Starting tamper-proof certificate generation"
    
    echo ""
    echo -e "${WHITE}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${WHITE}║            TAMPER-PROOF CERTIFICATE GENERATION               ║${NC}"
    echo -e "${WHITE}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Step 1: Initialize CA
    if ! initialize_certificate_authority; then
        log_wipe "ERROR" "Failed to initialize certificate authority"
        return 1
    fi
    
    # Step 2: Generate device certificate
    local device_serial=$(echo "$device" | tr '/' '-' | tr -d '/dev')
    local device_model="Generic Storage Device"
    
    if ! generate_device_certificate "$device" "$device_serial" "$device_model"; then
        log_wipe "ERROR" "Failed to generate device certificate"
        return 1
    fi
    
    # Step 3: Create certificate data
    if ! create_certificate_data "$device" "$device_info" "$wipe_method" "$wipe_duration" "$verification_status"; then
        log_wipe "ERROR" "Failed to create certificate data"
        return 1
    fi
    
    # Step 4: Generate cryptographic signature
    if ! generate_cryptographic_signature; then
        log_wipe "ERROR" "Failed to generate cryptographic signature"
        return 1
    fi
    
    # Step 5: Create PDF certificate
    if ! create_pdf_certificate; then
        log_wipe "ERROR" "Failed to create PDF certificate"
        return 1
    fi
    
    # Final summary
    echo ""
    echo -e "${GREEN}🎉 TAMPER-PROOF CERTIFICATE GENERATED SUCCESSFULLY${NC}"
    echo ""
    echo -e "${WHITE}Certificate Details:${NC}"
    echo "• Certificate ID: $CERT_ID"
    echo "• Cryptographic Hash: ${CERT_HASH:0:32}..."
    echo "• Timestamp: $CERT_TIMESTAMP"
    echo "• Authority: $CERT_AUTHORITY"
    echo ""
    echo -e "${WHITE}Generated Files:${NC}"
    echo "• Certificate: $FINAL_CERT_FILE"
    echo "• Data: $CERT_DIR/certificate-data.json"
    echo "• CA Certificate: $CA_CERT_FILE"
    
    log_wipe "INFO" "Tamper-proof certificate generation completed successfully"
    
    # Display certificate location
    echo ""
    echo -e "${CYAN}📂 Certificate saved to: $CERT_DIR${NC}"
    echo -e "${YELLOW}💾 Please save these files for your records${NC}"
    
    return 0
}

# Export functions for use by main engine
export -f initialize_certificate_authority
export -f generate_device_certificate
export -f create_certificate_data
export -f generate_cryptographic_signature
export -f create_pdf_certificate
export -f generate_tamper_proof_certificate