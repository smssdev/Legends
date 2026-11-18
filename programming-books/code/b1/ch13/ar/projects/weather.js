const http = require("node:http");

// واجهة طقس صغيرة: /api/weather/cairo وهكذا
const weather = {
  cairo: { city: "القاهرة", temp: 31, sky: "مشمس" },
  dubai: { city: "دبي", temp: 35, sky: "حار جداً" },
  london: { city: "لندن", temp: 14, sky: "مطر خفيف" },
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

// كود العميل
async function getJson(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }
  return response.json();
}

async function report(names) {
  console.log("جارٍ تحميل الطقس…");
  for (const name of names) {
    try {
      const day = await getJson(`http://localhost:3002/api/weather/${name}`);
      console.log(`${day.city}: ${day.temp}°C، ${day.sky}`);
    } catch (error) {
      console.log(`${name}: لا بيانات (${error.message})`);
    }
  }
  console.log("اكتمل التقرير.");
}

server.listen(3002, async () => {
  await report(["cairo", "atlantis", "london"]);
  server.close();
});
