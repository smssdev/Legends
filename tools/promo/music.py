# The promo video's sound [2026-11-15]: an original track made here (no sample, no licence): 40 s at 120 beats a
# minute in A minor, cut to the video's scenes (stage.html): a pad and a riser under the logo, the drop when the team
# comes (4.2 s), whooshes on every change of scene, the crowd's roar and a horn on the two goals, a last hit and a fade.
# → tools/promo/out/music.wav (48 kHz, stereo). python3 tools/promo/music.py
import wave
from pathlib import Path
import numpy as np

SR = 48000
DUR = 40.0
N = int(SR * DUR)
t = np.arange(N) / SR
rng = np.random.default_rng(7)
mix = np.zeros((N, 2))
BEAT = 0.5  # 120 bpm

def add(sig, at, gain=1.0, pan=0.0):
    i = int(at * SR)
    if i >= N:
        return
    sig = sig[: N - i]
    l, r = np.sqrt(0.5 * (1 - pan)), np.sqrt(0.5 * (1 + pan))
    mix[i:i + len(sig), 0] += sig * gain * l
    mix[i:i + len(sig), 1] += sig * gain * r

def env(n, a=0.005, d=0.2):
    x = np.arange(n) / SR
    return np.minimum(1, x / a) * np.exp(-x / d)

def kick():
    n = int(0.45 * SR); x = np.arange(n) / SR
    f = 45 + 110 * np.exp(-x * 30)
    return np.sin(2 * np.pi * np.cumsum(f) / SR) * env(n, 0.002, 0.16)

def snare():
    n = int(0.3 * SR); x = np.arange(n) / SR
    noise = rng.standard_normal(n)
    noise = noise - np.convolve(noise, np.ones(8) / 8, 'same')  # brighter
    return (0.6 * noise * env(n, 0.001, 0.09) + 0.4 * np.sin(2 * np.pi * 190 * x) * env(n, 0.001, 0.06))

def hat(open_=False):
    n = int((0.25 if open_ else 0.06) * SR)
    noise = rng.standard_normal(n)
    noise = noise - np.convolve(noise, np.ones(4) / 4, 'same')
    return noise * env(n, 0.001, 0.12 if open_ else 0.02)

def note(freq, dur, kind='saw', a=0.01, d=None):
    n = int(dur * SR); x = np.arange(n) / SR
    if kind == 'saw':
        sig = sum(np.sin(2 * np.pi * freq * k * x) / k for k in range(1, 9))
    elif kind == 'sq':
        sig = sum(np.sin(2 * np.pi * freq * k * x) / k for k in range(1, 12, 2))
    else:
        sig = np.sin(2 * np.pi * freq * x)
    e = np.minimum(1, x / a) * (np.exp(-x / d) if d else np.minimum(1, (dur - x) / 0.05))
    return sig * e

def lowpass(sig, k=12):
    return np.convolve(sig, np.ones(k) / k, 'same')

def hz(n):  # semitones from A4
    return 440 * 2 ** (n / 12)

# Chords (A minor): Am, F, C, G, two beats each bar (2 s a chord).
CHORDS = [[-12, -9, -5], [-16, -12, -9], [-21, -17, -14], [-14, -10, -7]]
BASS = [-36, -40, -33, -38]

# Pad: the whole track, softer under the logo and the end.
for b in range(int(DUR / 2)):
    at = b * 2.0
    for n in CHORDS[b % 4]:
        sig = lowpass(note(hz(n), 2.05, 'saw', a=0.3), 24)
        add(sig, at, 0.045 if at < 4 else 0.035, pan=(n % 3 - 1) * 0.4)

# The riser under the logo (0 to 4.2 s): filtered noise and a rising tone.
n = int(4.2 * SR); x = np.arange(n) / SR
riser = lowpass(rng.standard_normal(n), 6) * (x / 4.2) ** 2 * 0.5 + np.sin(2 * np.pi * np.cumsum(200 + 600 * (x / 4.2) ** 2) / SR) * (x / 4.2) ** 3 * 0.15
add(riser, 0.0, 0.5)

