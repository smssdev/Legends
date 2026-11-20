import { z } from "zod";

// process.env holds strings only: coerce and check them once, at start-up
const Env = z.object({
  PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  LOG_LEVEL: z.enum(["debug", "info", "warn", "error"]).default("info"),
  ALLOWED_ORIGINS: z
    .string()
    .transform((list) => list.split(",").map((origin) => origin.trim()))
    .pipe(z.array(z.url())),
});

const parsed = Env.safeParse(process.env);
if (!parsed.success) {
  console.error("Invalid configuration:\n" + z.prettifyError(parsed.error));
  process.exit(1);
}

// read-only: nothing can change the configuration later
export const config = Object.freeze(parsed.data);
export type Config = typeof config;
