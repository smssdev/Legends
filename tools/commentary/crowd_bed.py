"""The real crowd of a stadium [X41], from the pauses of a commentator's match recording: the seconds where he says
nothing are the stands as they were. Collected into a loop that the match sound plays instead of synthesized noise.

    python3 tools/commentary/crowd_bed.py audio/raw/shawalli.mp3     # writes web/public/sfx/crowd-bed.mp3

Takes the pauses of 2 to 15 seconds inside the match (not the studio before, the break or after), keeps only those
where a voice detector finds no speech at all (a strict threshold: a word of the commentator would be heard on every
loop), and chains them with short crossfades into one loop at a low, even loudness.
Needs ffmpeg and faster-whisper (its voice detector); nothing is sent anywhere.
"""
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np
from faster_whisper.vad import VadOptions, get_speech_timestamps

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
OUT = os.path.join(ROOT, 'web', 'public', 'sfx', 'crowd-bed.mp3')


def mono16k(src, dst, start=None, length=None):
    cmd = ['ffmpeg', '-v', 'error', '-y']
    if start is not None:
        cmd += ['-ss', str(start), '-t', str(length)]
    subprocess.run(cmd + ['-i', src, '-ac', '1', '-ar', '16000', dst], check=True)
    w = wave.open(dst)
    return np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float32) / 32768


def main():
    src = sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, 'audio', 'raw', 'shawalli.mp3')
    tmp = tempfile.mkdtemp()
    audio = mono16k(src, os.path.join(tmp, 'all.wav'))
    speech = get_speech_timestamps(audio, VadOptions(min_silence_duration_ms=320, speech_pad_ms=120, min_speech_duration_ms=500))
    gaps, prev = [], 0
    for c in speech:
        if c['start'] - prev >= 16000 * 1.6:
            gaps.append(((prev + 3200) / 16000, (c['start'] - 3200) / 16000))
        prev = c['end']
    total = len(audio) / 16000
    picked = [(s, e) for s, e in gaps if 600 < s < total - 400 and 2 <= e - s <= 15][:30]
    clean = []
    for i, (s, e) in enumerate(picked):
        part = mono16k(src, os.path.join(tmp, f'{i}.m.wav'), s, e - s)
        if not get_speech_timestamps(part, VadOptions(threshold=0.35, min_speech_duration_ms=200)):
            out = os.path.join(tmp, f'{i}.wav')
            subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', str(s), '-t', str(e - s), '-i', src, '-ac', '2', '-ar', '44100', out], check=True)
            clean.append(out)
    if len(clean) < 2:
        sys.exit('Too few pauses without speech for a loop.')
    cmd, chain, last = ['ffmpeg', '-v', 'error', '-y'], '', '[0]'
    for p in clean:
        cmd += ['-i', p]
    for i in range(1, len(clean)):
        chain += f'{last}[{i}]acrossfade=d=0.6:c1=tri:c2=tri[a{i}];'
        last = f'[a{i}]'
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    subprocess.run(cmd + ['-filter_complex', chain + f'{last}loudnorm=I=-24:TP=-3[out]', '-map', '[out]',
                          '-c:a', 'libmp3lame', '-b:a', '96k', OUT], check=True)
    print(f'{len(clean)} pauses without speech -> {OUT}')


if __name__ == '__main__':
    main()
