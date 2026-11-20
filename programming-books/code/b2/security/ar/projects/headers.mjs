// ar/projects/headers.ts
import { createServer } from "node:http";
var RECOMMENDED = {
  "content-security-policy": "\u062A\u0648\u0642\u0641 \u0627\u0644\u0633\u0643\u0631\u0628\u062A\u0627\u062A \u0627\u0644\u0645\u062D\u0642\u0648\u0646\u0629",
  "strict-transport-security": "\u062A\u0641\u0631\u0636 HTTPS",
  "x-content-type-options": "\u062A\u0648\u0642\u0641 \u062A\u062E\u0645\u064A\u0646 \u0646\u0648\u0639 \u0627\u0644\u0645\u0644\u0641",
  "referrer-policy": "\u062A\u062D\u062F\u0651 \u0645\u0645\u0627 \u064A\u062A\u0633\u0631\u0628 \u0641\u064A \u0627\u0644\u0631\u0648\u0627\u0628\u0637",
  "permissions-policy": "\u062A\u0637\u0641\u0626 \u0627\u0644\u0645\u0632\u0627\u064A\u0627 \u0627\u0644\u0642\u0648\u064A\u0629 \u063A\u064A\u0631 \u0627\u0644\u0645\u0633\u062A\u062E\u062F\u0645\u0629"
};
async function check(url) {
  const response = await fetch(url);
  let score = 0;
  for (const [name, why] of Object.entries(RECOMMENDED)) {
    const value = response.headers.get(name);
    if (value) score++;
    console.log(`${value ? "\u2713" : "\u2717"} ${name.padEnd(26)} ${value ? "\u0645\u0648\u062C\u0648\u062F\u0629" : `\u063A\u0627\u0626\u0628\u0629 (${why})`}`);
  }
  console.log(`\u0627\u0644\u0646\u062A\u064A\u062C\u0629: ${score}/${Object.keys(RECOMMENDED).length}`);
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
