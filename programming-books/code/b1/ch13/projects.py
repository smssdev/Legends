"""Writes the solutions of chapter 13's practice projects (asynchronous JavaScript), in English and Arabic.
Run: python3 projects.py   (the files go to en/projects/ and ar/projects/)
"""
from pathlib import Path

HERE = Path(__file__).parent

FILES = {
    "countdown.js": ('''function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function countdown(from) {
  for (let n = from; n > 0; n--) {
    console.log(n + "…");
    await wait(200);
  }
  console.log("{go}");
}

countdown(3);
console.log("{ready}");
''', {"en": {"go": "Go!", "ready": "Get ready…"},
      "ar": {"go": "انطلق!", "ready": "استعد…"}}),
    "breakfast.js": ('''function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function make(item, ms) {
  await wait(ms);
  return item;
}

function seconds(start) {
  const ms = Date.now() - start;
  return (Math.round(ms / 100) / 10).toFixed(1);
}

async function main() {
  let start = Date.now();
  await make("{tea}", 300);
  await make("{toast}", 400);
  await make("{eggs}", 500);
  console.log("{one}", seconds(start), "{s}");

  start = Date.now();
  const breakfast = await Promise.all([
    make("{tea}", 300),
    make("{toast}", 400),
    make("{eggs}", 500),
  ]);
  console.log("{all}", seconds(start), "{s}");
  console.log(breakfast.join(" + "));
}

main();
''', {"en": {"tea": "tea", "toast": "toast", "eggs": "eggs", "one": "One after another:", "all": "All at once:", "s": "seconds"},
      "ar": {"tea": "شاي", "toast": "خبز محمص", "eggs": "بيض", "one": "واحداً بعد الآخر:", "all": "كلها معاً:", "s": "ثانية"}}),
    "weather.js": ('''const http = require("node:http");

// {c1}
const weather = {
  cairo: { city: "{cairo}", temp: 31, sky: "{sunny}" },
  dubai: { city: "{dubai}", temp: 35, sky: "{hot}" },
  london: { city: "{london}", temp: 14, sky: "{rain}" },
};
const server = http.createServer((request, response) => {
  const name = request.url.replace("/api/weather/", "");
  if (weather[name]) {
    response.writeHead(200, { "Content-Type": "application/json" });
    response.end(JSON.stringify(weather[name]));
  } else {
    response.writeHead(404);
    response.end();
  }
});

// {c2}
async function getJson(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }
  return response.json();
}

async function report(names) {
  console.log("{loading}");
  for (const name of names) {
    try {
      const day = await getJson(`http://localhost:3002/api/weather/${name}`);
      console.log(`${day.city}: ${day.temp}°C{sep} ${day.sky}`);
    } catch (error) {
      console.log(`${name}: {missing} (${error.message})`);
    }
  }
  console.log("{done}");
}

server.listen(3002, async () => {
  await report(["cairo", "atlantis", "london"]);
  server.close();
});
''', {"en": {"c1": "A tiny weather API: /api/weather/cairo and so on", "c2": "The client code", "sep": ",",
             "cairo": "Cairo", "dubai": "Dubai", "london": "London", "sunny": "sunny", "hot": "very hot", "rain": "light rain",
             "loading": "Loading the weather…", "missing": "no data", "done": "Report finished."},
      "ar": {"c1": "واجهة طقس صغيرة: /api/weather/cairo وهكذا", "c2": "كود العميل", "sep": "،",
             "cairo": "القاهرة", "dubai": "دبي", "london": "لندن", "sunny": "مشمس", "hot": "حار جداً", "rain": "مطر خفيف",
             "loading": "جارٍ تحميل الطقس…", "missing": "لا بيانات", "done": "اكتمل التقرير."}}),
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
