// Idempotency keys that belong to one client and expire, with a clock that tests can control.
export type Saved<T> = { fingerprint: string; result?: T; storedAt: number };

export class IdempotencyStore<T> {
  #entries = new Map<string, Saved<T>>();
  #ttl: number;
  #now: () => number;

  constructor(ttlMs = 24 * 60 * 60 * 1000, now = () => Date.now()) {
    this.#ttl = ttlMs;
    this.#now = now;
  }

  // The same key from two clients is two different keys.
  #id(client: string, key: string) {
    return `${client}:${key}`;
  }

  get(client: string, key: string): Saved<T> | undefined {
    const entry = this.#entries.get(this.#id(client, key));
    if (entry && this.#now() - entry.storedAt >= this.#ttl) {
      this.#entries.delete(this.#id(client, key));
      return undefined;
    }
    return entry;
  }

  set(client: string, key: string, fingerprint: string, result?: T) {
    this.#entries.set(this.#id(client, key), { fingerprint, result, storedAt: this.#now() });
  }

  delete(client: string, key: string) {
    this.#entries.delete(this.#id(client, key));
  }
}
