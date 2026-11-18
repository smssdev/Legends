import { useState } from "react";
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

  if (sent) return <p className="card done" role="status">شكراً لك! سنرد خلال يومين.</p>;

  return (
    <form onSubmit={handleSubmit(onSubmit)} noValidate>
      <Field id="name" label="الاسم الكامل" error={errors.name?.message}>
        <input id="name" autoComplete="name" {...register("name")} />
      </Field>
      <Field id="email" label="البريد الإلكتروني" error={errors.email?.message}>
        <input id="email" type="email" autoComplete="email" dir="ltr" {...register("email")} />
      </Field>
      <Field id="age" label="العمر" error={errors.age?.message}>
        <input id="age" inputMode="numeric" {...register("age")} />
      </Field>
      <Field id="message" label="الرسالة" error={errors.message?.message}>
        <textarea id="message" rows={3} {...register("message")} />
      </Field>
      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? "جارٍ الإرسال…" : "أرسل"}
      </button>
    </form>
  );
}

createRoot(document.getElementById("root")!).render(<ContactForm />);
