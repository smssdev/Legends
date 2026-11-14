import { describe, expect, it } from 'vitest'
import { nextTick, ref } from 'vue'
import { announcement, useMatchAnnouncer } from './useMatchAnnouncer'

const word = (h: number, a: number) => `${h}-${a}`

describe('announcement', () => {
  it('says the newest important entry with the score, and nothing for the rest', () => {
    const added = [
      { minute: "52'", text: 'هدف لصلاح', important: true },
      { minute: "51'", text: 'ركنية', important: false },
      { minute: "50'", text: 'بطاقة صفراء', important: true },
    ]
    expect(announcement(added, { home: 2, away: 1 }, word)).toBe("52' هدف لصلاح 2-1")
    expect(announcement([{ minute: "3'", text: 'ركنية', important: false }], { home: 0, away: 0 }, word)).toBe('')
  })
})

describe('useMatchAnnouncer', () => {
  function setup() {
    const feed = ref<{ minute: string; text: string; important: boolean }[]>([])
    const score = ref({ home: 0, away: 0 })
    const windowOn = ref(false)
    const skipping = ref(false)
    const a = useMatchAnnouncer({ feed, score, windowOn, skipping, scoreWord: word, windowWord: () => 'window' })
    return { feed, score, windowOn, skipping, a }
  }

  it('speaks a goal as it lands, then the coach’s window', async () => {
    const s = setup()
    s.score.value = { home: 1, away: 0 }
    s.feed.value = [{ minute: "10'", text: 'هدف', important: true }]
    await nextTick()
    expect(s.a.said.value).toBe("10' هدف 1-0")
    s.windowOn.value = true
    await nextTick()
    expect(s.a.said.value).toBe('window')
  })

  it('keeps quiet through a skip ahead and says only where it landed', async () => {
    const s = setup()
    s.skipping.value = true
    await nextTick()
    s.score.value = { home: 0, away: 3 }
    s.feed.value = [
      { minute: "80'", text: 'هدف', important: true },
      { minute: "40'", text: 'هدف', important: true },
    ]
    await nextTick()
    expect(s.a.said.value).toBe('')
    s.skipping.value = false
    await nextTick()
    expect(s.a.said.value).toBe('0-3')
  })
})
