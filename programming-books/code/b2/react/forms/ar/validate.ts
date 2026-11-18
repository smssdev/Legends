import { contactSchema } from "./contact-schema";

// والمخطط نفسه يفحص البيانات التي تصل إلى الخادم
const good = contactSchema.safeParse({
  name: "  سارة خان ",
  email: "sara@example.com",
  age: "27",
  message: "أريد أن أطلب عشرين نسخة لطلاب فصلي.",
});
console.log("سليم:", good.success, good.data);

const bad = contactSchema.safeParse({ name: "S", email: "sara@", age: "9", message: "Hi" });
console.log("غير سليم:", bad.success);
for (const issue of bad.error?.issues ?? []) {
  console.log(`  ${issue.path.join(".")}: ${issue.message}`);
}
