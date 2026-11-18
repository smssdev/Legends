"""Writes the examples of Book 2, chapter "TypeScript for Real Projects", in English and Arabic.
Run: python3 make.py   (then the book runs each .ts file with Node, which strips the types,
and checks the files marked data-check with the TypeScript compiler, showing its real messages)
"""
import re
from pathlib import Path

HERE = Path(__file__).parent
FILES, L = {}, {"en": {}, "ar": {}}


def example(name, code, en=None, ar=None):
    FILES[name] = code
    L["en"][name] = en or {}
    L["ar"][name] = ar or {}


example("why.ts", '''type Product = { name: string; price: number; quantity: number };

function lineTotal(product: Product) {
  return product.price * product.quantitiy;
}

const book: Product = { name: "{book}", price: "25", quantity: 2 };
lineTotal(book);
lineTotal({ name: "{mug}", price: 8 });
''', {"book": "Book", "mug": "Mug"}, {"book": "كتاب", "mug": "كوب"})

example("basics.ts", '''// {c1}
let city = "{city}";
const year = 2026;
const scores = [72, 95, 88];

// {c2}
function average(values: number[]): number {
  return values.reduce((sum, v) => sum + v, 0) / values.length;
}

function greet(name: string, title?: string): string {
  return title ? `${title} ${name}` : name;
}

console.log(city, year, average(scores));
console.log(greet("{name}"), "|", greet("{name}", "{dr}"));
''', {"c1": "Inferred: TypeScript knows these types without being told", "c2": "Annotate function parameters and the return type",
      "city": "Cairo", "name": "Sara", "dr": "Dr."},
   {"c1": "مستنتجة: تعرف TypeScript هذه الأنواع دون أن تُخبَر", "c2": "اكتب أنواع معاملات الدالة ونوع ما تُرجعه",
    "city": "القاهرة", "name": "سارة", "dr": "د."})

example("objects.ts", '''type User = {
  readonly id: number;
  name: string;
  email: string;
  phone?: string; // {c1}
  roles: readonly string[];
};

const user: User = { id: 7, name: "{name}", email: "sara@example.com", roles: ["admin"] };

user.name = "{other}";
user.id = 8;
user.roles.push("editor");
console.log(user.phone.length);
''', {"c1": "optional: string or undefined", "name": "Sara", "other": "Huda"},
   {"c1": "اختياري: نص أو undefined", "name": "سارة", "other": "هدى"})

example("narrowing.ts", '''function formatPrice(value: number | string | null): string {
  if (value === null) return "{free}";
  if (typeof value === "string") return value; // {c1}
  return `${value.toFixed(2)} {currency}`; // {c2}
}

type Cat = { kind: "cat"; meows: boolean };
type Dog = { kind: "dog"; barks: boolean };

function describe(pet: Cat | Dog): string {
  if ("meows" in pet) return pet.meows ? "{cat1}" : "{cat2}";
  return pet.barks ? "{dog1}" : "{dog2}";
}

console.log(formatPrice(19.5), "|", formatPrice("{ask}"), "|", formatPrice(null));
console.log(describe({ kind: "cat", meows: true }), "|", describe({ kind: "dog", barks: false }));
''', {"free": "Free", "c1": "here value is a string", "c2": "here it can only be a number", "currency": "EGP",
      "cat1": "A talkative cat", "cat2": "A quiet cat", "dog1": "A loud dog", "dog2": "A calm dog", "ask": "Ask us"},
   {"free": "مجاناً", "c1": "هنا value نص", "c2": "وهنا لا يمكن أن تكون إلا رقماً", "currency": "جنيهاً",
    "cat1": "قطة ثرثارة", "cat2": "قطة هادئة", "dog1": "كلب صاخب", "dog2": "كلب هادئ", "ask": "اسألنا"})

REMOTE = '''type RemoteData<T> =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; data: T }
  | { status: "error"; message: string };

function assertNever(value: never): never {
  throw new Error("{unexpected} " + JSON.stringify(value));
}

function render(state: RemoteData<string[]>): string {
  switch (state.status) {
    case "idle":
      return "{idle}";
    case "loading":
      return "{loading}";
    case "success":
      return `${state.data.length} {items}: ${state.data.join(", ")}`; // {c1}
@@ERROR@@    default:
      return assertNever(state); // {c2}
  }
}

const states: RemoteData<string[]>[] = [
  { status: "idle" },
  { status: "loading" },
  { status: "success", data: ["{a}", "{b}"] },
@@ERRSTATE@@];
for (const state of states) console.log(render(state));
'''
REMOTE_TEXT = ({"unexpected": "Unexpected state:", "idle": "Press the button to load", "loading": "Loading…",
                "items": "products", "c1": "data exists only in this case",
                "c2": "if a case is missing, state is not never here, and the build fails",
                "error_msg": "Could not load:", "a": "book", "b": "mug", "offline": "You are offline"},
               {"unexpected": "حالة غير متوقعة:", "idle": "اضغط الزر للتحميل", "loading": "جارٍ التحميل…",
                "items": "منتجات", "c1": "data موجودة في هذه الحالة فقط",
                "c2": "إن نقصت حالة فلن تكون state من نوع never هنا، ويفشل البناء",
                "error_msg": "تعذّر التحميل:", "a": "كتاب", "b": "كوب", "offline": "أنت غير متصل"})
