import { buildApp } from "./app.ts";

const port = Number(process.env.PORT ?? 3000);
const app = await buildApp(`server ${port}`);
await app.listen({ port });
for (const signal of ["SIGINT", "SIGTERM"]) process.once(signal, () => app.close());
