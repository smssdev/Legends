import { buildApp } from "./app.ts";

const port = Number(process.env.PORT ?? 3000);
const app = await buildApp({ rateLimit: Number(process.env.RATE_LIMIT ?? 100) });
await app.listen({ port });
console.log(`Listening on http://localhost:${port}`);
for (const signal of ["SIGINT", "SIGTERM"]) process.once(signal, () => app.close());
