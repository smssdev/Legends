"""Writes the examples of Book 2 (React edition), chapter "State, Effects and Data Flow", in English and Arabic.
Run: python3 make.py   Text placeholders are {w_…}, so they never collide with names in the code.
"""
import sys
from pathlib import Path

HERE = Path(__file__).parent
sys.path.insert(0, str(HERE.parents[1]))
import react_kit as kit  # noqa: E402

T = {
    "en": dict(
        title="State", w_arrow=" → ", w_plus3="+3 (wrong)", w_plus3ok="+3 (right)", w_reset="Reset",
        w_name="Name", w_email="Email", w_city="City", w_saved="Saved profile:",
        w_book="Code from Zero", w_mug="Bit mug", w_cap="Bit cap", w_items="Items", w_total="Total", w_currency="EGP",
        w_remove="Remove", w_empty="Your cart is empty.", w_free="Free delivery!", w_more="more for free delivery",
        w_add="Add", w_qty="Quantity", w_after="After", w_state="State:",
        w_start="Start", w_stop="Stop", w_seconds="seconds", w_title_tick="Timer",
        w_task="New task", w_tasks="Tasks", w_left="left", w_clear="Clear done", w_t1="Read chapter 5", w_t2="Write a reducer",
        w_t3="Test it with Node", w_search="Search products", w_searching="Searching for", w_noresults="No products match",
        w_results="results", w_step="Step", w_undo="Undo", w_history="History",
        w_c1="Every handler sees the value of this render", w_c2="An updater function receives the latest value",
        w_c3="The reducer is a pure function: it can run anywhere, even without React",
        w_c4="Without the cleanup, every render would start another interval",
        w_c5="If the user types again, ignore the old answer",
    ),
    "ar": dict(
        title="الحالة", w_arrow=" ← ", w_plus3="‎+3 (خطأ)", w_plus3ok="‎+3 (صحيح)", w_reset="صفّر",
        w_name="الاسم", w_email="البريد", w_city="المدينة", w_saved="الملف المحفوظ:",
        w_book="البرمجة من الصفر", w_mug="كوب بِت", w_cap="قبعة بِت", w_items="العناصر", w_total="المجموع", w_currency="جنيهاً",
        w_remove="احذف", w_empty="سلتك فارغة.", w_free="توصيل مجاني!", w_more="أخرى للتوصيل المجاني",
        w_add="أضف", w_qty="الكمية", w_after="بعد", w_state="الحالة:",
        w_start="ابدأ", w_stop="أوقف", w_seconds="ثانية", w_title_tick="المؤقت",
        w_task="مهمة جديدة", w_tasks="المهام", w_left="متبقية", w_clear="احذف المنجزة", w_t1="اقرأ الفصل 5", w_t2="اكتب دالة اختزال",
        w_t3="اختبرها بـ Node", w_search="ابحث في المنتجات", w_searching="جارٍ البحث عن", w_noresults="لا منتجات تطابق",
        w_results="نتائج", w_step="الخطوة", w_undo="تراجع", w_history="السجل",
        w_c1="كل معالج يرى قيمة هذا الرسم", w_c2="دالة التحديث تستقبل أحدث قيمة",
        w_c3="دالة الاختزال نقية: تعمل في أي مكان، حتى دون React",
        w_c4="دون التنظيف سيبدأ كل رسم مؤقتاً آخر",
        w_c5="إن كتب المستخدم من جديد، فتجاهل الرد القديم",
    ),
}

CARD = """.card { background: white; border-radius: 14px; padding: 14px 16px; box-shadow: 0 2px 10px rgb(67 56 202 / 0.1); max-width: 460px; }
.row { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
.big { font-size: 2rem; font-weight: 700; color: #4338ca; margin: 0 0 8px; }
label { display: block; font-weight: 600; margin-top: 8px; }
input { font: inherit; padding: 6px 10px; border: 2px solid #c7d2fe; border-radius: 10px; width: 100%; }
ul { list-style: none; padding: 0; margin: 8px 0; }
li { display: flex; align-items: center; gap: 8px; padding: 6px 0; border-bottom: 1px solid #eef2ff; }
li span { flex: 1; }
.muted { color: #5b5873; }
.ok { color: #047857; font-weight: 700; }
pre { background: #1e1b2e; color: #e0e7ff; padding: 8px 10px; border-radius: 8px; font-size: 0.85rem; white-space: pre-wrap; }
"""

