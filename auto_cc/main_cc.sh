#!/bin/bash

# =============================================================================
# Claude Code 主安装和启动脚本
# =============================================================================
# 这个脚本会：
# 1. 运行安装脚本 install_cc.sh
# 2. 运行检查脚本 check_cc.sh
# 3. 设置 Google Cloud 自动登录 (使用 auto_setup_gcloud.sh)
# 4. 启动 Claude Code
# 
# 用法:
#   bash main_cc.sh              # 使用默认的 service-account-key.json
#   bash main_cc.sh abc          # 使用自定义的 abc.json
#   bash main_cc.sh path/to/key  # 使用指定路径的 key.json
#
# 前提条件:
#   必须先创建服务账号密钥 JSON 文件并放在 auto_cc 目录下
# =============================================================================

set -e  # 遇到错误立即退出

echo "🚀 开始 Claude Code 完整安装和启动流程..."
echo "================================================"

# 步骤1：运行安装脚本
echo ""
echo "📦 步骤1：运行安装脚本..."
if [ -f "install_cc.sh" ]; then
    bash install_cc.sh
    echo "✅ 安装脚本执行完成"
else
    echo "❌ 安装脚本 install_cc.sh 不存在"
    exit 1
fi

# 步骤2：运行检查脚本
echo ""
echo "🔍 步骤2：运行检查脚本..."
if [ -f "check_cc.sh" ]; then
    bash check_cc.sh
    echo "✅ 检查脚本执行完成"
else
    echo "❌ 检查脚本 check_cc.sh 不存在"
    exit 1
fi

# 步骤3：运行安装gcloud脚本
echo ""
echo "🔍 步骤3：检查并安装 gcloud..."

# 检查 gcloud 是否已安装
if command -v gcloud &> /dev/null; then
    echo "✅ gcloud 已经安装，跳过安装步骤"
    echo "📊 当前 gcloud 版本:"
    gcloud version --format="value(version.version_string)" | head -1
else
    echo "📦 gcloud 未安装，开始安装..."
    if [ -f "install_gcloud.sh" ]; then
        bash install_gcloud.sh
        echo "✅ gcloud 安装脚本执行完成"
    else
        echo "❌ 安装脚本 install_gcloud.sh 不存在"
        exit 1
    fi
fi

# 步骤4：自动登录设置
echo ""
echo "🔐 步骤4：设置 Claude Code 自动登录..."

# 获取自定义密钥文件名参数
KEY_NAME="${1:-service-account-key}"

# 构建完整的密钥文件名
if [[ "$KEY_NAME" == *.json ]]; then
    # 如果已经包含 .json 后缀，直接使用
    SERVICE_ACCOUNT_KEY="$KEY_NAME"
else
    # 否则添加 .json 后缀
    SERVICE_ACCOUNT_KEY="${KEY_NAME}.json"
fi

SERVICE_ACCOUNT_KEY="gcloud_key/${SERVICE_ACCOUNT_KEY}"

if [ -f "auto_setup_gcloud.sh" ]; then
    echo "📝 检查服务账号密钥文件: $SERVICE_ACCOUNT_KEY"
    
    # Check if service account key exists
    if [ -f "$SERVICE_ACCOUNT_KEY" ]; then
        echo "🔑 发现服务账号密钥文件，执行自动登录..."
        bash auto_setup_gcloud.sh "$SERVICE_ACCOUNT_KEY"
        echo "✅ 登录设置完成"
    else
        echo "⚠️  未找到密钥文件: $SERVICE_ACCOUNT_KEY"
        echo "📝 请先创建服务账号密钥："
        echo "   1. 登录 Google Cloud Console"
        echo "   2. 创建服务账号并下载 JSON 密钥"
        echo "   3. 将密钥文件命名为: $SERVICE_ACCOUNT_KEY"
        echo "   4. 放置在当前目录: $(pwd)"
        echo "⏭️  跳过自动登录设置"
    fi
else
    echo "❌ 自动登录脚本 auto_setup_gcloud.sh 不存在，跳过登录设置"
fi

# 步骤5：配置完成
echo ""
echo "🎯 步骤5：环境配置完成..."

# 环境配置完成，现在可以使用 Claude Code SDK
PROJECT_ID=$(gcloud config get-value project 2>/dev/null)
if [ -n "$PROJECT_ID" ]; then
    echo "✅ 环境配置完成！现在您可以："
    echo ""
    echo "🔧 使用 Claude Code SDK (推荐):"
    echo "   python cc_sdk.py --test                    # 测试连接"
    echo "   python cc_sdk.py                           # 运行默认示例"
    echo "   python cc_sdk.py --help-usage              # 查看更多用法"
    echo ""
    echo "🚀 或启动交互式 Claude Code:"
    if [ -f "start_claude.sh" ]; then
        echo "   bash start_claude.sh                       # 使用启动脚本"
    fi
    echo "   claude                                      # 直接启动"
    echo ""
    echo "🌐 环境变量已配置:"
    echo "   CLAUDE_CODE_USE_VERTEX=1"
    echo "   CLOUD_ML_REGION=us-east5"  
    echo "   ANTHROPIC_VERTEX_PROJECT_ID=$PROJECT_ID"
else
    echo "⚠️  未找到项目 ID，请先完成认证步骤"
fi