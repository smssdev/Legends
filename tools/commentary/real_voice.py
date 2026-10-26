"""His voice from one recorded match [X41]: audio/raw/patches/shawalli/.

    python3 tools/commentary/real_voice.py transcribe   # the phrases and their words (Whisper, slow: an hour or two)
    python3 tools/commentary/real_voice.py classify     # writes the cuts table: audio/raw/patches/shawalli/cuts.csv
    python3 tools/commentary/real_voice.py reference    # his voice, calm and excited, for cloning: .../reference/*.wav

The phrases of another match never fit ours (the owner, 2026-10-26: «التعليق في وادي والمباراة في وادي آخر»), so
«الشوالي حقيقي» (voice-7) is gone: «عصام الشوالي» (voice-2) says this match's own lines, and this recording is the
reference to clone his voice again from, calm and screaming.

transcribe: a voice detector cuts the recording at the commentator's own pauses into phrases of up to 7 seconds,
and Whisper (the base model, on this machine; nothing is sent anywhere) writes each one's words, beside its loudness.
classify: each phrase gets the moment it fits (the kinds voice.ts plays: goal, goal_post, attack, save, miss, post,
foul, card, corner, offside, penalty, freekick, sub, injury, kickoff, half, full, calm) from its words and its
loudness (measured against the match from MATCH_FROM on, not the studio before it); the goal is his scream at the loudest. A phrase that names someone is left out: a word the match repeats
that the game's own commentary never uses is almost surely a player's or a club's name. The table keeps every
phrase with its kind and keep=1/0, so Hamza listens and corrects (a kind, a start or an end, keep) and builds again.
"""
import collections
import csv
import json
import os
import re
import subprocess
import sys
import wave

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
FOLDER = os.path.join(ROOT, 'audio', 'raw', 'patches', 'shawalli')
SOURCE = 'shawalli.mp3'
PHRASES = os.path.join(FOLDER, 'phrases.jsonl')
MATCH_FROM = 600  # the studio before kickoff (the clubs' history, the line-ups) is not match commentary

# Words for each kind, loose enough for Whisper's spelling of a shouting commentator.
KINDS = [
    ('card', r'بطاق|إنذار|انذار|صفرا|حمرا|طرد'),
    ('penalty', r'جزاء|بلانت|بنالت'),
    ('offside', r'تسل'),
    ('corner', r'ركني|زاوي|كورنر'),
    ('freekick', r'ضربة حر|ركلة حر|خطأ مباشر'),
    ('post', r'القائم|العارض|القايم'),
    ('save', r'الحارس|يتصد|تصد|أنقذ|انقذ|ينقذ|إنقاذ|انقاذ|يمسك|أمسك|كفوف'),
    ('miss', r'خسار|ضاع|ضيع|فوق|بجانب|خارج|كاد|كان هدف|قريب'),
    ('injury', r'إصاب|اصاب|مصاب|يتألم|الطبي'),
    ('sub', r'تغيير|تبديل|يخرج|يدخل|التغيير'),
    ('foul', r'خطأ|خطا|مخالف|عرقل|يسقط|سقط|الحكم|عنيف|تدخل'),
    ('kickoff', r'بداية|انطلاق|ضربة البداية|صافرة البداية|مساء الخير|أهلا|اهلا|مرحبا'),
    ('half', r'نهاية الشوط|الشوط الأول|الشوط الاول|الشوط الثاني|استراح|بين الشوطين'),
    ('full', r'نهاية المباراة|انتهت|صافرة النهاية|تتويج|بطل|الكأس|الكاس'),
    ('attack', r'تسديد|يسدد|سدد|انطلاق|ينطلق|هجم|مرتد|عرضي|يمرر|تمرير|طويل|المنطقة|منطقة|رأس|راس|يراوغ|مراوغ|ينفرد|انفراد'),
]
GOAL = r'غو+ل|قو+ل|جو+ل|هد+ف|الهدف'
# This match's own names (the two clubs, the coaches, the best known players), in Whisper's spellings of them:
# a phrase with one is left out even when the name is not repeated enough to be caught by the count below.
NAMES = (r'برش|بارش|بارث|برث|برس|بارس|كتالون|ريال|مدريد|ملكي|ميسي|مسي|ماسي|رونالد|مورين|غوارديول|كورديول|جوارديول|'
         r'تشافي|اتشابي|شافي|انييست|إنييست|بويول|بيول|بيكي|كاسياس|كسيس|راموس|بيب|بنزيم|زيما|اوزيل|وزيل|دي ماريا|'
         r'بيدرو|بوسكيتس|البوسكت|فيا|داني|الفيس|ابيدال|كلاسيك|كلاسك|نوكام|نو كامب|كامبنو|كامب')
