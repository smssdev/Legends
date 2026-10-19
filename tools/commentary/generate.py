"""Records the commentator (docs/PLAN.md 2.21) with free open-source voices:
English with Kokoro (George), Arabic with Piper (Kareem).

Output in web/public/commentary/:
  phrases.mp3 + .json          every English phrase in feed/story.ts, in the voice it is said (calm or excited)
  ar/phrases.mp3 + .json       the same for Arabic (the Arabic voice says no names); once lines are
                               recorded by a person (ar-voice/), arabic_voice.py builds this pack instead
  clubs/<slug>.mp3 + .json     each covered club's name and its players' surnames (English)

The browser joins the pieces into lines at play time (web/src/match/voice.ts).
Run it again after changing a line in story.ts or the player data:

  python -m venv .venv && .venv/bin/pip install kokoro-onnx piper-tts soundfile
  curl -LO https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/kokoro-v1.0.int8.onnx
  curl -LO https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/voices-v1.0.bin
  curl -LO https://huggingface.co/rhasspy/piper-voices/resolve/main/ar/ar_JO/kareem/medium/ar_JO-kareem-medium.onnx
  curl -LO https://huggingface.co/rhasspy/piper-voices/resolve/main/ar/ar_JO/kareem/medium/ar_JO-kareem-medium.onnx.json
  .venv/bin/python tools/commentary/generate.py --model kokoro-v1.0.int8.onnx --voices voices-v1.0.bin --arabic ar_JO-kareem-medium.onnx

ffmpeg and node (with the web app's dependencies installed) must be available.
Only what changed is recorded again (a cache sits next to the model).
"""
import argparse, csv, hashlib, json, os, re, subprocess, sys, tempfile, unicodedata
import numpy as np, soundfile as sf
from kokoro_onnx import Kokoro

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
OUT = os.path.join(ROOT, 'web', 'public', 'commentary')
VOICE, SR = 'bm_george', 24000
# The leagues whose players get their names spoken; other clubs fall back to the browser voice.
LEAGUES = ['Premier League', 'LALIGA EA SPORTS', 'Serie A Enilive', 'Bundesliga', "Ligue 1 McDonald's",
           'ROSHN Saudi League', 'Liga Portugal', 'Eredivisie', 'Trendyol Süper Lig']
PARTICLES = {'de', 'da', 'di', 'do', 'dos', 'van', 'von', 'der', 'den', 'ten', 'le', 'la', 'el', 'al', 'ben', 'mac', 'bin'}


# Keep these three in step with web/src/match/voice.ts.
def slug(name):
    s = unicodedata.normalize('NFD', name).encode('ascii', 'ignore').decode().lower()
    return re.sub(r'[^a-z0-9]+', '-', s).strip('-')


def phrase_key(text):
    return re.sub(r'\s+', ' ', re.sub(r'^[\s!.,?…]+', '', text)).strip()


def surname(full):
    w = full.strip().split()
    if len(w) < 2 or re.match(r'^(j(ú|u)nior|jr\.?)$', w[-1], re.I):
        return ' '.join(w)
    i = len(w) - 1
    while i > 0 and w[i - 1].lower() in PARTICLES:
        i -= 1
    return ' '.join(w[i:])


def lines():
    """LINES from web/src/match/feed/story.ts, as JSON (bundled with the web app's esbuild)."""
    web = os.path.join(ROOT, 'web')
    code = subprocess.run(['npx', 'esbuild', 'src/match/feed/story.ts', '--format=esm', '--log-level=error'], cwd=web, capture_output=True, text=True, check=True).stdout
    with tempfile.TemporaryDirectory() as d:
        with open(f'{d}/story.mjs', 'w', encoding='utf-8') as h:
            h.write(code)
        out = subprocess.run(['node', '-e', f"import('{d}/story.mjs').then(m => process.stdout.write(JSON.stringify(m.LINES)))"], capture_output=True, text=True, check=True).stdout
    return json.loads(out)


def phrases(lang):
    """Every phrase to record for a language, as (text, excited): the text between names for English."""
    found = set()
    for moment in lines().values():
        for name, slot in moment.items():
            if name == 'bubble':
                continue
            for text in slot[lang]:
                ex = bool(slot.get('x'))
                if '{n}' in text:
                    found.update((text.replace('{n}', str(n)), ex) for n in range(1, 11))
                    continue
                for frag in re.split(r'\{[^}]*\}', text) if lang == 'en' else [text]:
                    k = phrase_key(frag)
                    if re.search(r'[A-Za-z\u0600-\u06FF]', k):
                        found.add((k, ex))
    return sorted(found)


def squads():
    clubs = {}
    for f in ('ea_fc26_outfield.csv', 'ea_fc26_goalkeepers.csv'):
        with open(os.path.join(ROOT, 'data', 'ea-fc26', f), encoding='utf-8') as h:
            for r in csv.DictReader(h):
                if r['leagueName'] not in LEAGUES:
                    continue
                name = r['commonName'].strip() or f"{r['firstName']} {r['lastName']}".strip()
                clubs.setdefault(r['team'], set()).add(surname(name))
    return clubs


