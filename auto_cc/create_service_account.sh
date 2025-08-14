#!/bin/bash

# =============================================================================
# 首次登录脚本 - 创建服务账号密钥文件
# =============================================================================
# 这个脚本用于首次设置，会创建服务账号并生成 JSON 密钥文件
# 
# 用法:
#   bash create_service_account.sh                    # 生成 service-account-key.json
#   bash create_service_account.sh mykey              # 生成 mykey.json
#   bash create_service_account.sh production         # 生成 production.json
# =============================================================================

set -e  # 遇到错误立即退出

echo "🔧 首次登录设置 - 创建服务账号密钥文件"
echo "================================================"

# 获取密钥文件名参数
KEY_NAME="${1:-service-account-key}"

# 构建完整的密钥文件名
if [[ "$KEY_NAME" == *.json ]]; then
    # 如果已经包含 .json 后缀，直接使用
    SERVICE_ACCOUNT_KEY="$KEY_NAME"
    KEY_BASE_NAME="${KEY_NAME%.json}"
else
    # 否则添加 .json 后缀
    SERVICE_ACCOUNT_KEY="${KEY_NAME}.json"
    KEY_BASE_NAME="$KEY_NAME"
fi

echo "📁 将创建密钥文件: $SERVICE_ACCOUNT_KEY"

# 检查密钥文件是否已存在
if [ -f "$SERVICE_ACCOUNT_KEY" ]; then
    echo "⚠️  密钥文件已存在: $SERVICE_ACCOUNT_KEY"
    read -p "是否覆盖现有文件? (y/N): " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "❌ 操作已取消"
        exit 0
    fi
fi

# 服务账号相关配置
SERVICE_ACCOUNT_NAME="claude-auto-auth-${KEY_BASE_NAME}"
SERVICE_ACCOUNT_DISPLAY_NAME="Claude Auto Authentication (${KEY_BASE_NAME})"

echo ""
echo "📝 开始设置流程..."

# 步骤1: 首次认证
echo ""
echo "🔐 步骤1: Google 账号认证"
echo "这需要打开浏览器完成 OAuth 认证（仅此一次）"
echo "请在浏览器中完成登录..."

gcloud auth login --no-launch-browser

# 步骤2: 获取或设置项目ID
echo ""
echo "📊 步骤2: 设置 Google Cloud 项目"

# 尝试获取当前项目
current_project=$(gcloud config get-value project 2>/dev/null || echo "")

if [ -z "$current_project" ]; then
    echo "📋 未检测到当前项目，请选择一个项目："
    
    # 列出可用项目
    echo "可用项目列表:"
    gcloud projects list --format="table(projectId:label=PROJECT_ID,name:label=PROJECT_NAME)"
    
    echo ""
    read -p "请输入项目 ID: " project_id
    
    if [ -z "$project_id" ]; then
        echo "❌ 项目 ID 不能为空"
        exit 1
    fi
    
    # 设置项目
    gcloud config set project "$project_id"
    echo "✅ 项目设置完成: $project_id"
else
    echo "📊 当前项目: $current_project"
    read -p "是否使用当前项目? (Y/n): " use_current
    
    if [[ "$use_current" =~ ^[Nn]$ ]]; then
        echo "📋 可用项目列表:"
        gcloud projects list --format="table(projectId:label=PROJECT_ID,name:label=PROJECT_NAME)"
        
        echo ""
        read -p "请输入新的项目 ID: " project_id
        gcloud config set project "$project_id"
        echo "✅ 项目切换完成: $project_id"
    else
        project_id="$current_project"
    fi
fi

# 步骤3: 启用必要的API
echo ""
echo "🔧 步骤3: 启用必要的 API"
echo "启用 IAM API..."
gcloud services enable iam.googleapis.com

# 步骤4: 创建服务账号
echo ""
echo "👤 步骤4: 创建服务账号"

account_email="${SERVICE_ACCOUNT_NAME}@${project_id}.iam.gserviceaccount.com"

# 检查服务账号是否已存在
if gcloud iam service-accounts describe "$account_email" &>/dev/null; then
    echo "✅ 服务账号已存在: $account_email"
else
    echo "🆕 创建新服务账号: $SERVICE_ACCOUNT_NAME"
    gcloud iam service-accounts create "$SERVICE_ACCOUNT_NAME" \
        --display-name="$SERVICE_ACCOUNT_DISPLAY_NAME" \
        --description="Service account for automated Claude Code authentication"
    echo "✅ 服务账号创建成功"
fi

# 步骤5: 授予权限
echo ""
echo "🔐 步骤5: 授予权限"
echo "为服务账号授予必要权限..."

# 授予 Editor 角色（比 Owner 更安全）
gcloud projects add-iam-policy-binding "$project_id" \
    --member="serviceAccount:$account_email" \
    --role="roles/editor" \
    --quiet

echo "✅ 权限授予完成"

# 步骤6: 生成密钥文件
echo ""
echo "🔑 步骤6: 生成密钥文件"
echo "创建密钥文件: $SERVICE_ACCOUNT_KEY"

gcloud iam service-accounts keys create "$SERVICE_ACCOUNT_KEY" \
    --iam-account="$account_email" \
    --quiet

# 设置文件权限
chmod 600 "$SERVICE_ACCOUNT_KEY"

echo "✅ 密钥文件创建成功"

# 步骤7: 验证设置
echo ""
echo "✅ 步骤7: 验证设置"

# 测试使用服务账号认证
echo "🔍 测试服务账号认证..."
gcloud auth activate-service-account --key-file="$SERVICE_ACCOUNT_KEY"

# 验证认证状态
if gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | grep -q "@"; then
    ACTIVE_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null | head -1)
    echo "✅ 服务账号认证测试成功!"
    echo "📊 当前活跃账号: $ACTIVE_ACCOUNT"
else
    echo "❌ 服务账号认证测试失败"
    exit 1
fi

# 完成提示
echo ""
echo "🎉 首次设置完成!"
echo "================================================"
echo "✅ 已创建密钥文件: $SERVICE_ACCOUNT_KEY"
echo "✅ 文件权限已设置为 600"
echo "✅ 服务账号认证测试通过"
echo ""
echo "📝 接下来您可以:"
echo "1. 使用默认文件名运行主脚本:"
echo "   bash main_cc.sh"
echo ""
if [ "$KEY_NAME" != "service-account-key" ]; then
    echo "2. 使用自定义文件名运行主脚本:"
    echo "   bash main_cc.sh $KEY_BASE_NAME"
    echo ""
fi
echo "⚠️  重要提醒:"
echo "- 妥善保管密钥文件 $SERVICE_ACCOUNT_KEY"
echo "- 不要将此文件提交到 Git 仓库"
echo "- 定期轮换密钥以确保安全"
echo ""
echo "📚 如需帮助，请查看 README_AUTH.md"