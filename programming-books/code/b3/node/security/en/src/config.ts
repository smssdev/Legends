import { z } from "zod";

// checked once, at start-up: a missing or wrong setting stops the server at once
const Config = z.object({
  DATABASE_URL: z.url(),
  ALLOWED_ORIGIN: z.url(),
  PORT: z.coerce.number().int().default(3000),
});

const parsed = Config.safeParse(process.env);
if (!parsed.success) {
  console.error("Invalid configuration:");
  for (const issue of parsed.error.issues) {
    console.error(`  ${issue.path.join(".")}: ${issue.message}`);
  }
  process.exit(1);
}
export const config = parsed.data;
