"use server"; // A Server Action: a function that runs on the server, called by a form

import { z } from "zod";

const schema = z.object({
  name: z.string().trim().min(1, "Please write your name."),
  message: z.string().trim().min(10, "Please write at least 10 characters."),
});

export type ContactState = { errors?: Partial<Record<"name" | "message", string>>; done?: string };

export async function sendMessage(_previous: ContactState, form: FormData): Promise<ContactState> {
  const parsed = schema.safeParse(Object.fromEntries(form));
  if (!parsed.success) {
    const errors: ContactState["errors"] = {};
    for (const issue of parsed.error.issues) errors[issue.path[0] as "name" | "message"] ??= issue.message;
    return { errors };
  }
  // Save the message, send an email… on the server, with secrets that never reach the browser
  return { done: `Thank you, {name}! We will reply soon.`.replace("{name}", parsed.data.name) };
}
