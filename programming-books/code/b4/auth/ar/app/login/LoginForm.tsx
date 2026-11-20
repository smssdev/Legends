"use client";

import { useActionState } from "react";
import { loginAction } from "./actions";

export function LoginForm() {
  const [state, action, pending] = useActionState(loginAction, {});
  return (
    <form action={action}>
      <label>
        البريد الإلكتروني
        <input name="email" type="email" required defaultValue={state.email} />
      </label>
      <label>
        كلمة المرور
        <input name="password" type="password" required />
      </label>
      {state.error && <p role="alert">{state.error}</p>}
      <button disabled={pending}>{pending ? "جارٍ الدخول…" : "تسجيل الدخول"}</button>
    </form>
  );
}
