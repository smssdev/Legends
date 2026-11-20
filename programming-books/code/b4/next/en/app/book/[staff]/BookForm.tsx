"use client";

import { useActionState } from "react";
import type { Slot } from "@/lib/bookings";
import { time } from "@/lib/time";
import { bookAction, type BookState } from "../actions";

// a Client Component: it runs in the browser too, and only receives plain data
export function BookForm({ staffId, slots }: { staffId: number; slots: Slot[] }) {
  const [state, action, pending] = useActionState(bookAction, {} as BookState);
  return (
    <form action={action}>
      <input type="hidden" name="staffId" value={staffId} />
      <fieldset>
        <legend>Free times on 1 December</legend>
        {slots.map((slot) => (
          <label key={slot.starts_at}>
            <input type="radio" name="startsAt" value={slot.starts_at} required />
            {time.format(new Date(slot.starts_at))}
          </label>
        ))}
      </fieldset>
      <label>
        Your email
        <input name="email" type="email" required defaultValue={state.email} />
      </label>
      {state.error && <p role="alert">{state.error}</p>}
      <button disabled={pending}>{pending ? "Booking…" : "Book"}</button>
    </form>
  );
}
