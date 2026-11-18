var __getOwnPropNames = Object.getOwnPropertyNames;
var __esm = (fn, res, err) => function __init() {
  if (err) throw err[0];
  try {
    return fn && (res = (0, fn[__getOwnPropNames(fn)[0]])(fn = 0)), res;
  } catch (e) {
    throw err = [e], e;
  }
};
var __commonJS = (cb, mod) => function __require() {
  try {
    return mod || (0, cb[__getOwnPropNames(cb)[0]])((mod = { exports: {} }).exports, mod), mod.exports;
  } catch (e) {
    throw mod = 0, e;
  }
};

// en/contact-schema.ts
import { z } from "zod";
var contactSchema;
var init_contact_schema = __esm({
  "en/contact-schema.ts"() {
    contactSchema = z.object({
      name: z.string().trim().min(3, "Please write your full name (at least 3 letters)."),
      email: z.email("Please enter an email like name@example.com."),
      age: z.coerce.number().int("Age must be a whole number.").min(13, "You must be 13 or older."),
      message: z.string().trim().min(20, "Please write at least 20 characters.")
    });
  }
});

// en/validate.ts
var require_validate = __commonJS({
  "en/validate.ts"() {
    init_contact_schema();
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
  }
});
export default require_validate();
