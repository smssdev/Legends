"""Writes out/series-plan-ar.html: the series plan in Arabic, from series.json.

  python3 plan.py && node render.cjs series-plan
"""
import json
from pathlib import Path

ROOT = Path(__file__).parent
S = json.loads((ROOT / "series.json").read_text())

SPECS = [
    ("المقاس", "7 × 10 بوصة (مقاس كتب البرمجة الشائع: سطر الكود يتسع لـ 70 حرفاً تقريباً)"),
    ("النسخ لكل لغة", "ثلاثة ملفات: (1) PDF ملون للتصفح على الشاشة، غلافه أول صفحة، وهوامشه متساوية، وفيه فهرس جانبي للعناوين. (2) داخل الكتاب الورقي أبيض وأسود لـ KDP، بهوامش تجليد. (3) غلاف الكتاب الورقي ملوّناً كاملاً (الظهر والكعب والوجه) بمقاس KDP، ويُحسب عرض الكعب من عدد الصفحات"),
    ("الشكل", "الكود ملوّن، والمخرجات في طرفية داكنة، وكل فصل يفتح بلوحة ملونة. وفي نسخة الأبيض والأسود نفس التصميم بدرجات الرمادي وخلفيات فاتحة لتوفير الحبر"),
    ("الدليل", "روبوت اسمه Bit (وبالعربية «بِت») يرافق القارئ في كل فصل: يرحب به، ويعطيه حيلاً، ويشجعه قبل المشاريع"),
    ("ما يجعله شيقاً", "قصة أو مشروع صغير يربط كل فصل، ومربعات «هل تعلم؟» بحقائق ممتعة، و«اختبر نفسك» في منتصف الفصل، و«جرّب» لتغيير الكود واللعب به"),
    ("الهوامش", "الداخلي 0.875 بوصة (KDP يطلب 0.625 لكتاب من 301 إلى 500 صفحة)، والخارجي 0.625، والأعلى والأسفل 0.8"),
    ("الخطوط", "Source Serif 4 للنص الإنجليزي، وNoto Naskh Arabic للعربي، وInter وCairo للعناوين، وJetBrains Mono للكود. كلها برخصة OFL المجانية وتُضمَّن في الملف"),
    ("الملف", "PDF واحد للداخل بكل خطوطه، وغلاف كامل (أمام وظهر وكعب) يُصمَّم بعد معرفة عدد الصفحات"),
    ("الكود", "كل مثال ملف حقيقي يُشغَّل عند بناء الكتاب، والمخرجات المطبوعة هي ما طبعه البرنامج فعلاً، فلا يوجد مثال لا يعمل"),
    ("في كل فصل", "أهداف الفصل، وشرح بأمثلة، وأشكال توضيحية، ومربعات (نصيحة، وانتبه، وعادة المحترفين، وجرّب)، وأخطاء شائعة، وخلاصة، وتمارين بثلاثة مستويات، وتمهيد للفصل التالي"),
]

OPEN = [
    ("إصداران للواجهات وإصداران للخوادم", "الكتاب الثاني بإصدارين مستقلين: React وVue، والثالث بإصدارين: Node.js وLaravel. وكل إصدار كتاب كامل بعنوانه وغلافه وكوده، يشترك مع أخيه في الفصول العامة (مثل HTTP وSQL والأمان والاختبار) ويختلف في فصول الإطار. والكتاب الرابع (الشامل) يُكتب ليصلح بعد أي إصدار منهما."),
    ("تكلفة الطباعة الملونة", "الطباعة الملونة في KDP أغلى بكثير من الأبيض والأسود، وتزيد مع عدد الصفحات، فكتاب من 350 صفحة ملونة قد يحتاج سعراً أعلى من المعتاد. والحل الذي جهزناه: النسخة الملونة أساسية، ونسخة Kindle الإلكترونية ملونة بلا تكلفة طباعة، ويمكن إخراج نسخة ورقية أبيض وأسود أرخص من المصدر نفسه."),
    ("ISBN", "KDP يعطي رقماً مجانياً لكل نسخة ورقية (الإنجليزية والعربية رقمان منفصلان)، أو تشتري أرقامك من Bowker."),
    ("دعم KDP للعربية", "يجب التأكد من أن KDP يقبل الكتب الورقية العربية في وقت النشر، ومن اتجاه التجليد من اليمين. والنسخة العربية مبنية من الآن بهامش التجليد على اليمين."),
    ("مستودع الكود للقراء", "كل كتاب يعد القارئ بمستودع فيه كل الأمثلة والحلول. ويُنشأ مستودع عام لكل كتاب قبل النشر."),
]


