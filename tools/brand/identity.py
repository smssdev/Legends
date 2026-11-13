"""[Sprint 63 G1] The game's identity on one page (docs/design/legends-ui/Identity.html), for the owner to approve:
the two worlds and where each begins, the colours and their shares, the corners, the lines, the shadows, the motion,
the icons, the dock, the mascot, and what to do and not to do. Its values are read from their sources (tokens.json,
brand/icons, nav.json, brand/states), so the page shows what the game draws.

    python3 tools/brand/identity.py
"""

import base64
import html
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[2]
OUT = ROOT / 'docs' / 'design' / 'legends-ui' / 'Identity.html'
tokens = json.loads((ROOT / 'docs' / 'design' / 'tokens.json').read_text())
nav = json.loads((ROOT / 'docs' / 'design' / 'nav.json').read_text())
C, B = tokens['color'], tokens['broadcast']
R = tokens['size']['radius']
M = tokens['motion']
icons = {f.stem: f.read_text().split('<path d="')[1].split('"')[0] for f in sorted((ROOT / 'brand' / 'icons').glob('*.svg'))}


def icon(name, size=24, colour='currentColor'):
    return (f'<svg width="{size}" height="{size}" viewBox="0 0 24 24" fill="none" stroke="{colour}" stroke-width="1.75" '
            f'stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="{icons[name]}"/></svg>')


def swatch(name, value, share=''):
    ink = C['bgDeep'] if int(value[1:3], 16) * 0.3 + int(value[3:5], 16) * 0.59 + int(value[5:7], 16) * 0.11 > 140 else '#FFFFFF'
    return f'<div class="sw" style="background:{value};color:{ink}"><b>{html.escape(name)}</b><span dir="ltr">{value}</span>{f"<em>{share}</em>" if share else ""}</div>'


TILE = {'gold': C['gold'], 'brand': C['brand'], 'ring': C['ring'], 'live': C['live'], 'warning': C['warning'], 'chrome': C['chrome']}
dock = ''.join(
    f'<div class="dock-i"><span class="tile" style="background:{TILE[s["color"]]};color:{B["ink"] if s["ink"] == "dark" else "#fff"}">{icon(s["icon"], 18)}</span><small>{s["ar"]}</small></div>'
    for s in nav['dock']
)
states = {'empty': 'فراغ', 'error': 'خطأ', 'offline': 'بلا اتصال', 'slow': 'انتظار طويل', 'celebrate': 'احتفال', 'welcome': 'ترحيب'}
# The page stands alone (sent as one file): the mascot's pictures and the fonts inside it.
def data(path, kind):
    return f'data:{kind};base64,' + base64.b64encode(path.read_bytes()).decode()


mascot = ''.join(
    f'<figure><img src="{data(ROOT / "brand" / "states" / f"{k}.png", "image/png")}" alt="" width="96"><figcaption>{v}</figcaption></figure>'
    for k, v in states.items()
)
FONTS = ROOT / 'web' / 'public' / 'fonts'
font = {n: data(FONTS / f'{n}.woff2', 'font/woff2') for n in ('tajawal-400-arabic', 'tajawal-700-arabic', 'barlow-condensed-800-latin')}
grid = ''.join(f'<span class="ic" title="{n}">{icon(n)}<small dir="ltr">{n}</small></span>' for n in icons)

