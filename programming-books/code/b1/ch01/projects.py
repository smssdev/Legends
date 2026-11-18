"""Writes the solutions of chapter 1's practice projects, in English and Arabic.
Run: python3 projects.py   (the files go to en/projects/ and ar/projects/)
"""
from pathlib import Path

HERE = Path(__file__).parent

FILES = {
    "my-numbers.js": ('''// {c1}
const age = 20;

console.log("{l1}", age * 12);
console.log("{l2}", age * 365);
console.log("{l3}", age * 365 * 24);
console.log("{l4}", age * 365 * 24 * 60);
''', {"en": {"c1": "Change 20 to your own age", "l1": "Months:", "l2": "Days:", "l3": "Hours:", "l4": "Minutes:"},
      "ar": {"c1": "غيّر 20 إلى عمرك أنت", "l1": "الشهور:", "l2": "الأيام:", "l3": "الساعات:", "l4": "الدقائق:"}}),
    "secret-code.js": ('''// {c1}
console.log("B".charCodeAt(0), "i".charCodeAt(0), "t".charCodeAt(0));

// {c2}
console.log(String.fromCharCode(66, 105, 116));
console.log(String.fromCharCode(1576, 1616, 1578));
''', {"en": {"c1": "Turn each letter into its Unicode number", "c2": "And back again: numbers into letters"},
      "ar": {"c1": "حوّل كل حرف إلى رقمه في يونيكود", "c2": "والعكس: الأرقام إلى حروف"}}),
    "binary-birthday.js": ('''const day = 14;
const month = 3;
const year = 2008;

console.log("{l1}", day.toString(2));
console.log("{l2}", month.toString(2));
console.log("{l3}", year.toString(2));
console.log("{l4}", parseInt(year.toString(2), 2));
''', {"en": {"l1": "Day in binary:", "l2": "Month in binary:", "l3": "Year in binary:", "l4": "Check, back to decimal:"},
      "ar": {"l1": "اليوم بالثنائي:", "l2": "الشهر بالثنائي:", "l3": "السنة بالثنائي:", "l4": "تحقق، عودة إلى العشري:"}}),
}

for name, (tpl, langs) in FILES.items():
    for lang, vals in langs.items():
        s = tpl
        for k, v in vals.items():
            s = s.replace("{" + k + "}", v)
        d = HERE / lang / "projects"
        d.mkdir(parents=True, exist_ok=True)
        (d / name).write_text(s)
print("ok")