PLAIN = {}
NODE = {}
BROWSER = {}

BROWSER["snapshot.tsx"] = ('''import { useState } from "react";
import { createRoot } from "react-dom/client";

function Counter() {
  const [count, setCount] = useState(0);

  function addThreeWrong() {
    // {w_c1}: count is 0 three times
    setCount(count + 1);
    setCount(count + 1);
    setCount(count + 1);
  }

  function addThree() {
    // {w_c2}
    setCount((c) => c + 1);
    setCount((c) => c + 1);
    setCount((c) => c + 1);
  }

  return (
    <div className="card">
      <p className="big">{count}</p>
      <div className="row">
        <button onClick={addThreeWrong}>{w_plus3}</button>
        <button onClick={addThree}>{w_plus3ok}</button>
        <button className="secondary" onClick={() => setCount(0)}>{w_reset}</button>
      </div>
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<Counter />);
''', CARD)

PLAIN["cart-model.ts"] = '''export type Product = { id: number; name: string; price: number };
export type Line = { product: Product; quantity: number };

export const catalogue: Product[] = [
  { id: 1, name: "{w_book}", price: 25 },
  { id: 2, name: "{w_mug}", price: 8 },
  { id: 3, name: "{w_cap}", price: 12 },
];

export const FREE_DELIVERY = 50;
'''

BROWSER["cart.tsx"] = ('''import { useState } from "react";
import { createRoot } from "react-dom/client";
import { catalogue, FREE_DELIVERY, type Line, type Product } from "./cart-model";

function Cart() {
  const [lines, setLines] = useState<Line[]>([]);

  // Derived: calculated on every render, never stored
  const count = lines.reduce((sum, line) => sum + line.quantity, 0);
  const total = lines.reduce((sum, line) => sum + line.quantity * line.product.price, 0);
  const missing = FREE_DELIVERY - total;

  function add(product: Product) {
    setLines((current) => {
      const found = current.find((line) => line.product.id === product.id);
      if (!found) return [...current, { product, quantity: 1 }];
      return current.map((line) => (line === found ? { ...line, quantity: line.quantity + 1 } : line));
    });
  }

  function remove(id: number) {
    setLines((current) => current.filter((line) => line.product.id !== id));
  }

  return (
    <div className="card">
      <div className="row">
        {catalogue.map((product) => (
          <button key={product.id} className="secondary" onClick={() => add(product)}>
            + {product.name}
          </button>
        ))}
      </div>
      {lines.length === 0 ? (
        <p className="muted">{w_empty}</p>
      ) : (
        <ul>
          {lines.map((line) => (
            <li key={line.product.id}>
              <span>
                {line.quantity} × {line.product.name}
              </span>
              <button className="secondary" onClick={() => remove(line.product.id)}>
                {w_remove}
              </button>
            </li>
          ))}
        </ul>
      )}
      <p>
        {w_items}: {count} · {w_total}: <b>{total} {w_currency}</b>
      </p>
      <p className={missing <= 0 ? "ok" : "muted"}>
        {missing <= 0 ? "{w_free}" : `${missing} {w_currency} {w_more}`}
      </p>
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<Cart />);
''', CARD)

