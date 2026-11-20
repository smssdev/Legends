"use server";

import { redirect } from "next/navigation";
import { signIn, startWebSession } from "@/lib/auth";

type State = { error?: string; email?: string };

export async function loginAction(
  _previous: State,
  form: FormData,
): Promise<State> {
  const email = String(form.get("email") ?? "").slice(0, 254);
  const token = await signIn(
    email,
    String(form.get("password") ?? "").slice(0, 128),
  );
  if (!token) return { error: "Email or password is wrong.", email };
  await startWebSession(token);
  redirect("/owner");
}
