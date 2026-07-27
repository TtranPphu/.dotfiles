#!/home/ttranpphu/.local/share/pipx/venvs/faster-whisper/bin/python3
import sys
from faster_whisper import WhisperModel

model = WhisperModel("large-v3", device="cpu", compute_type="int8")

segments, info = model.transcribe(sys.argv[1], beam_size=5)
text = " ".join(seg.text for seg in segments)

if len(text.strip()) < 3:
    sys.exit(2)

print(text.strip())
