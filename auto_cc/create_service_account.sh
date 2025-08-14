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
    SERVICE_ACCOUNT_KEY="gcloud_key/{$KEY_NAME}"
    KEY_BASE_NAME="${KEY_NAME%.json}"
else
    # 否则添加 .json 后缀
    SERVICE_ACCOUNT_KEY="gcloud_key/${KEY_NAME}.json"
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
# 生成符合要求的服务账号名称（6-30字符，只能包含小写字母、数字和连字符）
if [ ${#KEY_BASE_NAME} -le 15 ]; then
    # 如果密钥名称较短，使用完整名称
    SERVICE_ACCOUNT_NAME="claude-${KEY_BASE_NAME}"
else
    # 如果密钥名称较长，使用缩短版本
    SHORT_NAME=$(echo "$KEY_BASE_NAME" | cut -c1-15)
    SERVICE_ACCOUNT_NAME="claude-${SHORT_NAME}"
fi

# 确保名称长度在6-30字符范围内
if [ ${#SERVICE_ACCOUNT_NAME} -gt 30 ]; then
    # 如果还是太长，使用更短的版本
    SERVICE_ACCOUNT_NAME="claude-$(date +%s | tail -c 8)"
elif [ ${#SERVICE_ACCOUNT_NAME} -lt 6 ]; then
    # 如果太短，添加后缀
    SERVICE_ACCOUNT_NAME="${SERVICE_ACCOUNT_NAME}-sa"
fi

# 确保只包含有效字符（小写字母、数字、连字符）
SERVICE_ACCOUNT_NAME=$(echo "$SERVICE_ACCOUNT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g')

SERVICE_ACCOUNT_DISPLAY_NAME="Claude Auto Authentication (${KEY_BASE_NAME})"

echo "📝 服务账号名称: $SERVICE_ACCOUNT_NAME (长度: ${#SERVICE_ACCOUNT_NAME})"

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

# 默认项目 ID（生成唯一的项目 ID）
DEFAULT_PROJECT_ID="opencoder-$(date +%s)"
DEFAULT_PROJECT_NAME="OpenCoder"

# 尝试获取当前项目
current_project=$(gcloud config get-value project 2>/dev/null || echo "")

if [ -z "$current_project" ]; then
    echo "📋 未检测到当前项目"
    echo ""
    echo "选项："
    echo "1. 创建新项目 'OpenCoder' (推荐)"
    echo "2. 使用现有项目"
    echo ""
    read -p "请选择 (1/2): " choice
    
    if [[ "$choice" == "1" ]]; then
        project_id="$DEFAULT_PROJECT_ID"
        echo "🆕 将创建新项目:"
        echo "   项目 ID: $project_id"
        echo "   项目名称: $DEFAULT_PROJECT_NAME"
        
        # 创建项目
        echo "🔧 创建项目中..."
        echo "⚠️  注意：如果这是首次使用 Google Cloud，可能需要："
        echo "   1. 接受服务条款"
        echo "   2. 启用计费账户"
        echo "   3. 验证身份信息"
        echo ""
        
        if gcloud projects create "$project_id" --name="$DEFAULT_PROJECT_NAME"; then
            echo "✅ 项目创建成功: $project_id"
        else
            echo "❌ 项目创建失败"
            echo ""
            echo "可能的原因："
            echo "1. 需要接受 Google Cloud 服务条款"
            echo "2. 需要组织权限"
            echo "3. 项目 ID 已存在"
            echo "4. 需要设置计费账户"
            echo ""
            echo "解决方案："
            echo "1. 请访问 https://console.cloud.google.com/"
            echo "2. 手动创建一个名为 'OpenCoder' 的项目"
            echo "3. 记录项目 ID，然后选择使用现有项目"
            echo ""
            read -p "是否继续使用现有项目? (y/N): " continue_existing
            
            if [[ "$continue_existing" =~ ^[Yy]$ ]]; then
                echo "📋 可用项目列表:"
                gcloud projects list --format="table(projectId:label=PROJECT_ID,name:label=PROJECT_NAME)"
                
                echo ""
                while true; do
                    read -p "请输入要使用的项目 ID: " project_id
                    
                    if [ -z "$project_id" ]; then
                        echo "❌ 项目 ID 不能为空"
                        continue
                    fi
                    
                    # 验证项目 ID 是否有效
                    echo "🔍 验证项目 ID: $project_id"
                    if gcloud projects describe "$project_id" &>/dev/null; then
                        echo "✅ 项目 ID 验证成功"
                        break
                    else
                        echo "❌ 无效的项目 ID: $project_id"
                        echo ""
                    fi
                done
            else
                echo "❌ 操作已取消"
                exit 1
            fi
        fi
        
        # 设置项目
        gcloud config set project "$project_id"
        echo "✅ 项目设置完成: $project_id"
        
    else
        # 使用现有项目的逻辑
        echo "📋 可用项目列表:"
        gcloud projects list --format="table(projectId:label=PROJECT_ID,name:label=PROJECT_NAME)"
        
        echo ""
        echo "⚠️  注意: 请输入 PROJECT_ID（不是项目名称）"
        echo ""
        
        while true; do
            read -p "请输入项目 ID: " project_id
            
            if [ -z "$project_id" ]; then
                echo "❌ 项目 ID 不能为空"
                continue
            fi
            
            # 验证项目 ID 是否有效
            echo "🔍 验证项目 ID: $project_id"
            if gcloud projects describe "$project_id" &>/dev/null; then
                echo "✅ 项目 ID 验证成功"
                break
            else
                echo "❌ 无效的项目 ID: $project_id"
                echo "请检查项目 ID 是否正确，或从上面的列表中选择"
                echo ""
            fi
        done
        
        # 设置项目
        gcloud config set project "$project_id"
        echo "✅ 项目设置完成: $project_id"
    fi
else
    echo "📊 当前项目: $current_project"
    echo ""
    echo "选项："
    echo "1. 使用当前项目 ($current_project)"
    echo "2. 创建新项目 'OpenCoder'"
    echo "3. 选择其他项目"
    echo ""
    read -p "请选择 (1/2/3): " choice
    
    if [[ "$choice" == "1" ]]; then
        project_id="$current_project"
    elif [[ "$choice" == "2" ]]; then
        project_id="$DEFAULT_PROJECT_ID"
        echo "🆕 将创建新项目:"
        echo "   项目 ID: $project_id"
        echo "   项目名称: $DEFAULT_PROJECT_NAME"
        
        # 创建项目
        echo "🔧 创建项目中..."
        echo "⚠️  注意：如果这是首次使用 Google Cloud，可能需要："
        echo "   1. 接受服务条款"
        echo "   2. 启用计费账户"
        echo "   3. 验证身份信息"
        echo ""
        
        if gcloud projects create "$project_id" --name="$DEFAULT_PROJECT_NAME"; then
            echo "✅ 项目创建成功: $project_id"
        else
            echo "❌ 项目创建失败"
            echo ""
            echo "解决方案："
            echo "1. 请访问 https://console.cloud.google.com/"
            echo "2. 手动创建一个名为 'OpenCoder' 的项目"
            echo "3. 记录项目 ID，然后重新运行此脚本并选择使用现有项目"
            echo ""
            echo "❌ 自动创建项目失败，请手动创建后重新运行"
            exit 1
        fi
        
        # 设置项目
        gcloud config set project "$project_id"
        echo "✅ 项目设置完成: $project_id"
    else
        # 选择其他项目
        echo "📋 可用项目列表:"
        gcloud projects list --format="table(projectId:label=PROJECT_ID,name:label=PROJECT_NAME)"
        
        echo ""
        while true; do
            read -p "请输入项目 ID: " project_id
            
            if [ -z "$project_id" ]; then
                echo "❌ 项目 ID 不能为空"
                continue
            fi
            
            # 验证项目 ID 是否有效
            echo "🔍 验证项目 ID: $project_id"
            if gcloud projects describe "$project_id" &>/dev/null; then
                echo "✅ 项目 ID 验证成功"
                break
            else
                echo "❌ 无效的项目 ID: $project_id"
                echo ""
            fi
        done
        
        gcloud config set project "$project_id"
        echo "✅ 项目切换完成: $project_id"
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