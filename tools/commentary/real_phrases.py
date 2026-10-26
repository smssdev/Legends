"""A commentator's real phrases [X37]: cut from the recordings the team put in audio/raw/patches/<commentator>/, as
the cuts table there says, into a small pack beside his voice (web/public/commentary/ar/voice-<n>/real.mp3 + .json).

    python3 tools/commentary/real_phrases.py            # every commentator with a cuts.csv
    python3 tools/commentary/real_phrases.py chawali    # one

cuts.csv: file, start and end (seconds), kind (goal, goal_big, magic, slow: the moments the match plays them at, in
web/src/match/feed/MatchFeed.vue), and the text said (for the reviewer). Hamza adjusts a start or an end and runs it
again. Each phrase gets a few milliseconds of fade so it never clicks, and the loudness of the voice packs.
The game (web/src/match/voice.ts) picks one of a kind's phrases at random each time, so they do not repeat.
"""
import csv
import json
import os
import subprocess
import sys
import tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
PATCHES = os.path.join(ROOT, 'audio', 'raw', 'patches')
# The folder of each commentator's recordings, and his voice in the game (tools/commentary/arabic_voice.py VOICES).
VOICE_OF = {'ali': 'voice-1', 'chawali': 'voice-2', 'fahad': 'voice-3', 'faris': 'voice-4', 'medhat': 'voice-5', 'hafid': 'voice-6'}
SR = 24000
GAP = 0.12


def build(name):
    folder = os.path.join(PATCHES, name)
    with open(os.path.join(folder, 'cuts.csv'), encoding='utf-8-sig') as f:
        cuts = list(csv.DictReader(f))
    tmp = tempfile.mkdtemp()
    parts, kinds, at = [], {}, 0.0
    for i, c in enumerate(cuts):
        start, end = float(c['start']), float(c['end'])
        length = round(end - start, 3)
        out = os.path.join(tmp, f'{i:03}.wav')
        fade = min(0.04, length / 4)
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', str(start), '-t', str(length), '-i', os.path.join(folder, c['file']),
                        '-af', f'afade=t=in:d={fade},afade=t=out:st={length - fade}:d={fade},loudnorm=I=-16:TP=-1.5:LRA=11',
                        '-ac', '1', '-ar', str(SR), out], check=True)
        # The real length after the filters, and a short silence after it in the strip.
        got = float(subprocess.run(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', out],
                                   capture_output=True, text=True, check=True).stdout.strip())
        parts.append(out)
        kinds.setdefault(c['kind'], []).append([round(at, 3), round(got, 3)])
        at += got + GAP
    silence = os.path.join(tmp, 'gap.wav')
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'lavfi', '-i', f'anullsrc=r={SR}:cl=mono', '-t', str(GAP), silence], check=True)
    listing = os.path.join(tmp, 'list.txt')
    with open(listing, 'w') as f:
        for p in parts:
            f.write(f"file '{p}'\nfile '{silence}'\n")
    pack = os.path.join(ROOT, 'web', 'public', 'commentary', 'ar', VOICE_OF[name], 'real')
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', listing, '-ac', '1', '-ar', str(SR),
                    '-c:a', 'libmp3lame', '-b:a', '64k', pack + '.mp3'], check=True)
    with open(pack + '.json', 'w', encoding='utf-8') as f:
        json.dump(kinds, f, ensure_ascii=False)
    print(f'{name}: {len(cuts)} phrases ({", ".join(f"{k} {len(v)}" for k, v in kinds.items())}) -> {pack}.mp3')


def main():
    names = sys.argv[1:] or sorted(n for n in os.listdir(PATCHES) if os.path.exists(os.path.join(PATCHES, n, 'cuts.csv')))
    for n in names:
        build(n)


if __name__ == '__main__':
    main()
