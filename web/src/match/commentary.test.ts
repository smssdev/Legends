import { describe, expect, it } from 'vitest'
import type { MatchEvent } from '../api/sim'
import { line } from './commentary'

const name = (s: string, id?: number) => `${s}#${id ?? '-'}`
const club = (s: string) => (s === 'home' ? 'ليفربول' : 'آرسنال')
const say = (e: Record<string, unknown>) => line(e as unknown as MatchEvent, name as never, club as never)

describe('commentary lines', () => {
  it('tells attacks by how they end', () => {
    expect(say({ type: 'attack', team: 'home', result: 'saved', shooter: 11, keeper: 1 })).toBe('home#11 يسدد... والحارس away#1 يتصدى!')
    expect(say({ type: 'attack', team: 'home', result: 'missed', creator: 8 })).toBe('home#8 يسدد بجانب القائم.')
    expect(say({ type: 'attack', team: 'home', result: 'blocked', shooter: 9 })).toBe('تسديدة home#9 تصطدم بالدفاع.')
    expect(say({ type: 'attack', team: 'away', result: 'offside', receiver: 7 })).toBe('راية التسلل ترتفع على away#7.')
    expect(say({ type: 'attack', team: 'home', result: 'cleared', plan: 'wings' })).toBe('ليفربول يفتح اللعب على الطرف، والدفاع يشتت.')
    expect(say({ type: 'attack', team: 'home', result: 'cleared', plan: 'odd' })).toBe('ليفربول يهاجم، والدفاع يشتت.')
    expect(say({ type: 'attack', team: 'home', result: 'corner' })).toBe('ليفربول يكسب ركنية.')
    expect(say({ type: 'attack', team: 'home', result: 'lost', phases: [1] })).toBe('ضغط آرسنال يقطع بناء ليفربول.')
    expect(say({ type: 'attack', team: 'home', result: 'lost', phases: [1, 2], defender: 4 })).toBe('away#4 يقطع الكرة.')
    expect(say({ type: 'attack', team: 'home', result: 'goal' })).toBeNull()
    expect(say({ type: 'attack', team: 'home', result: 'other' })).toBeNull()
  })

  it('tells goals, cards, set pieces and the match’s moments', () => {
    expect(say({ type: 'goal', team: 'home', scorer: 11, assist: 8 })).toBe('هدف! home#11 يسجل لـليفربول بصناعة home#8!')
    expect(say({ type: 'goal', team: 'away', scorer: 9 })).toBe('هدف! away#9 يسجل لـآرسنال!')
    expect(say({ type: 'card', team: 'away', color: 'red', player: 5 })).toBe('بطاقة حمراء لـaway#5! آرسنال يكمل بعشرة.')
    expect(say({ type: 'card', team: 'away', color: 'yellow', player: 5 })).toBe('بطاقة صفراء لـaway#5.')
    expect(say({ type: 'penalty', team: 'home', taker: 11, scored: true })).toBe('ركلة جزاء لـليفربول... home#11 يسجلها!')
    expect(say({ type: 'penalty', team: 'home', taker: 11, scored: false })).toBe('ركلة جزاء لـليفربول... home#11 يضيعها!')
    expect(say({ type: 'free_kick', team: 'home', taker: 10, scored: true })).toBe('ركلة حرة مباشرة يسددها home#10... في الشباك!')
    expect(say({ type: 'injury', team: 'home', player: 4 })).toBe('إصابة لـhome#4.')
    expect(say({ type: 'sub', team: 'home', in: 14, out: 9 })).toBe('تبديل في ليفربول: يدخل home#14 ويخرج home#9.')
    expect(say({ type: 'stoppage', added: 4 })).toBe('4 دقائق وقت بدل ضائع.')
    expect(say({ type: 'period', name: 'fulltime' })).toBe('صافرة النهاية.')
    expect(say({ type: 'period', name: 'kickoff' })).toBeNull()
    expect(say({ type: 'shootout', score: { home: 4, away: 3 } })).toBe('ركلات الترجيح: 4 - 3.')
    expect(say({ type: 'unknown' })).toBeNull()
  })
})
