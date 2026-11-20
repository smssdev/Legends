"use client";

import { useActionState } from "react";
import type { Slot } from "@/lib/bookings";
import { time } from "@/lib/time";
import { bookAction, type BookState } from "../actions";

// مكوّن عميل: يعمل في المتصفح أيضاً، ولا يستقبل إلا بيانات عادية
export function BookForm({ staffId, slots }: { staffId: number; slots: Slot[] }) {
  const [state, action, pending] = useActionState(bookAction, {} as BookState);
  return (
    <form action={action}>
      <input type="hidden" name="staffId" value={staffId} />
      <fieldset>
        <legend>الأوقات المتاحة يوم 1 ديسمبر</legend>
        {slots.map((slot) => (
          <label key={slot.starts_at}>
            <input type="radio" name="startsAt" value={slot.starts_at} required />
            {time.format(new Date(slot.starts_at))}
          </label>
        ))}
      </fieldset>
      <label>
        بريدك الإلكتروني
        <input name="email" type="email" required defaultValue={state.email} />
      </label>
      {state.error && <p role="alert">{state.error}</p>}
      <button disabled={pending}>{pending ? "جارٍ الحجز…" : "احجز"}</button>
    </form>
  );
}
