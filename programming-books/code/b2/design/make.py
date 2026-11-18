"""Writes the examples of Book 2, chapter "Design Systems and Component Libraries", in English and Arabic.
Run: python3 make.py   Shared files (tokens, the token script) at the top; React components under react/.
Text placeholders are {w_…}.
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parent))
import react_kit as kit  # noqa: E402

T = {
    "en": dict(
        title="Design system", w_save="Save", w_cancel="Cancel", w_delete="Delete", w_saving="Saving…", w_small="Small",
        w_large="Large", w_primary="Primary", w_secondary="Secondary", w_danger="Danger", w_ghost="Ghost",
        w_order="Order #1042", w_paid="Paid", w_pending="Pending", w_refunded="Refunded", w_new="New",
        w_info="Your order ships tomorrow.", w_success="Payment received. Thank you!",
        w_warning="Only 2 left in stock.", w_error="The card was declined. Please try another one.",
        w_notify="Email me about new books", w_wifi="Wi-Fi", w_dark="Dark theme",
        w_c1="Primitive tokens: the raw palette. Components never use these directly.",
        w_c2="Semantic tokens: what a colour is for. Themes change these.",
        w_c3="Reads tokens.json and writes CSS variables for the light and dark themes",
        w_c5="Each text colour is checked on the background it is used on", w_fail="below 4.5",
        w_allpass="All pairs pass WCAG AA.", w_failed="pairs fail. Fix the tokens before releasing.",
        w_c4="Every native button prop (type, disabled, onClick, aria-…) still works",
    ),
    "ar": dict(
        title="نظام التصميم", w_save="احفظ", w_cancel="ألغِ", w_delete="احذف", w_saving="جارٍ الحفظ…", w_small="صغير",
        w_large="كبير", w_primary="أساسي", w_secondary="ثانوي", w_danger="خطر", w_ghost="شفاف",
        w_order="الطلب #1042", w_paid="مدفوع", w_pending="قيد الانتظار", w_refunded="مسترد", w_new="جديد",
        w_info="يُشحن طلبك غداً.", w_success="وصل الدفع. شكراً لك!",
        w_warning="بقيت قطعتان فقط في المخزون.", w_error="رُفضت البطاقة. جرّب بطاقة أخرى من فضلك.",
        w_notify="راسلني عن الكتب الجديدة", w_wifi="الواي فاي", w_dark="المظهر الداكن",
        w_c1="رموز أولية: لوحة الألوان الخام، ولا تستخدمها المكونات مباشرة أبداً.",
        w_c2="رموز دلالية: الغرض من اللون، والمظاهر تغيّر هذه.",
        w_c3="يقرأ tokens.json ويكتب متغيرات CSS للمظهرين الفاتح والداكن",
        w_c5="يُفحص كل لون نص على الخلفية التي يُستخدم عليها", w_fail="أقل من 4.5",
        w_allpass="كل الأزواج تنجح في WCAG AA.", w_failed="أزواج تفشل. أصلح الرموز قبل الإصدار.",
        w_c4="كل خصائص الزر الأصلية (type وdisabled وonClick وaria-…) تبقى عاملة",
    ),
}

PLAIN, NODE, BROWSER = {}, {}, {}

PLAIN["tokens.json"] = '''{
  "primitive": {
    "indigo-50": "#eef2ff", "indigo-600": "#4338ca", "indigo-800": "#312e81",
    "pink-600": "#db2777", "red-50": "#fef2f2", "red-700": "#b91c1c",
    "green-50": "#ecfdf5", "green-700": "#047857", "amber-50": "#fffbeb", "amber-800": "#92400e",
    "gray-50": "#f5f5fb", "gray-400": "#a5a3bd", "gray-600": "#5b5873", "indigo-300": "#a5b4fc", "gray-900": "#1e1b2e", "gray-950": "#16142a", "white": "#ffffff"
  },
  "semantic": {
    "light": {
      "surface": "white", "surface-muted": "gray-50", "text": "gray-900", "text-muted": "gray-600",
      "action": "indigo-600", "action-text": "white", "action-soft": "indigo-50", "action-soft-text": "indigo-800",
      "danger": "red-700", "danger-soft": "red-50", "success": "green-700", "success-soft": "green-50",
      "warning": "amber-800", "warning-soft": "amber-50", "focus": "pink-600"
    },
    "dark": {
      "surface": "gray-950", "surface-muted": "gray-900", "text": "gray-50", "text-muted": "gray-400",
      "action": "indigo-300", "action-text": "indigo-800", "action-soft": "indigo-800", "action-soft-text": "indigo-50",
      "danger": "red-50", "danger-soft": "red-700", "success": "green-50", "success-soft": "green-700",
      "warning": "amber-50", "warning-soft": "amber-800", "focus": "pink-600"
    }
  },
  "space": { "1": "4px", "2": "8px", "3": "12px", "4": "16px", "6": "24px" },
  "radius": { "sm": "6px", "md": "10px", "full": "999px" }
}
'''

NODE["build-tokens.ts"] = '''import { readFileSync } from "node:fs";

// {w_c3}
type Tokens = {
  primitive: Record<string, string>;
  semantic: Record<"light" | "dark", Record<string, string>>;
  space: Record<string, string>;
  radius: Record<string, string>;
};

const tokens = JSON.parse(readFileSync(new URL("./tokens.json", import.meta.url), "utf8")) as Tokens;

function resolve(name: string): string {
  const value = tokens.primitive[name];
  if (!value) throw new Error(`Unknown primitive token: ${name}`);
  return value;
}

function block(selector: string, vars: Record<string, string>): string {
  const lines = Object.entries(vars).map(([k, v]) => `  --${k}: ${v};`);
  return `${selector} {\\n${lines.join("\\n")}\\n}`;
}

const light = Object.fromEntries(Object.entries(tokens.semantic.light).map(([k, v]) => [`color-${k}`, resolve(v)]));
const dark = Object.fromEntries(Object.entries(tokens.semantic.dark).map(([k, v]) => [`color-${k}`, resolve(v)]));
const space = Object.fromEntries(Object.entries(tokens.space).map(([k, v]) => [`space-${k}`, v]));
const radius = Object.fromEntries(Object.entries(tokens.radius).map(([k, v]) => [`radius-${k}`, v]));

const css = [block(":root", { ...light, ...space, ...radius }), block('[data-theme="dark"]', dark)].join("\\n\\n");
console.log(css.split("\\n").slice(0, 8).join("\\n"));
console.log("  …");
console.log(`(${Object.keys(light).length} colours × 2 themes, ${Object.keys(space).length} spaces, ${Object.keys(radius).length} radii)`);
'''

TOKENS_CSS = """:root {
  --color-surface: #ffffff; --color-surface-muted: #f5f5fb; --color-text: #1e1b2e; --color-text-muted: #5b5873;
  --color-action: #4338ca; --color-action-text: #ffffff; --color-action-soft: #eef2ff; --color-action-soft-text: #312e81;
  --color-danger: #b91c1c; --color-danger-soft: #fef2f2; --color-success: #047857; --color-success-soft: #ecfdf5;
  --color-warning: #92400e; --color-warning-soft: #fffbeb; --color-focus: #db2777;
  --space-1: 4px; --space-2: 8px; --space-3: 12px; --space-4: 16px; --space-6: 24px;
  --radius-sm: 6px; --radius-md: 10px; --radius-full: 999px;
}
[data-theme="dark"] {
  --color-surface: #16142a; --color-surface-muted: #1e1b2e; --color-text: #f5f5fb; --color-text-muted: #a5a3bd;
  --color-action: #a5b4fc; --color-action-text: #312e81; --color-action-soft: #312e81; --color-action-soft-text: #eef2ff;
  --color-danger: #fef2f2; --color-danger-soft: #b91c1c; --color-success: #ecfdf5; --color-success-soft: #047857;
  --color-warning: #fffbeb; --color-warning-soft: #92400e;
}
body { background: var(--color-surface-muted); color: var(--color-text); }
"""

PLAIN["components.css"] = """.btn { display: inline-flex; align-items: center; gap: var(--space-2); border: 2px solid transparent;
  border-radius: var(--radius-full); font: inherit; font-weight: 600; cursor: pointer; }
