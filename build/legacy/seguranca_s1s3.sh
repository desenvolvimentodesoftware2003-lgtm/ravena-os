#!/bin/bash
# seguranca_s1s3.sh - SSH hardening: firewall LAN-only + sem root + brute-force + chage
set -e
R=/root/ravv2/rootfs

# --- S1: firewall nftables: porta 22 aceita SO de sub-redes privadas (LAN/VPN local),
#      bloqueada de qualquer outra rede (internet/cafe). Tambem protege 8080 (IA). ---
cat > "$R/etc/ravena/ravena-sec-firewall.nft" << 'EOF'
#!/usr/sbin/nft -f
# RAVENA SEC (S1,S4,S5) - firewall de entrada: so LAN/loopback, resto drop
table inet ravena-sec {
    chain input {
        type filter hook input priority filter - 5; policy accept;

        # loopback livre
        iif "lo" accept

        # ICMP (ping) livre
        ip protocol icmp accept
        ip6 nexthdr icmpv6 accept

        # SSH (22) e IA (8080): somente de sub-redes privadas (LAN da casa/escritorio)
        # e 10.0.2.0/24 (NAT do VirtualBox p/ teste) e 172.16-31/12 (VPN wireguard)
        ip saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } tcp dport 22 accept
        ip saddr { 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 } tcp dport 8080 accept

        # estabelecidas/relacionadas
        ct state established,related accept

        # resto: drop (nada de fora chega)
        drop
    }
}
EOF
chmod 755 "$R/etc/ravena/ravena-sec-firewall.nft"

cat > "$R/etc/systemd/system/ravena-sec-firewall.service" << 'EOF'
[Unit]
Description=RAVENA SEC - firewall de entrada (LAN only)
After=network-pre.target
Before=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/usr/sbin/nft -f /etc/ravena/ravena-sec-firewall.nft
ExecStop=/usr/sbin/nft delete table inet ravena-sec

[Install]
WantedBy=multi-user.target
EOF
ln -sf /etc/systemd/system/ravena-sec-firewall.service "$R/etc/systemd/system/multi-user.target.wants/ravena-sec-firewall.service"

# --- S2: sshd - sem root, brute-force limitado ---
cat > "$R/etc/ssh/sshd_config.d/10-archiso.conf" << 'EOF'
# RAVENA SEC (S2) - hardening SSH
# Root nao loga via SSH (login remoto so com usuario ravena)
PermitRootLogin no

# Senha permitida (usuario ravena) - chave publica futura
PasswordAuthentication yes

# Anti brute-force: max 2 tentativas por conexao, 30s para autenticar
MaxAuthTries 2
LoginGraceTime 30

# Log de autenticacao detalhado no journal
LogLevel VERBOSE
EOF

# --- S3: expiracao da senha em 90 dias (senha atual permanece) ---
cat > "$R/etc/systemd/system/ravena-chage.service" << 'EOF'
[Unit]
Description=RAVENA SEC - expiracao de senha (90 dias)
After=local-fs.target
ConditionPathExists=!/etc/ravena/.chage-done

[Service]
Type=oneshot
ExecStart=/usr/bin/chage -M 90 -W 7 ravena
ExecStart=/usr/bin/touch /etc/ravena/.chage-done
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
ln -sf /etc/systemd/system/ravena-chage.service "$R/etc/systemd/system/multi-user.target.wants/ravena-chage.service"

echo "=== validacao ==="
cat "$R/etc/ssh/sshd_config.d/10-archiso.conf"
echo "---"
ls -la "$R/etc/systemd/system/multi-user.target.wants/ravena-sec-firewall.service" "$R/etc/systemd/system/multi-user.target.wants/ravena-chage.service"
echo "S1S3 OK"