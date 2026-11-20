import { z } from "zod";

// مخطط واحد: القواعد، ورسائل الخطأ، ونوع TypeScript (مع z.infer)
export const contactSchema = z.object({
  name: z.string().trim().min(3, "اكتب اسمك الكامل (3 أحرف على الأقل)."),
  email: z.email("اكتب بريداً مثل name@example.com"),
  age: z.coerce.number<string>().int("يجب أن يكون العمر رقماً صحيحاً.").min(13, "يجب أن يكون عمرك 13 سنة أو أكثر."),
  message: z.string().trim().min(20, "اكتب 20 حرفاً على الأقل."),
});

export type Contact = z.infer<typeof contactSchema>;
