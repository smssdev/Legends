import { z } from "zod";

// لا يحمل process.env إلا نصوصاً: حوّلها وافحصها مرة واحدة عند البدء
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
  console.error("الإعدادات غير صالحة:\n" + z.prettifyError(parsed.error));
  process.exit(1);
}

// للقراءة فقط: لا شيء يستطيع تغيير الإعدادات لاحقاً
export const config = Object.freeze(parsed.data);
export type Config = typeof config;
