#!/bin/bash

# 脚本：全自动安装并初始化 Google Cloud CLI
# 描述：本脚本下载、安装、更新PATH、初始化并验证 gcloud CLI。

# 检查是否已存在 google-cloud-sdk 目录
if [ -d "google-cloud-sdk" ]; then
    echo "✅ 发现已存在的 google-cloud-sdk 目录，跳过下载和解压步骤"
    echo "直接运行安装脚本..."
else
    echo "开始下载 Google Cloud CLI..."
    
    # 下载对应Linux平台的包
    # 使用 -L 选项以处理重定向
    curl -O -L https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz
    
    # 检查下载是否成功
    if [ ! -f "google-cloud-cli-linux-x86_64.tar.gz" ]; then
        echo "下载失败，请检查您的网络连接或URL是否正确。"
        exit 1
    fi
    
    echo "下载完成，开始解压文件..."
    
    # 解压文件
    tar -xf google-cloud-cli-linux-x86_64.tar.gz
    
    echo "解压完成，以非交互模式运行安装脚本..."
fi

# 以非交互模式运行安装脚本，这将自动更新您的 ~/.bashrc 文件
# --quiet: 禁用交互式提示
# --path-update=true: 自动将gcloud CLI工具添加到PATH
# --usage-reporting=true/false: 根据您的偏好选择是否开启使用情况报告
./google-cloud-sdk/install.sh --quiet --path-update=true --usage-reporting=true

echo "安装脚本执行完毕。正在更新当前 shell 环境..."

# 检查并加载gcloud的路径配置
# 通常安装脚本会将其添加到 .bashrc 中
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
    echo "~/.bashrc 已重新加载。"
elif [ -f ~/.zshrc ]; then
    # 为 zsh 用户也提供支持
    source ~/.zshrc
    echo "~/.zshrc 已重新加载。"
else
    echo "警告：无法找到 .bashrc 或 .zshrc。您可能需要手动 source 合适的配置文件。"
    # 尝试直接 source 安装目录中的路径文件作为备用方案
    if [ -f ~/google-cloud-sdk/path.bash.inc ]; then
        source ~/google-cloud-sdk/path.bash.inc
        echo "已直接加载 gcloud 路径配置。"
    fi
fi


echo "---------------------------------------------------------------------"
echo "环境已更新。现在启动 gcloud init 进行初始化..."
echo "请按照接下来的提示登录您的 Google 账户并选择一个项目。"
echo "---------------------------------------------------------------------"
echo ""

gcloud -v

echo ""
echo "Google Cloud CLI 安装和配置完成！"