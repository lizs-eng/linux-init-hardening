#!/usr/bin/env bash
# SSH 加固：禁用密码登录（仅密钥）、禁 root 直接登录、关闭空密码
# 安全设计：①先确认当前用户已配置 SSH 公钥，否则拒绝执行 ②修改前备份 ③sshd -t 校验通过才生效
# 用法：sudo ./ssh_hardening.sh
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "请用 sudo 运行"; exit 1; }
command -v sshd >/dev/null || { echo "未找到 sshd"; exit 1; }

SSHD_CONFIG="/etc/ssh/sshd_config"

# ── 安全检查 1：确认当前用户已放好公钥，否则禁密码 = 把自己锁死 ──
USER_HOME=$(getent passwd "${SUDO_USER:-root}" | cut -d: -f6)
AUTH_KEYS="$USER_HOME/.ssh/authorized_keys"
if [ ! -s "$AUTH_KEYS" ]; then
  echo "❌ $AUTH_KEYS 不存在或为空。"
  echo "   请先把你的公钥放上去（ssh-copy-id 用户@服务器），确认能密钥登录后再跑本脚本！"
  exit 1
fi
echo "✅ 已检测到公钥：$AUTH_KEYS"

# ── 备份 ──
BAK="${SSHD_CONFIG}.bak.$(date +%Y%m%d%H%M%S)"
cp "$SSHD_CONFIG" "$BAK"
echo "✅ 已备份到 $BAK"

# ── 逐项写入配置（幂等：先删旧行再追加）──
set_cfg() { # $1=键 $2=值
  sed -i "/^#\?[[:space:]]*$1\b/d" "$SSHD_CONFIG"
  echo "$1 $2" >> "$SSHD_CONFIG"
}
set_cfg "PasswordAuthentication" "no"
set_cfg "PermitRootLogin" "prohibit-password"
set_cfg "PermitEmptyPasswords" "no"
set_cfg "X11Forwarding" "no"
set_cfg "MaxAuthTries" "4"

# ── 语法校验，通过才 reload（不重启，当前连接不断）──
if sshd -t 2>/dev/null; then
  systemctl reload sshd 2>/dev/null || systemctl reload ssh 2>/dev/null
  echo "✅ SSH 已加固并生效。"
  echo "⚠️  重要：不要关闭当前终端！另开一个终端确认密钥登录成功后再退出。"
  echo "    万一被锁：sudo cp $BAK $SSHD_CONFIG && sudo systemctl reload sshd"
else
  echo "❌ sshd 配置校验失败，已还原备份"
  cp "$BAK" "$SSHD_CONFIG"
  exit 1
fi
