#!/usr/bin/env bash
# 防火墙（UFW）：默认拒绝入站、放行 SSH 端口，防"开了防火墙把自己踢下线"
# 用法：sudo ./firewall_ufw.sh [SSH端口，默认22] [额外端口，如 80,443]
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "请用 sudo 运行"; exit 1; }
command -v ufw >/dev/null || { echo "未安装 ufw，先执行: apt install -y ufw"; exit 1; }

SSH_PORT="${1:-22}"
shift || true
EXTRA="$*"

# ── 先放行端口，再启用防火墙（顺序错了会把自己踢下线）──
ufw allow "${SSH_PORT}/tcp" > /dev/null
echo "✅ 已放行 SSH 端口 ${SSH_PORT}/tcp"
if [ -n "$EXTRA" ]; then
  for p in $EXTRA; do
    ufw allow "${p}/tcp" > /dev/null
    echo "✅ 已放行 ${p}/tcp"
  done
fi

ufw --force enable > /dev/null
ufw default deny incoming > /dev/null
ufw default allow outgoing > /dev/null

echo "✅ UFW 已启用（默认拒绝入站）。当前规则："
ufw status numbered
