# linux-init-hardening

Linux 服务器初始化加固脚本：把"新服务器上线该做的安全配置"变成几条命令。

写给一个人管几台 VPS 的你：脚本全部带**防锁死设计**（先验公钥、先放行端口、改配置前备份、校验通过才生效），每一步都有回滚方法，中文注释逐行可读。

## 快速开始

```bash
git clone https://github.com/lizs-eng/linux-init-hardening.git
cd linux-init-hardening/scripts

# 前提：你的 SSH 公钥已经放好（ssh-copy-id 用户@服务器）
sudo ./sysctl_tune.sh            # 1. 内核参数加固
sudo ./firewall_ufw.sh 22        # 2. 防火墙（先放行 SSH 再启用）
sudo ./ssh_hardening.sh          # 3. SSH 加固（禁密码登录）
```

## 免费样章（本仓库）

| 脚本 | 用途 | 防锁死设计 |
|---|---|---|
| `sysctl_tune.sh` | 内核参数加固（防 SYN 洪泛/欺骗/提权），独立配置文件 | 删文件即回滚 |
| `firewall_ufw.sh` | UFW 默认拒绝入站，**先放行 SSH 再启用** | 顺序防踢线 |
| `ssh_hardening.sh` | 禁密码登录/禁 root 直登，**先验公钥再动手** | 公钥校验+备份+sshd -t 校验 |

目标系统：Debian 11+/Ubuntu 20.04+（CentOS/Rocky 用户可参考，防火墙部分需改 firewalld）。

## 完整版（¥19.9）

在免费样章之上追加：

- **fail2ban_setup.sh**：SSH 暴力破解自动封禁（5 次失败封 1 小时）
- **user_audit.sh**：只读安全审计（可疑账号/空密码/开放端口/待更新数/失败登录）
- **auto_updates.sh**：自动安全更新（只装 security 补丁，不自动重启）
- **harden_all.sh**：一键按序执行全部步骤，单步失败不中断
- **使用说明**：每步的原理、回滚方法、常见翻车点

→ 完整版与更多作品：[面包多小店](https://mbd.pub/o/engineer)

## 校准与许可

- 按 2026-10 的 Debian/Ubuntu 软件源行为校准；脚本不会自动重启 SSH，改完配置后请按提示新开终端验证
- 发现 bug 欢迎提 issue；许可：MIT（见 LICENSE）
