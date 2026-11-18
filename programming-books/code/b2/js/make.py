"""Writes the examples of Book 2, chapter "Modern JavaScript in Depth", in English and Arabic.
Run: python3 make.py   (the files go to en/ and ar/; the book runs each one and shows its real output)

Each example is a template: {key} is replaced by the text of the language. Code names stay in English.
"""
from pathlib import Path

HERE = Path(__file__).parent

FILES = {}
L = {"en": {}, "ar": {}}


def example(name, code, en=None, ar=None):
    FILES[name] = code
    L["en"][name] = en or {}
    L["ar"][name] = ar or {}


# ---------------------------------------------------------------- values and references
example("values.js", '''// {c1}
let a = 10;
let b = a;
b = 20;
console.log(a, b);

// {c2}
const original = { name: "{name}", tags: ["js"] };
const same = original;
same.name = "{other}";
console.log(original.name);

// {c3}
const shallow = { ...original };
shallow.tags.push("ts");
console.log(original.tags);

// {c4}
const deep = structuredClone(original);
deep.tags.push("react");
console.log(original.tags, deep.tags);
''', {"c1": "Primitives are copied", "c2": "Objects are shared: two names, one object",
      "c3": "Spread copies only the first level", "c4": "structuredClone copies every level",
      "name": "Sara", "other": "Huda"},
   {"c1": "القيم البسيطة تُنسخ", "c2": "الكائنات مشتركة: اسمان لكائن واحد",
    "c3": "النشر ينسخ المستوى الأول فقط", "c4": "structuredClone ينسخ كل المستويات",
    "name": "سارة", "other": "هدى"})

example("immutable.js", '''const cart = { items: [{ id: 1, qty: 1 }], coupon: null };

// {c1}
function addOne(cart, id) {
  return {
    ...cart,
    items: cart.items.map((item) =>
      item.id === id ? { ...item, qty: item.qty + 1 } : item,
    ),
  };
}

const next = addOne(cart, 1);
console.log(cart.items[0].qty, next.items[0].qty);
console.log(cart === next, cart.items === next.items);
''', {"c1": "Return a new object instead of changing the old one"},
   {"c1": "أرجع كائناً جديداً بدل تغيير القديم"})

# ---------------------------------------------------------------- scope and closures
example("closures.js", '''function makeCounter(start = 0) {
  let count = start; // {c1}
  return {
    up: () => ++count,
    down: () => --count,
    value: () => count,
  };
}

const likes = makeCounter();
const stock = makeCounter(10);
likes.up();
likes.up();
stock.down();
console.log(likes.value(), stock.value());
console.log(likes.count); // {c2}
''', {"c1": "private: only the three functions can see it", "c2": "undefined: there is no way in from outside"},
   {"c1": "خاص: لا تراه إلا الدوال الثلاث", "c2": "undefined: لا طريق إليه من الخارج"})

example("once.js", '''function once(fn) {
  let done = false;
  let result;
  return (...args) => {
    if (!done) {
      done = true;
      result = fn(...args);
    }
    return result;
  };
}

const connect = once(() => {
  console.log("{connecting}");
  return "connection #1";
});

console.log(connect());
console.log(connect());
''', {"connecting": "Connecting to the server…"}, {"connecting": "جارٍ الاتصال بالخادم…"})

example("loop.js", '''for (var i = 1; i <= 3; i++) {
  setTimeout(() => console.log("var:", i));
}
for (let j = 1; j <= 3; j++) {
  setTimeout(() => console.log("let:", j));
}
''')

# ---------------------------------------------------------------- classes and this
example("classes.js", '''class Account {
  #balance = 0; // {c1}
  static count = 0;

  constructor(owner) {
    this.owner = owner;
    Account.count++;
  }

  get balance() {
    return this.#balance;
  }

  deposit(amount) {
    if (amount <= 0) throw new RangeError("{positive}");
    this.#balance += amount;
    return this; // {c2}
  }
}

class SavingsAccount extends Account {
  addInterest(rate) {
    return this.deposit(Math.round(this.balance * rate));
  }
}

const acc = new SavingsAccount("{owner}");
acc.deposit(1000).deposit(500).addInterest(0.1);
console.log(acc.owner, acc.balance, Account.count);
console.log(acc instanceof Account);

try {
  acc.deposit(-5);
} catch (error) {
  console.log(error.name + ":", error.message);
}
''', {"c1": "private field: invisible outside the class", "c2": "returning this lets calls be chained",
      "positive": "Amount must be positive", "owner": "Sara"},
   {"c1": "حقل خاص: لا يُرى خارج الصنف", "c2": "إرجاع this يسمح بسلسلة الاستدعاءات",
    "positive": "يجب أن يكون المبلغ موجباً", "owner": "سارة"})

