// [Sprint 30 P11] The server's states in words: a league's and an alliance tournament's, never «waiting» or «running»
// on a screen. Arabic keys (en.ts has their English); anything unknown keeps its own word.
const LABELS: Record<string, string> = {
  waiting: 'بانتظار البداية',
  running: 'جارٍ',
  finished: 'انتهى',
  pending: 'بانتظار الاعتماد',
  approved: 'معتمد',
  rejected: 'مرفوض',
  cancelled: 'أُلغي',
  live: 'مباشر',
  upcoming: 'قادم',
}

export function statusLabel(status: string | null | undefined): string {
  return status ? (LABELS[status] ?? status) : ''
}
