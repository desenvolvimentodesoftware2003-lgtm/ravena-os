# RAVENA OS — "DEV PRO" (RV10)

> Estação de trabalho de **trading (B3) + desenvolvimento**, enxuta e profissional,
> baseada em **Arch Linux remasterado** (isohybrid, MBR, modo DD). Terminal-only,
> com blindagem corporativa (viés): criptografia em repouso (LUKS2), pós-quântica
> (ML-KEM/ML-DSA) e persistência real de dados entre boots.

| | |
|---|---|
| **Versão** | RV10 "DEV PRO" |
| **Build ISO** | `ravena-remaster-RV10.iso` — sha512 `3b99d52d…` |
| **Tamanho** | 7.813.332.992 bytes (~7.28 GiB) |
| **Base** | Arch Linux remasterado (RV5b) |
| **Status** | F1–F8 concluídos; falta teste real no PC (Latitude 5400) |

---

## Visão geral das fases

| Fase | O que é | Status |
|---|---|---|
| **F1** | OOBE de 1º boot estilo Windows/MEC (boas-vindas + painel de rede) | ✅ implementado + validado na VM |
| **F2** | Persistência real: LUKS2 na RAVENA-DATA + chaves no pendrive + dotfiles/WiFi/eDEX | ✅ implementado + validado na VM |
| **F3** | Painel de hardware (Gerenciador de Dispositivos do Latitude 5400) | ✅ implementado |
| **F4** | Ambiente de desenvolvimento (npm, go, rust, nvim, rg, fzf, btop, git) | ✅ confirmado na VM (10/10) |
| **F5** | Instalador real para NVMe (GPT: ESP + RAVENA root + RAVENA-DATA, GRUB, LUKS) | ✅ implementado |
| **F6** | Build + suíte de testes na VM (1º boot 13/13, 2º boot 11/11 checks) | ✅ validado |
| **F7** | Documentação para o Git | ✅ este repositório |
| **F8** | Gravação final no pendrive + verificação física pós-gravação | ✅ gravado e íntegro |

---

## Resultados-chave da validação (VM, 2026-08-12/13)

**1º boot (13/13 checks OK):**
- Cria **LUKS2 (AES-256-XTS, 512 bits, Argon2id)** na RAVENA-DATA automaticamente
- Imprime a **chave de recuperação** na tela (IMPRIMIR E GUARDAR)
- Grava `data.key` + `recovery.key` na **partição EFI do pendrive** (persistem o live ISO)
- Monta `/mnt/ravena-data`, linka `/home/ravena/.ravena`, persiste dotfiles + eDEX-UI
- OOBE mostra "BEM-VINDO AO RAVENA OS" quando off-line

**2º boot (11/11 checks OK):**
- Restaura as chaves da ESP → reabre o LUKS **sem interação** → monta a partição
- Restaura dotfiles, perfis WiFi, config do eDEX-UI e chaves
- Não recria o LUKS (chave reusada); OOBE não re-exibe (marcador persistido)

**Gravação no pendrive (F8):**
- Rufus modo DD no SanDisk Cruzer Blade (114.6 GB, Disco 1)
- Verificação física pós-gravação: MBR + boot 1 MB + squashfs 4 MB@8 MB + final 2 MB — **3/3 blocos conferem com o ISO**

---

## Estrutura do repositório

```
ravena-os/
├── README.md                      ← este arquivo
├── docs/
│   ├── PLANO_EXECUCAO.md          ← plano completo com checkpoints por fase
│   ├── ROTEIRO_INSTALACAO.md      ← passo a passo de instalação no PC real
│   └── relatorios/
│       ├── F1-OOBE.md             ← relatório fase 1
│       ├── F2-PERSISTENCIA.md     ← relatório fase 2 (com resultado dos testes)
│       ├── F3-HARDWARE.md         ← relatório fase 3
│       ├── F4-DEVTOOLS.md         ← relatório fase 4
│       ├── F5-INSTALADOR.md       ← relatório fase 5
│       ├── F6-TESTES-VM.md        ← relatório fase 6 (suíte completa)
│       └── F8-GRAVACAO.md         ← relatório fase 8 (gravação + verificação)
├── scripts/
│   ├── build_rv10.sh              ← build do squashfs + remaster ISO
│   ├── rv10_1boot_ssh.py          ← teste 1º boot na VM (SSH)
│   ├── rv10_2boot_ssh.py          ← teste 2º boot na VM (persistência)
│   ├── GRAVAR_RV10.ps1            ← gravação com controle de hash (Windows)
│   └── VERIFICAR_PENDRIVE.ps1     ← verificação física pós-gravação (admin)
└── hashes/
    ├── ravena-remaster-RV10.iso.sha512
    └── airootfs.sfs.sha512
```

---

## Requisitos de hardware (PC alvo)

- **Latitude 5400 Dell** (i7-8665U 1.9–4.8 GHz, 16 GiB RAM, sem GPU)
- Pendrive USB ≥ 8 GB (gravação DD)
- NVMe para instalação (opcional; o sistema também roda live)

## Segurança

- **LUKS2** AES-256-XTS na RAVENA-DATA (chave de recuperação impressa no 1º boot)
- Chaves persistidas na ESP do pendrive (`ravena-keys/`) — sobrevivem ao reboot
- **Pós-quântica**: OpenSSL 3.6.3 (MLKEM512/768/1024), OpenSSH 10.4 (KEX mlkem768x25519 + MLDSA44-ED25519)
- `find_esp_partition` com proteções para **nunca** gravar chaves na ESP do Windows

## Credenciais (padrão, alterar no primeiro uso)

- `root` / `ravena`: `Dozinh@12` (autologin no tty1; sudo NOPASSWD no `ravena`)

---

## Como reproduzir os testes

```bash
# 1º boot (cria LUKS, valida persistência)
python3 scripts/rv10_1boot_ssh.py

# 2º boot (reabre LUKS com chave restaurada da ESP)
python3 scripts/rv10_2boot_ssh.py
```

Os scripts usam qemu/KVM com hostfwd SSH (porta 2222) e discos de teste
(`vm_esp.img` + `vm_data.img`). Requisitos do WSL: `qemu-system-x86_64`, `sshpass`, `sgdisk`.

## Fora de escopo (documentado)

OTA corporativo com rollback A/B, SELinux/AppArmor estrito, whitelist USB rígida,
watchdog de hardware agressivo, containers/Docker, pós-quântico em assinaturas
(ML-DSA em ed25519 — avaliação futura), IA local em produção
(Qwen 3.6-27B IQ2_M ~12 GB — download pendente, PC real 16 GB).

---

Feito com o método: **tudo validado na VM antes de gravar, gravação única no fim.**
