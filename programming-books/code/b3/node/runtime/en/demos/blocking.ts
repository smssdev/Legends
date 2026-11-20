import { createServer } from "node:http";
import { countPrimes } from "../src/primes.ts";

createServer((req, res) => {
  const url = new URL(req.url ?? "/", "http://localhost");
  if (url.pathname === "/primes") {
    const primes = countPrimes(Number(url.searchParams.get("limit"))); // blocks!
    return res.end(JSON.stringify({ primes }));
  }
  res.end(JSON.stringify({ message: "hello" }));
}).listen(3001);