example("this.js", '''class Timer {
  seconds = 0;

  tick() {
    this.seconds++;
  }

  tickArrow = () => {
    this.seconds++;
  };
}

const timer = new Timer();
const run = (callback) => callback();

try {
  run(timer.tick); // {c1}
} catch (error) {
  console.log("{lost}", error.message);
}

run(() => timer.tick()); // {c2}
run(timer.tick.bind(timer)); // {c3}
run(timer.tickArrow); // {c4}
console.log(timer.seconds);
''', {"c1": "the method is passed without its object", "c2": "fix 1: call it inside an arrow function",
      "c3": "fix 2: bind it to the object", "c4": "fix 3: an arrow-function field keeps this",
      "lost": "Lost this:"},
   {"c1": "مُررت الدالة دون كائنها", "c2": "الحل 1: استدعها داخل دالة سهمية",
    "c3": "الحل 2: اربطها بالكائن بـ bind", "c4": "الحل 3: حقل بدالة سهمية يحفظ this",
    "lost": "ضاع this:"})

# ---------------------------------------------------------------- the modern toolkit
example("modern.js", '''const user = { name: "{name}", address: null, settings: { theme: "" } };

// {c1}
console.log(user.address?.city);
console.log(user.address?.city ?? "{unknown}");

// {c2}
console.log(user.settings.theme || "light", user.settings.theme ?? "light");

// {c3}
user.settings.fontSize ??= 16;
console.log(user.settings);

const scores = [72, 95, 88, 61];
console.log(scores.at(-1), scores.findLast((s) => s > 80));
console.log(scores.toSorted((a, b) => b - a), scores); // {c4}
''', {"c1": "?. stops at null or undefined instead of crashing", "c2": "|| replaces every falsy value; ?? only null and undefined",
      "c3": "??= assigns only when the value is missing", "c4": "toSorted returns a copy: the original keeps its order",
      "name": "Omar", "unknown": "unknown"},
   {"c1": "?. تتوقف عند null أو undefined بدل الانهيار", "c2": "|| تستبدل كل قيمة كاذبة، و?? تستبدل null وundefined فقط",
    "c3": "??= تُسند فقط حين تكون القيمة ناقصة", "c4": "toSorted تُرجع نسخة: يبقى الأصل بترتيبه",
    "name": "عمر", "unknown": "غير معروف"})

example("group.js", '''const orders = [
  { id: 1, status: "paid", total: 40 },
  { id: 2, status: "pending", total: 15 },
  { id: 3, status: "paid", total: 22 },
  { id: 4, status: "refunded", total: 9 },
];

const byStatus = Object.groupBy(orders, (order) => order.status);
console.log(Object.keys(byStatus));

const totals = Object.fromEntries(
  Object.entries(byStatus).map(([status, list]) => [
    status,
    list.reduce((sum, order) => sum + order.total, 0),
  ]),
);
console.log(totals);
''')

# ---------------------------------------------------------------- collections and generators
example("collections.js", '''// {c1}
const visits = new Map();
for (const page of ["/home", "/shop", "/home", "/cart", "/home"]) {
  visits.set(page, (visits.get(page) ?? 0) + 1);
}
console.log(visits);
console.log([...visits].toSorted((a, b) => b[1] - a[1])[0]);

// {c2}
const tags = new Set(["js", "css", "js", "html", "css"]);
console.log(tags.size, tags.has("css"), [...tags]);
''', {"c1": "Map: keys of any type, kept in insertion order", "c2": "Set: each value once"},
   {"c1": "Map: مفاتيح من أي نوع، بترتيب الإضافة", "c2": "Set: كل قيمة مرة واحدة"})

