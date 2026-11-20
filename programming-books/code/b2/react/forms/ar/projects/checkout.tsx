import { useState } from "react";
import { createRoot } from "react-dom/client";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { checkoutSchema, STEPS, type Checkout } from "./checkout-schema";
import { Field } from "../field";

const CITY_NAMES = { cairo: "القاهرة", alexandria: "الإسكندرية", giza: "الجيزة" };

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

  if (placed) return <p className="card done" role="status">تم الطلب!</p>;

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
        الخطوة {step + 1} من {STEPS.length}
      </p>

      {step === 0 && (
        <>
          <Field id="city" label="المدينة" error={errors.city?.message}>
            <select id="city" {...register("city")}>
              <option value="">اختر…</option>
              {Object.entries(CITY_NAMES).map(([value, name]) => (
                <option key={value} value={value}>
                  {name}
                </option>
              ))}
            </select>
          </Field>
          <Field id="street" label="الشارع ورقم المبنى" error={errors.street?.message}>
            <input id="street" autoComplete="street-address" {...register("street")} />
          </Field>
          <Field id="phone" label="رقم الجوال" error={errors.phone?.message}>
            <input id="phone" type="tel" autoComplete="tel" dir="ltr" {...register("phone")} />
          </Field>
        </>
      )}

      {step === 1 && (
        <fieldset className="field" style={{ border: 0, padding: 0 }}>
          <legend style={{ fontWeight: 600 }}>طريقة الدفع</legend>
          <label className="check">
            <input type="radio" value="cash" {...register("method")} /> الدفع عند الاستلام
          </label>
          <label className="check">
            <input type="radio" value="card" {...register("method")} /> بطاقة
          </label>
        </fieldset>
      )}

      {step === 2 && (
        <dl>
          <dt>التوصيل</dt>
          <dd>
            {CITY_NAMES[values.city]}، {values.street}، <span dir="ltr">{values.phone}</span>
          </dd>
          <dt>الدفع</dt>
          <dd>{values.method === "card" ? "بطاقة" : "الدفع عند الاستلام"}</dd>
        </dl>
      )}

      <div className="row">
        <button type="button" className="secondary" onClick={() => setStep(step - 1)} disabled={step === 0}>
          رجوع
        </button>
        {step < STEPS.length - 1 ? (
          <button key="next" type="button" onClick={next}>
            التالي
          </button>
        ) : (
          // مفتاح مختلف: زر جديد، لا زر «التالي» وقد صار زر إرسال
          <button key="submit" type="submit">
            أكّد الطلب
          </button>
        )}
      </div>
    </form>
  );
}

createRoot(document.getElementById("root")!).render(<CheckoutForm />);
