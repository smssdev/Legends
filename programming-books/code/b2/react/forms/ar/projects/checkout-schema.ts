import { z } from "zod";

export const delivery = z.object({
  city: z.enum(["cairo", "alexandria", "giza"], "اختر مدينة."),
  street: z.string().trim().min(5, "اكتب الشارع ورقم المبنى."),
  phone: z.string().regex(/^01[0125]\d{8}$/, "اكتب رقم جوال مصرياً من 11 رقماً."),
});

export const payment = z.object({
  method: z.enum(["card", "cash"]),
});

export const checkoutSchema = delivery.extend(payment.shape);
export type Checkout = z.infer<typeof checkoutSchema>;

// Each step lists the fields it is responsible for
export const STEPS = [
  { title: "التوصيل", fields: ["city", "street", "phone"] },
  { title: "الدفع", fields: ["method"] },
  { title: "المراجعة", fields: [] },
] as const;
