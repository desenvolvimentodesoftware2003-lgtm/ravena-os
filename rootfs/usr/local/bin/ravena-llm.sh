#!/bin/bash
# RAVENA LLM provider - prioriza GGUF L3-Dark-Planet-8B Q4_K_M (llama-server);
# airLLM text-only fica como fallback futuro (quando houver rede p/ safetensors).
set -e
CONF=/etc/ravena/llm.conf
LLM_QUANT=Q4_k_m
LLM_PORT=8080
SERVE=/usr/local/bin/ravena-airllm-server.py
[ -f "$CONF" ] && . "$CONF"

MODELOS="/mnt/ravena-data/modelos"
TXT_DIR="/mnt/ravena-data/modelos/qwen27b-txt"
SFS_MODELOS="/home/ravena/os/.modelos-squashfs"

# --- 0. se a RAVENA-DATA estiver montada mas sem modelo, copia o modelo do
#    squashfs (sistema live, comprimido = mmap lento) para o disco real ---
if [ -d "$MODELOS" ] && [ -z "$(ls "$MODELOS"/L3-Dark-Planet*gguf 2>/dev/null)" ]; then
    SRC=$(ls "$SFS_MODELOS"/L3-Dark-Planet*gguf 2>/dev/null | head -1)
    if [ -n "$SRC" ]; then
        echo "ravena-llm: copiando modelo para RAVENA-DATA (1a vez)..."
        cp -f "$SRC" "$MODELOS/" 2>/dev/null || true
        sync
    fi
fi
[ -d "$MODELOS" ] || MODELOS="/home/ravena/os/modelos"

# --- 1. prioridade: GGUF L3-Dark-Planet-8B via llama-server (MHA puro;
#    nota original diz 3.78 tok/s - contexto nao documentado. Medido DENTRO do
#    ravena-llm.service: ~0.59 tok/s, porque CPUQuota=90% + 1 thread = 0.9 de
#    1 CPU. Ver LLM_THREADS abaixo) ---
F=""
for q in "$LLM_QUANT" "Q4_k_s" "Q5_k_s"; do
  f="$MODELOS/L3-Dark-Planet-8B-D_AU-${q}.gguf"
  [ -f "$f" ] && { F="$f"; break; }
done
[ -z "$F" ] && F=$(ls "$MODELOS"/L3-Dark-Planet*gguf 2>/dev/null | head -1)
if [ -n "$F" ] && [ -f "$F" ]; then
  echo "ravena-llm: provendo GGUF em $(basename "$F") na :$LLM_PORT"
  # --threads NAO usa $(nproc): o ravena-llm.service roda com CPUQuota=90% e o
  # nproc do coreutils passa a reportar 1 unidade nesse cgroup (medido: affinity
  # 0-3, cpu.max 90000 100000, nproc=1). Com cpu.max em 0.9 de 1 CPU, >1 thread
  # so faz os threads briguarem pelo mesmo cap (throttle a cada 100ms) - 1 e o
  # valor certo, mas agora e explicito e sobrescrevivel (LLM_THREADS) em vez de
  # derivado por acidente do cgroup. Remover CPUQuota exige rever isto.
  LLM_THREADS="${LLM_THREADS:-1}"
  exec llama-server -m "$F" -c 4096 --port "$LLM_PORT" -fit off --load-mode mmap \
    --threads "$LLM_THREADS" --host 127.0.0.1
fi

# --- 2. fallback: airLLM text-only (safetensors convertido) ---
if [ -f "$TXT_DIR/model.safetensors.index.json" ]; then
  echo "ravena-llm: provendo AirLLM text-only de $TXT_DIR na :$LLM_PORT"
  export LLM_PORT
  exec python3 "$SERVE" "$TXT_DIR"
fi

echo "ravena-llm: nenhum modelo disponivel. Rodar: llm baixar-dark-planet Q4_k_m"
exit 0