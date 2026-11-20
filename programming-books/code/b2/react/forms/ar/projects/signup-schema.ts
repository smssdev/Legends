import { z } from "zod";

export const signupSchema = z
  .object({
    email: z.email("اكتب بريداً مثل name@example.com"),
    password: z.string().min(8, "8 أحرف على الأقل، وفيها رقم.").regex(/\d/, "8 أحرف على الأقل، وفيها رقم."),
    confirm: z.string(),
    terms: z.literal(true, "وافق على الشروط لتتابع."),
  })
  .refine((data) => data.password === data.confirm, {
    message: "كلمتا المرور غير متطابقتين.",
    path: ["confirm"],
  });

export type Signup = z.infer<typeof signupSchema>;
