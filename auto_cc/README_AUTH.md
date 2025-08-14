# Google Cloud 自动认证说明

## 概述
本认证系统使用 Google Cloud 服务账号密钥文件实现完全自动化认证，无需浏览器交互或手动输入密码。

## 前提条件

必须先创建服务账号密钥 JSON 文件（可以使用自定义名称）

## 创建服务账号密钥

### 方法1：通过 Google Cloud Console（推荐）

1. 访问 [Google Cloud Console](https://console.cloud.google.com/)
2. 选择或创建一个项目
3. 导航到 "IAM 和管理" > "服务账号"
4. 点击 "创建服务账号"
   - 名称：`claude-auto-auth`
   - 描述：Claude Code Auto Authentication
5. 授予角色（根据需要选择，建议 Owner 或 Editor）
6. 创建密钥：
   - 点击创建的服务账号
   - 选择 "密钥" 标签
   - 点击 "添加密钥" > "创建新密钥"
   - 选择 JSON 格式
   - 下载密钥文件
7. 将下载的文件重命名（可选）：
   - 默认名称：`service-account-key.json`
   - 自定义名称：任意名称，如 `mykey.json`、`prod-key.json` 等
8. 将文件放置在 `OpenCoder/auto_cc/` 目录下

### 方法2：通过 gcloud CLI

如果你在其他已认证的机器上：

```bash
# 设置项目
gcloud config set project YOUR_PROJECT_ID

# 创建服务账号
gcloud iam service-accounts create claude-auto-auth \
  --display-name="Claude Auto Authentication" \
  --description="Service account for automated Claude Code authentication"

# 授予权限
gcloud projects add-iam-policy-binding YOUR_PROJECT_ID \
  --member="serviceAccount:claude-auto-auth@YOUR_PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/owner"

# 生成密钥文件（可以使用自定义名称）
gcloud iam service-accounts keys create mykey.json \
  --iam-account=claude-auto-auth@YOUR_PROJECT_ID.iam.gserviceaccount.com

# 将密钥文件复制到目标机器的 OpenCoder/auto_cc/ 目录
```

## 使用方法

### 使用默认密钥文件名

```bash
cd /home/tuney.zh/OpenCoder/auto_cc
bash main_cc.sh  # 将查找 service-account-key.json
```

### 使用自定义密钥文件名

```bash
# 使用 abc.json 作为密钥文件
bash main_cc.sh abc

# 使用 myproject.json 作为密钥文件
bash main_cc.sh myproject

# 直接指定完整文件名
bash main_cc.sh custom-key.json
```

脚本会自动：
1. 检测指定的密钥文件（如果未指定则使用默认的 `service-account-key.json`）
2. 使用服务账号进行认证
3. 设置应用默认凭据
4. 完成 Claude Code 配置

## 文件结构

```
/home/tuney.zh/OpenCoder/auto_cc/
├── main_cc.sh              # 主执行脚本
├── auto_setup_cc.sh        # 自动认证脚本
├── *.json                  # 服务账号密钥文件（需自行创建，名称可自定义）
│   ├── service-account-key.json  # 默认名称
│   ├── mykey.json               # 或自定义名称
│   └── prod-key.json            # 可以有多个密钥文件
└── README_AUTH.md          # 本文档
```

## 工作原理

1. `main_cc.sh` 接受可选的密钥文件名参数
2. 如果未指定参数，使用默认的 `service-account-key.json`
3. 如果指定了参数（如 `abc`），将查找 `abc.json` 文件
4. 检查密钥文件是否存在
5. 调用 `auto_setup_cc.sh` 并传递密钥文件名
6. `auto_setup_cc.sh` 使用指定的密钥文件进行 gcloud 认证
7. 设置环境变量 `GOOGLE_APPLICATION_CREDENTIALS`
8. 验证认证状态

## 安全注意事项

⚠️ **重要安全提示**：

1. **不要将任何 `.json` 密钥文件提交到 Git**
   - 所有 `*.json` 文件已在 `.gitignore` 中排除
   - 包含敏感认证信息

2. **妥善保管密钥文件**
   - 限制文件权限：`chmod 600 *.json`
   - 定期轮换密钥

3. **最小权限原则**
   - 只授予服务账号必要的权限
   - 避免使用 Owner 角色用于生产环境

## 故障排除

### 问题：找不到密钥文件

```
❌ Error: Service account key file not found: abc.json
```

**解决方案**：
1. 检查文件名是否正确
2. 确认文件在正确的目录下
3. 按照上述步骤创建并放置密钥文件

### 问题：认证失败

```
❌ Authentication failed
```

**解决方案**：
1. 检查密钥文件是否有效
2. 确认服务账号有正确的权限
3. 验证项目 ID 是否正确

### 问题：已有其他认证

如果系统已有其他 gcloud 认证，可以清除后重新认证：

```bash
gcloud auth revoke --all
# 使用默认密钥文件
bash auto_setup_cc.sh
# 或使用自定义密钥文件
bash auto_setup_cc.sh mykey.json
```

### 使用示例

```bash
# 示例1：使用默认密钥文件
bash main_cc.sh

# 示例2：使用自定义密钥文件
bash main_cc.sh production
# 将查找 production.json

# 示例3：指定完整文件名
bash main_cc.sh dev-environment.json
```

## 相关链接

- [Google Cloud 服务账号文档](https://cloud.google.com/iam/docs/service-accounts)
- [gcloud auth 命令参考](https://cloud.google.com/sdk/gcloud/reference/auth)