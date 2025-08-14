#!/bin/bash

# =============================================================================
# Claude Code 启动脚本 (使用 Vertex AI)
# =============================================================================
# 这个脚本配置环境变量并启动 Claude Code with Vertex AI
# =============================================================================

set -e  # 遇到错误立即退出

echo "🎯 启动 Claude Code (Vertex AI 模式)"
echo "===================================="

# 获取项目 ID
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)

if [ -z "$PROJECT_ID" ]; then
    echo "❌ 未找到 Google Cloud 项目 ID"
    echo "请先运行认证脚本或手动设置项目"
    exit 1
fi

echo "📊 使用项目 ID: $PROJECT_ID"

# 设置环境变量
echo "🔧 配置 Vertex AI 环境变量..."

# 启用 Vertex AI 集成
export CLAUDE_CODE_USE_VERTEX=1

# 设置区域 (使用 us-east5，也可以根据需要调整)
export CLOUD_ML_REGION=us-east5

# 设置项目 ID
export ANTHROPIC_VERTEX_PROJECT_ID="$PROJECT_ID"

# 可选：禁用提示缓存（如果需要的话）
# export DISABLE_PROMPT_CACHING=1

echo "✅ 环境变量配置完成:"
echo "   CLAUDE_CODE_USE_VERTEX=1"
echo "   CLOUD_ML_REGION=us-east5"
echo "   ANTHROPIC_VERTEX_PROJECT_ID=$PROJECT_ID"

# 验证认证状态
echo ""
echo "🔍 验证 Google Cloud 认证状态..."
if gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q "@"; then
    ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | head -1)
    echo "✅ 已认证账号: $ACTIVE_ACCOUNT"
else
    echo "❌ Google Cloud 认证失败"
    echo "请先运行认证脚本"
    exit 1
fi

# 检查 Claude Code 是否可用
echo ""
echo "🔍 检查 Claude Code 可用性..."
if command -v claude &> /dev/null; then
    echo "✅ Claude Code 已安装"
else
    echo "❌ Claude Code 未找到"
    echo "请确保 Claude Code 已正确安装"
    exit 1
fi

# 启动 Claude Code
echo ""
echo "🚀 启动 Claude Code..."
echo "💡 提示: 使用 Vertex AI 时，/login 和 /logout 命令已禁用"
echo "💡 身份验证通过 Google Cloud 凭据自动处理"
echo ""

# 启动 Claude Code
claude