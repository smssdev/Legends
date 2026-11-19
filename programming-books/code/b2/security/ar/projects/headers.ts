import { createServer } from "node:http";
import type { AddressInfo } from "node:net";

// يفحص ترويسات الأمان التي يرسلها الخادم، كالأدوات التي تستخدمها فرق الأمان
const RECOMMENDED: Record<string, string> = {
  "content-security-policy": "توقف السكربتات المحقونة",
  "strict-transport-security": "تفرض HTTPS",
  "x-content-type-options": "توقف تخمين نوع الملف",
  "referrer-policy": "تحدّ مما يتسرب في الروابط",
  "permissions-policy": "تطفئ المزايا القوية غير المستخدمة",
};

export async function check(url: string): Promise<number> {
  const response = await fetch(url);
  let score = 0;
  for (const [name, why] of Object.entries(RECOMMENDED)) {
    const value = response.headers.get(name);
    if (value) score++;
    console.log(`${value ? "✓" : "✗"} ${name.padEnd(26)} ${value ? "موجودة" : `غائبة (${why})`}`);
  }
  console.log(`النتيجة: ${score}/${Object.keys(RECOMMENDED).length}`);
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
