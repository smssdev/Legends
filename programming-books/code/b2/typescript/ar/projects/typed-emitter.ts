class Emitter<Events extends Record<string, unknown[]>> {
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
shop.on("order", (id, total) => console.log(`الطلب #${id}: ${total.toFixed(2)}`));
shop.on("logout", () => console.log("إلى اللقاء!"));

shop.emit("order", 101, 41);
shop.emit("logout");
