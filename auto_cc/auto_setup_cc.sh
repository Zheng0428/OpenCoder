#!/bin/bash

# =============================================================================
# Claude Code Auto Login Setup Script
# =============================================================================
# This script will automatically set up Claude Code login with Google account
# =============================================================================

set -e  # Exit immediately on error

echo "🔐 Starting Claude Code auto login setup..."

# Check if already logged in
if claude auth status &>/dev/null; then
    echo "✅ Claude Code is already logged in, skipping login setup"
    exit 0
fi

echo "📝 Setting up Google account login..."

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

# Attempt auto login (will open browser)
if [ -n "$GOOGLE_PASSWORD" ]; then
    echo "🤖 Attempting automated login with provided credentials..."
    echo "⚠️  About to open browser for Google login..."
    echo "Credentials will be auto-filled: $GOOGLE_ACCOUNT"
else
    echo "⚠️  About to open browser for Google login..."
    echo "Please manually use account $GOOGLE_ACCOUNT to complete login in the browser"
fi

# Start Claude Code login process
claude auth login --provider google

# Check login status
if claude auth status &>/dev/null; then
    echo "✅ Claude Code login successful!"
    echo "📊 Current login status:"
    claude auth status
else
    echo "❌ Claude Code login failed"
    exit 1
fi

echo "🎉 Auto login setup completed!"