"""The app's own sounds, synthesized from nothing (no recording, no licence): run from mobile/ with
python3 tool/sounds/make_sounds.py — it writes assets/sounds/*.ogg (needs numpy and ffmpeg).

[2026-11-06] The Legend sound: a stadium at night. The intro switches the floodlights on (two heavy clunks and their
hum), the referee whistles, the crowd rises and a gold chord rings; the taps are a soft stud on turf, success a
two-bell chime, coins a bright double ding, an error a low muted knock, and the whistle opens a match.
"""
import os
import subprocess
import tempfile
import wave

import numpy as np

RATE = 44100
OUT = os.path.join(os.path.dirname(__file__), '..', '..', 'assets', 'sounds')
rng = np.random.default_rng(7)


def t(sec):
    return np.arange(int(sec * RATE)) / RATE


def env(n, attack=0.004, release=0.05):
    """A linear attack and an exponential fall over n samples."""
    a = max(1, int(attack * RATE))
    e = np.exp(-np.arange(n) / max(1.0, release * RATE))
    e[:a] *= np.linspace(0, 1, a)
    return e


def lowpass(x, cutoff):
    """A gentle one-pole low-pass, run twice."""
    k = np.exp(-2 * np.pi * cutoff / RATE)
    for _ in range(2):
        y = np.empty_like(x)
        acc = 0.0
        for i, v in enumerate(x):
            acc = (1 - k) * v + k * acc
            y[i] = acc
        x = y
    return x


def bandnoise(sec, lo, hi):
    n = rng.standard_normal(int(sec * RATE))
    return lowpass(n, hi) - lowpass(n, lo)


def place(track, sound, at):
    i = int(at * RATE)
    end = min(len(track), i + len(sound))
    track[i:end] += sound[: end - i]


def bell(freq, sec, partials=((1, 1.0), (2.76, .45), (5.4, .2), (8.9, .08)), release=None):
    x = t(sec)
    out = sum(a * np.sin(2 * np.pi * freq * r * x) * np.exp(-x * (3 + r * 1.5) / (release or sec)) for r, a in partials)
    return out * env(len(x), 0.002, sec)


def clunk():
    """A floodlight bank switching on: a heavy thump, a metal click, then the hum of the lamps."""
    x = t(0.9)
    thump = np.sin(2 * np.pi * (55 + 40 * np.exp(-x * 30)) * x) * np.exp(-x * 9)
    click = bandnoise(0.9, 1500, 6000) * np.exp(-x * 160) * 0.6
    hum = (np.sin(2 * np.pi * 100 * x) + .35 * np.sin(2 * np.pi * 200 * x) + .15 * np.sin(2 * np.pi * 300 * x)) * (1 - np.exp(-x * 12)) * np.exp(-x * 2.2) * 0.10
    return thump * 0.9 + click + hum


def whistle(sec=0.42, pitch=2650):
    """A referee's pea whistle: a bright tone trilled by the pea, breath noise around it."""
    x = t(sec)
    trill = 1 + 0.035 * np.sin(2 * np.pi * 34 * x)
    tone = np.sin(2 * np.pi * pitch * np.cumsum(trill) / RATE) + 0.25 * np.sin(2 * np.pi * 2 * pitch * np.cumsum(trill) / RATE)
    am = 0.75 + 0.25 * np.sin(2 * np.pi * 34 * x)
    breath = bandnoise(sec, 1800, 5000) * 0.18
    shape = np.minimum(1, x / 0.02) * np.minimum(1, (sec - x) / 0.06)
    return (tone * am + breath) * shape * 0.45


def crowd(sec):
    """A stadium crowd rising: low murmur and a brighter roar, swelling then settling."""
    x = t(sec)
    low = bandnoise(sec, 150, 900)
    high = bandnoise(sec, 600, 2600) * 0.6
    swell = np.clip(x / (sec * 0.45), 0, 1) ** 1.6 * np.clip((sec - x) / (sec * 0.4), 0, 1)
    return (low + high) * swell * 1.4


def norm(x, peak=0.89):
    m = np.max(np.abs(x)) or 1
    return x / m * peak