page = f'''<!doctype html>
<html lang="ar" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>هوية اللعبة · Sprint 63</title>
<style>
@font-face {{ font-family: Tajawal; src: url({font['tajawal-400-arabic']}) format('woff2'); font-weight: 400; }}
@font-face {{ font-family: Tajawal; src: url({font['tajawal-700-arabic']}) format('woff2'); font-weight: 700; }}
@font-face {{ font-family: 'Barlow Condensed'; src: url({font['barlow-condensed-800-latin']}) format('woff2'); font-weight: 800; }}
:root {{ --bg: {C['bg']}; --deep: {C['bgDeep']}; --surface: {C['surface']}; --raised: {C['surfaceRaised']}; --gold: {C['gold']}; --text: {C['text']}; --muted: {C['textMuted']}; --brand: {C['brand']}; --live: {C['live']}; }}
* {{ box-sizing: border-box; }}
body {{ margin: 0; background: var(--deep); color: var(--text); font: 15px/1.7 Tajawal, sans-serif; }}
main {{ max-width: 1080px; margin: 0 auto; padding: 24px 16px 64px; }}
h1 {{ font-size: 32px; margin: 0 0 4px; }} h1 + p {{ color: var(--muted); margin: 0 0 28px; }}
h2 {{ font-size: 22px; margin: 36px 0 12px; color: var(--gold); }}
section > p, li {{ color: #C9D2E1; }}
.two {{ display: grid; grid-template-columns: 1fr 1fr; gap: 16px; }} @media (max-width: 760px) {{ .two {{ grid-template-columns: 1fr; }} }}
.world {{ border-radius: {R['xl']}px; padding: 18px; min-height: 220px; }}
.manage {{ background: linear-gradient(180deg, var(--surface), var(--bg)); box-shadow: 0 18px 40px -24px #000; }}
.pitchw {{ background: linear-gradient(180deg, {B['tv']}, {B['tvDeep']}); border: 2px solid {B['gold']}; }}
.pitchw .grass {{ height: 70px; border-radius: 10px; margin-top: 10px; background: repeating-linear-gradient(90deg, {C['pitch']} 0 40px, {C['pitchDark']} 40px 80px); }}
.sw-row {{ display: flex; flex-wrap: wrap; gap: 8px; }}
.sw {{ width: 128px; height: 84px; border-radius: {R['lg']}px; padding: 8px 10px; display: flex; flex-direction: column; justify-content: space-between; font-size: 13px; }}
.sw span {{ font-family: 'Barlow Condensed', sans-serif; font-weight: 800; }} .sw em {{ font-style: normal; font-weight: 700; }}
.bar {{ display: flex; height: 26px; border-radius: 8px; overflow: hidden; margin: 12px 0 4px; }}
.radii {{ display: flex; gap: 14px; flex-wrap: wrap; align-items: end; }} .radii div {{ width: 74px; height: 56px; background: var(--raised); display: grid; place-items: center; font-size: 12px; color: var(--muted); }}
.shadows {{ display: flex; gap: 22px; flex-wrap: wrap; }} .shadows div {{ width: 150px; height: 84px; border-radius: {R['xl']}px; background: var(--surface); display: grid; place-items: center; }}
.icons {{ display: grid; grid-template-columns: repeat(auto-fill, minmax(84px, 1fr)); gap: 6px; }}
.ic {{ display: flex; flex-direction: column; align-items: center; gap: 2px; padding: 8px 0; border-radius: 8px; background: var(--surface); color: var(--text); }} .ic small {{ font-size: 10px; color: var(--muted); }}
.dock {{ display: inline-flex; flex-direction: column; gap: 10px; padding: 12px 10px; border-radius: {R['xl']}px; background: var(--bg); }}
.dock-i {{ display: flex; flex-direction: column; align-items: center; gap: 2px; }} .dock-i small {{ font-weight: 700; font-size: 12px; }}
.tile {{ width: 30px; height: 30px; border-radius: 9px; display: grid; place-items: center; box-shadow: 0 3px 8px -3px {B['ink']}; }}
.mascot {{ display: flex; flex-wrap: wrap; gap: 14px; }} .mascot figure {{ margin: 0; text-align: center; }} .mascot figcaption {{ color: var(--muted); font-size: 13px; }}
.motion {{ display: flex; gap: 18px; flex-wrap: wrap; }}
.dot {{ width: 46px; height: 46px; border-radius: 50%; background: var(--gold); animation: go var(--d) cubic-bezier({','.join(map(str, M['easeSoft']))}) infinite alternate; }}
@keyframes go {{ to {{ transform: translateX(-140px); }} }}
@media (prefers-reduced-motion: reduce) {{ .dot {{ animation: none; }} }}
.do, .dont {{ border-radius: {R['xl']}px; padding: 14px 16px; }} .do {{ background: color-mix(in srgb, {C['success']} 14%, var(--surface)); }} .dont {{ background: color-mix(in srgb, var(--live) 14%, var(--surface)); }}
.do h3, .dont h3 {{ margin: 0 0 6px; font-size: 17px; }} .do li, .dont li {{ margin: 4px 0; }}
.approve {{ margin-top: 36px; padding: 16px; border: 2px dashed var(--gold); border-radius: {R['xl']}px; }}
</style>
</head>
<body>
<main>
<h1>هوية اللعبة</h1>
<p>Sprint 63 G1 · لغة بصرية واحدة للموقع والتطبيق وUnity. كل قيمة هنا من مصدرها: <code dir="ltr">tokens.json</code> و<code dir="ltr">brand/icons</code> و<code dir="ltr">nav.json</code>. للاعتماد من صاحب المشروع.</p>

<section>
<h2>العالمان</h2>
<div class="two">
  <div class="world manage">
    <h3>«الإدارة»: الهادئ</h3>
    <p>المكتب والفريق والسوق والنادي وكل ما في الإطار (الرصيف والشريط). ليل أزرق داكن، وبطاقات أفتح منه بدرجة، والذهبي للفعل الرئيسي وحده، والزمردي للحالة الحسنة. حركة قليلة.</p>
  </div>
  <div class="world pitchw">
    <h3>«الملعب»: الزاهي</h3>
    <p>المباراة الحية والمحاكي ولقطاتها والتقرير. أزرق البث، والعشب، وقمصان الناديين، والأصفر للحدث. يبدأ بالستارة بلوني الناديين (420ms) وينتهي بها.</p>
    <div class="grass"></div>
  </div>
</div>
</section>

<section>
<h2>الألوان ونسبها</h2>
<p>في «الإدارة»: الليل نحو 60% من الشاشة، والبطاقات 25%، والذهبي 10%، والزمردي والإنذار 5%.</p>
<div class="bar"><span style="flex:60;background:{C['bg']}"></span><span style="flex:25;background:{C['surfaceRaised']}"></span><span style="flex:10;background:{C['gold']}"></span><span style="flex:5;background:{C['brand']}"></span></div>
<div class="sw-row">{swatch('الليل', C['bg'], '60%')}{swatch('البطاقة', C['surfaceRaised'], '25%')}{swatch('الذهبي', C['gold'], '10%')}{swatch('الزمردي', C['brand'], '5%')}{swatch('النعناعي', C['ring'])}{swatch('الإنذار', C['live'])}{swatch('التنبيه', C['warning'])}{swatch('الكريمي', C['chrome'])}{swatch('النص', C['text'])}</div>
<p>وفي «الملعب»: البث والعشب والأصفر، وقميصا الناديين من الخادم.</p>
<div class="sw-row">{swatch('البث', B['tv'])}{swatch('عمق البث', B['tvDeep'])}{swatch('العشب', C['pitch'])}{swatch('الأصفر', B['yellow'])}{swatch('البطاقة الصفراء', C['cardYellow'])}{swatch('الأحمر', B['red'])}</div>
</section>

<section>
<h2>الزوايا والخطوط والظلال</h2>
<div class="radii">{''.join(f'<div style="border-radius:{v if v < 999 else 28}px">{k} · {v if v < 999 else "pill"}</div>' for k, v in R.items() if not k.startswith('$'))}</div>
<p>الأيقونات بخط 1.75 على شبكة 24، والحدود 1px، والفعل الرئيسي بلا حد. لا زوايا حادة في شيء يُلمس.</p>
<div class="shadows">{''.join(f'<div style="box-shadow:0 {v["y"]}px {v["blur"]}px {v["spread"]}px rgba(0,0,0,{v["alpha"]})">{k}</div>' for k, v in tokens['shadow'].items() if not k.startswith('$'))}</div>
<p>ظلال ثلاثة بلون الظل وحده: البطاقة على الأرض، وما يرتفع (قائمة)، وما يعلو كل شيء (نافذة).</p>
</section>

<section>
<h2>الحركة</h2>
<div class="motion">{''.join(f'<div><div class="dot" style="--d:{M[k]}ms"></div><small>{k} · {M[k]}ms</small></div>' for k in ('fast', 'base', 'slow'))}</div>
<p>السريعة للضغط والمرور، والأساسية لظهور القوائم واللوحات، والبطيئة للانتقال بين العالمين (الستارة). ومع «تقليل الحركة» تقف كلها.</p>
</section>

<section>
<h2>الأيقونات ({len(icons)})</h2>
<p>طقم واحد من <code dir="ltr">brand/icons</code>: الموقع والتطبيق يرسمان الملف نفسه. ولا رموز تعبيرية في الواجهة إلا تفاعلات الجمهور.</p>
<div class="icons">{grid}</div>
</section>

<section>
<h2>الرصيف</h2>
<div class="two"><div class="dock">{dock}</div><p>كل قسم على مربع بلونه، والأيقونة بحبر داكن على الفاتح وأبيض على الداكن. اللون والحبر في <code dir="ltr">nav.json</code>.</p></div>
</section>

<section>
<h2>التميمة في الحالات</h2>
<div class="mascot">{mascot}</div>
</section>

<section>
<h2>افعل ولا تفعل</h2>
<div class="two">
  <div class="do"><h3>افعل</h3><ul>
    <li>لون واحد ذهبي في الشاشة: لفعلها الرئيسي.</li>
    <li>كل لون وقياس ونص من الرموز (<code dir="ltr">tokens.json</code>).</li>
    <li>الأيقونة من الطقم، وبجانبها اسمها أو تسمية للوصول.</li>
    <li>الشعار يظهر درعاً باللونين فوراً، والصورة فوقه حين تصل.</li>
    <li>الأرقام بخط Barlow Condensed، والكلمات بـ Tajawal، بالأوزان الموجودة فقط.</li>
  </ul></div>
  <div class="dont"><h3>لا تفعل</h3><ul>
    <li>زرّان ذهبيان في شاشة واحدة.</li>
    <li>لون أو قياس تكتبه الشاشة بنفسها.</li>
    <li>رمز تعبيري مكان أيقونة (🔒 ✕ ▾).</li>
    <li>ألوان «الملعب» الزاهية في «الإدارة»، أو هدوء «الإدارة» في المباراة.</li>
    <li>وزن 900 أو خط من خارج اللعبة.</li>
  </ul></div>
</div>
</section>

<div class="approve"><b>للاعتماد:</b> العالمان وحدودهما، والألوان ونسبها، وأقسام الرصيف بألوانها، والتميمة في الحالات. أي تعديل يُكتب في مصدره (الرموز، أو <code dir="ltr">brand/icons</code>، أو <code dir="ltr">nav.json</code>) فيتغيّر الموقع والتطبيق معاً.</div>
</main>
</body>
</html>
'''
OUT.write_text(page)
print(f'identity: {OUT.relative_to(ROOT)}')
