import { useState, type FormEvent } from "react";
import { signIn as defaultSignIn } from "./api";

type Props = { signIn?: typeof defaultSignIn };

export function LoginForm({ signIn = defaultSignIn }: Props) {
  const [error, setError] = useState("");
  const [user, setUser] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const data = new FormData(event.currentTarget);
    const email = String(data.get("email") ?? "").trim();
    if (!email) return setError("اكتب بريدك الإلكتروني.");
    setBusy(true);
    try {
      const result = await signIn(email, String(data.get("password") ?? ""));
      setUser(result.name);
    } catch (e) {
      setError((e as Error).message);
    } finally {
      setBusy(false);
    }
  }

  if (user) return <h2>أهلاً بعودتك يا {user}!</h2>;

  return (
    <form onSubmit={submit} noValidate aria-describedby={error ? "login-error" : undefined}>
      <label htmlFor="email">البريد الإلكتروني</label>
      <input id="email" name="email" type="email" autoComplete="email" dir="ltr" />
      <label htmlFor="password">كلمة المرور</label>
      <input id="password" name="password" type="password" autoComplete="current-password" dir="ltr" />
      {error && (
        <p id="login-error" role="alert">
          {error}
        </p>
      )}
      <button type="submit" disabled={busy}>
        {busy ? "جارٍ الدخول…" : "سجّل الدخول"}
      </button>
    </form>
  );
}