def save(name, x):
    os.makedirs(OUT, exist_ok=True)
    pcm = (norm(x) * 32767).astype('<i2')
    with tempfile.NamedTemporaryFile(suffix='.wav', delete=False) as f:
        path = f.name
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(pcm.tobytes())
    subprocess.run(['ffmpeg', '-y', '-loglevel', 'error', '-i', path, '-c:a', 'libvorbis', '-q:a', '3', os.path.join(OUT, f'{name}.ogg')], check=True)
    os.unlink(path)
    print(name, f'{len(x) / RATE:.2f}s')


def intro():
    track = np.zeros(int(3.0 * RATE))
    place(track, clunk(), 0.12)
    place(track, clunk() * 0.85, 0.48)
    place(track, crowd(2.2) * 0.55, 0.75)
    place(track, whistle(0.38), 0.95)
    # The gold chord as the crest lands: a rising arpeggio of bells.
    for i, f in enumerate([523.25, 659.25, 783.99, 1046.5]):
        place(track, bell(f, 1.4) * (0.32 - i * 0.03), 1.30 + i * 0.07)
    fade = np.clip((len(track) / RATE - t(len(track) / RATE)) / 0.5, 0, 1)
    return track * fade


def tap():
    x = t(0.07)
    knock = np.sin(2 * np.pi * (900 + 600 * np.exp(-x * 120)) * x) * np.exp(-x * 90)
    stud = bandnoise(0.07, 2000, 7000) * np.exp(-x * 220) * 0.5
    return (knock + stud) * 0.5


def confirm():
    track = np.zeros(int(0.7 * RATE))
    place(track, bell(1318.5, 0.55), 0)
    place(track, bell(1975.5, 0.6) * 0.8, 0.09)
    return track


def coin():
    track = np.zeros(int(0.6 * RATE))
    ding = lambda: bell(2093, 0.45, ((1, 1.0), (1.34, .6), (2.1, .3), (3.0, .12)))
    place(track, ding() * 0.8, 0)
    place(track, ding(), 0.075)
    return track


def error():
    track = np.zeros(int(0.4 * RATE))
    for i, f in enumerate([220, 165]):
        x = t(0.16)
        knock = (np.sin(2 * np.pi * f * x) + .3 * np.sin(2 * np.pi * f * 2.01 * x)) * env(len(x), 0.004, 0.05)
        place(track, knock, i * 0.12)
    return track * 0.8


def kick():
    """[Sprint 44 C2] A boot on the ball: a dull thump and a leather slap."""
    x = t(0.18)
    thump = np.sin(2 * np.pi * (150 * np.exp(-x * 25) + 60) * x) * np.exp(-x * 35)
    slap = bandnoise(0.18, 800, 4000) * np.exp(-x * 120) * 0.7
    return thump + slap


def roar():
    """The crowd erupting at a goal: a sudden wall of voices, held, then easing."""
    sec = 3.2
    x = t(sec)
    low = bandnoise(sec, 120, 800)
    mid = bandnoise(sec, 500, 2400) * 0.8
    air = bandnoise(sec, 2000, 6000) * 0.25
    shape = np.minimum(1, x / 0.12) * np.clip((sec - x) / 1.6, 0, 1) ** 0.8
    wobble = 1 + 0.12 * np.sin(2 * np.pi * 3.3 * x)
    return (low + mid + air) * shape * wobble


def ooh():
    """The crowd's groan at a chance gone: a rising then falling vowel of thousands."""
    sec = 1.6
    x = t(sec)
    voices = bandnoise(sec, 200, 1200)
    # A formant sweeping like «ooo-oh».
    f = 380 + 160 * np.sin(np.pi * x / sec)
    vowel = np.sin(2 * np.pi * np.cumsum(f) / RATE) * 0.35
    shape = np.sin(np.pi * np.clip(x / sec, 0, 1)) ** 1.2
    return (voices + vowel * np.abs(voices).mean() * 6) * shape


if __name__ == '__main__':
    save('intro', intro())
    save('tap', tap())
    save('confirm', confirm())
    save('coin', coin())
    save('error', error())
    save('whistle', whistle(0.55))
    # [Sprint 44 C2] Last, so the sounds above keep their noise (the generator's draws stay in order).
    save('kick', kick())
    save('roar', roar())
    save('ooh', ooh())
