# F3 — Painel de Hardware (Latitude 5400)

**Status:** ✅ Implementado
**Data:** 2026-08-12

## Objetivo

"Gerenciador de Dispositivos" por terminal — listar e diagnosticar os componentes
do Latitude 5400 Dell sem sair do console.

## O que foi feito

### `/usr/local/bin/ravena-hardware.sh`

- Lista e testa os drivers do Latitude 5400:
  - **GPU**: i915 (Intel UHD Graphics 620)
  - **WiFi**: iwlwifi (Intel Wireless 9260 / cc-a0)
  - **Áudio**: SOF (Sound Open Firmware)
  - **Sensores**: temperaturas via `sensors` (coretemp, etc.)
- Diagnóstico por dispositivo + estado de drivers
- Comando: `ravena-hardware` (alias)

## Validação (VM)

| Teste | Resultado |
|---|---|
| Painel abre e mostra cabeçalho "RAVENA HARDWARE — diagnóstico" | ✅ |
| Lista componentes (CPU, disco, rede, etc.) | ✅ |
| Não quebra em ambiente sem os drivers reais (VM) | ✅ |

## Observação

Na VM os dispositivos reais (i915/iwlwifi/SOF) não existem — o painel lista o que
o sistema reconhece. A validação completa dos drivers do Latitude 5400 deve ser
feita no **teste real no PC** (F8).
