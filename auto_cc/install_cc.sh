#!/bin/bash

# =============================================================================
# Claude Code Installation Script
# =============================================================================
# This script installs Claude Code (@anthropic-ai/claude-code) on a Linux system
# with proper Node.js version management and permission handling.
#
# Prerequisites:
# - Linux system with apt package manager
# - Internet connection
# - sudo privileges
#
# What this script does:
# 1. Checks for existing Node.js installation
# 2. Upgrades Node.js to a supported version (v18.x)
# 3. Ensures npm is installed and up to date
# 4. Configures npm for proper global package installation
# 5. Installs Claude Code globally
# 6. Verifies the installation
# =============================================================================

set -e  # Exit on any error

# Function to safely configure npm prefix
configure_npm_prefix() {
    local target_prefix="$HOME/.npm-global"
    
    # Check if prefix is already set correctly
    local current_prefix=$(npm config get prefix 2>/dev/null || echo "")
    
    if [ "$current_prefix" = "$target_prefix" ]; then
        echo "   ✅ npm prefix already configured correctly"
        return 0
    fi
    
    # Try to set the prefix with global flag
    if npm config set --global prefix "$target_prefix" 2>/dev/null; then
        echo "   ✅ npm prefix configured successfully"
        return 0
    else
        echo "   ⚠️  Failed to set global prefix, trying alternative approach..."
        # Try setting it directly in the user's .npmrc
        echo "prefix=$target_prefix" > "$HOME/.npmrc"
        echo "   ✅ npm prefix configured via .npmrc"
        return 0
    fi
}

# Function to ensure npm is installed and up to date
ensure_npm_installed() {
    if ! command -v npm &> /dev/null; then
        echo "   ❌ npm not found. Installing npm..."
        sudo apt-get install npm -y
        
        if ! command -v npm &> /dev/null; then
            echo "   ❌ npm installation failed"
            return 1
        fi
    fi
    
    NPM_VERSION=$(npm --version)
    echo "   ✅ npm is installed: $NPM_VERSION"
    return 0
}

echo "🚀 Starting Claude Code installation..."
echo "======================================"

# =============================================================================
# Step 1: Check if Node.js is already installed
# =============================================================================
echo "📋 Step 1: Checking existing Node.js installation..."

if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "   Found Node.js: $NODE_VERSION"
    
    # Check if version is too old (we need v14+ for modern npm packages)
    NODE_MAJOR=$(echo $NODE_VERSION | sed 's/v\([0-9]*\)\..*/\1/')
    if [ "$NODE_MAJOR" -lt 14 ]; then
        echo "   ⚠️  Node.js version is too old. Upgrading to v18.x..."
        UPGRADE_NODE=true
    else
        echo "   ✅ Node.js version is acceptable"
        UPGRADE_NODE=false
    fi
else
    echo "   ❌ Node.js not found. Will install v18.x..."
    UPGRADE_NODE=true
fi

# =============================================================================
# Step 2: Upgrade Node.js to v18.x if needed
# =============================================================================
if [ "$UPGRADE_NODE" = true ]; then
    echo ""
    echo "📦 Step 2: Upgrading Node.js to v18.x..."
    
    # Update package lists
    echo "   Updating package lists..."
    sudo apt update
    
    # Add NodeSource repository for Node.js v18.x
    echo "   Adding NodeSource repository..."
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    
    # Install Node.js v18.x and npm
echo "   Installing Node.js v18.x and npm..."
sudo apt-get install nodejs npm -y

echo "   ✅ Node.js and npm upgrade completed"
fi

# =============================================================================
# Step 3: Verify and install npm if needed
# =============================================================================
echo ""
echo "🔍 Step 3: Verifying Node.js and npm installation..."

NODE_VERSION=$(node --version)
echo "   Node.js version: $NODE_VERSION"

# Ensure npm is installed
ensure_npm_installed
if [ $? -ne 0 ]; then
    echo "   ❌ npm installation failed"
    exit 1
fi

if [ -z "$NODE_VERSION" ] || [ -z "$NPM_VERSION" ]; then
    echo "   ❌ Node.js or npm installation failed"
    exit 1
fi

echo "   ✅ Node.js and npm are properly installed"

# Update npm to latest version if needed
echo "   Checking npm version..."
CURRENT_NPM_VERSION=$(npm --version)
echo "   Current npm version: $CURRENT_NPM_VERSION"

# Note: npm usually comes with Node.js, but we can update it if needed
# Uncomment the following lines if you want to update npm to latest
# echo "   Updating npm to latest version..."
# sudo npm install -g npm@latest

# =============================================================================
# Step 4: Configure npm for global package installation
# =============================================================================
echo ""
echo "⚙️  Step 4: Configuring npm for global package installation..."

# Create directory for global npm packages
echo "   Creating npm global directory..."
mkdir -p ~/.npm-global

# Configure npm to use the new directory
echo "   Configuring npm prefix..."
configure_npm_prefix

# Add npm global bin to PATH
echo "   Adding npm global bin to PATH..."
if ! grep -q "~/.npm-global/bin" ~/.bashrc; then
    echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
    echo "   ✅ PATH updated in ~/.bashrc"
else
    echo "   ✅ PATH already configured"
fi

# Reload bashrc to apply changes
echo "   Reloading shell configuration..."
source ~/.bashrc

echo "   ✅ npm configuration completed"

# =============================================================================
# Step 5: Install Claude Code globally
# =============================================================================
echo ""
echo "📦 Step 5: Installing Claude Code..."

echo "   Installing @anthropic-ai/claude-code globally..."
npm install -g @anthropic-ai/claude-code

if [ $? -eq 0 ]; then
    echo "   ✅ Claude Code installation completed"
else
    echo "   ❌ Claude Code installation failed"
    exit 1
fi
# =============================================================================
# Step 6: Source bashrc to apply changes
# =============================================================================
source ~/.bashrc