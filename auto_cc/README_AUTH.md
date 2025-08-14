# Google Cloud 自动认证说明

## 问题说明
Google Cloud CLI (`gcloud`) 不支持直接通过命令行输入密码进行认证，这是出于安全考虑的设计。

## 自动化认证方案

### 方案1：使用服务账号密钥（推荐用于自动化）

1. 在 Google Cloud Console 创建服务账号：
   ```bash
   # 创建服务账号
   gcloud iam service-accounts create claude-auto-auth \
     --display-name="Claude Auto Authentication"
   
   # 生成密钥文件
   gcloud iam service-accounts keys create service-account-key.json \
     --iam-account=claude-auto-auth@YOUR_PROJECT_ID.iam.gserviceaccount.com
   ```

2. 将 `service-account-key.json` 文件放在 `/home/tuney.zh/OpenCoder/auto_cc/` 目录下

3. 脚本会自动检测并使用该密钥文件进行认证

### 方案2：使用无浏览器模式

脚本现在使用 `--no-launch-browser` 标志，这会：
- 不自动打开浏览器
- 显示一个 URL 链接
- 你可以手动复制链接到浏览器完成认证
- 将认证码粘贴回终端

### 方案3：使用已存在的认证

如果你已经在系统上认证过：
```bash
# 检查当前认证状态
gcloud auth list

# 如果已认证，脚本会自动跳过认证步骤
```

## 使用方法

```bash
# 使用服务账号（最自动化）
# 先将 service-account-key.json 放在 auto_cc 目录
bash main_cc.sh

# 使用无浏览器模式
bash main_cc.sh your@gmail.com your_password
# 注意：密码参数现在只用于标识需要自动化，实际认证仍需通过 OAuth

# 交互式认证
bash main_cc.sh
```

## 安全建议

1. **服务账号密钥**：妥善保管，不要提交到 Git
2. **个人账号**：使用 OAuth 认证更安全
3. **自动化场景**：优先使用服务账号

## 相关文件

- `service-account-key.json`：服务账号密钥文件（需自行创建）
- `auto_setup_cc.sh`：自动认证脚本
- `main_cc.sh`：主执行脚本