PLAIN["tasks-reducer.ts"] = '''export type Task = { id: number; text: string; done: boolean };

export type Action =
  | { type: "added"; id: number; text: string }
  | { type: "toggled"; id: number }
  | { type: "cleared" };

// {w_c3}
export function tasksReducer(tasks: Task[], action: Action): Task[] {
  switch (action.type) {
    case "added":
      return [...tasks, { id: action.id, text: action.text, done: false }];
    case "toggled":
      return tasks.map((t) => (t.id === action.id ? { ...t, done: !t.done } : t));
    case "cleared":
      return tasks.filter((t) => !t.done);
  }
}
'''

NODE["reducer-test.ts"] = '''import { tasksReducer, type Action, type Task } from "./tasks-reducer";

const actions: Action[] = [
  { type: "added", id: 1, text: "{w_t1}" },
  { type: "added", id: 2, text: "{w_t2}" },
  { type: "toggled", id: 1 },
  { type: "cleared" },
];

let state: Task[] = [];
for (const action of actions) {
  state = tasksReducer(state, action);
  console.log(action.type.padEnd(8), JSON.stringify(state.map((t) => `${t.done ? "✓" : "·"} ${t.text}`)));
}
'''

BROWSER["timer.tsx"] = ('''import { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";

function Timer() {
  const [running, setRunning] = useState(false);
  const [seconds, setSeconds] = useState(0);

  useEffect(() => {
    if (!running) return;
    const id = setInterval(() => setSeconds((s) => s + 1), 1000);
    return () => clearInterval(id); // {w_c4}
  }, [running]);

  useEffect(() => {
    document.title = `${seconds} {w_seconds} · {w_title_tick}`;
  }, [seconds]);

  return (
    <div className="card">
      <p className="big">
        {seconds} {w_seconds}
      </p>
      <button onClick={() => setRunning(!running)}>{running ? "{w_stop}" : "{w_start}"}</button>
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<Timer />);
''', CARD)

PLAIN["fake-api.ts"] = '''import { catalogue, type Product } from "./cart-model";

// A pretend server: answers after a delay, slower for short queries, like a real search.
export function searchProducts(query: string, signal: AbortSignal): Promise<Product[]> {
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      const q = query.trim().toLowerCase();
      resolve(catalogue.filter((p) => p.name.toLowerCase().includes(q)));
    }, 600 - query.length * 100);
    signal.addEventListener("abort", () => {
      clearTimeout(timer);
      reject(signal.reason);
    });
  });
}
'''

# ---------------------------------------------------------------- projects
BROWSER["projects/history.tsx"] = ('''import { useState } from "react";
import { createRoot } from "react-dom/client";

function StepCounter() {
  const [step, setStep] = useState(1);
  const [history, setHistory] = useState<number[]>([0]);
  const value = history.at(-1) ?? 0; // derived from the history

  function change(by: number) {
    setHistory((h) => [...h, (h.at(-1) ?? 0) + by]);
  }

  function undo() {
    setHistory((h) => (h.length > 1 ? h.slice(0, -1) : h));
  }

  return (
    <div className="card">
      <p className="big">{value}</p>
      <label htmlFor="step">{w_step}</label>
      <input id="step" type="number" min={1} value={step} onChange={(e) => setStep(Number(e.target.value) || 1)} />
      <div className="row" style={{ marginTop: 10 }}>
        <button onClick={() => change(-step)}>− {step}</button>
        <button onClick={() => change(step)}>+ {step}</button>
        <button className="secondary" onClick={undo} disabled={history.length === 1}>
          {w_undo}
        </button>
      </div>
      <p className="muted">
        {w_history}: {history.join("{w_arrow}")}
      </p>
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<StepCounter />);
''', CARD)

