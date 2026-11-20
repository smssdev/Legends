import { createServer } from "node:http";
import type { IncomingMessage, ServerResponse } from "node:http";
import { createHash } from "node:crypto";

type Product = { id: number; name: string; price: number };
type Headers = Record<string, string>;

const products: Product[] = [
  { id: 1, name: "Robot kit", price: 45000 },
  { id: 2, name: "Spare wheels", price: 6000 },
  { id: 3, name: "Battery pack", price: 12500 },
];
// the web app that may call this API from a browser
const ORIGINS = ["http://localhost:5173"];
const MAX_BODY = 1024; // bytes

function send(res: ServerResponse, status: number, body?: unknown,
              headers: Headers = {}) {
  const text = body === undefined ? "" : JSON.stringify(body);
  res.writeHead(status, {
    ...(text && { "Content-Type": "application/json; charset=utf-8" }),
    "Content-Length": String(Buffer.byteLength(text)), // bytes, not characters
    ...headers,
  });
  res.end(text);
}

function fail(res: ServerResponse, status: number, code: string,
              message: string, extra = {}, headers: Headers = {}) {
  send(res, status, { error: { code, message, ...extra } }, headers);
}

async function handle(req: IncomingMessage, res: ServerResponse) {
  const url = new URL(req.url ?? "/", "http://localhost");
  const origin = req.headers.origin;
  if (origin && ORIGINS.includes(origin)) {
    res.setHeader("Access-Control-Allow-Origin", origin);
    res.setHeader("Vary", "Origin");
  }

  if (req.method === "OPTIONS") {
    return send(res, 204, undefined, {
      "Access-Control-Allow-Methods": "GET, POST",
      "Access-Control-Allow-Headers": "Content-Type",
      "Access-Control-Max-Age": "600",
    });
  }

  if (url.pathname === "/products") {
    if (req.method === "GET" || req.method === "HEAD") {
      const max = Number(url.searchParams.get("max_price") ?? Infinity);
      const list = products.filter((p) => p.price <= max);
      const hash = createHash("md5").update(JSON.stringify(list)).digest("hex");
      const etag = `"${hash.slice(0, 16)}"`;
      if (req.headers["if-none-match"] === etag) {
        return send(res, 304, undefined, { ETag: etag });
      }
      return send(res, 200, list, { ETag: etag, "Cache-Control": "no-cache" });
    }
    if (req.method === "POST") return create(req, res);
    return fail(res, 405, "method_not_allowed", "Use GET or POST here", {},
                { Allow: "GET, HEAD, POST" });
  }

  const one = url.pathname.match(/^\/products\/(\d+)$/);
  if (one && req.method === "GET") {
    const product = products.find((p) => p.id === Number(one[1]));
    if (!product) return fail(res, 404, "not_found", "No product with this id");
    return send(res, 200, product);
  }
  return fail(res, 404, "not_found", "Nothing here");
}

async function readBody(req: IncomingMessage): Promise<string> {
  let size = 0;
  const parts: Buffer[] = [];
  for await (const chunk of req) {
    size += chunk.length;
    if (size > MAX_BODY) throw new Error("too_large");
    parts.push(chunk);
  }
  return Buffer.concat(parts).toString("utf8");
}

async function create(req: IncomingMessage, res: ServerResponse) {
  if (!req.headers["content-type"]?.startsWith("application/json")) {
    return fail(res, 415, "unsupported_media_type", "Send JSON");
  }
  let data: { name?: unknown; price?: unknown };
  try {
    data = JSON.parse(await readBody(req));
  } catch (e) {
    if (e instanceof Error && e.message === "too_large") {
      return fail(res, 413, "too_large", "At most 1 KB");
    }
    return fail(res, 400, "bad_json", "The body is not valid JSON");
  }

  const { name, price } = data;
  const errors: Record<string, string> = {};
  if (typeof name !== "string" || !name.trim()) errors.name = "Required";
  if (typeof price !== "number" || !Number.isInteger(price) || price <= 0) {
    errors.price = "A whole number of piastres above 0";
  }
  if (Object.keys(errors).length) {
    return fail(res, 422, "invalid", "Check the fields", { fields: errors });
  }

  const product = {
    id: products.length + 1,
    name: (name as string).trim(),
    price: price as number,
  };
  products.push(product);
  send(res, 201, product, { Location: `/products/${product.id}` });
}

const server = createServer((req, res) => {
  const start = performance.now();
  res.on("finish", () => {
    const ms = Math.round(performance.now() - start);
    console.log(`${req.method} ${req.url} ${res.statusCode} ${ms}ms`);
  });
  handle(req, res).catch((error) => {
    console.error(error); // the details stay in the server's log
    if (!res.headersSent) {
      fail(res, 500, "server_error", "Something went wrong on our side");
    }
  });
});
server.requestTimeout = 10_000; // a client that sends too slowly is cut off
server.listen(3000, () => console.log("Listening on http://localhost:3000"));
