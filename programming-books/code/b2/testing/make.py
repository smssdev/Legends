"""Writes the examples of Book 2, chapter "Testing: Unit, Component and End-to-End", in English and Arabic.
Run: python3 make.py   The book runs Vitest and Playwright on these files and shows their real output.
Text placeholders are {w_…}.
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
import react_kit as kit  # noqa: E402

T = {
    "en": dict(
        w_title="Testing", lang="en", w_shop="Bit's shop", w_currency="EGP",
        w_t_format="formats a price with two decimals and the currency",
        w_t_total="adds the lines of a cart", w_t_empty="returns 0 for an empty cart",
        w_t_coupon="applies the coupon %s to a total of %s: %s", w_t_unknown="ignores an unknown coupon",
        w_t_neg="refuses a negative quantity", w_t_debounce="calls the function once, after the user stops typing",
        w_email="Email", w_password="Password", w_signin="Sign in", w_signing="Signing in…",
        w_e_email="Please enter your email.", w_e_wrong="Wrong email or password.", w_welcome="Welcome back,",
        w_name="Sara", w_t_errors="shows an error when the email is empty", w_t_success="signs in and greets the user",
        w_t_wrong="shows the server's error for a wrong password", w_t_e2e="a user can sign in",
        w_t_e2e_wrong="a wrong password keeps the user on the form",
        w_t_pw_weak="rates %s as %s", w_weak="weak", w_ok="okay", w_strong="strong",
        w_tasks="Tasks", w_task="New task", w_add="Add", w_left="left", w_t_add="adds a task from the form",
        w_t_toggle="ticks a task off and updates the count", w_t_blank="does not add an empty task",
        w_read="Read chapter 11", w_write="Write a test",
        w_t_axe="the sign-in page has no accessibility violations",
        w_t_keyboard="the whole sign-in works with the keyboard only",
        w_c_mock="A fake server: no network, always the same answers",
        w_c_role="Find things the way users do: by role and by name",
    ),
    "ar": dict(
        w_title="الاختبار", lang="ar", w_shop="متجر بِت", w_currency="جنيهاً",
        w_t_format="ينسّق السعر بمنزلتين عشريتين والعملة",
        w_t_total="يجمع أسطر السلة", w_t_empty="يُرجع 0 للسلة الفارغة",
        w_t_coupon="يطبّق الكوبون %s على مجموع %s: %s", w_t_unknown="يتجاهل الكوبون المجهول",
        w_t_neg="يرفض الكمية السالبة", w_t_debounce="يستدعي الدالة مرة واحدة، بعد أن يتوقف المستخدم عن الكتابة",
        w_email="البريد الإلكتروني", w_password="كلمة المرور", w_signin="سجّل الدخول", w_signing="جارٍ الدخول…",
        w_e_email="اكتب بريدك الإلكتروني.", w_e_wrong="البريد أو كلمة المرور غير صحيحة.", w_welcome="أهلاً بعودتك يا",
        w_name="سارة", w_t_errors="يعرض خطأً حين يكون البريد فارغاً", w_t_success="يسجّل الدخول ويرحّب بالمستخدم",
        w_t_wrong="يعرض خطأ الخادم لكلمة مرور خاطئة", w_t_e2e="يستطيع المستخدم تسجيل الدخول",
        w_t_e2e_wrong="كلمة المرور الخاطئة تُبقي المستخدم في النموذج",
        w_t_pw_weak="يقيّم %s بأنها %s", w_weak="ضعيفة", w_ok="مقبولة", w_strong="قوية",
        w_tasks="المهام", w_task="مهمة جديدة", w_add="أضف", w_left="متبقية", w_t_add="يضيف مهمة من النموذج",
        w_t_toggle="يعلّم المهمة منجزة ويحدّث العدد", w_t_blank="لا يضيف مهمة فارغة",
        w_read="اقرأ الفصل 11", w_write="اكتب اختباراً",
        w_t_axe="صفحة الدخول بلا مخالفات إتاحة",
        w_t_keyboard="الدخول كله يعمل بلوحة المفاتيح وحدها",
        w_c_mock="خادم وهمي: بلا شبكة، والردود نفسها دائماً",
        w_c_role="جِد الأشياء كما يجدها المستخدمون: بالدور وبالاسم",
    ),
}

PLAIN, BROWSER = {}, {}

PLAIN["vitest.config.ts"] = '''import { defineConfig } from "vitest/config";

export default defineConfig({
  test: {
    environment: "jsdom", // a pretend browser, so components can render
    setupFiles: ["./vitest.setup.ts"],
    include: ["**/*.test.{ts,tsx}"],
  },
});
'''
PLAIN["vitest.setup.ts"] = '''import "@testing-library/jest-dom/vitest";
import { cleanup } from "@testing-library/react";
import { afterEach } from "vitest";

afterEach(cleanup);
'''

PLAIN["price.ts"] = '''export type Line = { price: number; quantity: number };

const COUPONS: Record<string, number> = { WELCOME10: 10, SPRING25: 25 };

export function formatPrice(value: number): string {
  return `${value.toFixed(2)} {w_currency}`;
}

export function cartTotal(lines: Line[], coupon?: string): number {
  if (lines.some((l) => l.quantity < 0)) throw new RangeError("quantity must not be negative");
  const sum = lines.reduce((total, l) => total + l.price * l.quantity, 0);
  const percent = coupon ? (COUPONS[coupon] ?? 0) : 0;
  return Math.round(sum * (100 - percent)) / 100;
}
'''

PLAIN["price.test.ts"] = '''import { describe, expect, it } from "vitest";
import { cartTotal, formatPrice } from "./price";

describe("formatPrice", () => {
  it("{w_t_format}", () => {
    expect(formatPrice(8)).toBe("8.00 {w_currency}");
    expect(formatPrice(19.5)).toBe("19.50 {w_currency}");
  });
});

describe("cartTotal", () => {
  const lines = [
    { price: 25, quantity: 1 },
    { price: 8, quantity: 2 },
  ];

  it("{w_t_total}", () => {
    expect(cartTotal(lines)).toBe(41);
  });

  it("{w_t_empty}", () => {
    expect(cartTotal([])).toBe(0);
  });

  it.each([
    ["WELCOME10", 41, 36.9],
    ["SPRING25", 41, 30.75],
  ])("{w_t_coupon}", (coupon, _total, expected) => {
    expect(cartTotal(lines, coupon)).toBe(expected);
  });

  it("{w_t_unknown}", () => {
    expect(cartTotal(lines, "FREE100")).toBe(41);
  });

  it("{w_t_neg}", () => {
    expect(() => cartTotal([{ price: 8, quantity: -1 }])).toThrow(RangeError);
  });
});
'''

PLAIN["debounce.ts"] = '''export function debounce<A extends unknown[]>(fn: (...args: A) => void, ms: number) {
  let timer: ReturnType<typeof setTimeout> | undefined;
  return (...args: A) => {
    clearTimeout(timer);
    timer = setTimeout(() => fn(...args), ms);
  };
}
'''

PLAIN["debounce.test.ts"] = '''import { expect, it, vi } from "vitest";
import { debounce } from "./debounce";

it("{w_t_debounce}", () => {
  vi.useFakeTimers(); // the test controls the clock: no real waiting
  const search = vi.fn(); // a fake function that records its calls
  const debounced = debounce(search, 300);

  debounced("b");
  debounced("bi");
  debounced("bit");
  expect(search).not.toHaveBeenCalled();

  vi.advanceTimersByTime(300);
  expect(search).toHaveBeenCalledTimes(1);
  expect(search).toHaveBeenCalledWith("bit");
  vi.useRealTimers();
});
'''

PLAIN["react/api.ts"] = '''// {w_c_mock}
export async function signIn(email: string, password: string): Promise<{ name: string }> {
  await new Promise((resolve) => setTimeout(resolve, 50));
  if (email === "sara@example.com" && password === "bit2026code") return { name: "{w_name}" };
  throw new Error("{w_e_wrong}");
}
'''

PLAIN["react/LoginForm.tsx"] = '''import { useState, type FormEvent } from "react";
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
    if (!email) return setError("{w_e_email}");
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

  if (user) return <h2>{w_welcome} {user}!</h2>;

  return (
    <form onSubmit={submit} noValidate aria-describedby={error ? "login-error" : undefined}>
      <label htmlFor="email">{w_email}</label>
      <input id="email" name="email" type="email" autoComplete="email" dir="ltr" />
      <label htmlFor="password">{w_password}</label>
      <input id="password" name="password" type="password" autoComplete="current-password" dir="ltr" />
      {error && (
        <p id="login-error" role="alert">
          {error}
        </p>
      )}
      <button type="submit" disabled={busy}>
        {busy ? "{w_signing}" : "{w_signin}"}
      </button>
    </form>
  );
}
'''

PLAIN["react/LoginForm.test.tsx"] = '''import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { LoginForm } from "./LoginForm";

describe("LoginForm", () => {
  it("{w_t_errors}", async () => {
    const user = userEvent.setup();
    render(<LoginForm />);
    // {w_c_role}
    await user.click(screen.getByRole("button", { name: "{w_signin}" }));
    expect(screen.getByRole("alert")).toHaveTextContent("{w_e_email}");
  });

  it("{w_t_success}", async () => {
    const user = userEvent.setup();
    const signIn = vi.fn().mockResolvedValue({ name: "{w_name}" });
    render(<LoginForm signIn={signIn} />);

    await user.type(screen.getByLabelText("{w_email}"), "sara@example.com");
    await user.type(screen.getByLabelText("{w_password}"), "bit2026code");
    await user.click(screen.getByRole("button", { name: "{w_signin}" }));

    expect(await screen.findByRole("heading", { name: "{w_welcome} {w_name}!" })).toBeInTheDocument();
    expect(signIn).toHaveBeenCalledWith("sara@example.com", "bit2026code");
  });

  it("{w_t_wrong}", async () => {
    const user = userEvent.setup();
    render(<LoginForm />);
    await user.type(screen.getByLabelText("{w_email}"), "sara@example.com");
    await user.type(screen.getByLabelText("{w_password}"), "wrong");
    await user.click(screen.getByRole("button", { name: "{w_signin}" }));
    expect(await screen.findByRole("alert")).toHaveTextContent("{w_e_wrong}");
  });
});
'''

FORM_CSS = """form { background: white; border-radius: 14px; padding: 14px 16px; max-width: 380px; display: flex; flex-direction: column; gap: 4px; }
label { font-weight: 600; margin-top: 6px; }
input { font: inherit; padding: 7px 10px; border: 2px solid #c7d2fe; border-radius: 10px; }
[role="alert"] { color: #b91c1c; margin: 6px 0 0; }
button { margin-top: 10px; align-self: flex-start; }
"""

BROWSER["react/login.tsx"] = ('''import { createRoot } from "react-dom/client";
import { LoginForm } from "./LoginForm";

createRoot(document.getElementById("root")!).render(
  <main>
    <h1>{w_shop}</h1>
    <LoginForm />
  </main>,
);
''', FORM_CSS)

PLAIN["playwright.config.ts"] = '''import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./e2e",
  reporter: "list",
  // Start the site before the tests, and stop it after. In a Vite project: "npm run build && npm run preview".
  webServer: { command: "node ../../serve.mjs 4173", url: "http://localhost:4173/vendor/react.js", reuseExistingServer: true },
  use: { baseURL: "http://localhost:4173/testing/{lang}/", browserName: "chromium" },
});
'''

PLAIN["e2e/login.spec.ts"] = '''import { expect, test } from "@playwright/test";

const page_url = "react/login.html"; // relative to baseURL in playwright.config.ts

test("{w_t_e2e}", async ({ page }) => {
  await page.goto(page_url);
  await page.getByLabel("{w_email}").fill("sara@example.com");
  await page.getByLabel("{w_password}").fill("bit2026code");
  await page.getByRole("button", { name: "{w_signin}" }).click();
  await expect(page.getByRole("heading", { name: "{w_welcome} {w_name}!" })).toBeVisible();
});

test("{w_t_e2e_wrong}", async ({ page }) => {
  await page.goto(page_url);
  await page.getByLabel("{w_email}").fill("sara@example.com");
  await page.getByLabel("{w_password}").fill("nope");
  await page.getByRole("button", { name: "{w_signin}" }).click();
  await expect(page.getByRole("alert")).toHaveText("{w_e_wrong}");
  await expect(page.getByLabel("{w_email}")).toHaveValue("sara@example.com");
});
'''

# ---------------------------------------------------------------- projects
PLAIN["projects/password.ts"] = '''export type Strength = "weak" | "okay" | "strong";

export function strength(password: string): Strength {
  let points = 0;
  if (password.length >= 8) points++;
  if (password.length >= 12) points++;
  if (/\\d/.test(password)) points++;
  if (/[A-Z]/.test(password)) points++;
  if (points <= 1) return "weak";
  if (points <= 3) return "okay";
  return "strong";
}
'''

PLAIN["projects/password.test.ts"] = '''import { expect, it } from "vitest";
import { strength } from "./password";

it.each([
  ["", "weak"],
  ["cat", "weak"],
  ["sunshine", "weak"],
  ["sunshine2026", "okay"],
  ["Sunshine2026", "strong"],
  ["correct horse battery staple", "okay"],
] as const)("{w_t_pw_weak}", (password, expected) => {
  expect(strength(password)).toBe(expected);
});
'''

PLAIN["react/projects/Tasks.tsx"] = '''import { useState, type FormEvent } from "react";

type Task = { id: number; text: string; done: boolean };

export function Tasks({ initial = [] }: { initial?: Task[] }) {
  const [tasks, setTasks] = useState(initial);
  const [text, setText] = useState("");
  const left = tasks.filter((t) => !t.done).length;

  function add(event: FormEvent) {
    event.preventDefault();
    if (!text.trim()) return;
    setTasks((all) => [...all, { id: all.length + 1, text: text.trim(), done: false }]);
    setText("");
  }

  return (
    <section aria-labelledby="tasks-title">
      <h2 id="tasks-title">{w_tasks}</h2>
      <form onSubmit={add}>
        <input aria-label="{w_task}" value={text} onChange={(e) => setText(e.target.value)} />
        <button type="submit">{w_add}</button>
      </form>
      <ul>
        {tasks.map((t) => (
          <li key={t.id}>
            <label>
              <input
                type="checkbox"
                checked={t.done}
                onChange={() => setTasks((all) => all.map((x) => (x.id === t.id ? { ...x, done: !x.done } : x)))}
              />
              {t.text}
            </label>
          </li>
        ))}
      </ul>
      <p role="status">
        {left} {w_left}
      </p>
    </section>
  );
}
'''

PLAIN["react/projects/Tasks.test.tsx"] = '''import { expect, it } from "vitest";
import { render, screen } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { Tasks } from "./Tasks";

it("{w_t_add}", async () => {
  const user = userEvent.setup();
  render(<Tasks />);
  await user.type(screen.getByRole("textbox", { name: "{w_task}" }), "{w_read}{Enter}");
  expect(screen.getByRole("checkbox", { name: "{w_read}" })).not.toBeChecked();
  expect(screen.getByRole("status")).toHaveTextContent("1 {w_left}");
  expect(screen.getByRole("textbox", { name: "{w_task}" })).toHaveValue("");
});

it("{w_t_toggle}", async () => {
  const user = userEvent.setup();
  render(<Tasks initial={[{ id: 1, text: "{w_read}", done: false }, { id: 2, text: "{w_write}", done: false }]} />);
  await user.click(screen.getByRole("checkbox", { name: "{w_read}" }));
  expect(screen.getByRole("checkbox", { name: "{w_read}" })).toBeChecked();
  expect(screen.getByRole("status")).toHaveTextContent("1 {w_left}");
});

it("{w_t_blank}", async () => {
  const user = userEvent.setup();
  render(<Tasks />);
  await user.type(screen.getByRole("textbox", { name: "{w_task}" }), "   {Enter}");
  expect(screen.queryAllByRole("checkbox")).toHaveLength(0);
});
'''

PLAIN["e2e/a11y.spec.ts"] = '''import { expect, test } from "@playwright/test";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const page_url = "react/login.html";

test("{w_t_axe}", async ({ page }) => {
  await page.goto(page_url);
  await page.addScriptTag({ path: require.resolve("axe-core/axe.min.js") });
  // @ts-expect-error axe is added to the page by the script tag above
  const violations = await page.evaluate(() => axe.run().then((r) => r.violations.map((v) => v.id)));
  expect(violations).toEqual([]);
});

test("{w_t_keyboard}", async ({ page }) => {
  await page.goto(page_url);
  await page.keyboard.press("Tab");
  await page.keyboard.type("sara@example.com");
  await page.keyboard.press("Tab");
  await page.keyboard.type("bit2026code");
  await page.keyboard.press("Enter");
  await expect(page.getByRole("heading", { name: "{w_welcome} {w_name}!" })).toBeVisible();
});
'''

kit.generate(HERE, T, plain=PLAIN, browser_files=BROWSER, title_key="w_title")
