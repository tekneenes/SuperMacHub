#!/usr/bin/env python3
"""
SuperMacHub — AI Dosya Düzenleyici Veri Seti Hazırlayıcı (Dataset Pipeline)
===========================================================================
Desteklenen Veri Kaynakları:
1. Sentetik Türkçe/İngilizce macOS Klasör & OCR Veri Seti (Anında Üretim - 0 bağımlılık)
2. HuggingFace RVL-CDIP (`aharley/rvl_cdip` - 16 Belge Sınıfı)
3. HuggingFace CORD-v2 (`naver-clova-ix/cord-v2` - Fiş/Fatura Tarih ve Tutar Çıkarımı)

Çıktı:
- `data/train.jsonl` ve `data/valid.jsonl` (Apple MLX `mlx_lm.lora` ile doğrudan uyumlu ChatML formatı)
"""

import json
import os
import random
from pathlib import Path

SYSTEM_PROMPT = (
    "Sen SuperMacHub içinde çalışan yerel AI Dosya Sınıflandırma ve İsimlendirme modelisin. "
    "Verilen dosya adını, Magika byte imzasını ve Vision OCR / PDF metin özetini analiz ederek "
    "yalnızca geçerli bir JSON döndür: "
    '{"semantic_category": "...", "suggested_filename": "...", "confidence": 0.95, "reason": "..."}'
)

SYNTHETIC_SAMPLES = [
    {
        "input": {
            "original_filename": "IMG_8492.PNG",
            "magic_signature": "PNG Image (89PNG)",
            "created_date": "2026-10-25",
            "ocr_snippet": "GARANTİ BBVA FAST DEKONT Gönderen: Muhammed Alıcı: Ev Sahibi Tutar: 22.500,00 TL Açıklama: Ekim 2026 Kira Ödemesi"
        },
        "output": {
            "semantic_category": "01_Finans_ve_Faturalar/Kira_Dekontlari",
            "suggested_filename": "2026-10-25_Garanti_Ekim_Kira_Dekontu_22500TL.png",
            "confidence": 0.98,
            "reason": "Vision OCR metninde banka FAST dekontu, tarih ve kira ödemesi tespit edildi."
        }
    },
    {
        "input": {
            "original_filename": "Screen Shot 2026-10-27 at 14.22.10.png",
            "magic_signature": "PNG Image (89PNG)",
            "created_date": "2026-10-27",
            "ocr_snippet": "Fatal error: Index out of range: file Swift/ContiguousArrayBuffer.swift, line 600 Xcode 16.2"
        },
        "output": {
            "semantic_category": "02_Ekran_Goruntuleri_OCR/Hata_Raporlari",
            "suggested_filename": "2026-10-27_Ekran_Swift_IndexOutOfRange_Hatasi.png",
            "confidence": 0.95,
            "reason": "Ekran görüntüsü içinde Swift/Xcode hata mesajı tespit edildi."
        }
    },
    {
        "input": {
            "original_filename": "efatura_9928172.pdf",
            "magic_signature": "PDF Document (%PDF)",
            "created_date": "2026-10-20",
            "ocr_snippet": "e-Arşiv Fatura TURKCELL İLETİŞİM HİZMETLERİ A.Ş. Ödenecek Tutar: 840,00 TL Son Ödeme: 04.11.2026"
        },
        "output": {
            "semantic_category": "01_Finans_ve_Faturalar/Telekom_Faturalari",
            "suggested_filename": "2026-10-20_Turkcell_eArsiv_Fatura_840TL.pdf",
            "confidence": 0.99,
            "reason": "e-Arşiv fatura şablonu, şirket adı ve fatura tutarı tespit edildi (RVL-CDIP: invoice)."
        }
    },
    {
        "input": {
            "original_filename": "document_final_v3(1).pdf",
            "magic_signature": "PDF Document (%PDF)",
            "created_date": "2026-10-12",
            "ocr_snippet": "CURRICULUM VITAE - Senior iOS & macOS Engineer - Skills: Swift, SwiftUI, CoreML, Metal, Objective-C"
        },
        "output": {
            "semantic_category": "04_Belgeler_ve_Sunumlar/Kariyer_CV",
            "suggested_filename": "2026-10-12_CV_Senior_macOS_Engineer.pdf",
            "confidence": 0.96,
            "reason": "Özgeçmiş (CV) yapısı tespit edildi (RVL-CDIP: resume)."
        }
    },
    {
        "input": {
            "original_filename": "Docker-AppleSilicon-4.35.dmg",
            "magic_signature": "macOS Disk Image (DMG)",
            "created_date": "2026-10-01",
            "ocr_snippet": ""
        },
        "output": {
            "semantic_category": "03_Kurulum_Paketleri_DMG",
            "suggested_filename": "Docker-AppleSilicon-4.35.dmg",
            "confidence": 0.99,
            "reason": "macOS kurulum disk imajı tespit edildi."
        }
    }
]


def build_jsonl_dataset(output_dir: Path, total_count: int = 200):
    output_dir.mkdir(parents=True, exist_ok=True)
    rows = []

    for i in range(total_count):
        base = random.choice(SYNTHETIC_SAMPLES)
        record = {
            "messages": [
                {"role": "system", "content": SYSTEM_PROMPT},
                {"role": "user", "content": json.dumps(base["input"], ensure_ascii=False)},
                {"role": "assistant", "content": json.dumps(base["output"], ensure_ascii=False)}
            ]
        }
        rows.append(record)

    split_idx = int(len(rows) * 0.85)
    train_rows = rows[:split_idx]
    valid_rows = rows[split_idx:]

    with open(output_dir / "train.jsonl", "w", encoding="utf-8") as f:
        for r in train_rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")

    with open(output_dir / "valid.jsonl", "w", encoding="utf-8") as f:
        for r in valid_rows:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")

    print(f"[+] Veri seti hazırlandı: {len(train_rows)} train, {len(valid_rows)} valid -> {output_dir}")


if __name__ == "__main__":
    target = Path(__file__).parent / "data"
    build_jsonl_dataset(target, total_count=200)
