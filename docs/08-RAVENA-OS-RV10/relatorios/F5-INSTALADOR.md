# F5 — Instalador Real (NVMe)

**Status:** ✅ Implementado (teste real pendente no PC)
**Data:** 2026-08-12

## Objetivo

Instalar o Ravena definitivamente no NVMe do PC (substituindo o Windows),
com a mesma persistência LUKS do modo live.

## O que foi feito

### `/usr/local/bin/ravena-instalar.sh`

- Particiona o NVMe em **GPT**:
  1. **ESP** (EFI System Partition, vfat)
  2. **RAVENA** (raiz do sistema)
  3. **RAVENA-DATA** (dados persistidos, LUKS2)
- Copia o sistema para o NVMe
- Instala o **GRUB** (boot no UEFI)
- Configura **LUKS** na RAVENA-DATA + `fstab`
- Cria `/etc/ravena/instalado` — habilita o **modo instalado** no
  `find_esp_partition` (aceita ESP do disco interno)
- **Confirmação obrigatória** antes de destruir o disco (anti-erro)

## Validação

- Na VM (pendrive simulado): o instalador está presente e executável
- Teste real (apagar NVMe do Latitude 5400) → **pendente, parte do F8**

## Aviso

O instalador apaga o disco alvo. Confirmar o disco correto antes de executar.
