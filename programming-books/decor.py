"""The colour edition's decorations: Bit the robot guide, box icons, and the chapter opener.

Chapter sources stay plain HTML; decorate() turns them into the designed page:
  <p class="chapter-kicker"> + <h1>                -> the gradient opener with the chapter number and Bit
  <h2>8.1 Title</h2>                                -> numbered section heading
  <aside class="box tip|warn|fact|try|quiz|rule">   -> coloured box with its icon
  <aside class="bit" data-mood="happy|think|wow">   -> Bit talking in a speech bubble
  <span class="level">                              -> coloured difficulty pill
"""
import re

NAME = {"en": "Bit", "ar": "بِت"}

EYES = {
    "happy": '<ellipse cx="46" cy="55" rx="6" ry="7.5" fill="#1e1b4b"/><ellipse cx="74" cy="55" rx="6" ry="7.5" fill="#1e1b4b"/>'
             '<circle cx="48" cy="52" r="2.2" fill="#fff"/><circle cx="76" cy="52" r="2.2" fill="#fff"/>'
             '<path d="M48,68 Q60,78 72,68" fill="none" stroke="#1e1b4b" stroke-width="3.5" stroke-linecap="round"/>',
    "think": '<ellipse cx="49" cy="52" rx="5.5" ry="7" fill="#1e1b4b"/><ellipse cx="77" cy="52" rx="5.5" ry="7" fill="#1e1b4b"/>'
             '<circle cx="51" cy="49" r="2" fill="#fff"/><circle cx="79" cy="49" r="2" fill="#fff"/>'
             '<path d="M50,71 L66,69" fill="none" stroke="#1e1b4b" stroke-width="3.5" stroke-linecap="round"/>',
    "wow":   '<circle cx="46" cy="55" r="8.5" fill="#1e1b4b"/><circle cx="74" cy="55" r="8.5" fill="#1e1b4b"/>'
             '<circle cx="49" cy="52" r="3" fill="#fff"/><circle cx="77" cy="52" r="3" fill="#fff"/>'
             '<ellipse cx="60" cy="72" rx="5" ry="6" fill="#1e1b4b"/>',
}


def bit(mood="happy", wave=True):
    arm = ('<path d="M88,104 Q104,96 106,80" fill="none" stroke="#312e81" stroke-width="6" stroke-linecap="round"/>'
           '<circle cx="106" cy="76" r="7" fill="#fbbf24" stroke="#312e81" stroke-width="3"/>') if wave else \
          ('<path d="M88,104 Q100,112 100,122" fill="none" stroke="#312e81" stroke-width="6" stroke-linecap="round"/>')
    return f'''<svg viewBox="0 0 120 140" aria-hidden="true">
<path d="M32,104 Q20,112 20,122" fill="none" stroke="#312e81" stroke-width="6" stroke-linecap="round"/>
{arm}
<rect x="34" y="90" width="52" height="40" rx="13" fill="#818cf8" stroke="#312e81" stroke-width="3"/>
<circle cx="60" cy="108" r="7" fill="#f472b6" stroke="#312e81" stroke-width="2.5"/>
<line x1="60" y1="10" x2="60" y2="24" stroke="#312e81" stroke-width="3.5"/>
<circle cx="60" cy="8" r="6.5" fill="#fbbf24" stroke="#312e81" stroke-width="3"/>
<rect x="6" y="46" width="12" height="24" rx="5" fill="#fbbf24" stroke="#312e81" stroke-width="3"/>
<rect x="102" y="46" width="12" height="24" rx="5" fill="#fbbf24" stroke="#312e81" stroke-width="3"/>
<rect x="14" y="22" width="92" height="72" rx="24" fill="#6366f1" stroke="#312e81" stroke-width="3.5"/>
<rect x="24" y="33" width="72" height="50" rx="16" fill="#e0e7ff"/>
<ellipse cx="33" cy="70" rx="5" ry="3" fill="#f9a8d4"/><ellipse cx="87" cy="70" rx="5" ry="3" fill="#f9a8d4"/>
{EYES[mood]}
</svg>'''


ICONS = {
    "tip": '<path d="M12 3a6 6 0 0 0-3.5 10.9V16h7v-2.1A6 6 0 0 0 12 3z" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/><path d="M9.5 19h5M10.5 21.5h3" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>',
    "warn": '<path d="M12 3 22 20H2z" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/><path d="M12 9v5" stroke="currentColor" stroke-width="2.2" stroke-linecap="round"/><circle cx="12" cy="17" r="1.3" fill="currentColor"/>',
    "fact": '<path d="M12 2.8l2.8 5.9 6.4.8-4.7 4.4 1.2 6.3L12 17.1l-5.7 3.1 1.2-6.3L2.8 9.5l6.4-.8z" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>',
    "try": '<rect x="2.5" y="6" width="19" height="12" rx="2.5" fill="none" stroke="currentColor" stroke-width="2"/><path d="M6 10h1M9.5 10h1M13 10h1M16.5 10h1M7 14h10" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>',
    "quiz": '<circle cx="12" cy="12" r="9.5" fill="none" stroke="currentColor" stroke-width="2"/><path d="M9.3 9.3a2.8 2.8 0 1 1 3.9 2.6c-.8.4-1.2 1-1.2 1.9v.6" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round"/><circle cx="12" cy="17.3" r="1.3" fill="currentColor"/>',
    "rule": '<circle cx="12" cy="9" r="6" fill="none" stroke="currentColor" stroke-width="2"/><path d="M8.5 14 7 22l5-2.5L17 22l-1.5-8" fill="none" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>',
}

LEVELS = {"Medium": "medium", "متوسط": "medium", "Challenge": "hard", "تحدٍّ": "hard"}


def decorate(chapter, lang, number):
    # Opener: kicker + title inside a gradient panel with a giant number and Bit waving.
    chapter = re.sub(
        r'<p class="chapter-kicker">(.*?)</p>\s*<h1>(.*?)</h1>',
        lambda m: (f'<div class="opener"><span class="opener-num">{number}</span>'
                   f'<p class="chapter-kicker">{m.group(1)}</p><h1>{m.group(2)}</h1>'
                   f'<div class="opener-bit">{bit("happy")}</div></div>'),
        chapter, count=1, flags=re.S)

    chapter = re.sub(r'<h2>(\d+\.\d+) (.*?)</h2>', r'<h2><span class="sec">\1</span> <span>\2</span></h2>', chapter)
    chapter = re.sub(r'<h2>(?!<span)', '<h2 class="plain-h">', chapter)

    def box(m):
        kind = m.group(1).split()[0]
        icon = f'<svg viewBox="0 0 24 24" aria-hidden="true">{ICONS.get(kind, ICONS["tip"])}</svg>'
        return m.group(0).replace('<p class="box-title">', f'<p class="box-title">{icon}', 1)
    chapter = re.sub(r'<aside class="box ([^"]+)">.*?</aside>', box, chapter, flags=re.S)

    def talk(m):
        mood, body = m.group(1), m.group(2)
        return (f'<div class="bit">{bit(mood, wave=mood == "happy")}<div class="bubble">'
                f'<p class="bubble-name">{NAME[lang]}</p>{body}</div></div>')
    chapter = re.sub(r'<aside class="bit" data-mood="(\w+)">(.*?)</aside>', talk, chapter, flags=re.S)

    for word, cls in LEVELS.items():
        chapter = chapter.replace(f'<span class="level">{word}</span>', f'<span class="level {cls}">{word}</span>')
    return chapter