example("remote.ts", REMOTE.replace("@@ERROR@@", '''    case "error":
      return `{error_msg} ${state.message}`;
''').replace("@@ERRSTATE@@", '''  { status: "error", message: "{offline}" },
'''), *REMOTE_TEXT)
example("remote-missing.ts", REMOTE.replace("@@ERROR@@", "").replace("@@ERRSTATE@@", ""), *REMOTE_TEXT)

example("generics.ts", '''function first<T>(list: readonly T[]): T | undefined {
  return list[0];
}

function byId<T extends { id: number }>(list: readonly T[]): Map<number, T> {
  return new Map(list.map((item) => [item.id, item]));
}

type Result<T> = { ok: true; value: T } | { ok: false; error: string };

function parseAge(text: string): Result<number> {
  const age = Number(text);
  if (!Number.isInteger(age) || age < 0) return { ok: false, error: `"${text}" {notage}` };
  return { ok: true, value: age };
}

const products = [
  { id: 1, name: "{book}", price: 25 },
  { id: 2, name: "{mug}", price: 8 },
];
console.log(first(products)?.name, first<number>([]));
console.log(byId(products).get(2)?.price);
for (const text of ["34", "-2", "{abc}"]) {
  const result = parseAge(text);
  console.log(result.ok ? `{age} ${result.value}` : result.error);
}
''', {"notage": "is not an age", "book": "Book", "mug": "Mug", "age": "Age:", "abc": "abc"},
   {"notage": "ليس عمراً", "book": "كتاب", "mug": "كوب", "age": "العمر:", "abc": "abc"})

example("utility.ts", '''type Product = { id: number; name: string; price: number; stock: number };

// {c1}
type ProductUpdate = Partial<Omit<Product, "id">>;
type ProductCard = Pick<Product, "name" | "price">;

function update(product: Product, changes: ProductUpdate): Product {
  return { ...product, ...changes };
}

const mug: Product = { id: 2, name: "{mug}", price: 8, stock: 40 };
const card: ProductCard = { name: mug.name, price: mug.price };
console.log(update(mug, { price: 7 }), card);

// {c2}
const ROLES = ["viewer", "editor", "admin"] as const;
type Role = (typeof ROLES)[number];
const labels = {
  viewer: "{viewer}",
  editor: "{editor}",
  admin: "{admin}",
} satisfies Record<Role, string>;

const role: Role = "editor";
console.log(ROLES.length, labels[role]);
''', {"c1": "New types made from an existing one", "c2": "One list of values, and the type comes from it",
      "mug": "Mug", "viewer": "Can view", "editor": "Can edit", "admin": "Full control"},
   {"c1": "أنواع جديدة مصنوعة من نوع موجود", "c2": "قائمة قيم واحدة، والنوع يأتي منها",
    "mug": "كوب", "viewer": "يشاهد", "editor": "يعدّل", "admin": "تحكم كامل"})

example("boundary.ts", '''type User = { id: number; name: string };

// {c1}
function isUser(value: unknown): value is User {
  return (
    typeof value === "object" &&
    value !== null &&
    "id" in value &&
    typeof value.id === "number" &&
    "name" in value &&
    typeof value.name === "string"
  );
}

function parseUser(json: string): User {
  const data: unknown = JSON.parse(json);
  if (!isUser(data)) throw new TypeError("{bad}");
  return data;
}

console.log(parseUser('{"id": 1, "name": "{name}"}').name);
try {
  parseUser('{"id": "1", "fullName": "{name}"}');
} catch (error) {
  console.log((error as Error).message);
}
''', {"c1": "A type guard: if it returns true, TypeScript treats value as a User", "bad": "The server sent a user in the wrong shape",
      "name": "Sara"},
   {"c1": "حارس نوع: إن أرجع true عاملت TypeScript القيمة كـ User", "bad": "أرسل الخادم مستخدماً بشكل خاطئ",
    "name": "سارة"})

example("index.ts", '''const prices: Record<string, number> = { book: 25, mug: 8 };
const colours = ["red", "green"];

const cap = prices["cap"];
console.log(cap.toFixed(2));
console.log(colours[5].toUpperCase());
''')