# The beat from the drop (4.2 s) to 34.5 s; the match scene (15 to 25 s) a little busier.
DROP, END = 4.2, 34.6
b = 0
at = DROP
while at < END:
    beat_in_bar = b % 4
    add(kick(), at, 0.9)
    if beat_in_bar in (1, 3):
        add(snare(), at, 0.35, pan=0.1)
    add(hat(), at + BEAT / 2, 0.12, pan=-0.3)
    if 15 <= at < 25:
        add(hat(), at + BEAT / 4, 0.07, pan=0.3)
        add(hat(), at + 3 * BEAT / 4, 0.07, pan=0.3)
    if beat_in_bar == 3:
        add(hat(True), at + BEAT / 2, 0.08, pan=-0.2)
    # Bass: eighth notes on the chord's root.
    chord = int(at / 2) % 4
    for e in (0, BEAT / 2):
        add(lowpass(note(hz(BASS[chord]), BEAT / 2 - 0.02, 'sq', a=0.005, d=0.18), 8), at + e, 0.22)
    b += 1
    at = DROP + b * BEAT

# A lead line: the hook, twice (4.2 to 10, and 25 to 30).
HOOK = [0, 3, 7, 5, 3, 0, -2, 0]
for start in (6.2, 26.2):
    for i, n in enumerate(HOOK):
        add(lowpass(note(hz(n), 0.42, 'sq', a=0.01, d=0.35), 3), start + i * BEAT, 0.07, pan=0.25)

# Whooshes on every change of scene.
def whoosh(dur=0.7):
    n = int(dur * SR); x = np.arange(n) / SR
    w = lowpass(rng.standard_normal(n), 10) * np.sin(np.pi * x / dur) ** 2
    return w
for at in (4.0, 9.8, 14.8, 24.8, 29.8, 34.8):
    add(whoosh(), at - 0.2, 0.35, pan=-0.5)
    add(whoosh(), at - 0.15, 0.25, pan=0.5)

# The crowd: a low murmur through the match, a roar on each goal and a horn.
def crowd(dur, swell):
    n = int(dur * SR); x = np.arange(n) / SR
    c = lowpass(rng.standard_normal(n), 30) + 0.4 * lowpass(rng.standard_normal(n), 5)
    shape = np.minimum(1, x / 0.15) * (np.exp(-(x / swell)) if swell else 1)
    return c * shape
add(crowd(10.0, None) * 0.25, 15.0, 0.25)
for goal in (18.45, 20.55):
    add(crowd(2.6, 1.3), goal, 0.9, pan=-0.2)
    add(crowd(2.6, 1.3), goal + 0.03, 0.9, pan=0.2)
    horn = sum(note(f, 0.9, 'saw', a=0.02, d=0.6) for f in (233, 294, 349)) * 0.3
    add(lowpass(horn, 6), goal + 0.1, 0.35)
add(crowd(1.8, 0.8), 22.8, 0.5)  # the save: an «ooh»

# The last hit (35 s): a big chord and a cymbal, then the fade.
for n in (-24, -12, -9, -5, 0):
    add(lowpass(note(hz(n), 4.5, 'saw', a=0.01, d=1.6), 6), 35.0, 0.09)
cym = rng.standard_normal(int(3 * SR)); cym = (cym - np.convolve(cym, np.ones(3) / 3, 'same')) * env(len(cym), 0.002, 0.9)
add(cym, 35.0, 0.18)
add(kick(), 35.0, 1.0)

# Out: a fade in the last two seconds, a soft limiter, 16-bit.
fade = np.ones(N); f0 = int(38 * SR); fade[f0:] = np.linspace(1, 0, N - f0)
mix *= fade[:, None]
mix = np.tanh(mix * 1.4) / np.tanh(1.4)
mix /= max(1e-9, np.abs(mix).max()) / 0.9
out = Path(__file__).resolve().parent / 'out' / 'music.wav'
with wave.open(str(out), 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(SR)
    w.writeframes((mix * 32767).astype('<i2').tobytes())
print('music:', out, f'{DUR:.0f} s')
