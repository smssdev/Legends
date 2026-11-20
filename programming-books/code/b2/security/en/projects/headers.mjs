// en/projects/headers.ts
import { createServer } from "node:http";
var RECOMMENDED = {
  "content-security-policy": "stops injected scripts",
  "strict-transport-security": "forces HTTPS",
  "x-content-type-options": "stops MIME sniffing",
  "referrer-policy": "limits what leaks in links",
  "permissions-policy": "turns off unused powerful features"
};
async function check(url) {
  const response = await fetch(url);
  let score = 0;
  for (const [name, why] of Object.entries(RECOMMENDED)) {
    const value = response.headers.get(name);
    if (value) score++;
    console.log(`${value ? "\u2713" : "\u2717"} ${name.padEnd(26)} ${value ? "present" : `missing (${why})`}`);
  }
  console.log(`Score: ${score}/${Object.keys(RECOMMENDED).length}`);
  return score;
}
var server = createServer((_req, res) => {
  res.setHeader("Content-Security-Policy", "default-src 'self'");
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");
  res.end("ok");
});
await new Promise((ready) => server.listen(0, ready));
await check(`http://localhost:${server.address().port}/`);
server.close();
export {
  check
};
