#!/bin/bash

# =============================================================================
# Claude Code Auto Login Setup Script
# =============================================================================
# This script will authenticate using a service account key JSON file
# Usage: bash auto_setup_cc.sh [key_file_name]
#   - Default: service-account-key.json
#   - Custom: any .json file name
# =============================================================================

set -e  # Exit immediately on error

echo "🔐 Starting Claude Code auto login setup..."

# Get the service account key file path from parameter or use default
SERVICE_ACCOUNT_KEY="${1:-service-account-key.json}"

# Check if service account key file exists
if [ ! -f "$SERVICE_ACCOUNT_KEY" ]; then
    echo "❌ Error: Service account key file not found: $SERVICE_ACCOUNT_KEY"
    echo "📝 Please create a service account key file first"
    echo "   You can create one using Google Cloud Console or gcloud CLI"
    echo "   Place the JSON file at: $(pwd)/$SERVICE_ACCOUNT_KEY"
    exit 1
fi

echo "🔑 Found service account key file: $SERVICE_ACCOUNT_KEY"

# Check if already authenticated with service account
if gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q "iam.gserviceaccount.com"; then
    ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | head -1)
    echo "✅ Already authenticated with service account: $ACTIVE_ACCOUNT"
    exit 0
fi

# Authenticate with service account
echo "🔐 Authenticating with service account..."
gcloud auth activate-service-account --key-file="$SERVICE_ACCOUNT_KEY"

# Set application default credentials
FULL_KEY_PATH="$(realpath "$SERVICE_ACCOUNT_KEY")"
export GOOGLE_APPLICATION_CREDENTIALS="$FULL_KEY_PATH"
echo "📊 Set GOOGLE_APPLICATION_CREDENTIALS: $FULL_KEY_PATH"

# Set application default credentials using gcloud
echo "🔧 Setting up application default credentials..."
gcloud auth application-default login --no-launch-browser --quiet 2>/dev/null || {
    echo "⚠️  Regular ADC setup failed, using service account key directly"
    # 创建 ADC 文件
    ADC_PATH="$HOME/.config/gcloud/application_default_credentials.json"
    mkdir -p "$(dirname "$ADC_PATH")"
    cp "$SERVICE_ACCOUNT_KEY" "$ADC_PATH"
    echo "📁 Copied service account key to ADC path: $ADC_PATH"
}

# Verify authentication
if gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q "@"; then
    ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | head -1)
    echo "✅ Authentication successful!"
    echo "📊 Active account: $ACTIVE_ACCOUNT"
    
    # Get project ID from service account
    PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
    if [ -z "$PROJECT_ID" ]; then
        # Try to extract project from service account email
        if [[ "$ACTIVE_ACCOUNT" =~ @([^.]+)\.iam\.gserviceaccount\.com ]]; then
            PROJECT_ID="${BASH_REMATCH[1]}"
            echo "📊 Setting project from service account: $PROJECT_ID"
            gcloud config set project "$PROJECT_ID"
        fi
    else
        echo "📊 Current project: $PROJECT_ID"
    fi
else
    echo "❌ Authentication failed"
    exit 1
fi

echo "🎉 Auto login setup completed!"