#!/usr/bin/env bash
# 内核参数加固：写入独立配置文件，不动系统原配置，可随时删除回滚
# 用法：sudo ./sysctl_tune.sh
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "请用 sudo 运行"; exit 1; }

CONF="/etc/sysctl.d/99-hardening.conf"
cp /dev/null "$CONF"

cat >> "$CONF" <<'EOF'
# --- 防网络攻击基础项（2026-10 基线）---
# 防 SYN 洪泛
net.ipv4.tcp_syncookies = 1
# 不接受 ICMP 重定向（防中间人）
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
# 不发送 ICMP 重定向
net.ipv4.conf.all.send_redirects = 0
# 忽略源路由
net.ipv4.conf.all.accept_source_route = 0
# 防 IP 欺骗
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
# 记录可疑包
net.ipv4.conf.all.log_martians = 1
# 忽略广播 ICMP（防 smurf）
net.ipv4.icmp_echo_ignore_broadcasts = 1
# --- 文件与内存 ---
# 防硬链接/符号链接攻击
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
# 限制核心转储泄露内存
fs.suid_dumpable = 0
kernel.randomize_va_space = 2
EOF

sysctl --system > /dev/null 2>&1
echo "✅ 内核参数已加固（配置文件: $CONF）"
echo "回滚方法: sudo rm $CONF && sudo sysctl --system"
