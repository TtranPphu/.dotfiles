#!/usr/bin/env python3
import re
import subprocess
import sys

wav = sys.argv[1]
model = "/mnt/shared/whisper-models/ggml-large-v3.bin"

result = subprocess.run(
    ["whisper-cli", "-m", model, "-f", wav, "-t", "8", "-dev", "1", "-np"],
    capture_output=True, text=True
)

text = re.sub(r"\[\d+:\d+:\d+\.\d+ --> \d+:\d+:\d+\.\d+\]\s*", "", result.stdout).strip()

if not text or len(text) < 3:
    sys.exit(2)

print(text)
