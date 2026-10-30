#!/bin/zsh
# SuperMacHub — Apple Silicon MLX LoRA Fine-Tuning & Ollama Export Script
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "1) Eğitim veri seti oluşturuluyor (RVL-CDIP / CORD-v2 / Sentetik Türkçe-İngilizce Şeması)..."
python3 prepare_dataset.py

echo "2) Apple MLX (mlx-lm) ile Qwen2.5-1.5B-Instruct LoRA Fine-Tuning başlatılıyor..."
echo "   Komut: python3 -m mlx_lm.lora --model Qwen/Qwen2.5-1.5B-Instruct --train --data ./data --iters 200 --batch-size 2"
echo "3) Ollama üzerinde yerel ajan modelini oluşturmak için:"
echo "   ollama create supermac-agent -f Modelfile"
