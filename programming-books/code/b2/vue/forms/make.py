"""Writes the examples of Book 2 (Vue edition), chapter "Forms and Validation", in English and Arabic.
Run: python3 make.py   Text placeholders are {w_…}. Every file is type-checked with vue-tsc.

The forms use v-model, one zod schema per form, and a small useForm composable written in the chapter.
"""
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parents[1]))
import vue_kit as kit  # noqa: E402

T = {
    "en": dict(
        w_title="Forms", w_comma=",", w_name="Full name", w_email="Email", w_age="Age", w_message="Message", w_send="Send",
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
        w_c_form="A small form composable: values, errors, touched fields and submitting, around one schema",
        w_c_show="Show a field's error only after the user has left it once, or tried to submit",
        w_c_focus="Move the focus to the first wrong field, so keyboard and screen-reader users find it",
        w_c_server="Errors only the server knows go under the right field, like any other",
        w_c_slot="The slot receives the attributes that link the input to its label and its error",
        w_ok="Valid:", w_bad="Invalid:", w_sample_name="Sara Khan", w_sample_msg="I would like to order twenty copies for my class.",
    ),
    "ar": dict(
        w_title="النماذج", w_comma="،", w_name="الاسم الكامل", w_email="البريد الإلكتروني", w_age="العمر", w_message="الرسالة", w_send="أرسل",
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
        w_c_form="composable صغير للنماذج: القيم والأخطاء والحقول الملموسة والإرسال، حول مخطط واحد",
        w_c_show="اعرض خطأ الحقل فقط بعد أن يغادره المستخدم مرة، أو يحاول الإرسال",
        w_c_focus="انقل التركيز إلى أول حقل خاطئ، ليجده مستخدمو لوحة المفاتيح وقارئ الشاشة",
        w_c_server="الأخطاء التي لا يعرفها إلا الخادم تذهب تحت الحقل الصحيح، كغيرها",
        w_c_slot="تستلم الفتحة السمات التي تربط الحقل بعنوانه وخطئه",
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
dt { font-weight: 700; } dd { margin: 0 0 8px; }
"""

PLAIN, NODE, BROWSER = {}, {}, {}

PLAIN["tsconfig.json"] = '''{
  "compilerOptions": {
    "strict": true, "noUncheckedIndexedAccess": true, "target": "es2024", "module": "esnext",
    "moduleResolution": "bundler", "lib": ["es2024", "dom", "dom.iterable"], "types": ["node"], "noEmit": true,
    "skipLibCheck": true
  },
  "include": ["**/*.ts", "**/*.vue"]
}
'''

PLAIN["contact-schema.ts"] = '''import * as z from "zod";

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

PLAIN["useForm.ts"] = '''import { computed, nextTick, reactive, ref, watch } from "vue";
import type * as z from "zod";

type Errors<K extends PropertyKey> = Partial<Record<K, string>>;

// {w_c_form}
export function useForm<S extends z.ZodObject>(schema: S, initial: z.input<S>) {
  type Key = keyof z.input<S> & string;
  const values = reactive({ ...initial }) as z.input<S>;
  const allErrors = ref<Errors<Key>>({});
  const touched = reactive(new Set<string>());
  const submitted = ref(false);
  const submitting = ref(false);

  function check(): z.output<S> | undefined {
    const result = schema.safeParse(values);
    const next: Errors<Key> = {};
    for (const issue of result.success ? [] : result.error.issues) next[issue.path[0] as Key] ??= issue.message;
    allErrors.value = next;
    return result.success ? result.data : undefined;
  }
  watch(values, check, { deep: true });

  // {w_c_show}
  const errors = computed(() => {
    const shown: Errors<Key> = {};
    for (const [key, message] of Object.entries(allErrors.value) as [Key, string][]) {
      if (submitted.value || touched.has(key)) shown[key] = message;
    }
    return shown;
  });

  async function focusFirstError() {
    await nextTick();
    document.querySelector<HTMLElement>("[aria-invalid='true']")?.focus();
  }

  /** Checks some fields only (one step of a longer form), and shows their errors. */
  function checkFields(fields: readonly Key[]) {
    fields.forEach((f) => touched.add(f));
    check();
    const ok = fields.every((f) => !allErrors.value[f]);
    if (!ok) void focusFirstError();
    return ok;
  }

  function handleSubmit(send: (data: z.output<S>) => Promise<Errors<Key> | void>) {
    return async () => {
      submitted.value = true;
      const data = check();
      if (!data) return focusFirstError();
      submitting.value = true;
      try {
        const fromServer = await send(data);
        // {w_c_server}
        if (fromServer) {
          allErrors.value = fromServer;
          void focusFirstError();
        }
      } finally {
        submitting.value = false;
      }
    };
  }

  return { values, errors, submitting, checkFields, handleSubmit, blur: (field: Key) => touched.add(field) };
}
'''

PLAIN["FormField.vue"] = '''<script setup lang="ts">
defineProps<{ id: string; label: string; error?: string | undefined }>();
</script>

<template>
  <div class="field">
    <label :for="id">{{ label }}</label>
    <!-- {w_c_slot} -->
    <slot :id="id" :aria-invalid="!!error" :aria-describedby="error ? `${id}-error` : undefined" />
    <p v-if="error" :id="`${id}-error`" class="error">{{ error }}</p>
  </div>
</template>
'''

PLAIN["ContactForm.vue"] = '''<script setup lang="ts">
import { ref } from "vue";
import { contactSchema } from "./contact-schema";
import FormField from "./FormField.vue";
import { useForm } from "./useForm";

const { values, errors, submitting, blur, handleSubmit } = useForm(contactSchema, {
  name: "",
  email: "",
  age: "",
  message: "",
});
const sent = ref(false);

const submit = handleSubmit(async (contact) => {
  // contact.age is a number here, not text: the schema converted it
  await new Promise((resolve) => setTimeout(resolve, 600)); // send it to the server
  sent.value = true;
});
</script>

<template>
  <p v-if="sent" class="card done" role="status">{w_sent}</p>
  <form v-else novalidate @submit.prevent="submit">
    <FormField id="name" v-slot="attrs" label="{w_name}" :error="errors.name">
      <input v-bind="attrs" v-model="values.name" autocomplete="name" @blur="blur('name')" />
    </FormField>
    <FormField id="email" v-slot="attrs" label="{w_email}" :error="errors.email">
      <input v-bind="attrs" v-model="values.email" type="email" autocomplete="email" dir="ltr" @blur="blur('email')" />
    </FormField>
    <FormField id="age" v-slot="attrs" label="{w_age}" :error="errors.age">
      <input v-bind="attrs" v-model="values.age" inputmode="numeric" @blur="blur('age')" />
    </FormField>
    <FormField id="message" v-slot="attrs" label="{w_message}" :error="errors.message">
      <textarea v-bind="attrs" v-model="values.message" rows="3" @blur="blur('message')" />
    </FormField>
    <button type="submit" :disabled="submitting">{{ submitting ? "{w_sending}" : "{w_send}" }}</button>
  </form>
</template>
'''
BROWSER["contact.ts"] = ('''import { createApp } from "vue";
import ContactForm from "./ContactForm.vue";

createApp(ContactForm).mount("#app");
''', CSS)

# ---------------------------------------------------------------- projects
PLAIN["projects/signup-schema.ts"] = '''import * as z from "zod";

export const signupSchema = z
  .object({
    email: z.email("{w_e_email}"),
    password: z.string().min(8, "{w_e_pass}").regex(/\\d/, "{w_e_pass}"),
    confirm: z.string(),
    terms: z.literal(true, "{w_e_terms}"),
  })
  .refine((data) => data.password === data.confirm, { message: "{w_e_match}", path: ["confirm"] });
'''
PLAIN["projects/SignupForm.vue"] = '''<script setup lang="ts">
import { ref } from "vue";
import * as z from "zod";
import FormField from "../FormField.vue";
import { useForm } from "../useForm";
import { signupSchema } from "./signup-schema";

// refine() wraps the object, so useForm receives the inner object and the full schema checks the rest
const fields = z.object({ ...signupSchema.shape, terms: z.boolean() });
const { values, errors, submitting, blur, handleSubmit } = useForm(fields, {
  email: "",
  password: "",
  confirm: "",
  terms: false,
});
const created = ref(false);

const submit = handleSubmit(async (data) => {
  const result = signupSchema.safeParse(data);
  if (!result.success) {
    return Object.fromEntries(result.error.issues.map((i) => [String(i.path[0]), i.message]));
  }
  await new Promise((resolve) => setTimeout(resolve, 400));
  // {w_c3}
  if (data.email === "sara@example.com") return { email: "{w_taken}" };
  created.value = true;
});
</script>

<template>
  <p v-if="created" class="card done" role="status">{w_created}</p>
  <form v-else novalidate @submit.prevent="submit">
    <FormField id="email" v-slot="attrs" label="{w_email}" :error="errors.email">
      <input v-bind="attrs" v-model="values.email" type="email" autocomplete="email" dir="ltr" @blur="blur('email')" />
    </FormField>
    <FormField id="password" v-slot="attrs" label="{w_password}" :error="errors.password">
      <input v-bind="attrs" v-model="values.password" type="password" autocomplete="new-password" dir="ltr" @blur="blur('password')" />
    </FormField>
    <FormField id="confirm" v-slot="attrs" label="{w_confirm}" :error="errors.confirm">
      <input v-bind="attrs" v-model="values.confirm" type="password" autocomplete="new-password" dir="ltr" @blur="blur('confirm')" />
    </FormField>
    <div class="field">
      <label class="check"><input v-model="values.terms" type="checkbox" :aria-invalid="!!errors.terms" /> {w_terms}</label>
      <p v-if="errors.terms" class="error">{{ errors.terms }}</p>
    </div>
    <button type="submit" :disabled="submitting">{w_join}</button>
  </form>
</template>
'''
BROWSER["projects/signup.ts"] = ('''import { createApp } from "vue";
import SignupForm from "./SignupForm.vue";

createApp(SignupForm).mount("#app");
''', CSS)

PLAIN["projects/checkout-schema.ts"] = '''import * as z from "zod";

export const checkoutSchema = z.object({
  city: z.enum(["cairo", "alexandria", "giza"], "{w_e_city}"),
  street: z.string().trim().min(5, "{w_e_street}"),
  phone: z.string().regex(/^01[0125]\\d{8}$/, "{w_e_phone}"),
  method: z.enum(["card", "cash"]),
});

// Each step lists the fields it is responsible for
export const STEPS = [
  { title: "{w_s1}", fields: ["city", "street", "phone"] },
  { title: "{w_s2}", fields: ["method"] },
  { title: "{w_s3}", fields: [] },
] as const;
'''
PLAIN["projects/CheckoutForm.vue"] = '''<script setup lang="ts">
import { ref } from "vue";
import FormField from "../FormField.vue";
import { useForm } from "../useForm";
import { checkoutSchema, STEPS } from "./checkout-schema";

const { values, errors, blur, checkFields, handleSubmit } = useForm(checkoutSchema, {
  city: "" as "cairo",
  street: "",
  phone: "",
  method: "cash",
});
const step = ref(0);
const placed = ref(false);
const cities = { cairo: "{w_cairo}", alexandria: "{w_alex}", giza: "{w_giza}" };

function next() {
  if (checkFields(STEPS[step.value]!.fields)) step.value++;
}
const place = handleSubmit(async () => {
  placed.value = true;
});
</script>

<template>
  <p v-if="placed" class="card done" role="status">{w_placed}</p>
  <form v-else novalidate @submit.prevent="place">
    <ol class="steps">
      <li v-for="(s, i) in STEPS" :key="s.title" :aria-current="i === step ? 'step' : undefined">{{ s.title }}</li>
    </ol>
    <template v-if="step === 0">
      <FormField id="city" v-slot="attrs" label="{w_city}" :error="errors.city">
        <select v-bind="attrs" v-model="values.city" @blur="blur('city')">
          <option value="" disabled>{w_choose}</option>
          <option v-for="(name, value) in cities" :key="value" :value="value">{{ name }}</option>
        </select>
      </FormField>
      <FormField id="street" v-slot="attrs" label="{w_street}" :error="errors.street">
        <input v-bind="attrs" v-model="values.street" autocomplete="street-address" @blur="blur('street')" />
      </FormField>
      <FormField id="phone" v-slot="attrs" label="{w_phone}" :error="errors.phone">
        <input v-bind="attrs" v-model="values.phone" type="tel" autocomplete="tel" dir="ltr" @blur="blur('phone')" />
      </FormField>
    </template>
    <fieldset v-else-if="step === 1" class="field">
      <legend>{w_method}</legend>
      <label class="check"><input v-model="values.method" type="radio" value="card" /> {w_card}</label>
      <label class="check"><input v-model="values.method" type="radio" value="cash" /> {w_cash}</label>
    </fieldset>
    <dl v-else>
      <dt>{w_s1}</dt>
      <dd>{{ cities[values.city] }}{w_comma} {{ values.street }} · <span dir="ltr">{{ values.phone }}</span></dd>
      <dt>{w_s2}</dt>
      <dd>{{ values.method === "card" ? "{w_card}" : "{w_cash}" }}</dd>
    </dl>
    <div class="row">
      <button type="button" class="secondary" :disabled="step === 0" @click="step--">{w_back}</button>
      <button v-if="step < STEPS.length - 1" key="next" type="button" @click="next">{w_next}</button>
      <button v-else key="place" type="submit">{w_place}</button>
    </div>
  </form>
</template>
'''
BROWSER["projects/checkout.ts"] = ('''import { createApp } from "vue";
import CheckoutForm from "./CheckoutForm.vue";

createApp(CheckoutForm).mount("#app");
''', CSS + "fieldset { border: 0; padding: 0; } legend { font-weight: 600; margin-bottom: 6px; }\n")

kit.generate(HERE, T, plain=PLAIN, node_files=NODE, browser_files=BROWSER)

check = HERE.parents[1] / "vue-check" / "node_modules" / ".bin" / "vue-tsc"
for lang in T:
    r = subprocess.run([str(check), "-p", str(HERE / lang / "tsconfig.json")], capture_output=True, text=True)
    if r.returncode:
        raise SystemExit(f"vue-tsc ({lang}):\n{r.stdout}{r.stderr}")
print("types ok")
