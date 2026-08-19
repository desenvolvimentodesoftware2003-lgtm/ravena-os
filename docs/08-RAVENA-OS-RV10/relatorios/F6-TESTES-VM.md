# F6 — Build + Suíte de Testes na VM

**Status:** ✅ Validado (1º boot 13/13, 2º boot 11/11)
**Data:** 2026-08-12

## Build

| Artefato | Valor |
|---|---|
| ISO | `ravena-remaster-RV10.iso` — 7.813.332.992 bytes |
| ISO sha512 | `3b99d52dfdce205ad2992723714189e3579fbb0992df5a709d5cdf8e915813a636fe80297aa8bbd19395f5b5f008564cda69750d1a4c358c877aea234c9f7d10` |
| airootfs.sfs sha512 | `9b26b57f3bbfdb61d87a638d9e60f46bd099a8289aba09e8578d7f1ae8ab6a1eb27c0d144416f45caf7de2da693560c84a1a51deaa379fbaa380d0ceac364a6b` |

Comandos de build: `scripts/build_rv10.sh` (mksquashfs zstd + xorriso remaster
sobre a base RV5b).

## Método de teste

- **QEMU/KVM** com boot direto do kernel extraído (`/root/iso_kern`)
- **Rede user-mode `restrict=on`** (VM off-line, para testar o OOBE sem internet)
- **Acesso via SSH** (hostfwd `tcp:2222 → :22`) — muito mais robusto que serial
  (ttyS0 não tem autologin; archiso libera `PermitRootLogin yes`)
- Discos de teste: `vm_esp.img` (512M, partição vfat ESP) + `vm_data.img` (16G,
  partição DATA sem formato)
- Scripts: `rv10_1boot_ssh.py`, `rv10_2boot_ssh.py`

## Resultado — 1º boot (13/13 checks OK)

| # | Check | Resultado |
|---|---|---|
| 1 | RAVENA-DATA montada (LUKS criado no 1º boot) | ✅ |
| 2 | Recovery key impressa (ex.: `mNE8hDOojiWHF77esfqR`) | ✅ |
| 3 | `.ravena` linkado para a partição | ✅ |
| 4 | Estrutura `ravena/{cache,chaves,config}` criada | ✅ |
| 5 | Dotfiles persistidos (`.bashrc`, `.bash_profile`, `.tmux.conf`) | ✅ |
| 6 | Dev tools 10/10 presentes | ✅ |
| 7 | VM off-line (rede restrita) | ✅ |
| 8 | OOBE exibe banner "BEM-VINDO AO RAVENA OS" | ✅ |
| 9 | OOBE silencioso após conclusão (marcador) | ✅ |
| 10 | ravena-hardware responde | ✅ |
| 11 | ravena-instalar + ravena-sync-rede presentes | ✅ |
| 12 | Chaves gravadas na ESP (`ravena-keys/data.key` + `recovery.key`) | ✅ |
| 13 | Journal do serviço sem erros | ✅ |

## Resultado — 2º boot (11/11 checks OK) — persistência real

| # | Check | Resultado |
|---|---|---|
| 1 | Chaves restauradas da ESP → `/etc/ravena` (md5 idêntico) | ✅ |
| 2 | LUKS reaberto (`aes-xts-plain64`, 512 bits) | ✅ |
| 3 | RAVENA-DATA montada automaticamente | ✅ |
| 4 | Dados do 1º boot preservados | ✅ |
| 5 | Dotfiles restaurados da partição | ✅ |
| 6 | `.ravena` linkado novamente | ✅ |
| 7 | Não recriou o LUKS (chave reusada) | ✅ |
| 8 | eDEX-UI persistente (config na partição) | ✅ |
| 9 | Marcador `oobe-done` persistido → OOBE não re-exibe | ✅ |
| 10 | Journal: fluxo de reabertura limpo | ✅ |
| 11 | Boot sem falhas de serviço | ✅ |

## Correções feitas durante a validação

1. **Bug de persistência de chaves**: `find_esp_partition` não achava a ESP na
   VM (QEMU reporta `removable=0`) → adicionado passo 1b (ESP marcada
   PARTLABEL/LABEL=ESP) → chaves agora persistem e são restauradas
2. **Teste OOBE**: requer PTY (`script -qec`) — o painel `ravena-rede.sh` usa
   `read` interativo
3. **Teste serial abandonado** (ttyS0 sem autologin) → suíte SSH (estável)

## Logs

- Resultados detalhados: `rv10_2boot.log` (ambiente WSL)
