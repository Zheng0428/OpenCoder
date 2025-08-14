# =============================================================================
# Step 6: Verify Claude Code installation
# =============================================================================
echo ""
echo "🔍 : Verifying Claude Code installation..."
source ~/.bashrc
# Check if claude command is available
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version)
    echo "   ✅ Claude Code installed successfully: $CLAUDE_VERSION"
else
    echo "   ❌ Claude Code command not found"
    echo "   Checking npm global bin directory..."
    ls -la ~/.npm-global/bin/
    exit 1
fi

# =============================================================================
# Step 7: Display installation summary
# =============================================================================
echo ""
echo "🎉 Installation Summary"
echo "======================"
echo "✅ Claude Code: $CLAUDE_VERSION"
echo ""
echo "📝 Available commands:"
echo "   claude              - Start interactive session"
echo "   claude --help       - Show all options"
echo "   claude --version    - Show version"
echo "   claude config       - Manage configuration"
echo "   claude setup-token  - Set up authentication"
echo ""
echo "🚀 You can now use Claude Code by running 'claude' in your terminal!"
echo ""
echo "💡 Note: If you open a new terminal, the PATH changes will be"
echo "   automatically applied. If you need to use Claude Code immediately"
echo "   in this session, run: source ~/.bashrc"
echo ""

# =============================================================================
# Optional: Show help information
# =============================================================================
echo "📖 Quick start guide:"
echo "   1. Run 'claude' to start an interactive session"
echo "   2. Run 'claude setup-token' to configure authentication"
echo "   3. Run 'claude --help' to see all available options"
echo ""
echo "🔗 For more information, visit: https://github.com/anthropics/claude-code" 