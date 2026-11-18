const http = require("node:http");

// خادم واجهة برمجية صغير له عنوان واحد: /api/products
const products = [
  { id: 1, name: "البرمجة من الصفر", price: 25 },
  { id: 2, name: "كوب بِت", price: 8 },
  { id: 3, name: "ملصق بِت", price: 3 },
];
const server = http.createServer((request, response) => {
  if (request.url === "/api/products") {
    response.writeHead(200, { "Content-Type": "application/json" });
    response.end(JSON.stringify(products));
  } else {
    response.writeHead(404);
    response.end();
  }
});

// كود العميل: هذا ما يعمل في التطبيق الحقيقي
async function getJson(url) {
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`HTTP ${response.status}`);
  }
  return response.json();
}

server.listen(3001, async () => {
  const list = await getJson("http://localhost:3001/api/products");
  console.log(list.length, list[0].name);

  try {
    await getJson("http://localhost:3001/api/missing");
  } catch (error) {
    console.log("تعذّر التحميل:", error.message);
  }

  server.close();
});
