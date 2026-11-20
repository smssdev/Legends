import { buildApp } from "./app.ts";

await buildApp().listen({ port: 3000 });
