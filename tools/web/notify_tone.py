"""GLM's notification tone [Sprint 21 E3.6], made here (no outside sound): a short rising chime, a whistle's
brightness over two bell notes (E6 then B6), the game's own.

    python3 tools/web/notify_tone.py

Writes web/public/sounds/notify.ogg and notify.mp3 (ffmpeg), about 0.7 seconds and a few KB.
"""
import math
import os
import struct
import subprocess
import tempfile
import wave

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
OUT = os.path.join(ROOT, 'web', 'public', 'sounds')
RATE = 44100


def bell(freq: float, start: float, length: float, t: float) -> float:
    """A soft bell: the note and two quieter partials, a quick attack and a long fall."""
    if t < start or t > start + length:
        return 0.0
    x = t - start
    env = min(1.0, x / 0.008) * math.exp(-x * 6.5)
    return env * (math.sin(2 * math.pi * freq * x) + 0.35 * math.sin(2 * math.pi * freq * 2.01 * x) + 0.12 * math.sin(2 * math.pi * freq * 3.02 * x))


def sample(t: float) -> float:
    v = 0.55 * bell(1318.5, 0.0, 0.6, t) + 0.6 * bell(1975.5, 0.11, 0.6, t)
    # The whistle's breath under the second note, very short.
    if 0.11 <= t <= 0.2:
        v += 0.05 * math.sin(2 * math.pi * 2950 * t) * math.sin(math.pi * (t - 0.11) / 0.09)
    return v


def main() -> None:
    os.makedirs(OUT, exist_ok=True)
    n = int(RATE * 0.72)
    frames = [sample(i / RATE) for i in range(n)]
    peak = max(abs(f) for f in frames) or 1.0
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, 'notify.wav')
        with wave.open(wav, 'wb') as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(RATE)
            w.writeframes(b''.join(struct.pack('<h', int(32767 * 0.8 * f / peak)) for f in frames))
        subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav, '-c:a', 'libvorbis', '-q:a', '4', os.path.join(OUT, 'notify.ogg')], check=True)
        subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', wav, '-c:a', 'libmp3lame', '-b:a', '64k', os.path.join(OUT, 'notify.mp3')], check=True)
    for f in ('notify.ogg', 'notify.mp3'):
        print(f, os.path.getsize(os.path.join(OUT, f)), 'bytes')


if __name__ == '__main__':
    main()
