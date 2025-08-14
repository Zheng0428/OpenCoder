#!/bin/bash

# =============================================================================
# Claude Code 主安装和启动脚本
# =============================================================================
# 这个脚本会：
# 1. 运行安装脚本 install_cc.sh
# 2. 运行检查脚本 check_cc.sh
# 3. 设置 Claude Code 自动登录 (使用 auto_setup_cc.sh)
# 4. 启动 Claude Code
# 
# 用法:
#   bash main_cc.sh                                               # 手动输入 Google 账号和密码
#   bash main_cc.sh your@gmail.com                                # 直接指定 Google 账号，手动输入密码
#   bash main_cc.sh your@gmail.com your_password                  # 直接指定 Google 账号和密码
#   bash main_cc.sh your@gmail.com your_password your-project-id  # 完全自动化（包含项目 ID）
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

# 获取 Google 账号、密码和项目 ID 参数（可选）
GOOGLE_ACCOUNT="${1:-'aiic20public@gmail.com'}"
GOOGLE_PASSWORD="${2:-'aiiccomeon888'}"
PROJECT_ID="${3:-'test'}"  # Google Cloud Project ID (optional)

echo "GOOGLE_ACCOUNT: $GOOGLE_ACCOUNT"
echo "GOOGLE_PASSWORD: [PROVIDED]"
if [ -n "$PROJECT_ID" ]; then
    echo "PROJECT_ID: $PROJECT_ID"
fi

if [ -f "auto_setup_cc.sh" ]; then
    if [ -n "$GOOGLE_ACCOUNT" ]; then
        echo "📧 使用提供的 Google 账号: $GOOGLE_ACCOUNT"
        if [ -n "$GOOGLE_PASSWORD" ]; then
            echo "🔑 将自动创建服务账号进行完全自动化登录"
            bash auto_setup_cc.sh "$GOOGLE_ACCOUNT" "$GOOGLE_PASSWORD" "$PROJECT_ID"
        else
            bash auto_setup_cc.sh "$GOOGLE_ACCOUNT"
        fi
    else
        echo "⚠️  未提供 Google 账号，请手动输入:"
        read -p "请输入 Google 账号: " GOOGLE_ACCOUNT
        if [ -n "$GOOGLE_ACCOUNT" ]; then
            read -s -p "请输入密码 (可选，回车跳过): " GOOGLE_PASSWORD
            echo ""
            read -p "请输入 Google Cloud Project ID (可选，回车跳过): " PROJECT_ID
            if [ -n "$GOOGLE_PASSWORD" ]; then
                bash auto_setup_cc.sh "$GOOGLE_ACCOUNT" "$GOOGLE_PASSWORD" "$PROJECT_ID"
            else
                bash auto_setup_cc.sh "$GOOGLE_ACCOUNT" "" "$PROJECT_ID"
            fi
        else
            echo "⏭️  跳过自动登录设置"
        fi
    fi
    echo "✅ 登录设置完成"
else
    echo "❌ 自动登录脚本 auto_setup_cc.sh 不存在，跳过登录设置"
fi

# 步骤4：启动 Claude Code
echo ""
echo "🎯 步骤4：启动 Claude Code..."