example("generators.js", '''function* range(from, to, step = 1) {
  for (let n = from; n <= to; n += step) {
    yield n; // {c1}
  }
}

console.log([...range(1, 10, 3)]);

// {c2}
function* pages(items, size) {
  for (let i = 0; i < items.length; i += size) {
    yield items.slice(i, i + size);
  }
}

const letters = "ABCDEFG".split("");
for (const page of pages(letters, 3)) {
  console.log(page.join(" "));
}
''', {"c1": "pause here and hand n to the caller", "c2": "A generator that splits a list into pages"},
   {"c1": "توقف هنا وسلّم n للمستدعي", "c2": "مولّد يقسم القائمة إلى صفحات"})

# ---------------------------------------------------------------- the event loop
example("event-loop.js", '''console.log("1 {sync}");

setTimeout(() => console.log("5 {timer}"), 0);

Promise.resolve().then(() => console.log("3 {micro}"));
queueMicrotask(() => console.log("4 {micro2}"));

console.log("2 {sync2}");
''', {"sync": "synchronous code runs first", "timer": "a timer: a task, after all microtasks",
      "micro": "a promise callback: a microtask", "micro2": "another microtask, in order",
      "sync2": "still synchronous"},
   {"sync": "الكود المتزامن يعمل أولاً", "timer": "مؤقت: مهمة، بعد كل المهام الدقيقة",
    "micro": "رد وعد: مهمة دقيقة", "micro2": "مهمة دقيقة أخرى، بالترتيب",
    "sync2": "ما زال متزامناً"})

example("promises.js", '''const wait = (ms, value, fail = false) =>
  new Promise((resolve, reject) =>
    setTimeout(() => (fail ? reject(new Error(value)) : resolve(value)), ms),
  );

const results = await Promise.allSettled([
  wait(30, "{profile}"),
  wait(10, "{orders}", true),
  wait(20, "{messages}"),
]);
for (const r of results) {
  console.log(r.status, r.value ?? r.reason.message);
}

// {c1}
const fastest = await Promise.any([wait(40, "{mirror1}"), wait(15, "{mirror2}")]);
console.log("{winner}", fastest);

// {c2}
const timeout = (ms) => wait(ms, "{timeout}", true);
try {
  await Promise.race([wait(100, "{slow}"), timeout(50)]);
} catch (error) {
  console.log(error.message);
}
''', {"profile": "profile", "orders": "orders failed", "messages": "messages",
      "c1": "any: the first one to succeed", "c2": "race: the first one to finish, success or failure",
      "mirror1": "mirror A", "mirror2": "mirror B", "winner": "Fastest:", "timeout": "Timed out after 50 ms", "slow": "slow answer"},
   {"profile": "الملف الشخصي", "orders": "فشلت الطلبات", "messages": "الرسائل",
    "c1": "any: أول من ينجح", "c2": "race: أول من ينتهي، نجاحاً أو فشلاً",
    "mirror1": "النسخة أ", "mirror2": "النسخة ب", "winner": "الأسرع:", "timeout": "انتهت المهلة بعد 50 ملي ثانية", "slow": "رد بطيء"})

# ---------------------------------------------------------------- errors
example("errors.js", '''class NotFoundError extends Error {
  constructor(what, options) {
    super(`${what} {notfound}`, options);
    this.name = "NotFoundError";
  }
}

const users = new Map([[1, "{name}"]]);

function findUser(id) {
  if (!users.has(id)) throw new NotFoundError(`{user} #${id}`);
  return users.get(id);
}

function loadProfile(id) {
  try {
    return findUser(id);
  } catch (error) {
    throw new Error("{profile}", { cause: error }); // {c1}
  }
}

try {
  loadProfile(7);
} catch (error) {
  console.log(error.message);
  console.log("{because}", error.cause.name, "-", error.cause.message);
  console.log(error.cause instanceof NotFoundError);
}
''', {"notfound": "was not found", "name": "Sara", "user": "User", "profile": "Could not load the profile",
      "c1": "keep the original error as the cause", "because": "Because:"},
   {"notfound": "غير موجود", "name": "سارة", "user": "المستخدم", "profile": "تعذّر تحميل الملف الشخصي",
    "c1": "احتفظ بالخطأ الأصلي سبباً", "because": "السبب:"})