class Recorder:
    def __init__(self, model, voices, cache):
        self.k = Kokoro(model, voices)
        self.cache = cache
        os.makedirs(cache, exist_ok=True)

    def clip(self, text, excited=False):
        key = hashlib.sha1(f'{VOICE}|{excited}|{text}'.encode()).hexdigest()
        path = os.path.join(self.cache, key + '.npy')
        if os.path.exists(path):
            return np.load(path)
        a, _ = self.k.create(text, voice=VOICE, speed=1.12 if excited else 1.0, lang='en-gb')
        a = trim(a.astype('float32'))
        if excited:
            a = lift(a)
        np.save(path, a)
        return a


class ArabicRecorder:
    def __init__(self, model, cache):
        from piper import PiperVoice, SynthesisConfig
        self.v, self.cfg, self.cache = PiperVoice.load(model), SynthesisConfig, cache

    def clip(self, text, excited=False):
        key = hashlib.sha1(f'kareem|{excited}|{text}'.encode()).hexdigest()
        path = os.path.join(self.cache, key + '.npy')
        if os.path.exists(path):
            return np.load(path)
        chunks = [c.audio_float_array for c in self.v.synthesize(text, syn_config=self.cfg(length_scale=0.88 if excited else 1.0))]
        a = np.concatenate(chunks).astype('float32')
        rate = self.v.config.sample_rate
        if rate != SR:
            n = int(len(a) * SR / rate)
            a = np.interp(np.linspace(0, len(a) - 1, n), np.arange(len(a)), a).astype('float32')
        a = trim(a)
        if excited:
            a = lift(a)
        np.save(path, a)
        return a


def trim(a, floor=0.012):
    loud = np.where(np.abs(a) > floor)[0]
    if not len(loud):
        return a
    pad = int(SR * 0.03)
    return a[max(0, loud[0] - pad): loud[-1] + pad]


def lift(a):
    """A commentator lifting his voice: about 7% higher and a little louder."""
    with tempfile.TemporaryDirectory() as d:
        sf.write(f'{d}/in.wav', a, SR)
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', f'{d}/in.wav', '-af', 'asetrate=25700,aresample=24000,atempo=0.98,volume=1.2', f'{d}/out.wav'], check=True)
        b, _ = sf.read(f'{d}/out.wav', dtype='float32')
    return b


def sprite(items, path):
    """One mp3 per pack, and a map of key -> [start, length] in seconds."""
    gap = np.zeros(int(SR * 0.15), 'float32')
    parts, index, t = [], {}, 0.0
    for key, a in items:
        index[key] = [round(t, 3), round(len(a) / SR, 3)]
        parts += [a, gap]
        t += (len(a) + len(gap)) / SR
    audio = np.clip(np.concatenate(parts), -1, 1)
    with tempfile.TemporaryDirectory() as d:
        sf.write(f'{d}/s.wav', audio, SR)
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', f'{d}/s.wav', '-ac', '1', '-c:a', 'libmp3lame', '-b:a', '32k', path + '.mp3'], check=True)
    with open(path + '.json', 'w', encoding='utf-8') as h:
        json.dump(index, h, ensure_ascii=False, separators=(',', ':'))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--model', required=True)
    ap.add_argument('--voices', required=True)
    ap.add_argument('--arabic', help='the Piper Arabic voice (.onnx)')
    ap.add_argument('--only', choices=['phrases', 'arabic', 'clubs'])
    a = ap.parse_args()
    cache = os.path.join(os.path.dirname(os.path.abspath(a.model)), 'commentary-cache')
    rec = Recorder(a.model, a.voices, cache)
    os.makedirs(os.path.join(OUT, 'clubs'), exist_ok=True)
    os.makedirs(os.path.join(OUT, 'ar'), exist_ok=True)
    if a.only in (None, 'phrases'):
        ps = phrases('en')
        print(len(ps), 'English phrases', file=sys.stderr)
        sprite([(('!' if ex else '') + p, rec.clip(p, ex)) for p, ex in ps], os.path.join(OUT, 'phrases'))
    if a.only in (None, 'arabic') and a.arabic and any(f.endswith(('.wav', '.mp3', '.m4a', '.ogg', '.flac', '.aac')) for f in os.listdir(os.path.join(os.path.dirname(__file__), 'ar-voice'))):
        print('Arabic: recorded voice in ar-voice/, use arabic_voice.py build instead', file=sys.stderr)
    elif a.only in (None, 'arabic') and a.arabic:
        ar = ArabicRecorder(a.arabic, cache)
        ps = phrases('ar')
        print(len(ps), 'Arabic phrases', file=sys.stderr)
        sprite([(('!' if ex else '') + p, ar.clip(p, ex)) for p, ex in ps], os.path.join(OUT, 'ar', 'phrases'))
    if a.only in (None, 'clubs'):
        clubs = squads()
        for n, (club, names) in enumerate(sorted(clubs.items()), 1):
            items = [('@club', rec.clip(club))] + [(s, rec.clip(s)) for s in sorted(names)]
            sprite(items, os.path.join(OUT, 'clubs', slug(club)))
            print(f'{n}/{len(clubs)} {club}', file=sys.stderr)


if __name__ == '__main__':
    main()
