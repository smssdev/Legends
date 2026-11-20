"use client";

import { useActionState } from "react";
import { loginAction } from "./actions";

export function LoginForm() {
  const [state, action, pending] = useActionState(loginAction, {});
  return (
    <form action={action}>
      <label>
        Email
        <input name="email" type="email" required defaultValue={state.email} />
      </label>
      <label>
        Password
        <input name="password" type="password" required />
      </label>
      {state.error && <p role="alert">{state.error}</p>}
      <button disabled={pending}>{pending ? "Signing in…" : "Sign in"}</button>
    </form>
  );
}