# ---------------------------------------------------------------- projects
example("projects/memoize.js", '''function memoize(fn) {
  const cache = new Map();
  return (arg) => {
    if (cache.has(arg)) return cache.get(arg);
    const result = fn(arg);
    cache.set(arg, result);
    return result;
  };
}

let calls = 0;
function slowSquare(n) {
  calls++;
  return n * n;
}

const fastSquare = memoize(slowSquare);
console.log(fastSquare(9), fastSquare(9), fastSquare(12), fastSquare(9));
console.log("{calls}", calls);

// {c1}
const fib = memoize((n) => (n < 2 ? n : fib(n - 1) + fib(n - 2)));
console.log("fib(70) =", fib(70));
''', {"calls": "Real calls:", "c1": "Without the cache, fib(70) would need trillions of calls"},
   {"calls": "الاستدعاءات الحقيقية:", "c1": "دون الذاكرة المؤقتة يحتاج fib(70) إلى تريليونات الاستدعاءات"})

example("projects/emitter.js", '''class Emitter {
  #listeners = new Map();

  on(event, fn) {
    if (!this.#listeners.has(event)) this.#listeners.set(event, new Set());
    this.#listeners.get(event).add(fn);
    return () => this.off(event, fn); // {c1}
  }

  off(event, fn) {
    this.#listeners.get(event)?.delete(fn);
  }

  once(event, fn) {
    const stop = this.on(event, (...args) => {
      stop();
      fn(...args);
    });
    return stop;
  }

  emit(event, ...args) {
    for (const fn of [...(this.#listeners.get(event) ?? [])]) fn(...args);
  }
}

const shop = new Emitter();
const stopLog = shop.on("order", (id) => console.log("{log}", id));
shop.once("order", (id) => console.log("{first}", id));

shop.emit("order", 101);
shop.emit("order", 102);
stopLog();
shop.emit("order", 103);
console.log("{done}");
''', {"c1": "on returns a function that removes the listener", "log": "Log: order", "first": "First order of the day:",
      "done": "No more listeners."},
   {"c1": "on تُرجع دالة تزيل المستمع", "log": "السجل: الطلب", "first": "أول طلب اليوم:",
    "done": "لا مستمعين بعد الآن."})

example("projects/retry.js", '''const wait = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function retry(fn, { retries = 3, delay = 10 } = {}) {
  for (let attempt = 1; ; attempt++) {
    try {
      return await fn(attempt);
    } catch (error) {
      if (attempt > retries) {
        throw new Error(`{gaveup} ${attempt} {attempts}`, { cause: error });
      }
      const pause = delay * 2 ** (attempt - 1); // {c1}
      console.log(`  {att} ${attempt} {failed} ${pause} ms`);
      await wait(pause);
    }
  }
}

// {c2}
function flaky(failures) {
  let left = failures;
  return async (attempt) => {
    if (left-- > 0) throw new Error("{network}");
    return `OK ({on} ${attempt})`;
  };
}

console.log("{api1}");
console.log(await retry(flaky(2)));

console.log("{api2}");
try {
  await retry(flaky(5), { retries: 2 });
} catch (error) {
  console.log(error.message, "-", error.cause.message);
}
''', {"gaveup": "Gave up after", "attempts": "attempts", "c1": "exponential backoff: 10, 20, 40 ms…",
      "att": "attempt", "failed": "failed, waiting", "c2": "A fake API that fails a fixed number of times first",
      "network": "Network error", "on": "on attempt", "api1": "API that fails twice:", "api2": "API that fails five times:"},
   {"gaveup": "استسلمت بعد", "attempts": "محاولات", "c1": "انتظار متضاعف: 10 ثم 20 ثم 40 ملي ثانية…",
    "att": "المحاولة", "failed": "فشلت، انتظار", "c2": "واجهة وهمية تفشل عدداً محدداً من المرات أولاً",
    "network": "خطأ في الشبكة", "on": "في المحاولة", "api1": "واجهة تفشل مرتين:", "api2": "واجهة تفشل خمس مرات:"})


for lang in ("en", "ar"):
    for name, code in FILES.items():
        text = code
        for key, value in L[lang][name].items():
            text = text.replace("{" + key + "}", value)
        path = HERE / lang / name
        if name == "promises.js" or name == "projects/retry.js":
            path = path.with_suffix(".mjs")  # top-level await needs an ES module
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)
print("ok")
