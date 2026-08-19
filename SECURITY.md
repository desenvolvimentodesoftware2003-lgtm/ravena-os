# Security Policy

O Ravena OS é construído com **segurança por padrão**. Este documento resume as medidas implementadas e o fluxo de reporte de vulnerabilidades.

## Medidas implementadas (RV10v20)

| ID | Medida | Detalhe |
|---|---|---|
| S1 | **Firewall de entrada (LAN only)** | nftables `ravena-sec-firewall.service` — SSH (22) e IA (8080) só aceitam conexões de sub-redes privadas; resto é `drop` |
| S2 | **SSH hardening** | `PermitRootLogin no`, `MaxAuthTries 2`, `LoginGraceTime 30`, `LogLevel VERBOSE` |
| S3 | **Expiração de senha** | `ravena-chage.service` — `chage -M 90 -W 7 ravena` no 1º boot |
| S4 | **IA somente local** | llama-server/airllm bind em `127.0.0.1` |
| S5 | **LLMNR/mDNS desligados** | `resolved.conf` com `LLMNR=no` + `MulticastDNS=no` |
| S6 | **sudo NOPASSWD restrito** | `sudoers.d/ravena` — apenas comandos ravena-*, nmcli, efibootmgr, mount/umount/findmnt/lsblk, ln, chmod, reboot/poweroff. Regra genérica `ALL` (com senha) vem PRIMEIRO (última regra vence no sudoers) |
| S7 | **Auditoria** | auditd com regras para passwd/shadow/sudoers/ssh/execve + journald persistente (500M/90d) |

## Persistência

- Partição `RAVENA-DATA` (LUKS2 + ext4) criada no 1º boot em pendrive (≥4GiB livres), **nunca** no NVMe interno
- Perfis WiFi persistidos via dispatcher `10-ravena-sync`

## Reporte de vulnerabilidades

Reporte em [GitHub Issues](https://github.com/desenvolvimentodesoftware2003-lgtm/ravena-os/issues) (repo público) ou diretamente ao mantenedor. Não exponha senhas, chaves LUKS ou dados de conta em issues.

## Limitações conhecidas

- O RAVENA roda **live** (não instalável no disco interno ainda) — os dados persistem na RAVENA-DATA do pendrive
- `timedatectl` mostra "NTP service: inactive" por padrão: o sistema usa **chrony** (`ravena-ntp.service`), não o timesyncd — a hora é sincronizada mesmo assim