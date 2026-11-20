// A tiny static server for the book's examples (like `vite preview` in a real project).
// Usage: node serve.mjs [port]   Serves this folder, so pages can load /vendor/react.js.
import { createServer } from "node:http";
import { createReadStream, existsSync, statSync } from "node:fs";
import { extname, join, normalize } from "node:path";

const root = new URL(".", import.meta.url).pathname;
const types = { ".html": "text/html", ".js": "text/javascript", ".css": "text/css", ".svg": "image/svg+xml", ".json": "application/json" };
const port = Number(process.argv[2] ?? 4173);

createServer((req, res) => {
  const path = normalize(join(root, decodeURIComponent(new URL(req.url, "http://x").pathname)));
  if (!path.startsWith(root) || !existsSync(path) || statSync(path).isDirectory()) {
    res.writeHead(404).end();
    return;
  }
  res.writeHead(200, { "Content-Type": `${types[extname(path)] ?? "application/octet-stream"}; charset=utf-8` });
  createReadStream(path).pipe(res);
}).listen(port, () => console.log(`http://localhost:${port}`));