# ---------------------------------------------------------------- projects
example("projects/cart.ts", '''type Product = { readonly id: number; name: string; price: number };
type CartLine = { product: Product; quantity: number };
type Cart = { readonly lines: readonly CartLine[]; coupon?: string };

const DISCOUNTS: Record<string, number> = { WELCOME10: 0.1 };

function add(cart: Cart, product: Product, quantity = 1): Cart {
  const existing = cart.lines.find((line) => line.product.id === product.id);
  const lines = existing
    ? cart.lines.map((line) => (line === existing ? { ...line, quantity: line.quantity + quantity } : line))
    : [...cart.lines, { product, quantity }];
  return { ...cart, lines };
}

function total(cart: Cart): number {
  const sum = cart.lines.reduce((s, line) => s + line.product.price * line.quantity, 0);
  const discount = cart.coupon ? (DISCOUNTS[cart.coupon] ?? 0) : 0;
  return Math.round(sum * (1 - discount) * 100) / 100;
}

const book: Product = { id: 1, name: "{book}", price: 25 };
const mug: Product = { id: 2, name: "{mug}", price: 8 };

let cart: Cart = { lines: [] };
cart = add(cart, book);
cart = add(cart, mug, 2);
cart = add(cart, book);
console.log(cart.lines.map((l) => `${l.quantity} × ${l.product.name}`).join(", "));
console.log("{total}", total(cart));
console.log("{with}", total({ ...cart, coupon: "WELCOME10" }));
''', {"book": "Book", "mug": "Mug", "total": "Total:", "with": "With WELCOME10:"},
   {"book": "كتاب", "mug": "كوب", "total": "المجموع:", "with": "مع WELCOME10:"})

example("projects/orders.ts", '''type OrderStatus =
  | { kind: "placed"; at: string }
  | { kind: "paid"; at: string; amount: number }
  | { kind: "shipped"; at: string; tracking: string }
  | { kind: "delivered"; at: string }
  | { kind: "cancelled"; at: string; reason: string };

function assertNever(value: never): never {
  throw new Error(`{unknown} ${JSON.stringify(value)}`);
}

function describe(status: OrderStatus): string {
  switch (status.kind) {
    case "placed":
      return `{placed} ${status.at}`;
    case "paid":
      return `{paid} ${status.amount} {currency} (${status.at})`;
    case "shipped":
      return `{shipped} ${status.tracking}`;
    case "delivered":
      return `{delivered} ${status.at}`;
    case "cancelled":
      return `{cancelled} ${status.reason}`;
    default:
      return assertNever(status);
  }
}

function canCancel(status: OrderStatus): boolean {
  return status.kind === "placed" || status.kind === "paid";
}

const history: OrderStatus[] = [
  { kind: "placed", at: "09:12" },
  { kind: "paid", at: "09:14", amount: 41 },
  { kind: "shipped", at: "15:30", tracking: "EG-55120" },
];
for (const status of history) {
  console.log(describe(status), canCancel(status) ? "{yes}" : "");
}
''', {"unknown": "Unknown status:", "placed": "Order placed at", "paid": "Paid", "currency": "EGP",
      "shipped": "On its way, tracking number", "delivered": "Delivered at", "cancelled": "Cancelled:",
      "yes": "[can cancel]"},
   {"unknown": "حالة مجهولة:", "placed": "طُلب الساعة", "paid": "دُفع", "currency": "جنيهاً",
    "shipped": "في الطريق، رقم التتبع", "delivered": "سُلّم الساعة", "cancelled": "أُلغي:",
    "yes": "[يمكن إلغاؤه]"})

EMITTER = '''class Emitter<Events extends Record<string, unknown[]>> {
  #listeners: { [E in keyof Events]?: Set<(...args: Events[E]) => void> } = {};

  on<E extends keyof Events>(event: E, fn: (...args: Events[E]) => void): () => void {
    const set = (this.#listeners[event] ??= new Set());
    set.add(fn);
    return () => set.delete(fn);
  }

  emit<E extends keyof Events>(event: E, ...args: Events[E]): void {
    for (const fn of [...(this.#listeners[event] ?? [])]) fn(...args);
  }
}

type ShopEvents = {
  order: [id: number, total: number];
  logout: [];
};

const shop = new Emitter<ShopEvents>();
shop.on("order", (id, total) => console.log(`{order} #${id}: ${total.toFixed(2)}`));
shop.on("logout", () => console.log("{bye}"));

shop.emit("order", 101, 41);
shop.emit("logout");
@@BAD@@'''
EMITTER_TEXT = ({"order": "Order", "bye": "Goodbye!"}, {"order": "الطلب", "bye": "إلى اللقاء!"})
example("projects/typed-emitter.ts", EMITTER.replace("@@BAD@@", ""), *EMITTER_TEXT)
example("projects/typed-emitter-bad.ts", EMITTER.replace("@@BAD@@", '''
shop.emit("order", "101");
shop.emit("ordr", 102, 9);
shop.on("order", (id: string) => id.trim());
'''), *EMITTER_TEXT)

for lang in ("en", "ar"):
    for name, code in FILES.items():
        text = code
        for key, value in L[lang][name].items():
            text = re.sub(r"(?<!\$)\{" + key + r"\}", lambda m: value, text)
        path = HERE / lang / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
print("ok")
