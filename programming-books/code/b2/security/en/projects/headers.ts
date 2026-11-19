import { createServer } from "node:http";
import type { AddressInfo } from "node:net";

// Checks the security headers a server sends, like the tools security teams use
const RECOMMENDED: Record<string, string> = {
  "content-security-policy": "stops injected scripts",
  "strict-transport-security": "forces HTTPS",
  "x-content-type-options": "stops MIME sniffing",
  "referrer-policy": "limits what leaks in links",
  "permissions-policy": "turns off unused powerful features",
};

export async function check(url: string): Promise<number> {
  const response = await fetch(url);
  let score = 0;
  for (const [name, why] of Object.entries(RECOMMENDED)) {
    const value = response.headers.get(name);
    if (value) score++;
    console.log(`${value ? "✓" : "✗"} ${name.padEnd(26)} ${value ? "present" : `missing (${why})`}`);
  }
  console.log(`Score: ${score}/${Object.keys(RECOMMENDED).length}`);
  return score;
}

// A local server that sends only some of the headers, to check against
const server = createServer((_req, res) => {
  res.setHeader("Content-Security-Policy", "default-src 'self'");
  res.setHeader("X-Content-Type-Options", "nosniff");
  res.setHeader("Referrer-Policy", "strict-origin-when-cross-origin");
  res.end("ok");
});
await new Promise<void>((ready) => server.listen(0, ready));
await check(`http://localhost:${(server.address() as AddressInfo).port}/`);
server.close();
