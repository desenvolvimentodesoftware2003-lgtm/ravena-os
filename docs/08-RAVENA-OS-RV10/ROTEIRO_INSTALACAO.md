# ROTEIRO DE INSTALAÇÃO — RAVENA OS RV10 (PENDRIVE → PC REAL)

> Pendrive: SanDisk Cruzer Blade (114.6GB) com `ravena-remaster-RV10.iso` gravado em modo DD.
> PC real: Latitude 5400 Dell (i7-8665U, 16GB RAM).
> Duração total: ~20–30 minutos.

---

## PASSO 0 — Antes de começar

- [ ] **IMPRIMA a chave de recuperação** que aparecerá no primeiro boot (RAVENA-DATA é LUKS2)
- [ ] Tenha o backup de qualquer dado do Windows que queira manter (a instalação apaga o disco)
- [ ] Carregue o notebook na tomada

## PASSO 1 — Boot pelo pendrive

1. Desligue o notebook
2. Ligue e pressione **F12** (menu de boot)
3. Escolha o **SanDisk Cruzer Blade** (UEFI ou legacy — o ISO é isohybrid MBR, qualquer modo funciona)
4. O Ravena sobe em ~20s direto para o terminal

## PASSO 2 — Primeiro boot (OOBE + persistência)

1. O sistema cria a **criptografia LUKS2 na RAVENA-DATA** e imprime a **CHAVE DE RECUPERAÇÃO** na tela
2. **ESCREVA/IMPRIMA e guarde essa chave** — sem ela + sem o pendrive, os dados ficam inacessíveis
3. O OOBE "BEM-VINDO AO RAVENA OS" aparece (sem rede): configure o WiFi (opção 1) ou cabo (opção 2)
4. As chaves ficam gravadas no pendrive (partição EFI) — nos próximos boots tudo reabre sozinho

## PASSO 3 — Instalação no NVMe (opcional, recomendado)

Com o sistema rodando do pendrive:

1. Rode: `ravena-instalar`
2. Confirme a instalação (digite a confirmação pedida)
3. O instalador: particiona o NVMe (GPT: ESP + RAVENA root + RAVENA-DATA), copia o sistema,
   instala o GRUB, configura LUKS na RAVENA-DATA e o fstab
4. Ao final: desligue, retire o pendrive, ligue — o Ravena inicia do NVMe

## PASSO 4 — Pós-instalação (verificação)

- [ ] `net` — rede conectada (WiFi perfil foi sincronizado)
- [ ] `ravena-hardware` — drivers do Latitude 5400 OK (i915, iwlwifi, áudio SOF, sensors)
- [ ] `horas` — tempo de uptime (NTP/chrony)
- [ ] `eDEX-UI` — subiu automaticamente no tty1
- [ ] `npm go cargo nvim rg fzf btop` — ferramentas de dev presentes
- [ ] `intel` — monitor de notícias geopolíticas (WarWatch)
- [ ] `llm` — IA local (Qwen 3.6-27B: baixar ~12GB antes do primeiro uso)

## RECUPERAÇÃO DE EMERGÊNCIA

Se perder o pendrive e precisar abrir a RAVENA-DATA manualmente:

```
cryptsetup open --type luks2 /dev/<particao> ravena-data
# digite a CHAVE DE RECUPERACAO impressa no 1o boot
mount /dev/mapper/ravena-data /mnt/ravena-data
```

## FORA DE ESCOPO (documentado)
OTA corporativo, SELinux/AppArmor estrito, whitelist USB rígida, containers/Docker,
pós-quântico em assinaturas (avaliação futura).

---
Arquivo: ROTEIRO_INSTALACAO.md — parte da entrega RV10 (F8).
