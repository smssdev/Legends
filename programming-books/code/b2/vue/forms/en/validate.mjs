// vue/forms/en/contact-schema.ts
import * as z from "zod";
var contactSchema = z.object({
  name: z.string().trim().min(3, "Please write your full name (at least 3 letters)."),
  email: z.email("Please enter an email like name@example.com."),
  age: z.coerce.number().int("Age must be a whole number.").min(13, "You must be 13 or older."),
  message: z.string().trim().min(20, "Please write at least 20 characters.")
});

// vue/forms/en/validate.ts
var good = contactSchema.safeParse({
  name: "  Sara Khan ",
  email: "sara@example.com",
  age: "27",
  message: "I would like to order twenty copies for my class."
});
console.log("Valid:", good.success, good.data);
var bad = contactSchema.safeParse({ name: "S", email: "sara@", age: "9", message: "Hi" });
console.log("Invalid:", bad.success);
for (const issue of bad.error?.issues ?? []) {
  console.log(`  ${issue.path.join(".")}: ${issue.message}`);
}