def book(b):
    n = b["number"]
    parts = ""
    k = 0
    for i, p in enumerate(b["parts"], 1):
        items = ""
        for ch in p["chapters"]:
            k += 1
            s = ' <span class="tag">فصل نموذجي جاهز</span>' if ch.get("sample") else ""
            items += f'<li><span class="n">{k}</span>{ch["ar"]}<span class="en" dir="ltr">{ch["en"]}</span>{s}</li>'
        parts += f'<div class="part"><h4>الجزء {i}: {p["title"]["ar"]}</h4><ol>{items}</ol></div>'
    return f"""<section class="book">
      <div class="bhead"><span class="num">{n}</span><div>
        <h2>{b["title"]["ar"]}{(" · " + b["edition"]["ar"]) if b.get("edition") else ""}</h2><p class="en-title" dir="ltr">{b["title"]["en"]}: {b["subtitle"]["en"]}</p>
        <p class="sub">{b["subtitle"]["ar"]}</p></div></div>
      <table class="meta"><tr><th>المستوى</th><td>{b["level"]["ar"]}</td><th>الصفحات المتوقعة</th><td dir="ltr">{b["pages"]}</td><th>الفصول</th><td>{k}</td></tr>
      <tr><th>القارئ</th><td colspan="5">{b["reader"]["ar"]}</td></tr></table>
      <div class="parts">{parts}</div></section>"""


