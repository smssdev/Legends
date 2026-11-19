import * as z from "zod";

export const signupSchema = z
  .object({
    email: z.email("Please enter an email like name@example.com."),
    password: z.string().min(8, "At least 8 characters, with a number.").regex(/\d/, "At least 8 characters, with a number."),
    confirm: z.string(),
    terms: z.literal(true, "Please accept the terms to continue."),
  })
  .refine((data) => data.password === data.confirm, { message: "The passwords do not match.", path: ["confirm"] });