.btn:focus-visible { outline: 3px solid var(--color-focus); outline-offset: 2px; }
.btn:disabled { opacity: 0.55; cursor: not-allowed; }
.btn-sm { padding: 2px var(--space-3); font-size: 0.875rem; }
.btn-md { padding: var(--space-1) var(--space-4); }
.btn-lg { padding: var(--space-2) var(--space-6); font-size: 1.125rem; }
.btn-primary { background: var(--color-action); color: var(--color-action-text); }
.btn-secondary { background: var(--color-action-soft); color: var(--color-action-soft-text); }
.btn-danger { background: var(--color-danger); color: var(--color-surface); }
.btn-ghost { background: transparent; color: var(--color-action); border-color: var(--color-action-soft); }
.spinner { width: 1em; height: 1em; border: 2px solid currentColor; border-right-color: transparent; border-radius: 50%; animation: spin 0.8s linear infinite; }
@keyframes spin { to { transform: rotate(360deg); } }
@media (prefers-reduced-motion: reduce) { .spinner { animation-duration: 3s; } }
.badge { display: inline-block; padding: 0 var(--space-2); border-radius: var(--radius-full); font-size: 0.8rem; font-weight: 700; }
.badge-neutral { background: var(--color-action-soft); color: var(--color-action-soft-text); }
.badge-success { background: var(--color-success-soft); color: var(--color-success); }
.badge-warning { background: var(--color-warning-soft); color: var(--color-warning); }
.badge-danger { background: var(--color-danger-soft); color: var(--color-danger); }
.alert { display: flex; gap: var(--space-2); padding: var(--space-3) var(--space-4); border-radius: var(--radius-md); border-inline-start: 4px solid; margin-bottom: var(--space-2); }
.alert-info { background: var(--color-action-soft); color: var(--color-action-soft-text); }
.alert-success { background: var(--color-success-soft); color: var(--color-success); }
.alert-warning { background: var(--color-warning-soft); color: var(--color-warning); }
.alert-danger { background: var(--color-danger-soft); color: var(--color-danger); }
.switch { display: inline-flex; align-items: center; gap: var(--space-3); background: none; border: 0; padding: var(--space-1) 0; font: inherit; color: inherit; cursor: pointer; }
.switch .track { width: 44px; height: 24px; border-radius: var(--radius-full); background: var(--color-surface); border: 2px solid var(--color-text-muted); position: relative; transition: background 0.2s; }
.switch .thumb { position: absolute; top: 2px; inset-inline-start: 2px; width: 16px; height: 16px; border-radius: 50%; background: var(--color-text-muted); transition: inset-inline-start 0.2s; }
.switch[aria-checked="true"] .track { background: var(--color-action); border-color: var(--color-action); }
.switch[aria-checked="true"] .thumb { inset-inline-start: 22px; background: var(--color-action-text); }
.switch:focus-visible .track { outline: 3px solid var(--color-focus); outline-offset: 2px; }
.gallery { display: flex; flex-direction: column; gap: var(--space-3); background: var(--color-surface); color: var(--color-text); padding: var(--space-4); border-radius: var(--radius-md); }
.row { display: flex; gap: var(--space-2); flex-wrap: wrap; align-items: center; }
"""

PLAIN["react/Button.tsx"] = '''import type { ComponentProps } from "react";

type Variant = "primary" | "secondary" | "danger" | "ghost";
type Size = "sm" | "md" | "lg";

type ButtonProps = ComponentProps<"button"> & {
  variant?: Variant;
  size?: Size;
  loading?: boolean;
};

// {w_c4}
export function Button({ variant = "primary", size = "md", loading = false, className, children, disabled, ...rest }: ButtonProps) {
  const classes = ["btn", `btn-${variant}`, `btn-${size}`, className].filter(Boolean).join(" ");
  return (
    <button type="button" className={classes} disabled={disabled || loading} aria-busy={loading || undefined} {...rest}>
      {loading && <span className="spinner" aria-hidden="true" />}
      {children}
    </button>
  );
}
'''

BROWSER["react/buttons.tsx"] = ('''import { createRoot } from "react-dom/client";
import { Button } from "./Button";

function Gallery() {
  return (
    <div className="gallery">
      <div className="row">
        <Button>{w_primary}</Button>
        <Button variant="secondary">{w_secondary}</Button>
        <Button variant="danger">{w_danger}</Button>
        <Button variant="ghost">{w_ghost}</Button>
      </div>
      <div className="row">
        <Button size="sm">{w_small}</Button>
        <Button size="lg">{w_large}</Button>
        <Button loading>{w_saving}</Button>
        <Button disabled>{w_cancel}</Button>
      </div>
    </div>
  );
}

const root = createRoot(document.getElementById("root")!);
root.render(
  <>
    <Gallery />
    <div data-theme="dark" style={{ marginTop: 12 }}>
      <Gallery />
    </div>
  </>,
);
''', TOKENS_CSS + PLAIN["components.css"])

# ---------------------------------------------------------------- projects
NODE["projects/check-contrast.ts"] = '''import { readFileSync } from "node:fs";

type Tokens = { primitive: Record<string, string>; semantic: Record<string, Record<string, string>> };
const tokens = JSON.parse(readFileSync(new URL("../tokens.json", import.meta.url), "utf8")) as Tokens;

// The WCAG formula from Book 1
function luminance(hex: string): number {
  const [r, g, b] = [1, 3, 5].map((i) => {
    const c = parseInt(hex.slice(i, i + 2), 16) / 255;
    return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;
  }) as [number, number, number];
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function contrast(a: string, b: string): number {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x) as [number, number];
  return (hi + 0.05) / (lo + 0.05);
}

// {w_c5}
const PAIRS: [string, string][] = [
  ["text", "surface"],
  ["text-muted", "surface"],
  ["action-text", "action"],
  ["action-soft-text", "action-soft"],
  ["danger", "danger-soft"],
  ["success", "success-soft"],
  ["warning", "warning-soft"],
];

let failures = 0;
for (const [theme, colours] of Object.entries(tokens.semantic)) {
  for (const [fg, bg] of PAIRS) {
    const ratio = contrast(tokens.primitive[colours[fg]!]!, tokens.primitive[colours[bg]!]!);
    const ok = ratio >= 4.5;
    if (!ok) failures++;
    console.log(`${theme.padEnd(5)} ${`${fg} / ${bg}`.padEnd(32)} ${ratio.toFixed(2).padStart(5)} ${ok ? "✓" : "✗ {w_fail}"}`);
  }
}
console.log(failures === 0 ? "{w_allpass}" : `${failures} {w_failed}`);
process.exitCode = failures === 0 ? 0 : 1;
'''

PLAIN["react/projects/Badge.tsx"] = '''import type { ReactNode } from "react";

export type Tone = "neutral" | "success" | "warning" | "danger";

export function Badge({ tone = "neutral", children }: { tone?: Tone; children: ReactNode }) {
  return <span className={`badge badge-${tone}`}>{children}</span>;
}
'''

PLAIN["react/projects/Alert.tsx"] = '''import type { ReactNode } from "react";

type Tone = "info" | "success" | "warning" | "danger";

const ICONS: Record<Tone, string> = { info: "ℹ", success: "✓", warning: "!", danger: "✕" };

export function Alert({ tone = "info", children }: { tone?: Tone; children: ReactNode }) {
  // Errors interrupt (alert); everything else waits for a pause (status)
  const role = tone === "danger" ? "alert" : "status";
  return (
    <div className={`alert alert-${tone}`} role={role}>
      <span aria-hidden="true">{ICONS[tone]}</span>
      <span>{children}</span>
    </div>
  );
}
'''

BROWSER["react/projects/feedback.tsx"] = ('''import { createRoot } from "react-dom/client";
import { Alert } from "./Alert";
import { Badge } from "./Badge";

createRoot(document.getElementById("root")!).render(
  <div className="gallery">
    <div className="row">
      <b>{w_order}</b>
      <Badge tone="success">{w_paid}</Badge>
      <Badge tone="warning">{w_pending}</Badge>
      <Badge tone="danger">{w_refunded}</Badge>
      <Badge>{w_new}</Badge>
    </div>
    <div>
      <Alert>{w_info}</Alert>
      <Alert tone="success">{w_success}</Alert>
      <Alert tone="warning">{w_warning}</Alert>
      <Alert tone="danger">{w_error}</Alert>
    </div>
  </div>,
);
''', TOKENS_CSS + PLAIN["components.css"])

PLAIN["react/projects/Switch.tsx"] = '''import { useState } from "react";

type SwitchProps = {
  label: string;
  checked?: boolean; // controlled: the parent owns the value
  defaultChecked?: boolean; // uncontrolled: the switch owns it
  onChange?: (checked: boolean) => void;
};

export function Switch({ label, checked, defaultChecked = false, onChange }: SwitchProps) {
  const [inner, setInner] = useState(defaultChecked);
  const isControlled = checked !== undefined;
  const on = isControlled ? checked : inner;

  function toggle() {
    if (!isControlled) setInner(!on);
    onChange?.(!on);
  }

  return (
    <button type="button" role="switch" aria-checked={on} className="switch" onClick={toggle}>
      <span className="track" aria-hidden="true">
        <span className="thumb" />
      </span>
      {label}
    </button>
  );
}
'''

BROWSER["react/projects/switches.tsx"] = ('''import { useState } from "react";
import { createRoot } from "react-dom/client";
import { Switch } from "./Switch";

function Settings() {
  const [dark, setDark] = useState(false);
  return (
    <div className="gallery" data-theme={dark ? "dark" : undefined}>
      <Switch label="{w_notify}" defaultChecked />
      <Switch label="{w_wifi}" />
      <Switch label="{w_dark}" checked={dark} onChange={setDark} />
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<Settings />);
''', TOKENS_CSS + PLAIN["components.css"])

kit.generate(HERE, T, plain=PLAIN, node_files=NODE, browser_files=BROWSER)
