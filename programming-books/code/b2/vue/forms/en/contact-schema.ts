import * as z from "zod";

// One schema: the rules, the error messages, and (with z.infer) the TypeScript type
export const contactSchema = z.object({
  name: z.string().trim().min(3, "Please write your full name (at least 3 letters)."),
  email: z.email("Please enter an email like name@example.com."),
  age: z.coerce.number<string>().int("Age must be a whole number.").min(13, "You must be 13 or older."),
  message: z.string().trim().min(20, "Please write at least 20 characters."),
});

export type Contact = z.infer<typeof contactSchema>;
