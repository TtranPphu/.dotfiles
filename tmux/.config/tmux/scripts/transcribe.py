#!/usr/bin/env python3
import re
import subprocess
import sys

wav = sys.argv[1]
model = "/mnt/shared/whisper-models/ggml-large-v3.bin"

def on_ac():
    try:
        with open("/sys/class/power_supply/AC0/online") as f:
            return f.read().strip() == "1"
    except OSError:
        return False

dev = "1" if on_ac() else "0"

result = subprocess.run(
    ["whisper-cli", "-m", model, "-f", wav, "-t", "8", "-dev", dev, "-np"],
    capture_output=True, text=True
)

text = re.sub(r"\[\d+:\d+:\d+\.\d+ --> \d+:\d+:\d+\.\d+\]\s*", "", result.stdout).strip()

if not text or len(text) < 3:
    sys.exit(2)

print(text)