def main():
    total = sum(len(p["chapters"]) for b in S["books"] for p in b["parts"])
    specs = "".join(f"<tr><th>{a}</th><td>{b}</td></tr>" for a, b in SPECS)
    opens = "".join(f"<li><strong>{a}:</strong> {b}</li>" for a, b in OPEN)
    books = "".join(book(b) for b in S["books"])
    path_rows = "".join(f'<li><strong>{b["title"]["ar"]}</strong> ({b["level"]["ar"]})</li>' for b in S["books"])
    html = f"""<!doctype html><html lang="ar" dir="rtl"><head><meta charset="utf-8"><title>خطة السلسلة</title><style>
@font-face{{font-family:'Noto Naskh Arabic';font-weight:400;src:url(../fonts/noto-naskh-arabic-arabic-400-normal.woff2)}}
@font-face{{font-family:'Noto Naskh Arabic';font-weight:700;src:url(../fonts/noto-naskh-arabic-arabic-700-normal.woff2)}}
@font-face{{font-family:Cairo;font-weight:600;src:url(../fonts/cairo-arabic-600-normal.woff2)}}
@font-face{{font-family:Cairo;font-weight:700;src:url(../fonts/cairo-arabic-700-normal.woff2)}}
@font-face{{font-family:Inter;font-weight:400;src:url(../fonts/inter-latin-400-normal.woff2)}}
@font-face{{font-family:Inter;font-weight:600;src:url(../fonts/inter-latin-600-normal.woff2)}}
@page {{ size: A4; margin: 16mm 15mm; @bottom-center {{ content: counter(page); font: 600 9pt Cairo, Inter; }} }}
body {{ margin: 0; font: 400 10.5pt/1.75 'Noto Naskh Arabic', Inter, serif; color: #111; }}
h1 {{ font: 700 24pt/1.3 Cairo, Inter; margin: 0 0 4pt; }}
h2 {{ font: 700 16pt/1.3 Cairo, Inter; margin: 0; }}
h3 {{ font: 700 13pt Cairo, Inter; margin: 18pt 0 6pt; break-after: avoid; }}
h4 {{ font: 700 10pt Cairo, Inter; margin: 8pt 0 3pt; }}
.lead {{ font-size: 11.5pt; color: #333; }}
table {{ border-collapse: collapse; width: 100%; margin: 4pt 0 8pt; }}
th, td {{ border-bottom: 0.6pt solid #bbb; padding: 4pt 6pt; text-align: start; vertical-align: top; }}
th {{ font: 600 9pt Cairo, Inter; white-space: nowrap; background: #f3f3f3; }}
.book {{ break-before: page; }}
.bhead {{ display: flex; gap: 12pt; align-items: center; border-bottom: 2pt solid #111; padding-bottom: 6pt; margin-bottom: 6pt; }}
.num {{ font: 700 26pt Inter; width: 44pt; height: 44pt; border-radius: 50%; background: #111; color: #fff; display: flex; align-items: center; justify-content: center; flex: none; }}
.en-title {{ font: 600 9pt Inter; color: #555; margin: 2pt 0; text-align: right; }}
.sub {{ margin: 0; color: #333; }}
.parts {{ columns: 2; column-gap: 18pt; }}
.part {{ break-inside: avoid; }}
.part ol {{ list-style: none; padding: 0; margin: 0 0 6pt; }}
.part li {{ font-size: 9.5pt; line-height: 1.5; padding: 2pt 0; border-bottom: 0.5pt dotted #bbb; }}
.part .n {{ font: 600 8.5pt Inter; display: inline-block; width: 16pt; }}
.part .en {{ display: block; font: 400 7.5pt Inter; color: #666; padding-inline-start: 16pt; text-align: right; }}
.tag {{ font: 600 7.5pt Cairo; background: #111; color: #fff; border-radius: 6pt; padding: 0 5pt; }}
.path {{ display: flex; gap: 6pt; flex-wrap: wrap; padding: 0; list-style: none; }}
.path li {{ border: 1pt solid #111; border-radius: 6pt; padding: 3pt 8pt; font-size: 9.5pt; }}
ul.open li {{ margin-bottom: 4pt; }}
</style></head><body>
<h1>خطة السلسلة: {S["series"]["ar"]}</h1>
<p class="en-title" dir="ltr" style="font-size:11pt">{S["series"]["en"]}</p>
<p class="lead">ستة كتب تأخذ القارئ من الصفر إلى مستوى الخبير (Senior) في ثلاثة مسارات: الواجهات، والخوادم، والبرمجة الشاملة، ومعها مساران للموبايل بـ Flutter. والكتابان الثاني والثالث بإصدارين لكل منهما (React وVue، وNode.js وLaravel). وكل إصدار له نسختان مستقلتان، عربية وإنجليزية، مكتوبتان بلغتهما لا مترجمتان حرفياً، بالأمثلة نفسها. فالمجموع {len(S["books"])} إصدارات، و{total} فصلاً في كل لغة، و{len(S["books"]) * 2} كتاباً على أمازون. والمؤلف سليمان ماجد سعيد صلاح (Soliman Maged Saeed Salah).</p>
<h3>ترتيب القراءة</h3>
<ul class="path">{path_rows}</ul>
<p>الكتاب الأول أساس الجميع. ثم يختار القارئ: الثاني (الواجهات) أو الثالث (الخوادم)، والرابع (الشامل) بعدهما. ومسار الموبايل الخامس ثم السادس، ويكفيه الجزآن الأول والثالث من الكتاب الأول.</p>
<h3>مواصفات أمازون KDP للسلسلة</h3>
<table>{specs}</table>
<h3>قرارات تنتظر رأيك</h3>
<ul class="open">{opens}</ul>
<h3>ما أُنجز</h3>
<p>الفصل 8 من الكتاب الأول («القيم والمتغيرات والقرارات») كاملاً بالنسختين، مع صفحة العنوان وصفحة الحقوق والمحتويات، بنسخه الثلاث لكل لغة: PDF ملون للتصفح، وداخل أبيض وأسود للطباعة (الإنجليزية 19 صفحة والعربية 20)، وغلاف ملون كامل. والفصل يحدد شكل كل الكتب، فبعد اعتماده تُكتب الفصول الباقية بنفس النظام.</p>
{books}
</body></html>"""
    (ROOT / "out").mkdir(exist_ok=True)
    (ROOT / "out" / "series-plan-ar.html").write_text(html)
    print("built out/series-plan-ar.html")


if __name__ == "__main__":
    main()
