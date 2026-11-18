const http = require("node:http");

// A tiny weather API: /api/weather/cairo and so on
const weather = {
  cairo: { city: "Cairo", temp: 31, sky: "sunny" },
  dubai: { city: "Dubai", temp: 35, sky: "very hot" },
  london: { city: "London", temp: 14, sky: "light rain" },
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

// The client code
async function getJson(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }
  return response.json();
}

async function report(names) {
  console.log("Loading the weather…");
  for (const name of names) {
    try {
      const day = await getJson(`http://localhost:3002/api/weather/${name}`);
      console.log(`${day.city}: ${day.temp}°C, ${day.sky}`);
    } catch (error) {
      console.log(`${name}: no data (${error.message})`);
    }
  }
  console.log("Report finished.");
}

server.listen(3002, async () => {
  await report(["cairo", "atlantis", "london"]);
  server.close();
});
