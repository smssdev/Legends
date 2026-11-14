// [Sprint 65 W5] What axe cannot see in a page it never opened, checked in the source before every build:
// - every <button> says its type (a button with none submits the form it sits in: W-A03);
// - no table row is a control (a <tr> with tabindex or a key handler is no button to a screen reader: W-A02); the row
//   opens with the mouse, and a real button in its name cell opens it with the keys.
import fs from 'node:fs'
import path from 'node:path'

const root = new URL('../src/', import.meta.url).pathname
const walk = (d) =>
  fs
    .readdirSync(d, { withFileTypes: true })
    .flatMap((e) => (e.isDirectory() ? walk(path.join(d, e.name)) : e.name.endsWith('.vue') ? [path.join(d, e.name)] : []))

/** Every opening tag of a name, whole (quotes respected: a `>` inside an attribute does not close it). */
function tags(src, name) {
  const out = []
  const re = new RegExp(`<${name}\\b`, 'g')
  let m
  while ((m = re.exec(src))) {
    let i = m.index + name.length + 1
    let q = null
    for (; i < src.length; i++) {
      const c = src[i]
      if (q) {
        if (c === q) q = null
      } else if (c === '"' || c === "'") q = c
      else if (c === '>') break
    }
    out.push({ tag: src.slice(m.index, i + 1), line: src.slice(0, m.index).split('\n').length })
  }
  return out
}

const bad = []
for (const f of walk(root)) {
  const src = fs.readFileSync(f, 'utf8')
  const rel = path.relative(root, f)
  for (const { tag, line } of tags(src, 'button')) if (!/\s:?type=/.test(tag)) bad.push(`${rel}:${line} a <button> with no type`)
  for (const { tag, line } of tags(src, 'tr'))
    if (/\stabindex=|@keydown/.test(tag)) bad.push(`${rel}:${line} a table row made a control: put a button in its name cell`)
}
if (bad.length) {
  console.error(`a11y: ${bad.length} problem(s)\n  ${bad.join('\n  ')}`)
  process.exit(1)
}
console.log('a11y: every button has its type, no row is a control')