# Common words that repeat in any talk and are never a name.
STOP = set('هذا هذه هذي هاذا ذلك تلك هناك هنا الذي التي الذين على عن من إلى الى مع كان كانت يكون ليس لكن لقد كل بعد قبل '
           'عند حتى أما اما نحن انت أنت أنا انا هو هي هم يعني شيء شي كيف لماذا ماذا متى أين اين مرة كمان أيضا ايضا جدا '
           'كبير كبيرة صغير اليوم الآن الان ثم إنه انه أنه إنها انها كرة كورة قورة لاعب يلعب تلعب فريق مباراة'.split())
PRAISE = r'رائع|سلام|عالمي|خراف|أروع|اروع|جميل|ساحر|السحر|فنان|عظيم|لا يصدق|يا الله|ما شاء'


def transcribe():
    import numpy as np
    from faster_whisper import WhisperModel
    from faster_whisper.vad import VadOptions, get_speech_timestamps
    tmp = os.path.join(FOLDER, '.tmp.wav')
    subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', os.path.join(FOLDER, SOURCE), '-ac', '1', '-ar', '16000', tmp], check=True)
    w = wave.open(tmp)
    a = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float32) / 32768
    os.remove(tmp)
    speech = get_speech_timestamps(a, VadOptions(min_silence_duration_ms=320, speech_pad_ms=120, min_speech_duration_ms=500, max_speech_duration_s=7))
    model = WhisperModel('base', device='cpu', compute_type='int8')
    with open(PHRASES, 'w', encoding='utf-8') as f:
        for c in speech:
            seg = a[c['start']:c['end']]
            if len(seg) < 16000 * 0.6:
                continue
            out = list(model.transcribe(seg, language='ar', beam_size=1, without_timestamps=True, condition_on_previous_text=False)[0])
            f.write(json.dumps({'start': round(c['start'] / 16000, 2), 'end': round(c['end'] / 16000, 2),
                                'text': ' '.join(x.text.strip() for x in out).strip(), 'lp': round(min([x.avg_logprob for x in out] or [-9]), 2),
                                'rms': round(float(np.sqrt(np.mean(seg ** 2))), 4), 'peak': round(float(np.percentile(np.abs(seg), 99)), 3)},
                               ensure_ascii=False) + '\n')


def words(text):
    return re.findall(r'[ء-ي]{3,}', re.sub(r'[ً-ْ]', '', text or ''))


