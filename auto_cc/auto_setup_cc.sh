#!/bin/bash

# =============================================================================
# Claude Code Auto Login Setup Script
# =============================================================================
# This script will automatically set up Claude Code login with Google account
# Usage:
#   ./auto_setup_cc.sh <google_account> [password] [project_id]
# =============================================================================

set -e  # Exit immediately on error

echo "🔐 Starting Claude Code auto login setup..."

# Check if Google Cloud authentication is configured
if gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q "@"; then
    ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | head -1)
    echo "✅ Google Cloud authentication already active: $ACTIVE_ACCOUNT"
    echo "Skipping login setup"
    exit 0
fi

echo "📝 Setting up Google Cloud authentication for Claude Code..."

# Get parameters
GOOGLE_ACCOUNT="${1:-}"
GOOGLE_PASSWORD="${2:-}"
PROJECT_ID="${3:-}"

if [ -z "$GOOGLE_ACCOUNT" ]; then
    echo "❌ Error: Google account is required"
    echo "Usage: $0 <google_account> [password]"
    exit 1
fi

echo "🌐 Using Google account: $GOOGLE_ACCOUNT"

# Store credentials for automated login
if [ -n "$GOOGLE_PASSWORD" ]; then
    echo "🔑 Password provided for automated login"
    export GOOGLE_LOGIN_EMAIL="$GOOGLE_ACCOUNT"
    export GOOGLE_LOGIN_PASSWORD="$GOOGLE_PASSWORD"
fi

# Attempt Google Cloud authentication
echo "🌐 Authenticating with Google Cloud..."

# Check for service account key file (for automated authentication)
SERVICE_ACCOUNT_KEY="/home/tuney.zh/OpenCoder/auto_cc/service-account-key.json"
SERVICE_ACCOUNT_NAME="claude-auto-auth"

# Function to create service account
create_service_account() {
    local project_id="$1"
    local account_email="${SERVICE_ACCOUNT_NAME}@${project_id}.iam.gserviceaccount.com"
    
    echo "🔧 Creating service account for automated authentication..."
    
    # First authenticate with the regular account to create service account
    echo "📝 First, you need to authenticate with your Google account to create the service account..."
    gcloud auth login "$GOOGLE_ACCOUNT" --no-launch-browser
    
    # Set the project
    if [ -n "$project_id" ]; then
        echo "📊 Setting project to: $project_id"
        gcloud config set project "$project_id"
    else
        # Get current project or prompt for one
        current_project=$(gcloud config get-value project 2>/dev/null)
        if [ -z "$current_project" ]; then
            echo "❓ No project ID provided. Please enter your Google Cloud project ID:"
            read -p "Project ID: " project_id
            gcloud config set project "$project_id"
        else
            project_id="$current_project"
            echo "📊 Using current project: $project_id"
        fi
    fi
    
    # Check if service account already exists
    if gcloud iam service-accounts describe "$account_email" &>/dev/null; then
        echo "✅ Service account already exists: $account_email"
    else
        echo "🆕 Creating new service account: $SERVICE_ACCOUNT_NAME"
        gcloud iam service-accounts create "$SERVICE_ACCOUNT_NAME" \
            --display-name="Claude Auto Authentication" \
            --description="Service account for automated Claude Code authentication"
        
        # Grant necessary permissions
        echo "🔐 Granting necessary permissions..."
        gcloud projects add-iam-policy-binding "$project_id" \
            --member="serviceAccount:$account_email" \
            --role="roles/owner" \
            --quiet
    fi
    
    # Create key file
    echo "🔑 Generating service account key..."
    gcloud iam service-accounts keys create "$SERVICE_ACCOUNT_KEY" \
        --iam-account="$account_email" \
        --quiet
    
    echo "✅ Service account key created: $SERVICE_ACCOUNT_KEY"
}

if [ -n "$GOOGLE_PASSWORD" ]; then
    echo "⚠️  Note: Direct password authentication is not supported by Google Cloud CLI"
    echo "🤖 Setting up automated authentication using service account..."
    
    if [ -f "$SERVICE_ACCOUNT_KEY" ]; then
        echo "🔑 Found existing service account key, using it for authentication..."
        gcloud auth activate-service-account --key-file="$SERVICE_ACCOUNT_KEY"
    else
        echo "📝 Service account key not found. Creating one now..."
        create_service_account "$PROJECT_ID"
        
        # Now authenticate with the service account
        echo "🔐 Authenticating with service account..."
        gcloud auth activate-service-account --key-file="$SERVICE_ACCOUNT_KEY"
    fi
else
    echo "⚠️  Starting interactive Google Cloud authentication..."
    echo "Please use account $GOOGLE_ACCOUNT to complete authentication"
    
    # Try browser-less mode first
    echo "🔗 Using browser-less authentication (copy URL to browser)..."
    gcloud auth login --no-launch-browser
fi

# Set up application default credentials if not using service account
if [ ! -f "$SERVICE_ACCOUNT_KEY" ]; then
    echo "🔧 Setting up application default credentials..."
    gcloud auth application-default login --no-launch-browser
fi

# Verify authentication
if gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q "@"; then
    ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | head -1)
    echo "✅ Google Cloud authentication successful!"
    echo "📊 Active account: $ACTIVE_ACCOUNT"
else
    echo "❌ Google Cloud authentication failed"
    exit 1
fi

echo "🎉 Auto login setup completed!"