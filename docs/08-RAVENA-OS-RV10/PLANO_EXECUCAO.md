# PLANO DE EXECUÇÃO — RAVENA OS RV10 "DEV PRO"

> Objetivo: estação de trabalho de trading + desenvolvimento (B3), enxuta e profissional,
> terminal-only, com blindagem corporativa (viés) incluindo criptografia em repouso (LUKS2).
> Status global: F1–F6 implementadas e validadas, F7 (documentação) concluído, F8 (gravação final RV10v2 + testes VM) concluído.
> Cada item tem checkpoint de verificação antes de avançar.

---

## FASE 1 — OOBE DE PRIMEIRO BOOT (estilo Windows/MEC) — ✅ IMPLEMENTADO

### 1.1 `/usr/local/bin/ravena-oobe.sh`
- [x] Tela de 1º boot "BEM-VINDO AO RAVENA OS": sem internet → abre painel `rede` (1=WiFi, 2=cabo, 3=nmtui, 4=desconectar, 5=IP/DNS)
- [x] Pós-conexão: chama `ravena-sync-rede.sh` (persiste o perfil WiFi na RAVENA-DATA)
- [x] Integrado no `.bash_profile` ANTES do `startx` (roda uma vez, marcador `oobe-done`)
- [x] Marcador persistido na RAVENA-DATA (`ravena/config/oobe-done`) — não re-exibe nos próximos boots
- [x] Alias `oobe` para rodar manualmente
- **Checkpoint (VM, 1º boot off-line):** banner exibido; com marcador → execução silenciosa ✅

### 1.2 Pós-quântico (já embutido no build RV9/RV10)
- [x] OpenSSL 3.6.3: MLKEM512/768/1024 + híbridos X25519MLKEM768, SecP384r1MLKEM1024
- [x] OpenSSH 10.4: KEX mlkem768x25519-sha256 + sntrup761x25519-sha512 (`10-rav-pq.conf`), chave de host híbrida MLDSA44-ED25519 (FIPS 204)
- [x] Pendente de avaliação futura: ML-DSA em assinaturas

---

## FASE 2 — PERSISTÊNCIA REAL (a causa do "ciclo") — ✅ IMPLEMENTADO E VALIDADO

### 2.1 `ravena-data.sh` (20KB) — script de montagem/persistência
- [x] **1º boot**: detecta partição sem formato → cria **LUKS2 (AES-256-XTS, chave 512 bits, Argon2id)**, gera `data.key` (64B) + chave de recuperação (20 caracteres, impressa na tela), formata ext4 (`RAVENA-DATA`), monta em `/mnt/ravena-data`
- [x] **Boots seguintes**: restaura as chaves do pendrive (partição EFI → `ravena-keys/data.key` + `recovery.key`) e reabre o LUKS automaticamente
- [x] Persistência de: perfis WiFi (`system-connections`), dotfiles (`.bashrc`, `.bash_profile`, `.tmux.conf`, `.gitconfig`), config do eDEX-UI, chaves
- [x] `/home/ravena/.ravena` → link simbólico para `/mnt/ravena-data/ravena` (config+cache sobrevivem ao live ISO)
- [x] Sync bidirecional `/etc ↔ RAVENA-DATA`; `ravena-sync-rede.sh` chamado pós-OOBE
- [x] Ordem de boot: data → NM → login (não trava mais o boot)
- [x] `find_esp_partition` com 4 passos de segurança (removível → ESP marcada → modo instalado → fallback removível; nunca grava na ESP do Windows)
- [x] **PATCH 1b (2026-08-12)**: aceita ESP com `PARTLABEL/LABEL=ESP` em qualquer disco — necessário na VM/QEMU (sysfs reporta `removable=0`) e no modo instalado
- **Checkpoint (VM):** 1º boot cria LUKS + grava chaves na ESP; 2º boot restaura chaves e reabre sem recriar ✅

---

## FASE 3 — PAINEL DE HARDWARE (Latitude 5400) — ✅ IMPLEMENTADO

### 3.1 `/usr/local/bin/ravena-hardware.sh`
- [x] "Gerenciador de Dispositivos": i915, iwlwifi 9260/cc-a0, áudio SOF, sensors (temperaturas)
- [x] Diagnóstico por dispositivo + estado de drivers
- **Checkpoint (VM):** painel responde e lista componentes ✅

---

## FASE 4 — AMBIENTE DE DESENVOLVIMENTO — ✅ CONFIRMADO NA VM

### 4.1 Ferramentas (validadas no boot da VM, 10/10)
- [x] npm 12, go 1.26, rust/cargo 1.97, nvim 0.12, ripgrep, fzf, btop, git 2.55, python3, gcc/g++
- [x] `~/projects/` com git 2.55
- **Checkpoint (VM):** `command -v npm go cargo rg fzf btop nvim git python3` — todos presentes ✅

---

## FASE 5 — INSTALADOR REAL (NVMe) — ✅ IMPLEMENTADO

