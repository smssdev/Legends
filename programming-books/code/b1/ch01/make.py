"""Writes the chapter 1 examples in English and Arabic. Run: python3 make.py"""
from pathlib import Path

HERE = Path(__file__).parent

FILES = {
    "hello.js": ('''console.log("{hello}");
console.log(2 + 3);
console.log("2" + "3");
''', {"en": {"hello": "Hello, world!"}, "ar": {"hello": "مرحباً بالعالم!"}}),
    "binary.js": ('''console.log((5).toString(2));
console.log((13).toString(2));
console.log((255).toString(2));
console.log(parseInt("1101", 2));
''', {"en": {}, "ar": {}}),
    "letters.js": ('''console.log("A".charCodeAt(0));
console.log("a".charCodeAt(0));
console.log("ب".charCodeAt(0));
console.log(String.fromCharCode(72, 105));
''', {"en": {}, "ar": {}}),
}

for name, (tpl, langs) in FILES.items():
    for lang, vals in langs.items():
        s = tpl
        for k, v in vals.items():
            s = s.replace("{" + k + "}", v)
        (HERE / lang).mkdir(exist_ok=True)
        (HERE / lang / name).write_text(s)
print("ok")
