"""Writes the examples of Book 2 (React edition), chapter "Global State without Pain", in English and Arabic.
Run: python3 make.py   Text placeholders are {w_…}.
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parents[1]))
import react_kit as kit  # noqa: E402

T = {
    "en": dict(
        title="Global state", w_name="Sara", w_shop="Bit's shop", w_hello="Hello,", w_guest="Guest", w_signin="Sign in", w_signout="Sign out",
        w_light="Light", w_dark="Dark", w_theme="Theme", w_book="Code from Zero", w_mug="Bit mug", w_cap="Bit cap",
        w_add="Add", w_cart="Cart", w_items="items", w_total="Total", w_currency="EGP", w_clear="Empty the cart",
        w_empty="The cart is empty.", w_profile="Your profile", w_member="Member since 2025",
        w_saved="Saved to your list", w_added="added to the cart", w_removed="Removed", w_undo="Undo", w_close="Close",
        w_notices="Notifications",
        w_c1="Any component under the provider can read the user, however deep",
        w_c2="A selector: this component re-renders only when the count changes",
        w_c3="The store works without React: the same code runs in Node",
        w_c4="persist saves the store in localStorage and loads it on the next visit",
        w_after="after",
    ),
    "ar": dict(
        title="الحالة العامة", w_name="سارة", w_shop="متجر بِت", w_hello="أهلاً،", w_guest="زائر", w_signin="سجّل الدخول", w_signout="سجّل الخروج",
        w_light="فاتح", w_dark="داكن", w_theme="المظهر", w_book="البرمجة من الصفر", w_mug="كوب بِت", w_cap="قبعة بِت",
        w_add="أضف", w_cart="السلة", w_items="عناصر", w_total="المجموع", w_currency="جنيهاً", w_clear="أفرغ السلة",
        w_empty="السلة فارغة.", w_profile="ملفك الشخصي", w_member="عضو منذ 2025",
        w_saved="حُفظ في قائمتك", w_added="أُضيف إلى السلة", w_removed="حُذف", w_undo="تراجع", w_close="أغلق",
        w_notices="الإشعارات",
        w_c1="أي مكوّن تحت المزوّد يقرأ المستخدم، مهما كان عمقه",
        w_c2="محدِّد: يعاد رسم هذا المكوّن فقط حين يتغير العدد",
        w_c3="المخزن يعمل دون React: الكود نفسه يعمل في Node",
        w_c4="persist يحفظ المخزن في localStorage ويحمّله في الزيارة التالية",
        w_after="بعد",
    ),
}

CSS = """:root { --bg: #f5f5fb; --card: white; --ink: #1e1b2e; --muted: #5b5873; }
body.dark { --bg: #16142a; --card: #24213d; --ink: #eef2ff; --muted: #b8b5d6; }
body { background: var(--bg); color: var(--ink); }
header { display: flex; align-items: center; gap: 10px; background: var(--card); padding: 8px 12px; border-radius: 14px; margin-bottom: 12px; box-shadow: 0 2px 10px rgb(67 56 202 / 0.12); }
header .brand { font-weight: 800; color: #818cf8; margin-inline-end: auto; }
.card { background: var(--card); border-radius: 14px; padding: 12px 14px; box-shadow: 0 2px 10px rgb(67 56 202 / 0.12); margin-bottom: 10px; }
.muted { color: var(--muted); }
.row { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
.badge { background: #db2777; color: white; border-radius: 999px; padding: 0 8px; font-size: 0.85rem; font-weight: 700; }
ul { list-style: none; padding: 0; margin: 6px 0; }
li { display: flex; justify-content: space-between; padding: 4px 0; }
.toasts { position: fixed; inset-inline-end: 16px; bottom: 16px; display: flex; flex-direction: column; gap: 8px; width: 280px; }
.toast { background: #1e1b2e; color: #eef2ff; border-radius: 12px; padding: 10px 12px; display: flex; gap: 8px; align-items: center; box-shadow: 0 6px 18px rgb(0 0 0 / 0.25); }
.toast span { flex: 1; }
.toast button { padding: 2px 10px; }
"""

PLAIN = {}
NODE = {}
BROWSER = {}

PLAIN["auth.tsx"] = '''import { createContext, useContext, useMemo, useState, type ReactNode } from "react";

type User = { name: string };
type Auth = { user: User | null; signIn: (name: string) => void; signOut: () => void };

const AuthContext = createContext<Auth | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<User | null>(null);
  const value = useMemo(
    () => ({ user, signIn: (name: string) => setUser({ name }), signOut: () => setUser(null) }),
    [user],
  );
  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

export function useAuth(): Auth {
  const auth = useContext(AuthContext);
  if (!auth) throw new Error("useAuth must be used inside <AuthProvider>");
  return auth;
}
'''

BROWSER["context.tsx"] = ('''import { createRoot } from "react-dom/client";
import { AuthProvider, useAuth } from "./auth";

function Header() {
  return (
    <header>
      <span className="brand">{w_shop}</span>
      <UserMenu />
    </header>
  );
}

// {w_c1}
function UserMenu() {
  const { user, signIn, signOut } = useAuth();
  if (!user) return <button onClick={() => signIn("{w_name}")}>{w_signin}</button>;
  return (
    <span className="row">
      {w_hello} {user.name}
      <button className="secondary" onClick={signOut}>
        {w_signout}
      </button>
    </span>
  );
}

function Profile() {
  const { user } = useAuth();
  return (
    <section className="card">
      <h2>{w_profile}</h2>
      <p className="muted">{user ? `${user.name} · {w_member}` : "{w_guest}"}</p>
    </section>
  );
}

createRoot(document.getElementById("root")!).render(
  <AuthProvider>
    <Header />
    <main>
      <Profile />
    </main>
  </AuthProvider>,
);
''', CSS)

PLAIN["cart-store.ts"] = '''import { create } from "zustand";
import { persist } from "zustand/middleware";

export type Product = { id: number; name: string; price: number };

type CartState = {
  lines: Record<number, { product: Product; quantity: number }>;
  add: (product: Product) => void;
  clear: () => void;
};

export const useCart = create<CartState>()(
  // {w_c4}
  persist(
    (set) => ({
      lines: {},
      add: (product) =>
        set((state) => {
          const line = state.lines[product.id];
          return { lines: { ...state.lines, [product.id]: { product, quantity: (line?.quantity ?? 0) + 1 } } };
        }),
      clear: () => set({ lines: {} }),
    }),
    { name: "cart" },
  ),
);

// Derived values, calculated from the state
export const selectCount = (s: CartState) => Object.values(s.lines).reduce((n, l) => n + l.quantity, 0);
export const selectTotal = (s: CartState) =>
  Object.values(s.lines).reduce((n, l) => n + l.quantity * l.product.price, 0);
'''

NODE["store-node.ts"] = '''import { createStore } from "zustand/vanilla";

// {w_c3}
type Counter = { count: number; increase: () => void };

const store = createStore<Counter>()((set) => ({
  count: 0,
  increase: () => set((s) => ({ count: s.count + 1 })),
}));

const stop = store.subscribe((state, previous) => {
  console.log(`count: ${previous.count} → ${state.count}`);
});

store.getState().increase();
store.getState().increase();
stop();
store.getState().increase();
console.log("{w_after} stop():", store.getState().count);
'''

BROWSER["store.tsx"] = ('''import { createRoot } from "react-dom/client";
import { selectCount, selectTotal, useCart, type Product } from "./cart-store";

const products: Product[] = [
  { id: 1, name: "{w_book}", price: 25 },
  { id: 2, name: "{w_mug}", price: 8 },
  { id: 3, name: "{w_cap}", price: 12 },
];

function CartBadge() {
  const count = useCart(selectCount); // {w_c2}
  return (
    <span className="row">
      {w_cart} <span className="badge">{count}</span>
    </span>
  );
}

function ProductList() {
  const add = useCart((s) => s.add);
  return (
    <section className="card">
      {products.map((p) => (
        <div key={p.id} className="row" style={{ justifyContent: "space-between", padding: "4px 0" }}>
          <span>{p.name}</span>
          <button onClick={() => add(p)}>{w_add}</button>
        </div>
      ))}
    </section>
  );
}

function CartSummary() {
  const lines = useCart((s) => s.lines);
  const total = useCart(selectTotal);
  const clear = useCart((s) => s.clear);
  const list = Object.values(lines);
  if (list.length === 0) return <p className="card muted">{w_empty}</p>;
  return (
    <section className="card">
      <ul>
        {list.map((l) => (
          <li key={l.product.id}>
            <span>
              {l.quantity} × {l.product.name}
            </span>
            <span>
              {l.quantity * l.product.price} {w_currency}
            </span>
          </li>
        ))}
      </ul>
      <p>
        <b>
          {w_total}: {total} {w_currency}
        </b>
      </p>
      <button className="secondary" onClick={clear}>
        {w_clear}
      </button>
    </section>
  );
}

localStorage.clear();
createRoot(document.getElementById("root")!).render(
  <>
    <header>
      <span className="brand">{w_shop}</span>
      <CartBadge />
    </header>
    <ProductList />
    <CartSummary />
  </>,
);
''', CSS)

# ---------------------------------------------------------------- projects
PLAIN["projects/theme.tsx"] = '''import { createContext, useContext, useEffect, useState, type ReactNode } from "react";

export type Theme = "light" | "dark";
const ThemeContext = createContext<{ theme: Theme; toggle: () => void } | null>(null);

function initialTheme(): Theme {
  const saved = localStorage.getItem("theme");
  if (saved === "light" || saved === "dark") return saved;
  return matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

export function ThemeProvider({ children }: { children: ReactNode }) {
  const [theme, setTheme] = useState<Theme>(initialTheme);

  useEffect(() => {
    document.body.classList.toggle("dark", theme === "dark");
    localStorage.setItem("theme", theme);
  }, [theme]);

  const toggle = () => setTheme((t) => (t === "dark" ? "light" : "dark"));
  return <ThemeContext.Provider value={{ theme, toggle }}>{children}</ThemeContext.Provider>;
}

export function useTheme() {
  const value = useContext(ThemeContext);
  if (!value) throw new Error("useTheme must be used inside <ThemeProvider>");
  return value;
}
'''

BROWSER["projects/theme-page.tsx"] = ('''import { createRoot } from "react-dom/client";
import { ThemeProvider, useTheme } from "./theme";

function ThemeSwitch() {
  const { theme, toggle } = useTheme();
  return (
    <button className="secondary" aria-pressed={theme === "dark"} onClick={toggle}>
      {w_theme}: {theme === "dark" ? "{w_dark}" : "{w_light}"}
    </button>
  );
}

localStorage.removeItem("theme");
createRoot(document.getElementById("root")!).render(
  <ThemeProvider>
    <header>
      <span className="brand">{w_shop}</span>
      <ThemeSwitch />
    </header>
    <p className="card">{w_mug} · 8 {w_currency}</p>
  </ThemeProvider>,
);
''', CSS)

PLAIN["projects/toasts.tsx"] = '''import { createContext, useCallback, useContext, useState, type ReactNode } from "react";
import { createPortal } from "react-dom";

type Toast = { id: number; text: string; action?: { label: string; run: () => void } };
type Notify = (text: string, action?: Toast["action"]) => void;

const ToastContext = createContext<Notify | null>(null);
let nextId = 1;

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);

  const dismiss = useCallback((id: number) => setToasts((all) => all.filter((t) => t.id !== id)), []);

  const notify = useCallback<Notify>(
    (text, action) => {
      const id = nextId++;
      setToasts((all) => [...all.slice(-2), { id, text, action }]); // at most three on screen
      setTimeout(() => dismiss(id), 5000);
    },
    [dismiss],
  );

  return (
    <ToastContext.Provider value={notify}>
      {children}
      {createPortal(
        <div className="toasts" role="status" aria-live="polite" aria-label="{w_notices}">
          {toasts.map((t) => (
            <div className="toast" key={t.id}>
              <span>{t.text}</span>
              {t.action && (
                <button
                  onClick={() => {
                    t.action!.run();
                    dismiss(t.id);
                  }}
                >
                  {t.action.label}
                </button>
              )}
              <button className="secondary" aria-label="{w_close}" onClick={() => dismiss(t.id)}>
                ×
              </button>
            </div>
          ))}
        </div>,
        document.body,
      )}
    </ToastContext.Provider>
  );
}

export function useToast(): Notify {
  const notify = useContext(ToastContext);
  if (!notify) throw new Error("useToast must be used inside <ToastProvider>");
  return notify;
}
'''

BROWSER["projects/toasts-page.tsx"] = ('''import { useState } from "react";
import { createRoot } from "react-dom/client";
import { ToastProvider, useToast } from "./toasts";

const NAMES = ["{w_book}", "{w_mug}", "{w_cap}"];

function Shelf() {
  const notify = useToast();
  const [items, setItems] = useState(NAMES);

  function remove(name: string) {
    setItems((all) => all.filter((n) => n !== name));
    notify(`{w_removed}: ${name}`, { label: "{w_undo}", run: () => setItems((all) => [...all, name]) });
  }

  return (
    <section className="card">
      {items.map((name) => (
        <div key={name} className="row" style={{ justifyContent: "space-between", padding: "4px 0" }}>
          <span>{name}</span>
          <span className="row">
            <button onClick={() => notify(`${name} {w_added}`)}>{w_add}</button>
            <button className="secondary" onClick={() => remove(name)}>
              ×
            </button>
          </span>
        </div>
      ))}
    </section>
  );
}

createRoot(document.getElementById("root")!).render(
  <ToastProvider>
    <Shelf />
  </ToastProvider>,
);
''', CSS + "body { min-height: 360px; }\n")

kit.generate(HERE, T, plain=PLAIN, node_files=NODE, browser_files=BROWSER)
