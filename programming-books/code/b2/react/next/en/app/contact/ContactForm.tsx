"use client";

import { useActionState } from "react";
import { sendMessage, type ContactState } from "./actions";

export function ContactForm() {
  const [state, action, pending] = useActionState<ContactState, FormData>(sendMessage, {});
  if (state.done) return <p className="done" role="status">{state.done}</p>;
  return (
    <form action={action} noValidate>
      <label htmlFor="name">Name</label>
      <input id="name" name="name" autoComplete="name" aria-describedby="name-error" />
      {state.errors?.name && <p className="error" id="name-error">{state.errors.name}</p>}
      <label htmlFor="message">Message</label>
      <textarea id="message" name="message" rows={3} aria-describedby="message-error" />
      {state.errors?.message && <p className="error" id="message-error">{state.errors.message}</p>}
      <p>
        <button type="submit" disabled={pending}>{pending ? "Sending…" : "Send"}</button>
      </p>
    </form>
  );
}
