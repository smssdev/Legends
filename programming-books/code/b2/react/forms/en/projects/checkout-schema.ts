import { z } from "zod";

export const delivery = z.object({
  city: z.enum(["cairo", "alexandria", "giza"], "Please choose a city."),
  street: z.string().trim().min(5, "Please write the street and building number."),
  phone: z.string().regex(/^01[0125]\d{8}$/, "Please enter an 11-digit Egyptian mobile number."),
});

export const payment = z.object({
  method: z.enum(["card", "cash"]),
});

export const checkoutSchema = delivery.extend(payment.shape);
export type Checkout = z.infer<typeof checkoutSchema>;

// Each step lists the fields it is responsible for
export const STEPS = [
  { title: "Delivery", fields: ["city", "street", "phone"] },
  { title: "Payment", fields: ["method"] },
  { title: "Review", fields: [] },
] as const;
