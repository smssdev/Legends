"""Writes the examples of Book 2 (React edition), chapter "Forms and Validation", in English and Arabic.
Run: python3 make.py   Text placeholders are {w_…}.
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parents[1]))
import react_kit as kit  # noqa: E402

T = {
    "en": dict(
        title="Forms", w_comma=",", w_name="Full name", w_email="Email", w_age="Age", w_message="Message", w_send="Send",
        w_sending="Sending…", w_sent="Thank you! We will reply within two days.",
        w_e_name="Please write your full name (at least 3 letters).", w_e_email="Please enter an email like name@example.com.",
        w_e_age="You must be 13 or older.", w_e_message="Please write at least 20 characters.",
        w_e_agenum="Age must be a whole number.",
        w_password="Password", w_confirm="Confirm password", w_join="Create account", w_e_pass="At least 8 characters, with a number.",
        w_e_match="The passwords do not match.", w_taken="This email already has an account. Sign in instead?",
        w_created="Your account is ready.", w_terms="I accept the terms", w_e_terms="Please accept the terms to continue.",
        w_s1="Delivery", w_s2="Payment", w_s3="Review", w_city="City", w_street="Street and number", w_phone="Mobile number",
        w_method="Payment method", w_card="Card", w_cash="Cash on delivery", w_next="Next", w_back="Back", w_place="Place order",
        w_e_city="Please choose a city.", w_e_street="Please write the street and building number.",
        w_e_phone="Please enter an 11-digit Egyptian mobile number.", w_step="Step", w_of="of", w_placed="Order placed!",
        w_cairo="Cairo", w_alex="Alexandria", w_giza="Giza", w_choose="Choose…",
        w_c1="One schema: the rules, the error messages, and (with z.infer) the TypeScript type",
        w_c2="The same schema checks data that arrives at the server",
        w_c3="Pretend server: this email is already taken",
        w_c4="A different key: a new button, not the Next button turned into a submit button",
        w_ok="Valid:", w_bad="Invalid:", w_sample_name="Sara Khan", w_sample_msg="I would like to order twenty copies for my class.",
    ),
    "ar": dict(
        title="النماذج", w_comma="،", w_name="الاسم الكامل", w_email="البريد الإلكتروني", w_age="العمر", w_message="الرسالة", w_send="أرسل",
        w_sending="جارٍ الإرسال…", w_sent="شكراً لك! سنرد خلال يومين.",
        w_e_name="اكتب اسمك الكامل (3 أحرف على الأقل).", w_e_email="اكتب بريداً مثل name@example.com",
        w_e_age="يجب أن يكون عمرك 13 سنة أو أكثر.", w_e_message="اكتب 20 حرفاً على الأقل.",
        w_e_agenum="يجب أن يكون العمر رقماً صحيحاً.",
        w_password="كلمة المرور", w_confirm="أكّد كلمة المرور", w_join="أنشئ الحساب", w_e_pass="8 أحرف على الأقل، وفيها رقم.",
        w_e_match="كلمتا المرور غير متطابقتين.", w_taken="لهذا البريد حساب بالفعل. هل تريد تسجيل الدخول؟",
        w_created="حسابك جاهز.", w_terms="أوافق على الشروط", w_e_terms="وافق على الشروط لتتابع.",
        w_s1="التوصيل", w_s2="الدفع", w_s3="المراجعة", w_city="المدينة", w_street="الشارع ورقم المبنى", w_phone="رقم الجوال",
        w_method="طريقة الدفع", w_card="بطاقة", w_cash="الدفع عند الاستلام", w_next="التالي", w_back="رجوع", w_place="أكّد الطلب",
        w_e_city="اختر مدينة.", w_e_street="اكتب الشارع ورقم المبنى.",
        w_e_phone="اكتب رقم جوال مصرياً من 11 رقماً.", w_step="الخطوة", w_of="من", w_placed="تم الطلب!",
        w_cairo="القاهرة", w_alex="الإسكندرية", w_giza="الجيزة", w_choose="اختر…",
        w_c1="مخطط واحد: القواعد، ورسائل الخطأ، ونوع TypeScript (مع z.infer)",
        w_c2="والمخطط نفسه يفحص البيانات التي تصل إلى الخادم",
        w_c3="خادم وهمي: هذا البريد مستخدم بالفعل",
        w_c4="مفتاح مختلف: زر جديد، لا زر «التالي» وقد صار زر إرسال",
        w_ok="سليم:", w_bad="غير سليم:", w_sample_name="سارة خان", w_sample_msg="أريد أن أطلب عشرين نسخة لطلاب فصلي.",
    ),
}

CSS = """form, .card { background: white; border-radius: 14px; padding: 14px 16px; box-shadow: 0 2px 10px rgb(67 56 202 / 0.1); max-width: 440px; }
.field { margin-bottom: 10px; }
label { display: block; font-weight: 600; margin-bottom: 3px; }
input, textarea, select { font: inherit; width: 100%; padding: 7px 10px; border: 2px solid #c7d2fe; border-radius: 10px; background: white; }
input[aria-invalid="true"], textarea[aria-invalid="true"], select[aria-invalid="true"] { border-color: #b91c1c; }
.error { color: #b91c1c; font-size: 0.9rem; margin: 3px 0 0; }
.check { display: flex; gap: 8px; align-items: center; font-weight: 400; }
.check input { width: auto; }
.done { color: #047857; font-weight: 700; }
.steps { display: flex; gap: 6px; margin-bottom: 12px; list-style: none; padding: 0; }
.steps li { flex: 1; text-align: center; padding: 4px; border-radius: 999px; background: #eef2ff; color: #5b5873; font-size: 0.9rem; }
.steps li[aria-current="step"] { background: #4338ca; color: white; font-weight: 700; }
.row { display: flex; gap: 8px; justify-content: space-between; }
"""

PLAIN = {}
NODE = {}
BROWSER = {}

PLAIN["contact-schema.ts"] = '''import { z } from "zod";

// {w_c1}
export const contactSchema = z.object({
  name: z.string().trim().min(3, "{w_e_name}"),
  email: z.email("{w_e_email}"),
  age: z.coerce.number<string>().int("{w_e_agenum}").min(13, "{w_e_age}"),
  message: z.string().trim().min(20, "{w_e_message}"),
});

export type Contact = z.infer<typeof contactSchema>;
'''

NODE["validate.ts"] = '''import { contactSchema } from "./contact-schema";

// {w_c2}
const good = contactSchema.safeParse({
  name: "  {w_sample_name} ",
  email: "sara@example.com",
  age: "27",
  message: "{w_sample_msg}",
});
console.log("{w_ok}", good.success, good.data);

const bad = contactSchema.safeParse({ name: "S", email: "sara@", age: "9", message: "Hi" });
console.log("{w_bad}", bad.success);
for (const issue of bad.error?.issues ?? []) {
  console.log(`  ${issue.path.join(".")}: ${issue.message}`);
}
'''

BROWSER["contact.tsx"] = ('''import { useState } from "react";
import { createRoot } from "react-dom/client";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import type { z } from "zod";
import { contactSchema, type Contact } from "./contact-schema";
import { Field } from "./field";

function ContactForm() {
  const [sent, setSent] = useState(false);
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<z.input<typeof contactSchema>, unknown, Contact>({
    resolver: zodResolver(contactSchema),
    mode: "onTouched",
  });

  async function onSubmit(data: Contact) {
    await new Promise((resolve) => setTimeout(resolve, 500)); // send to the server here
    console.log(data);
    setSent(true);
  }

  if (sent) return <p className="card done" role="status">{w_sent}</p>;

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate>
      <Field id="name" label="{w_name}" error={errors.name?.message}>
        <input id="name" autoComplete="name" {...register("name")} />
      </Field>
      <Field id="email" label="{w_email}" error={errors.email?.message}>
        <input id="email" type="email" autoComplete="email" dir="ltr" {...register("email")} />
      </Field>
      <Field id="age" label="{w_age}" error={errors.age?.message}>
        <input id="age" inputMode="numeric" {...register("age")} />
      </Field>
      <Field id="message" label="{w_message}" error={errors.message?.message}>
        <textarea id="message" rows={3} {...register("message")} />
      </Field>
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? "{w_sending}" : "{w_send}"}
      </button>
    </form>
  );
}

createRoot(document.getElementById("root")!).render(<ContactForm />);
''', CSS)

PLAIN["field.tsx"] = '''import { cloneElement, isValidElement, type ReactElement } from "react";

type FieldProps = {
  id: string;
  label: string;
  error?: string;
  children: ReactElement<Record<string, unknown>>;
};

// One place for the label, the error and the accessibility links between them
export function Field({ id, label, error, children }: FieldProps) {
  const errorId = `${id}-error`;
  const input = isValidElement(children)
    ? cloneElement(children, {
        "aria-invalid": error ? true : undefined,
        "aria-describedby": error ? errorId : undefined,
      })
    : children;
  return (
    <div className="field">
      <label htmlFor={id}>{label}</label>
      {input}
      {error && (
        <p className="error" id={errorId}>
          {error}
        </p>
      )}
    </div>
  );
}
'''

# ---------------------------------------------------------------- projects
PLAIN["projects/signup-schema.ts"] = '''import { z } from "zod";

export const signupSchema = z
  .object({
    email: z.email("{w_e_email}"),
    password: z.string().min(8, "{w_e_pass}").regex(/\\d/, "{w_e_pass}"),
    confirm: z.string(),
    terms: z.literal(true, "{w_e_terms}"),
  })
  .refine((data) => data.password === data.confirm, {
    message: "{w_e_match}",
    path: ["confirm"],
  });

export type Signup = z.infer<typeof signupSchema>;
'''

BROWSER["projects/signup.tsx"] = ('''import { useState } from "react";
import { createRoot } from "react-dom/client";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { signupSchema, type Signup } from "./signup-schema";
import { Field } from "../field";

// {w_c3}
async function createAccount(data: Signup): Promise<{ ok: true } | { ok: false; field: "email"; message: string }> {
  await new Promise((resolve) => setTimeout(resolve, 400));
  if (data.email === "sara@example.com") return { ok: false, field: "email", message: "{w_taken}" };
  return { ok: true };
}

function SignupForm() {
  const [done, setDone] = useState(false);
  const {
    register,
    handleSubmit,
    setError,
    formState: { errors, isSubmitting },
  } = useForm<Signup>({ resolver: zodResolver(signupSchema), mode: "onTouched" });

  async function onSubmit(data: Signup) {
    const result = await createAccount(data);
    if (!result.ok) {
      setError(result.field, { message: result.message }, { shouldFocus: true });
      return;
    }
    setDone(true);
  }

  if (done) return <p className="card done" role="status">{w_created}</p>;

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate>
      <Field id="email" label="{w_email}" error={errors.email?.message}>
        <input id="email" type="email" autoComplete="email" dir="ltr" {...register("email")} />
      </Field>
      <Field id="password" label="{w_password}" error={errors.password?.message}>
        <input id="password" type="password" autoComplete="new-password" dir="ltr" {...register("password")} />
      </Field>
      <Field id="confirm" label="{w_confirm}" error={errors.confirm?.message}>
        <input id="confirm" type="password" autoComplete="new-password" dir="ltr" {...register("confirm")} />
      </Field>
      <div className="field">
        <label className="check">
          <input type="checkbox" aria-invalid={errors.terms ? true : undefined} {...register("terms")} />
          {w_terms}
        </label>
        {errors.terms && <p className="error">{errors.terms.message}</p>}
      </div>
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? "{w_sending}" : "{w_join}"}
      </button>
    </form>
  );
}

createRoot(document.getElementById("root")!).render(<SignupForm />);
''', CSS)

PLAIN["projects/checkout-schema.ts"] = '''import { z } from "zod";

export const delivery = z.object({
  city: z.enum(["cairo", "alexandria", "giza"], "{w_e_city}"),
  street: z.string().trim().min(5, "{w_e_street}"),
  phone: z.string().regex(/^01[0125]\\d{8}$/, "{w_e_phone}"),
});

export const payment = z.object({
  method: z.enum(["card", "cash"]),
});

export const checkoutSchema = delivery.extend(payment.shape);
export type Checkout = z.infer<typeof checkoutSchema>;

// Each step lists the fields it is responsible for
export const STEPS = [
  { title: "{w_s1}", fields: ["city", "street", "phone"] },
  { title: "{w_s2}", fields: ["method"] },
  { title: "{w_s3}", fields: [] },
] as const;
'''

BROWSER["projects/checkout.tsx"] = ('''import { useState } from "react";
import { createRoot } from "react-dom/client";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { checkoutSchema, STEPS, type Checkout } from "./checkout-schema";
import { Field } from "../field";

const CITY_NAMES = { cairo: "{w_cairo}", alexandria: "{w_alex}", giza: "{w_giza}" };

function CheckoutForm() {
  const [step, setStep] = useState(0);
  const [placed, setPlaced] = useState(false);
  const form = useForm<Checkout>({
    resolver: zodResolver(checkoutSchema),
    defaultValues: { method: "cash" },
    mode: "onTouched",
  });
  const { register, trigger, getValues, handleSubmit, formState } = form;
  const errors = formState.errors;

  async function next() {
    const ok = await trigger([...STEPS[step]!.fields], { shouldFocus: true });
    if (ok) setStep(step + 1);
  }

  if (placed) return <p className="card done" role="status">{w_placed}</p>;

  const values = getValues();
  return (
    <form onSubmit={handleSubmit(() => setPlaced(true))} noValidate>
      <ol className="steps">
        {STEPS.map((s, i) => (
          <li key={s.title} aria-current={i === step ? "step" : undefined}>
            {s.title}
          </li>
        ))}
      </ol>
      <p className="sr-only">
        {w_step} {step + 1} {w_of} {STEPS.length}
      </p>

      {step === 0 && (
        <>
          <Field id="city" label="{w_city}" error={errors.city?.message}>
            <select id="city" {...register("city")}>
              <option value="">{w_choose}</option>
              {Object.entries(CITY_NAMES).map(([value, name]) => (
                <option key={value} value={value}>
                  {name}
                </option>
              ))}
            </select>
          </Field>
          <Field id="street" label="{w_street}" error={errors.street?.message}>
            <input id="street" autoComplete="street-address" {...register("street")} />
          </Field>
          <Field id="phone" label="{w_phone}" error={errors.phone?.message}>
            <input id="phone" type="tel" autoComplete="tel" dir="ltr" {...register("phone")} />
          </Field>
        </>
      )}

      {step === 1 && (
        <fieldset className="field" style={{ border: 0, padding: 0 }}>
          <legend style={{ fontWeight: 600 }}>{w_method}</legend>
          <label className="check">
            <input type="radio" value="cash" {...register("method")} /> {w_cash}
          </label>
          <label className="check">
            <input type="radio" value="card" {...register("method")} /> {w_card}
          </label>
        </fieldset>
      )}

      {step === 2 && (
        <dl>
          <dt>{w_s1}</dt>
          <dd>
            {CITY_NAMES[values.city]}{w_comma} {values.street}{w_comma} <span dir="ltr">{values.phone}</span>
          </dd>
          <dt>{w_s2}</dt>
          <dd>{values.method === "card" ? "{w_card}" : "{w_cash}"}</dd>
        </dl>
      )}

      <div className="row">
        <button type="button" className="secondary" onClick={() => setStep(step - 1)} disabled={step === 0}>
          {w_back}
        </button>
        {step < STEPS.length - 1 ? (
          <button key="next" type="button" onClick={next}>
            {w_next}
          </button>
        ) : (
          // {w_c4}
          <button key="submit" type="submit">
            {w_place}
          </button>
        )}
      </div>
    </form>
  );
}

createRoot(document.getElementById("root")!).render(<CheckoutForm />);
''', CSS + ".sr-only { position: absolute; width: 1px; height: 1px; overflow: hidden; clip-path: inset(50%); }\ndt { font-weight: 700; } dd { margin: 0 0 8px; }\n")

kit.generate(HERE, T, plain=PLAIN, node_files=NODE, browser_files=BROWSER)
