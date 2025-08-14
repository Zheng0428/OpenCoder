#!/bin/bash

# =============================================================================
# Claude Code Auto Login Setup Script
# =============================================================================
# This script will automatically set up Claude Code login with Google account
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

# Get Google account and password (if provided as parameters)
GOOGLE_ACCOUNT="${1:-}"
GOOGLE_PASSWORD="${2:-}"

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

if [ -n "$GOOGLE_PASSWORD" ]; then
    echo "🤖 Attempting automated authentication with provided credentials..."
    echo "⚠️  Note: For automated login, you may need to set up service account authentication"
    echo "Account: $GOOGLE_ACCOUNT"
    
    # Try to authenticate using gcloud with the specified account
    echo "🔐 Running: gcloud auth login $GOOGLE_ACCOUNT"
    gcloud auth login "$GOOGLE_ACCOUNT"
else
    echo "⚠️  Starting interactive Google Cloud authentication..."
    echo "Please use account $GOOGLE_ACCOUNT to complete authentication"
    
    # Interactive authentication
    gcloud auth login
fi

# Set up application default credentials
echo "🔧 Setting up application default credentials..."
gcloud auth application-default login

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