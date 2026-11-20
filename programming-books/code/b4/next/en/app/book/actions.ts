"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";
import { book } from "@/lib/bookings";

const Input = z.object({
  staffId: z.coerce.number().int().positive(),
  startsAt: z.iso.datetime(),
  email: z.email().max(254),
});

export type BookState = { error?: string; email?: string };

// a Server Action: called by the form, on the server, with the checks of any API
export async function bookAction(
  _previous: BookState,
  form: FormData,
): Promise<BookState> {
  const parsed = Input.safeParse(Object.fromEntries(form));
  const email = String(form.get("email") ?? "");
  if (!parsed.success)
    return { error: "Please choose a time and write a valid email.", email };
  const result = await book(parsed.data);
  // the free times changed either way: render the page again with the answer
  revalidatePath(`/book/${parsed.data.staffId}`);
  if (!result.ok)
    return {
      error: "Sorry, that time was just taken. Please choose another.",
      email,
    };
  redirect(`/booking/${result.id}`);
}
