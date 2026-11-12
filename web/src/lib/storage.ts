// [Sprint 58 W8] The device's own memory (localStorage) in one place: every key under one prefix, `glm.`, and reads and
// writes that never throw (private mode, a full or blocked storage: the game goes on for this visit). Keys are given
// without the prefix. The keys of before (`legends.*`) move under it once, the first time this module loads, before
// any screen reads them (every reader imports this module, so it runs first).
const PREFIX = 'glm.'
const OLD = 'legends.'

function raw(): Storage | null {
  try { return typeof localStorage === 'undefined' ? null : localStorage } catch { return null }
}

/** Moves the keys of before under the prefix, once (a key already under it wins). */
export function migrateStorage(s: Storage | null = raw()) {
  if (!s) return
  try {
    if (s.getItem(PREFIX + 'migrated')) return
    for (const k of Object.keys(s)) {
      if (!k.startsWith(OLD)) continue
      const to = PREFIX + k.slice(OLD.length)
      if (s.getItem(to) === null) s.setItem(to, s.getItem(k) ?? '')
      s.removeItem(k)
    }
    s.setItem(PREFIX + 'migrated', '1')
  } catch {
    /* blocked: nothing to move */
  }
}
migrateStorage()

export const storage = {
  get(key: string): string | null {
    try { return raw()?.getItem(PREFIX + key) ?? null } catch { return null }
  },
  set(key: string, value: string | number) {
    try { raw()?.setItem(PREFIX + key, String(value)) } catch { /* private mode: for this visit only */ }
  },
  remove(key: string) {
    try { raw()?.removeItem(PREFIX + key) } catch {}
  },
  json<T>(key: string, fallback: T): T {
    try { const v = raw()?.getItem(PREFIX + key); return v == null ? fallback : (JSON.parse(v) as T) } catch { return fallback }
  },
  setJson(key: string, value: unknown) {
    try { raw()?.setItem(PREFIX + key, JSON.stringify(value)) } catch {}
  },
}
