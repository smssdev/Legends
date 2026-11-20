import { contactSchema } from "./contact-schema";

// The same schema checks data that arrives at the server
const good = contactSchema.safeParse({
  name: "  Sara Khan ",
  email: "sara@example.com",
  age: "27",
  message: "I would like to order twenty copies for my class.",
});
console.log("Valid:", good.success, good.data);

const bad = contactSchema.safeParse({ name: "S", email: "sara@", age: "9", message: "Hi" });
console.log("Invalid:", bad.success);
for (const issue of bad.error?.issues ?? []) {
  console.log(`  ${issue.path.join(".")}: ${issue.message}`);
}
