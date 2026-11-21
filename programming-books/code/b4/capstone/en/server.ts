import { createHash } from "node:crypto";
import { createServer } from "node:http";
import { apply, verify } from "./billing.ts";
import { Problem, book, list, one } from "./bookings.ts";
import { pool } from "./db.ts";

// find the salon by the hash of its key; there is no other way in
async function salonOf(key: string | string[] | undefined) {
  const hash = createHash("sha256")
    .update(String(key ?? ""))
    .digest("hex");
  const { rows } = await pool.query(
    "SELECT salon_id FROM api_keys WHERE hash = $1",
    [hash],
  );
  if (!rows[0]) throw new Problem(401, "Missing or unknown API key");
  return Number(rows[0].salon_id);
}

createServer(async (request, response) => {
  let body = "";
  for await (const chunk of request) body += chunk;
  const send = (status: number, data: unknown) =>
    response
      .writeHead(status, { "content-type": "application/json" })
      .end(JSON.stringify(data));
  try {
    const url = request.url ?? "";
    if (url === "/webhooks/billing") {
      verify(
        body,
        request.headers["x-signature"] as string | undefined,
      );
      return send(200, await apply(JSON.parse(body)));
    }
    const salon = await salonOf(request.headers["x-api-key"]);
    if (request.method === "POST" && url === "/bookings")
      return send(201, await book(salon, JSON.parse(body)));
    if (url === "/bookings") return send(200, await list(salon));
    if (url.startsWith("/bookings/"))
      return send(200, await one(salon, url.slice(10)));
    send(404, { message: "Not found" });
  } catch (error) {
    if (error instanceof Problem)
      return send(error.status, { message: error.message });
    console.error(error);
    send(500, { message: "Server error" });
  }
}).listen(4000);
