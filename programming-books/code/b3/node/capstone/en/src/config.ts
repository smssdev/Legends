import { z } from "zod";

// every setting comes from the environment, checked once at start-up: a missing one stops the app here, not at the first request
export const config = z
  .object({
    DATABASE_URL: z.url(),
    REDIS_URL: z.url(),
    PORT: z.coerce.number().int().default(3000),
    LOG_LEVEL: z.enum(["silent", "error", "warn", "info", "debug"]).default("info"),
  })
  .parse(process.env);
