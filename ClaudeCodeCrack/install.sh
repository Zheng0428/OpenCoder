curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
source ~/.bashrc
nvm install 18
http_proxy=http://sys-proxy-rd-relay.byted.org:8118
https_proxy=http://sys-proxy-rd-relay.byted.org:8118
no_proxy=.byted.org
npm config set registry https://bnpm.byted.org
npm i -g @byted/claude-code-bridge
export ANTHROPIC_MODEL=gcp-claude4-sonnet
export ANTHROPIC_API_URL=https://gpt-i18n.byteintl.net/gpt/openapi/online/v2/crawl
export ANTHROPIC_MAX_TOKENS=8192
export ANTHROPIC_AUTH_TOKEN=BXLS5vdOjkNRYFlzVUMumXNdYcOE3Eae
export 
echo "已安装 claude-code, 在工作目录下运行: 'claude-code' 即可激活  ..."