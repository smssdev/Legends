import { z } from "zod";

// كل إعداد من البيئة، ويُفحص مرة عند البدء: الناقص يوقف التطبيق هنا، لا عند أول طلب
export const config = z
  .object({
    DATABASE_URL: z.url(),
    REDIS_URL: z.url(),
    PORT: z.coerce.number().int().default(3000),
    LOG_LEVEL: z.enum(["silent", "error", "warn", "info", "debug"]).default("info"),
  })
  .parse(process.env);
