"""The Arabic commentator in a recorded human voice (docs/PLAN.md 2.21).

Every Arabic line of web/src/match/feed/backend/resources/commentary/voice.json has a file name: <moment>-<slot>-<n>.wav
(slot: pre before the moment, key the moment itself, post after it). The list, with each
line's tone and text, is in audio/raw/ar/story/files.txt.

  python3 tools/commentary/arabic_voice.py list     # rewrite files.txt after changing a line in backend/resources/commentary/voice.json
  python3 tools/commentary/arabic_voice.py build    # make web/public/commentary/ar/phrases.mp3 + .json
  python3 tools/commentary/arabic_voice.py voices   # one pack per uploaded voice: web/public/commentary/ar/voice-<n>/phrases.*

build takes each recording in audio/raw/ar/story/ (wav, mp3, m4a, ogg or flac, same name), trims the
silence and levels the loudness. A line not recorded yet keeps its clip from the current
pack, so the voice can be recorded a few lines at a time. Needs node (with the web app's
dependencies installed) and ffmpeg; nothing else.
"""
import json, os, re, shutil, subprocess, sys, tempfile

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
VOICE = os.path.join(ROOT, 'audio', 'raw', 'ar', 'story')
PACK = os.path.join(ROOT, 'web', 'public', 'commentary', 'ar', 'phrases')
LIST = os.path.join(VOICE, 'files.txt')
SR = 24000
EXT = ('.wav', '.mp3', '.m4a', '.ogg', '.flac', '.aac')
# The full voices Hamza uploaded (all 428 clips of catalog.tsv each, MP3 named .wav; ffmpeg reads them as they are).
# Shown in the game only as «صوت 1..5»: the folder names are real commentators' names, and the game names no real person.
VOICES = ['ali', 'chawali_audio_output', 'fahad_audio_output', 'faris_audio_output', 'medhat']

HEADER = """# أصوات المعلق العربي: سجّل كل سطر بالاسم المكتوب أمامه وضعه في هذا المجلد.
# الصيغة: WAV أحادي (mono)، 44.1 أو 48 كيلوهرتز، 16 أو 24 بت. (m4a أو mp3 من الهاتف تعمل أيضاً بنفس الاسم.)
# النبرة: متحمس = صوت مرتفع وسريع كلحظة الهدف. هادئ = تعليق عادي.
# اترك نصف ثانية صمت قبل الكلام وبعده، وحافظ على نفس المسافة من الميكروفون. لا تذكر أسماء لاعبين أو أندية.
# ما لم تسجله بعد يبقى بالصوت الحالي. بعد التسجيل: python3 tools/commentary/arabic_voice.py build
#
# الملف\tالنبرة\tالنص
"""


def phrase_key(text):
    """Keep in step with phraseKey() in web/src/match/voice.ts."""
    return re.sub(r'\s+', ' ', re.sub(r'^[\s!.,?…]+', '', text)).strip()


def lines():
    """Every Arabic line once, in the table's order: (file stem, excited, text)."""
    with open(os.path.join(ROOT, 'backend', 'resources', 'commentary', 'voice.json'), encoding='utf-8') as h:
        data = json.load(h)
    seen, out = set(), []
    for moment, slots in data.items():
        for slot, s in slots.items():
            if slot == 'bubble':
                continue
            for i, text in enumerate(s.get('ar', []), 1):
                key = ('!' if s.get('x') else '') + phrase_key(text)
                if key not in seen:
                    seen.add(key)
                    out.append((f'{moment}-{slot}-{i}', bool(s.get('x')), text))
    return out


def write_list():
    os.makedirs(VOICE, exist_ok=True)
    with open(LIST, 'w', encoding='utf-8') as h:
        h.write(HEADER)
        for stem, ex, text in lines():
            h.write(f"{stem}.wav\t{'متحمس' if ex else 'هادئ'}\t{text}\n")
    print(LIST)


def pcm(cmd):
    """Raw 16-bit mono samples at SR from an ffmpeg input."""
    return subprocess.run(['ffmpeg', '-v', 'error', *cmd, '-ac', '1', '-ar', str(SR), '-f', 's16le', '-'], capture_output=True, check=True).stdout


def recording(path):
    # Trim the silence at both ends, then level every clip to the same loudness.
    trim = 'silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.03'
    return pcm(['-i', path, '-af', f'{trim},areverse,{trim},areverse,loudnorm=I=-16:TP=-1.5:LRA=7'])


def build(voice=VOICE, pack=PACK, fallback=True):
    old = {}
    if fallback and os.path.exists(PACK + '.json'):
        with open(PACK + '.json', encoding='utf-8') as h:
            old = json.load(h)
    with tempfile.TemporaryDirectory() as d:
        src = os.path.join(d, 'old.mp3')
        if fallback and os.path.exists(PACK + '.mp3'):
            shutil.copy(PACK + '.mp3', src)
        gap = b'\0\0' * int(SR * 0.15)
        audio, index, recorded, kept, missing = bytearray(), {}, 0, 0, []
        for stem, ex, text in lines():
            key = ('!' if ex else '') + phrase_key(text)
            mine = next((os.path.join(voice, stem + e) for e in EXT if os.path.exists(os.path.join(voice, stem + e))), None)
            if mine:
                clip, recorded = recording(mine), recorded + 1
            elif key in old and os.path.exists(src):
                start, length = old[key]
                clip, kept = pcm(['-ss', str(start), '-t', str(length), '-i', src]), kept + 1
            else:
                missing.append(stem)
                continue
            index[key] = [round(len(audio) / 2 / SR, 3), round(len(clip) / 2 / SR, 3)]
            audio += clip + gap
        raw = os.path.join(d, 'all.raw')
        with open(raw, 'wb') as h:
            h.write(audio)
        os.makedirs(os.path.dirname(pack), exist_ok=True)
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 's16le', '-ar', str(SR), '-ac', '1', '-i', raw, '-c:a', 'libmp3lame', '-b:a', '64k', pack + '.mp3'], check=True)
    with open(pack + '.json', 'w', encoding='utf-8') as h:
        json.dump(index, h, ensure_ascii=False, separators=(',', ':'))
    print(f'{os.path.relpath(pack, ROOT)}: {recorded} recorded, {kept} kept from the current voice' + (f", missing: {' '.join(missing)}" if missing else ''))


def voices():
    for n, folder in enumerate(VOICES, 1):
        build(os.path.join(ROOT, 'audio', 'raw', folder), os.path.join(ROOT, 'web', 'public', 'commentary', 'ar', f'voice-{n}', 'phrases'), False)


if __name__ == '__main__':
    {'list': write_list, 'build': build, 'voices': voices}.get(sys.argv[1] if len(sys.argv) > 1 else '', lambda: sys.exit(__doc__))()