### 5.1 `/usr/local/bin/ravena-instalar.sh`
- [x] Particiona NVMe em GPT: ESP + RAVENA root + RAVENA-DATA
- [x] Copia o sistema, GRUB, LUKS na RAVENA-DATA, fstab
- [x] Modo "instalado no NVMe" ativado via `/etc/ravena/instalado` (muda busca da ESP)
- [x] Confirmação obrigatória (anti-erro)
- **Checkpoint:** pendente teste real no PC (F8)

---

## FASE 6 — BUILD + SUÍTE DE TESTES NA VM — ✅ VALIDADO (2026-08-12)

### 6.1 Build
- [x] ISO `ravena-remaster-RV10.iso` (7.813.332.992 bytes ≈ 7.28 GiB), sha512 `3b99d52dfdce...` (arquivo `.iso.sha512`)
- [x] airootfs.sfs sha512 `9b26b57f3bbf...` (arquivo `.sfs.sha512`)
- [x] Método de teste: **SSH via hostfwd (porta 2222)** — mais robusto que serial (archiso libera `PermitRootLogin yes`); VM com `restrict=on` (off-line)

### 6.2 Resultados 1º boot (13/13 checks OK)
| Check | Resultado |
|---|---|
| RAVENA-DATA montada (LUKS criado no 1º boot) | ✅ |
| Chave de recuperação impressa (ex.: `mNE8hDOojiWHF77esfqR`) | ✅ |
| `.ravena` → link simbólico para a partição | ✅ |
| Estrutura `ravena/{cache,chaves,config}` criada | ✅ |
| Dotfiles persistidos (`.bashrc`, `.bash_profile`, `.tmux.conf`) | ✅ |
| Dev tools 10/10 | ✅ |
| VM off-line (rede restrita) | ✅ |
| OOBE exibe banner "BEM-VINDO AO RAVENA OS" | ✅ |
| OOBE silencioso após conclusão (marcador) | ✅ |
| ravena-hardware responde | ✅ |
| ravena-instalar + ravena-sync-rede presentes | ✅ |
| Chaves gravadas na ESP (`ravena-keys/data.key` + `recovery.key`) | ✅ |
| Journal: fluxo completo sem erros | ✅ |

### 6.3 Resultados 2º boot (11/11 checks OK) — persistência real
| Check | Resultado |
|---|---|
| Chaves restauradas da ESP → `/etc/ravena` (md5 idêntico ao 1º boot) | ✅ |
| LUKS reaberto (`aes-xts-plain64`, 512 bits) | ✅ |
| RAVENA-DATA montada automaticamente | ✅ |
| Dados do 1º boot preservados (CHAVE_RECUPERACAO.txt, ravena/, modelos, scripts) | ✅ |
| Dotfiles restaurados da partição | ✅ |
| `.ravena` linkado novamente | ✅ |
| NÃO recriou LUKS (chave reusada) | ✅ |
| eDEX-UI persistente (config na partição) | ✅ |
| Marcador `oobe-done` persistido → OOBE não re-exibe | ✅ |
| Journal: fluxo de reabertura limpo | ✅ |

### 6.4 Correções feitas durante a validação
- **Bug encontrado**: `find_esp_partition` não achava a ESP na VM (QEMU reporta `removable=0`) → chaves nunca persistiam. **Fix**: passo 1b (ESP marcada) — validado e rebuildado
- **Teste serial abandonado** (ttyS0 sem autologin) → suíte SSH (estável)

---

## FASE 7 — DOCUMENTAÇÃO PARA O GIT — ✅ EM ANDAMENTO
- [x] Este plano atualizado com resultados por fase (F1–F6)
- [ ] Relatório técnico por fase (checkpoints de VM)
- [ ] Espelhar arquivos em `RAVENA-RV7\` + copiar ISO RV10 + hashes
- [ ] Instruções de instalação e uso (README do usuário)

---

## FASE 8 — GRAVAÇÃO FINAL NO PENDRIVE — PENDENTE
- [ ] Hash do ISO conferido antes de gravar
- [ ] Rufus DD no SanDisk (Disco 1, ~114.5 GB) com progresso
- [ ] Conferência pós-gravação (offset + size; hash se legível)
- [ ] Roteiro de instalação no NVMe (`ravena-instalar`, deletando o Windows)
- [ ] **Teste real no PC** → feedback p/ próximos ciclos

---

## ORDEM E DEPENDÊNCIAS
F1 (OOBE) → F2 (persistência, causa do ciclo) → F3 (hardware) → F4 (dev) → F5 (instalador)
→ F6 (build+testes VM) → F7 (documentação) → F8 (gravação única + teste real).
Método acordado: tudo validado na VM ANTES de gravar; gravação ÚNICA no fim.

## FORA DE ESCOPO (viés desconsiderado, documentado)
OTA corporativo com rollback A/B, SELinux/AppArmor estrito, whitelist USB rígida
(p/ manter plug-and-play), watchdog de hardware agressivo, ChromaDB/camadas de cache,
containers/Docker, pós-quântico em assinaturas (ed25519 mantido; ML-DSA fica p/ avaliação futura),
IA local em produção (Qwen 3.6-27B IQ2_M, ~12GB — download pendente, só no PC real de 16GB).

---
Arquivo: PLANO_EXECUCAO.md — mantido em OneDrive (Documentos/RAVENA-RV7) para continuidade entre sessões.
