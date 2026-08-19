# Ravena OS

> **Remaster de Arch Linux para trading na B3 — terminal-only, "DEV PRO".**

Sistema operacional de propósito específico construído sobre o Arch Linux (ISO oficial remasterizada), focado em operação de mercado financeiro na B3 com:

- Interface **eDEX-UI** (terminal futurista) em **pt-BR**, com widgets de rede e boot
- **Assistente local de IA** (llama.cpp/airllm) com bind somente em `127.0.0.1`
- **Segurança por padrão**: firewall nftables LAN-only, SSH com root desabilitado, sudo restrito, auditd, expiração de senha (90 dias)
- **Persistência em pendrive**: partição RAVENA-DATA (LUKS2) criada automaticamente no 1º boot
- **Hora correta**: RTC local + chrony (NTP)
- Menu de boot integrado ao OS, widgets e terminal tmux

## Builds

| Versão | Status | Descrição |
|---|---|---|
| **RV10v20** | ✅ **VALIDADA NO PC REAL (19/08/2026)** | Segurança S1–S7 + hora + locale pt-BR + eDEX traduzido + menu de contexto |
| RV10v19 | ❌ Tela preta (sudoers quebrou o X) | Corrigida na v20 |
| RV10v18 | ✅ Widget BOOT com 6 opções | — |

**ISO mais recente:** `ravena-remaster-RV10v20.iso` — SHA512 em `docs/hashes/`
(ISOs não são versionadas no Git — baixe o Arch ISO base e aplique os scripts de build)

## Estrutura

```
ravena-os/
├── build/            # scripts de build (remaster do ISO Arch)
├── docs/             # documentação oficial (ESTADO_VALIDADO, planos, relatórios)
├── rootfs/           # overlay customizado do sistema (etc/, home/, opt/edex-ui/, usr/local/bin/)
└── tools/            # scripts de verificação (gravação e VM)
```

## Requisitos

- WSL2 (Ubuntu) com root — todo build roda no WSL
- `archiso` + `xorriso` + `squashfs-tools` no WSL
- Rufus (Windows) para gravação do pendrive (modo DD)
- Pendrive ≥ 8GB (recomendado 16GB+) — a ISO tem ~7.8GB

## Como construir

```bash
# 1. Baixe a ISO base do Arch Linux e ajuste o caminho no script
# 2. Rode o build da versão desejada:
bash build/build_rv10v20.sh
# 3. O resultado fica em /root/ravv2/ravena-remaster-RV10v20.iso
```

## Como gravar (Windows)

1. `wsl --shutdown` (libera o pendrive do WSL)
2. Rufus → modo **DD** → selecione o pendrive SanDisk
3. Grave e verifique com `tools/verif_v20.ps1` (8/8 blocos IGUAL)

## Como verificar na VM

```bash
bash tools/verif_v20_vm.sh
```

## Segurança

Veja [SECURITY.md](SECURITY.md) e `docs/08-RAVENA-OS-RV10/ESTADO_VALIDADO.md` para o manifesto anti-regressão e validações por ciclo.

## Licença

MIT — veja [LICENSE](LICENSE).