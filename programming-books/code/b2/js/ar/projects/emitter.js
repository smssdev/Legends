class Emitter {
  #listeners = new Map();

  on(event, fn) {
    if (!this.#listeners.has(event)) this.#listeners.set(event, new Set());
    this.#listeners.get(event).add(fn);
    return () => this.off(event, fn); // on تُرجع دالة تزيل المستمع
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
const stopLog = shop.on("order", (id) => console.log("السجل: الطلب", id));
shop.once("order", (id) => console.log("أول طلب اليوم:", id));

shop.emit("order", 101);
shop.emit("order", 102);
stopLog();
shop.emit("order", 103);
console.log("لا مستمعين بعد الآن.");
