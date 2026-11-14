import { createPinia, setActivePinia } from 'pinia'
import { beforeEach, describe, expect, it, vi } from 'vitest'

vi.mock('../api/client', () => ({
  ensureCsrf: vi.fn(async () => {}),
  asApiError: (e: { message?: string }) => ({ message: e?.message ?? 'خطأ' }),
}))

import { act, busy, COINS_ASK } from './action'
import { useConfirm } from '../stores/confirm'
import { useToast } from '../stores/toast'

describe('act', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
    localStorage.clear()
  })

  it('waits on the pressed button only, ignores a second tap, and says the success', async () => {
    let finish!: (v: number) => void
    const run = vi.fn(() => new Promise<number>((r) => (finish = r)))
    const first = act('buy:7', run, { success: (n) => `اشتريت ${n}` })
    await Promise.resolve()
    await Promise.resolve()
    expect(busy('buy:7')).toBe(true)
    expect(busy('buy:8')).toBe(false)
    expect(await act('buy:7', run)).toBeUndefined()
    finish(3)
    expect(await first).toBe(3)
    expect(run).toHaveBeenCalledTimes(1)
    expect(busy('buy:7')).toBe(false)
    expect(useToast().list.map((t) => t.text)).toEqual(['اشتريت 3'])
  })

  it('offers an undo that runs the way back', async () => {
    const undo = vi.fn(async () => 'back')
    await act('sell:1', async () => 1, { success: 'عُرض', undo })
    const toast = useToast().list[0]!
    expect(toast.action?.label).toBe('تراجع')
    await toast.action!.run()
    expect(undo).toHaveBeenCalledOnce()
  })

  it('asks before what cannot be undone, and does nothing on a no', async () => {
    const run = vi.fn(async () => 1)
    const confirm = useConfirm()
    vi.spyOn(confirm, 'ask').mockResolvedValue(false)
    expect(await act('delete', run, { confirm: { title: 'احذف؟', action: 'احذف' } })).toBeUndefined()
    expect(run).not.toHaveBeenCalled()
  })

  it('asks before a spend of coins from the threshold up, not under it', async () => {
    const confirm = useConfirm()
    const ask = vi.spyOn(confirm, 'ask').mockResolvedValue(true)
    await act('spend:small', async () => 1, { coins: COINS_ASK - 1 })
    expect(ask).not.toHaveBeenCalled()
    await act('spend:big', async () => 1, { coins: COINS_ASK })
    expect(ask).toHaveBeenCalledOnce()
    expect(ask.mock.calls[0]![0]).toMatchObject({ tone: 'gold', remember: 'ask.coins' })
  })

  it('gives the error to the screen, and to the toast for a form error', async () => {
    const onError = vi.fn()
    expect(
      await act(
        'save',
        async () => {
          throw Object.assign(new Error('الاسم مطلوب'), { status: 422 })
        },
        { onError },
      ),
    ).toBeUndefined()
    expect(onError).toHaveBeenCalledWith('الاسم مطلوب')
    expect(useToast().list.map((t) => [t.text, t.tone])).toEqual([['الاسم مطلوب', 'error']])
    expect(busy('save')).toBe(false)
  })
})
