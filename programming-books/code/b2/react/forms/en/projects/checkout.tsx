import { useState } from "react";
import { createRoot } from "react-dom/client";
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import { checkoutSchema, STEPS, type Checkout } from "./checkout-schema";
import { Field } from "../field";

const CITY_NAMES = { cairo: "Cairo", alexandria: "Alexandria", giza: "Giza" };

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

  if (placed) return <p className="card done" role="status">Order placed!</p>;

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
        Step {step + 1} of {STEPS.length}
      </p>

      {step === 0 && (
        <>
          <Field id="city" label="City" error={errors.city?.message}>
            <select id="city" {...register("city")}>
              <option value="">Choose…</option>
              {Object.entries(CITY_NAMES).map(([value, name]) => (
                <option key={value} value={value}>
                  {name}
                </option>
              ))}
            </select>
          </Field>
          <Field id="street" label="Street and number" error={errors.street?.message}>
            <input id="street" autoComplete="street-address" {...register("street")} />
          </Field>
          <Field id="phone" label="Mobile number" error={errors.phone?.message}>
            <input id="phone" type="tel" autoComplete="tel" dir="ltr" {...register("phone")} />
          </Field>
        </>
      )}

      {step === 1 && (
        <fieldset className="field" style={{ border: 0, padding: 0 }}>
          <legend style={{ fontWeight: 600 }}>Payment method</legend>
          <label className="check">
            <input type="radio" value="cash" {...register("method")} /> Cash on delivery
          </label>
          <label className="check">
            <input type="radio" value="card" {...register("method")} /> Card
          </label>
        </fieldset>
      )}

      {step === 2 && (
        <dl>
          <dt>Delivery</dt>
          <dd>
            {CITY_NAMES[values.city]}, {values.street}, <span dir="ltr">{values.phone}</span>
          </dd>
          <dt>Payment</dt>
          <dd>{values.method === "card" ? "Card" : "Cash on delivery"}</dd>
        </dl>
      )}

      <div className="row">
        <button type="button" className="secondary" onClick={() => setStep(step - 1)} disabled={step === 0}>
          Back
        </button>
        {step < STEPS.length - 1 ? (
          <button key="next" type="button" onClick={next}>
            Next
          </button>
        ) : (
          // A different key: a new button, not the Next button turned into a submit button
          <button key="submit" type="submit">
            Place order
          </button>
        )}
      </div>
    </form>
  );
}

createRoot(document.getElementById("root")!).render(<CheckoutForm />);
