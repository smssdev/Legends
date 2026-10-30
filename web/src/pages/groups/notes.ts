// [Sprint 29] A group's own notes ("Sara added Omar"), sent as JSON by the server (ChatGroups::note), in words.
import { t } from '../../lib/i18n'

export function noteText(body: string): string {
  let n: { what?: string; by?: string; name?: string } = {}
  try { n = JSON.parse(body) } catch { return '' }
  const v = { by: n.by ?? '', name: n.name ?? '' }
  switch (n.what) {
    case 'created': return t('أنشأ {by} الجروب', v)
    case 'added': return t('أضاف {by} {name}', v)
    case 'joined': return t('انضم {name} بالرابط', v)
    case 'left': return t('غادر {name}', v)
    case 'removed': return t('أخرج {by} {name}', v)
    case 'renamed': return t('غيّر {by} اسم الجروب إلى «{name}»', v)
    default: return ''
  }
}
