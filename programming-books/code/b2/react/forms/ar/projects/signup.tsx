import { useState } from "react";
import { createRoot } from "react-dom/client";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { signupSchema, type Signup } from "./signup-schema";
import { Field } from "../field";

// خادم وهمي: هذا البريد مستخدم بالفعل
async function createAccount(data: Signup): Promise<{ ok: true } | { ok: false; field: "email"; message: string }> {
  await new Promise((resolve) => setTimeout(resolve, 400));
  if (data.email === "sara@example.com") return { ok: false, field: "email", message: "لهذا البريد حساب بالفعل. هل تريد تسجيل الدخول؟" };
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

  if (done) return <p className="card done" role="status">حسابك جاهز.</p>;

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate>
      <Field id="email" label="البريد الإلكتروني" error={errors.email?.message}>
        <input id="email" type="email" autoComplete="email" dir="ltr" {...register("email")} />
      </Field>
      <Field id="password" label="كلمة المرور" error={errors.password?.message}>
        <input id="password" type="password" autoComplete="new-password" dir="ltr" {...register("password")} />
      </Field>
      <Field id="confirm" label="أكّد كلمة المرور" error={errors.confirm?.message}>
        <input id="confirm" type="password" autoComplete="new-password" dir="ltr" {...register("confirm")} />
      </Field>
      <div className="field">
        <label className="check">
          <input type="checkbox" aria-invalid={errors.terms ? true : undefined} {...register("terms")} />
          أوافق على الشروط
        </label>
        {errors.terms && <p className="error">{errors.terms.message}</p>}
      </div>
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? "جارٍ الإرسال…" : "أنشئ الحساب"}
      </button>
    </form>
  );
}

createRoot(document.getElementById("root")!).render(<SignupForm />);
