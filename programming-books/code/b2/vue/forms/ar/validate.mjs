// vue/forms/ar/contact-schema.ts
import * as z from "zod";
var contactSchema = z.object({
  name: z.string().trim().min(3, "\u0627\u0643\u062A\u0628 \u0627\u0633\u0645\u0643 \u0627\u0644\u0643\u0627\u0645\u0644 (3 \u0623\u062D\u0631\u0641 \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644)."),
  email: z.email("\u0627\u0643\u062A\u0628 \u0628\u0631\u064A\u062F\u0627\u064B \u0645\u062B\u0644 name@example.com"),
  age: z.coerce.number().int("\u064A\u062C\u0628 \u0623\u0646 \u064A\u0643\u0648\u0646 \u0627\u0644\u0639\u0645\u0631 \u0631\u0642\u0645\u0627\u064B \u0635\u062D\u064A\u062D\u0627\u064B.").min(13, "\u064A\u062C\u0628 \u0623\u0646 \u064A\u0643\u0648\u0646 \u0639\u0645\u0631\u0643 13 \u0633\u0646\u0629 \u0623\u0648 \u0623\u0643\u062B\u0631."),
  message: z.string().trim().min(20, "\u0627\u0643\u062A\u0628 20 \u062D\u0631\u0641\u0627\u064B \u0639\u0644\u0649 \u0627\u0644\u0623\u0642\u0644.")
});

// vue/forms/ar/validate.ts
var good = contactSchema.safeParse({
  name: "  \u0633\u0627\u0631\u0629 \u062E\u0627\u0646 ",
  email: "sara@example.com",
  age: "27",
  message: "\u0623\u0631\u064A\u062F \u0623\u0646 \u0623\u0637\u0644\u0628 \u0639\u0634\u0631\u064A\u0646 \u0646\u0633\u062E\u0629 \u0644\u0637\u0644\u0627\u0628 \u0641\u0635\u0644\u064A."
});
console.log("\u0633\u0644\u064A\u0645:", good.success, good.data);
var bad = contactSchema.safeParse({ name: "S", email: "sara@", age: "9", message: "Hi" });
console.log("\u063A\u064A\u0631 \u0633\u0644\u064A\u0645:", bad.success);
for (const issue of bad.error?.issues ?? []) {
  console.log(`  ${issue.path.join(".")}: ${issue.message}`);
}
