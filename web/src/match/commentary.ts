// Arabic commentary lines for match events (docs/PLAN.md 2.21: plain fusha).
import type { MatchEvent, Side } from '../api/sim'

type Names = (side: Side, id?: number) => string

const plans: Record<string, string> = {
  counter: 'ينطلق في هجمة مرتدة',
  long: 'يرسل كرة طويلة',
  passing: 'يتبادل التمريرات في العمق',
  wings: 'يفتح اللعب على الطرف',
  shots: 'يحاول من خارج المنطقة',
}

export function line(e: MatchEvent, name: Names, club: (s: Side) => string): string | null {
  const s = e.team as Side
  switch (e.type) {
    case 'attack': {
      const who = name(s, e.shooter || e.creator || e.receiver || e.carrier)
      switch (e.result) {
        case 'goal': return null
        case 'saved': return `${who} يسدد... والحارس ${name(s === 'home' ? 'away' : 'home', e.keeper)} يتصدى!`
        case 'missed': return `${who} يسدد بجانب القائم.`
        case 'blocked': return `تسديدة ${who} تصطدم بالدفاع.`
        case 'offside': return `راية التسلل ترتفع على ${name(s, e.receiver)}.`
        case 'cleared': return `${club(s)} ${plans[e.plan] ?? 'يهاجم'}، والدفاع يشتت.`
        case 'corner': return `${club(s)} يكسب ركنية.`
        case 'lost':
          return e.phases?.length === 1
            ? `ضغط ${club(s === 'home' ? 'away' : 'home')} يقطع بناء ${club(s)}.`
            : `${name(s === 'home' ? 'away' : 'home', e.defender)} يقطع الكرة.`
        default: return null
      }
    }
    case 'goal': return `هدف! ${name(s, e.scorer)} يسجل لـ${club(s)}${e.assist ? ` بصناعة ${name(s, e.assist)}` : ''}!`
    case 'card': return e.color === 'red'
      ? `بطاقة حمراء لـ${name(s, e.player)}! ${club(s)} يكمل بعشرة.`
      : `بطاقة صفراء لـ${name(s, e.player)}.`
    case 'penalty': return `ركلة جزاء لـ${club(s)}... ${name(s, e.taker)} ${e.scored ? 'يسجلها!' : 'يضيعها!'}`
    case 'free_kick': return `ركلة حرة مباشرة يسددها ${name(s, e.taker)}${e.scored ? '... في الشباك!' : '.'}`
    case 'injury': return `إصابة لـ${name(s, e.player)}.`
    case 'sub': return `تبديل في ${club(s)}: يدخل ${name(s, e.in)} ويخرج ${name(s, e.out)}.`
    case 'stoppage': return `${e.added} دقائق وقت بدل ضائع.`
    case 'period':
      return ({ halftime: 'صافرة نهاية الشوط الأول.', extra_time: 'إلى الوقت الإضافي!', penalties: 'إلى ركلات الترجيح!', fulltime: 'صافرة النهاية.' } as Record<string, string>)[e.name] ?? null
    case 'shootout': return `ركلات الترجيح: ${e.score.home} - ${e.score.away}.`
    default: return null
  }
}
