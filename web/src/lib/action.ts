// [X87] One way for every button that changes something (the owner's request 2026-11-02: the actions were complicated):
// - Only the button pressed waits (busy(key)); the rest of the page goes on, and a second tap on it does nothing.
// - The result is said where the coach looks: a short toast for a success, with «تراجع» when the action can be undone,
//   and the error in the same toast (api/client.ts) and back to the screen (onError) for its own place.
// - One rule to ask first: what cannot be undone asks (confirm); a spend of coins from COINS_ASK up asks once, with
//   «لا تسألني مرة أخرى»; everything else runs at once, its undo standing in for the question.
// Screens keep their own state; act() only runs the request around it.
import { reactive } from 'vue'
import { asApiError, ensureCsrf } from '../api/client'
import { t } from './i18n'
import { useConfirm, type ConfirmAsk } from '../stores/confirm'
import { useToast } from '../stores/toast'

/** From this many coins a spend asks first (once, unless «لا تسألني مرة أخرى»). */
export const COINS_ASK = 10

const running = reactive(new Set<string>())
/** Whether the action of this key is running now (its button shows it waits). */
export const busy = (key: string) => running.has(key)

export type ActOptions<T> = {
  /** What the toast says when it worked (none: no toast). */
  success?: string | ((r: T) => string)
  /** How to take it back: the toast offers «تراجع» for a few seconds. */
  undo?: () => Promise<unknown>
  /** Ask first: for what cannot be undone. */
  confirm?: ConfirmAsk
  /** Coins this tap spends: from COINS_ASK up it asks first, once. */
  coins?: number
  /** The error's words, for the screen's own place (the toast says it too). */
  onError?: (message: string) => void
}

export async function act<T>(key: string, run: () => Promise<T>, o: ActOptions<T> = {}): Promise<T | undefined> {
  if (running.has(key)) return undefined
  const confirm = useConfirm()
  if (o.confirm && !(await confirm.ask(o.confirm))) return undefined
  if (!o.confirm && o.coins && o.coins >= COINS_ASK && !(await confirm.ask({
    title: t('تدفع {v0} كوينز؟', { v0: o.coins }), text: t('تُخصم من كوينزك الآن.'), action: t('ادفع {v0} كوينز', { v0: o.coins }), tone: 'gold', remember: 'glm.ask.coins',
  }))) return undefined
  running.add(key)
  try {
    await ensureCsrf()
    const r = await run()
    const text = typeof o.success === 'function' ? o.success(r) : o.success
    if (text) {
      // One toast per thing: a new one about the same key (the same player, the same slot) replaces the one before.
      useToast().show(text, 'success', 3200, o.undo ? { label: 'تراجع', run: () => act(`${key}:undo`, o.undo!, { success: t('تراجعت عنه.'), onError: o.onError }) } : undefined, key)
    }
    return r
  } catch (e) {
    const message = asApiError(e).message
    // The field errors (422) do not reach the toast on their own (api/client.ts): said here, once.
    if ((e as { status?: number })?.status === 422) useToast().show(t(message), 'error', 4500)
    o.onError?.(message)
    return undefined
  } finally {
    running.delete(key)
  }
}
