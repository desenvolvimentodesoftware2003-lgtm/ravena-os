#!/bin/bash
# seguranca_s7.sh - S7: auditd ativo + regras de auditoria + journald persistente
set -e
R=/root/ravv2/rootfs

# --- S7a: regras de auditoria (login, SSH, sudo, alteracoes de privilegio) ---
cat > "$R/etc/audit/rules.d/ravena.rules" << 'EOF'
## RAVENA SEC (S7) - regras de auditoria
-w /etc/shadow -p wa -k ravena_id
-w /etc/passwd -p wa -k ravena_id
-w /etc/sudoers -p wa -k ravena_id
-w /etc/sudoers.d/ -p wa -k ravena_id
-w /var/run/utmp -p wa -k ravena_login
-w /etc/ssh/sshd_config -p wa -k ravena_ssh
-w /etc/ssh/sshd_config.d/ -p wa -k ravena_ssh
-a always,exit -F arch=b64 -S execve -F auid>=1000 -F auid!=4294967295 -k ravena_exec
-a always,exit -F arch=b32 -S execve -F auid>=1000 -F auid!=4294967295 -k ravena_exec
EOF

# --- S7b: auditd.conf - rotacao e log consolidado ---
cat > "$R/etc/audit/auditd.conf" << 'EOF'
log_file = /var/log/audit/audit.log
log_format = ENRICHED
log_group = adm
priority_boost = 4
flush = INCREMENTAL_ASYNC
freq = 50
num_logs = 5
dispatcher = /sbin/audispd
max_log_file = 8
max_log_file_action = ROTATE
space_left = 75
space_left_action = SYSLOG
action_mail_acct = root
admin_space_left = 50
admin_space_left_action = HALT
disk_full_action = SUSPEND
disk_error_action = SUSPEND
use_libwrap = yes
EOF

# --- S7c: ativar auditd no boot ---
ln -sf /etc/systemd/system/auditd.service "$R/etc/systemd/system/multi-user.target.wants/auditd.service"

# --- S7d: journald persistente (logs sobrevivem a reinicializacao) ---
cat > "$R/etc/systemd/journald.conf" << 'EOF'
[Journal]
Storage=persistent
Compress=yes
SystemMaxUse=500M
SystemKeepFree=1G
MaxRetentionSec=90d
ForwardToSyslog=no
EOF

echo "=== audit rules ==="
cat "$R/etc/audit/rules.d/ravena.rules"
echo "=== journald.conf ==="
cat "$R/etc/systemd/journald.conf"
echo "=== auditd enabled ==="
ls -la "$R/etc/systemd/system/multi-user.target.wants/auditd.service"
echo "S7 OK"