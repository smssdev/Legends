// Expands Claude Design artboards (*.dc.html) into standalone static HTML pages.
// Usage: node tools/design-export/render.mjs <src-dir> <out-dir>
// The output pages are then screenshotted by shoot.py.
import fs from 'node:fs';
import path from 'node:path';

const [, , srcDir, outDir] = process.argv;
if (!srcDir || !outDir) {
  console.error('usage: node render.mjs <src-dir> <out-dir>');
  process.exit(1);
}

// Uploaded design assets → brand files in the repo.
const BLOBS = {
  '3db7f68e0ee8f757e178e4c66bed01da': 'icon-512.png',
  '89a325fa4a1e6b568f5d9f97d7aa5150': 'logo-512.png',
  '5bd2c4d5326f6c6a577d7a17fa6803e8': 'coin-128.png',
};

class DCLogic {
  constructor() { this.props = {}; this.state = {}; }
  setState(s) { Object.assign(this.state, s); }
  forceUpdate() {}
}

function lookup(scope, expr) {
  const p = expr.trim();
  if (p === 'true') return true;
  if (p === 'false') return false;
  if (/^-?\d+(\.\d+)?$/.test(p)) return Number(p);
  let v = scope;
  for (const part of p.split('.')) {
    if (v == null) return undefined;
    v = v[part];
  }
  return v;
}

const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');

function fillHoles(text, scope) {
  return text.replace(/\{\{\s*([^}]+?)\s*\}\}/g, (_, e) => {
    const v = lookup(scope, e);
    if (v == null || typeof v === 'function') return '';
    return esc(v);
  });
}

// Finds the matching close tag for a custom block tag, honoring nesting.
function matchBlock(text, start, tag) {
  const open = new RegExp(`<${tag}\\b`, 'g');
  const close = new RegExp(`</${tag}>`, 'g');
  let depth = 0;
  let i = start;
  while (true) {
    open.lastIndex = i; close.lastIndex = i;
    const o = open.exec(text);
    const c = close.exec(text);
    if (!c) throw new Error(`unclosed <${tag}>`);
    if (o && o.index < c.index) { depth++; i = o.index + 1; continue; }
    depth--;
    if (depth === 0) return { end: c.index, after: c.index + c[0].length };
    i = c.index + 1;
  }
}

function expand(text, scope) {
  let out = '';
  let i = 0;
  const re = /<(sc-for|sc-if)\b([^>]*)>/g;
  while (true) {
    re.lastIndex = i;
    const m = re.exec(text);
    if (!m) { out += fillHoles(text.slice(i), scope); return out; }
    out += fillHoles(text.slice(i, m.index), scope);
    const tag = m[1];
    const attrs = m[2];
    const { end, after } = matchBlock(text, m.index, tag);
    const inner = text.slice(m.index + m[0].length, end);
    const attr = (name) => {
      const a = attrs.match(new RegExp(`${name}="\\{\\{\\s*([^}]+?)\\s*\\}\\}"`)) || attrs.match(new RegExp(`${name}="([^"]*)"`));
      return a ? a[1] : undefined;
    };
    if (tag === 'sc-for') {
      const list = lookup(scope, attr('list')) || [];
      const as = attr('as') || 'item';
      list.forEach((item, idx) => { out += expand(inner, { ...scope, [as]: item, $index: idx }); });
    } else if (lookup(scope, attr('value'))) {
      out += expand(inner, scope);
    }
    i = after;
  }
}

function render(file) {
  const src = fs.readFileSync(file, 'utf8');
  const dc = src.match(/<x-dc>([\s\S]*?)<\/x-dc>/)[1];
  const helmet = (dc.match(/<helmet>([\s\S]*?)<\/helmet>/) || [, ''])[1];
  const body = dc.replace(/<helmet>[\s\S]*?<\/helmet>/, '');
  const code = src.match(/<script type="text\/x-dc"[^>]*>([\s\S]*?)<\/script>/)[1];
  const title = (src.match(/<title>([\s\S]*?)<\/title>/) || [, 'Legends'])[1];
  const lang = (src.match(/<html lang="([^"]+)"/) || [, 'ar'])[1];
  const Component = new Function('DCLogic', `${code}\nreturn Component;`)(DCLogic);
  const vals = new Component().renderVals();
  let html = expand(body, vals);
  html = html
    .replace(/\/_blob\/([0-9a-f]{32})/g, (_, id) => `assets/${BLOBS[id] || id}`)
    .replace(/href="([A-Za-z]+)\.dc\.html"/g, 'href="$1.html"');
  return `<!doctype html>
<html lang="${lang}" dir="rtl">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${title}</title>
${helmet.trim()}
</head>
<body>
${html.trim()}
</body>
</html>
`;
}

fs.mkdirSync(outDir, { recursive: true });
for (const f of fs.readdirSync(srcDir).filter((n) => n.endsWith('.dc.html')).sort()) {
  const name = f.replace(/\.dc\.html$/, '');
  fs.writeFileSync(path.join(outDir, `${name}.html`), render(path.join(srcDir, f)));
  console.log('rendered', name);
}
