const addresses = [
  "https://www.example.com/news/sport?team=ahly&page=2",
  "http://localhost:3000/about",
  "https://shop.example.com/cart#summary",
];

for (const text of addresses) {
  const url = new URL(text);
  console.log(url.hostname, "|", url.pathname, "|", url.search || "-", "|", url.hash || "-");
}