def classify():
    with open(PHRASES, encoding='utf-8') as f:
        phrases = [json.loads(line) for line in f if line.strip()]
    # The game's own commentary words: the vocabulary that is not a name.
    with open(os.path.join(ROOT, 'backend', 'resources', 'commentary', 'voice.json'), encoding='utf-8') as f:
        table = json.load(f)
    known = {w for m in table.values() for s in m.values() if isinstance(s, dict) for t in s.get('ar', []) for w in words(t)}
    count = collections.Counter(w for p in phrases for w in set(words(p['text'])))
    common = {w for w, n in count.items() if n >= 3 and w not in known and w not in STOP and not w.startswith(('ال', 'و', 'ف', 'ب', 'ل'))}
    # Loudness against the match itself: the studio is recorded louder than the stadium.
    loud = sorted(p['peak'] for p in phrases if p['start'] >= MATCH_FROM) or [1]
    scream, excited = loud[int(len(loud) * 0.93)], loud[int(len(loud) * 0.8)]
    # His loudest of all (the top 2%), held for a second and a half: the goal, whatever Whisper heard in it.
    roar = loud[int(len(loud) * 0.98)]
    last_goal = -999
    rows = []
    for p in phrases:
        text, length = p['text'], p['end'] - p['start']
        kind = None
        if p['start'] >= MATCH_FROM and ((re.search(GOAL, text) and p['peak'] >= scream * 0.9) or (p['peak'] >= roar and length >= 1.5)):
            kind, last_goal = 'goal', p['start']
        elif p['start'] - last_goal < 30 and (re.search(PRAISE, text) or p['peak'] >= excited):
            kind = 'goal_post'
        else:
            for k, pattern in KINDS:
                if re.search(pattern, text):
                    kind = k
                    break
        if kind is None:
            # No word for it, but his voice rises: the ball is going forward.
            kind = 'attack' if p['peak'] >= excited else 'calm'
        studio = p['start'] < MATCH_FROM and kind != 'kickoff'
        # A name, a number (a score, a minute, a year) or a minute in words would be wrong in another match.
        named = any(w in common for w in words(text)) or bool(re.search(r'[0-9٠-٩]|دقيق|' + NAMES, text))
        clear = p['lp'] > -1.1 and len(text) >= 4
        keep = int(not studio and not named and clear and 0.8 <= length <= 7 and (kind != 'calm' or length <= 5))
        rows.append({'file': SOURCE, 'start': p['start'], 'end': p['end'], 'kind': kind, 'keep': keep, 'clarity': p['lp'], 'text': text})
    with open(os.path.join(FOLDER, 'cuts.csv'), 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=['file', 'start', 'end', 'kind', 'keep', 'clarity', 'text'])
        w.writeheader()
        w.writerows(rows)
    kept = collections.Counter(r['kind'] for r in rows if r['keep'])
    print(f'{len(rows)} phrases, {sum(kept.values())} kept:', dict(sorted(kept.items(), key=lambda x: -x[1])))
    print('names left out (the most frequent):', ', '.join(sorted(common, key=lambda w: -count[w])[:25]))


def reference():
    """His voice for cloning: the clearest calm phrases and his loudest screams of the match, joined in one wav
    per tone (calm.wav, excited.wav: a cloning tool takes 6 to 30 seconds of one voice, or the whole for training)."""
    with open(PHRASES, encoding='utf-8') as f:
        phrases = [p for p in (json.loads(line) for line in f if line.strip()) if p['start'] >= MATCH_FROM]
    loud = sorted(p['peak'] for p in phrases)
    calm = sorted((p for p in phrases if p['peak'] < loud[int(len(loud) * 0.6)] and p['end'] - p['start'] >= 4.5), key=lambda p: -p['lp'])[:10]
    excited = sorted((p for p in phrases if p['peak'] >= loud[int(len(loud) * 0.9)] and p['end'] - p['start'] >= 2.5), key=lambda p: -p['lp'])[:8]
    out = os.path.join(FOLDER, 'reference')
    os.makedirs(out, exist_ok=True)
    for tone, chosen in (('calm', calm), ('excited', excited)):
        files = []
        for i, p in enumerate(sorted(chosen, key=lambda p: p['start']), 1):
            files.append(os.path.join(out, f'{tone}-{i}.wav'))
            subprocess.run(['ffmpeg', '-v', 'error', '-y', '-ss', str(p['start']), '-to', str(p['end']), '-i', os.path.join(FOLDER, SOURCE),
                            '-af', 'loudnorm=I=-16:TP=-1.5:LRA=11', '-ac', '1', '-ar', '24000', files[-1]], check=True)
        listing = os.path.join(out, 'list.txt')
        with open(listing, 'w') as f:
            f.writelines(f"file '{x}'\n" for x in files)
        subprocess.run(['ffmpeg', '-v', 'error', '-y', '-f', 'concat', '-safe', '0', '-i', listing, os.path.join(out, f'{tone}.wav')], check=True)
        os.remove(listing)
        for x in files:
            os.remove(x)
    print(f'{len(calm)} calm and {len(excited)} excited -> {out}')


if __name__ == '__main__':
    {'transcribe': transcribe, 'classify': classify, 'reference': reference}[sys.argv[1] if len(sys.argv) > 1 else 'classify']()
