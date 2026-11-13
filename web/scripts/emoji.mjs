// [Sprint 63 G5] No pictographs in the interface: a symbol on a screen is an icon of the set (brand/icons, Icon.vue in
// the site, GlmIcon in the app), drawn the same everywhere. Counts the emoji and pictograph symbols in the site's
// templates (the <template> of each .vue) and in the app's code (mobile/lib, past its words in l10n), except the
// match's reactions, which are emoji by design. The files not moved yet are in emoji-baseline.json, each with its
// count: a file may only go down, and a new one fails. After moving some: node scripts/emoji.mjs --write.
import { readdirSync, readFileSync, statSync, writeFileSync } from 'node:fs'
import { join, relative } from 'node:path'

const ROOT = join(import.meta.dirname, '..', '..')
const BASE = join(import.meta.dirname, 'emoji-baseline.json')
const EMOJI = /[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}\u{2190}-\u{21FF}\u{25A0}-\u{25FF}\u{2300}-\u{23FF}]/gu
// The reactions (a fan's 🔥 or 👏, a cheer 📣) are emoji on purpose: the web's and the app's lists and bars of them;
// and the cartoon clips' drawn crowd (a thumbs-up over the stand) is art, not the interface.
const REACTIONS = [
  'web/src/match/useMatchSocial.ts',
  'mobile/lib/features/match/live_state.dart',
  'mobile/lib/features/match/live_screen_social.dart',
  'mobile/lib/features/match/live_screen_broadcast.dart',
  'mobile/lib/features/groups/chat_screen.dart',
  'mobile/lib/features/match/feed/clips_corner.dart',
]

const walk = (dir, ext) =>
  readdirSync(dir).flatMap((f) => {
    const p = join(dir, f)
    return statSync(p).isDirectory() ? (f === 'l10n' || f === 'gen' ? [] : walk(p, ext)) : p.endsWith(ext) ? [p] : []
  })
const count = (text) => text.split('\n').filter((l) => !/^\s*(\/\/|\*|\/\*)/.test(l)).join('\n').match(EMOJI)?.length ?? 0

const now = {}
for (const f of walk(join(ROOT, 'web/src'), '.vue')) {
  const s = readFileSync(f, 'utf8')
  const t = s.slice(s.indexOf('<template'))
  const n = s.includes('<template') ? count(t.replace(/<!--[\s\S]*?-->/g, '')) : 0
  if (n) now[relative(ROOT, f)] = n
}
for (const f of walk(join(ROOT, 'mobile/lib'), '.dart')) {
  const rel = relative(ROOT, f)
  const n = REACTIONS.includes(rel) || rel.endsWith('.g.dart') ? 0 : count(readFileSync(f, 'utf8'))
  if (n) now[rel] = n
}

if (process.argv.includes('--write')) {
  writeFileSync(BASE, JSON.stringify(Object.fromEntries(Object.entries(now).sort()), null, 2) + '\n')
  console.log(`emoji: baseline written, ${Object.keys(now).length} files still to move`)
  process.exit(0)
}
const base = JSON.parse(readFileSync(BASE, 'utf8'))
const worse = Object.entries(now).filter(([f, n]) => n > (base[f] ?? 0))
if (worse.length) {
  console.error('emoji: a symbol on a screen is an icon of the set (Icon.vue, GlmIcon), not an emoji:')
  for (const [f, n] of worse) console.error(`  ${f}: ${n} (allowed ${base[f] ?? 0})`)
  process.exit(1)
}
const total = Object.values(now).reduce((a, b) => a + b, 0)
console.log(`emoji: OK (${Object.keys(now).length} files, ${total} symbols still to move)`)