BROWSER["projects/tasks.tsx"] = ('''import { useEffect, useReducer, useRef, useState } from "react";
import type { FormEvent } from "react";
import { createRoot } from "react-dom/client";
import { tasksReducer, type Task } from "../tasks-reducer";

const KEY = "tasks";

function load(): Task[] {
  try {
    const saved = localStorage.getItem(KEY);
    return saved ? (JSON.parse(saved) as Task[]) : [];
  } catch {
    return [];
  }
}

function Tasks() {
  const [tasks, dispatch] = useReducer(tasksReducer, [], load);
  const [text, setText] = useState("");
  const input = useRef<HTMLInputElement>(null);
  const left = tasks.filter((t) => !t.done).length;

  useEffect(() => {
    localStorage.setItem(KEY, JSON.stringify(tasks));
  }, [tasks]);

  function submit(event: FormEvent) {
    event.preventDefault();
    if (!text.trim()) return;
    dispatch({ type: "added", id: Date.now(), text: text.trim() });
    setText("");
    input.current?.focus();
  }

  return (
    <div className="card">
      <h2>{w_tasks}</h2>
      <form className="row" onSubmit={submit}>
        <input ref={input} aria-label="{w_task}" placeholder="{w_task}" value={text} onChange={(e) => setText(e.target.value)} style={{ flex: 1, width: "auto" }} />
        <button type="submit">{w_add}</button>
      </form>
      <ul>
        {tasks.map((task) => (
          <li key={task.id}>
            <input type="checkbox" id={`t${task.id}`} checked={task.done} onChange={() => dispatch({ type: "toggled", id: task.id })} style={{ width: "auto" }} />
            <span>
              <label htmlFor={`t${task.id}`} style={{ display: "inline", fontWeight: 400, textDecoration: task.done ? "line-through" : "none" }}>
                {task.text}
              </label>
            </span>
          </li>
        ))}
      </ul>
      <div className="row">
        <span className="muted" style={{ flex: 1 }}>
          {left} {w_left}
        </span>
        <button className="secondary" onClick={() => dispatch({ type: "cleared" })}>
          {w_clear}
        </button>
      </div>
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<Tasks />);
''', CARD)

BROWSER["projects/search.tsx"] = ('''import { useEffect, useState } from "react";
import { createRoot } from "react-dom/client";
import { searchProducts } from "../fake-api";
import type { Product } from "../cart-model";

type Result =
  | { status: "idle" }
  | { status: "loading"; query: string }
  | { status: "done"; query: string; products: Product[] }
  | { status: "error"; message: string };

function useDebounced<T>(value: T, ms: number): T {
  const [debounced, setDebounced] = useState(value);
  useEffect(() => {
    const id = setTimeout(() => setDebounced(value), ms);
    return () => clearTimeout(id);
  }, [value, ms]);
  return debounced;
}

function Search() {
  const [query, setQuery] = useState("");
  const [result, setResult] = useState<Result>({ status: "idle" });
  const debounced = useDebounced(query, 300);

  useEffect(() => {
    if (!debounced.trim()) {
      setResult({ status: "idle" });
      return;
    }
    const controller = new AbortController();
    setResult({ status: "loading", query: debounced });
    searchProducts(debounced, controller.signal)
      .then((products) => setResult({ status: "done", query: debounced, products }))
      .catch((error: unknown) => {
        if (controller.signal.aborted) return;
        setResult({ status: "error", message: String(error) });
      });
    return () => controller.abort(); // {w_c5}
  }, [debounced]);

  return (
    <div className="card">
      <label htmlFor="q">{w_search}</label>
      <input id="q" type="search" value={query} onChange={(e) => setQuery(e.target.value)} />
      {result.status === "loading" && <p className="muted">{w_searching} “{result.query}”…</p>}
      {result.status === "error" && <p role="alert">{result.message}</p>}
      {result.status === "done" &&
        (result.products.length === 0 ? (
          <p className="muted">{w_noresults} “{result.query}”.</p>
        ) : (
          <ul aria-label="{w_results}">
            {result.products.map((p) => (
              <li key={p.id}>
                <span>{p.name}</span>
                <b>
                  {p.price} {w_currency}
                </b>
              </li>
            ))}
          </ul>
        ))}
    </div>
  );
}

createRoot(document.getElementById("root")!).render(<Search />);
''', CARD)

kit.generate(HERE, T, plain=PLAIN, node_files=NODE, browser_files=BROWSER)
