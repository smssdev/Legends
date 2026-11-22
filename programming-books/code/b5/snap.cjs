// Screenshots of a Flutter app running in a browser, at phone size (390 x 780 CSS pixels, scale 2).
//   node snap.cjs <build/web folder> <out.png> ["x,y x,y"] [wait ms] [?query]   serves a release build, taps, shoots
//   node snap.cjs <http://url> <first.png> --live <signal folder>      for hot reload: shoots first.png, writes
//        <signal>/ready, waits for <signal>/go, then shoots <signal>/after.png into the path in <signal>/go
const http = require('http'), fs = require('fs'), path = require('path');
const { chromium } = require('playwright');
const [src, out, a3 = '', a4 = '5000', query = '', size = '390x780'] = process.argv.slice(2);
const [W, H] = size.split('x').map(Number);
const types = { '.js': 'text/javascript', '.mjs': 'text/javascript', '.html': 'text/html', '.wasm': 'application/wasm',
  '.json': 'application/json', '.png': 'image/png', '.otf': 'font/otf', '.ttf': 'font/ttf' };
const sleep = ms => new Promise(r => setTimeout(r, ms));

async function browser() {
  // Flutter draws with WebGL; a machine without a graphics card draws it in software.
  const b = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  // ?lang=ar in the address: the browser speaks Arabic, as a phone set to Arabic would.
  const locale = (query.match(/[?&]lang=([\w-]+)/) || [])[1];
  const page = await b.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 2, ...(locale && { locale }) });
  return [b, page];
}

async function live() {
  const signal = process.argv[5];
  const [b, page] = await browser();
  await page.goto(src);
  await sleep(12000);
  await page.screenshot({ path: out });
  fs.writeFileSync(path.join(signal, 'ready'), '');
  while (!fs.existsSync(path.join(signal, 'go'))) await sleep(200);
  await sleep(2500);
  await page.screenshot({ path: fs.readFileSync(path.join(signal, 'go'), 'utf8').trim() });
  await b.close();
}

async function serve() {
  const srv = http.createServer((q, r) => {
    let p = path.join(src, decodeURIComponent(q.url.split('?')[0]));
    if (fs.existsSync(p) && fs.statSync(p).isDirectory()) p = path.join(p, 'index.html');
    if (!fs.existsSync(p)) { r.writeHead(404); return r.end(); }
    r.writeHead(200, { 'content-type': types[path.extname(p)] || 'application/octet-stream' });
    fs.createReadStream(p).pipe(r);
  });
  await new Promise(r => srv.listen(0, r));
  const [b, page] = await browser();
  await page.goto(`http://localhost:${srv.address().port}/${query}`);
  await sleep(+a4);
  // Taps: "x,y x,y" by position, or "role=name|text=name|wait=ms" by what the screen says, through
  // Flutter's accessibility tree (the same labels a screen reader reads), which is turned on first.
  const byLabel = a3.includes('=');
  // Only taps by label need the tree; at= and keys= work on the drawn screen, like a finger.
  const tree = async () => {
    await page.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
    await sleep(800);
  };
  const needsTree = (ts) => ts.some((t) => !/^(at|keys|wait|reload|film)=/.test(t));
  const tokens = a3.split(byLabel ? '|' : ' ').filter(Boolean);
  // The tree is turned on again after each reload, only if a later tap needs it.
  const untilReload = (from) => {
    const rest = tokens.slice(from);
    const r = rest.findIndex((t) => t.startsWith('reload='));
    return r < 0 ? rest : rest.slice(0, r);
  };
  if (byLabel && needsTree(untilReload(0))) await tree();
  for (const [i, t] of tokens.entries()) {
    if (!byLabel) {
      const [x, y] = t.split(',').map(Number);
      await page.mouse.click(x, y);
    } else {
      const [kind, ...rest] = t.split('=');
      const name = rest.join('=');
      if (kind === 'wait') { await sleep(+name); continue; }
      // aria=1: what a screen reader is given, as the browser's accessibility tree, saved as <out>-aria.txt.
      if (kind === 'aria') {
        fs.mkdirSync(path.dirname(out), { recursive: true });
        fs.writeFileSync(out.replace(/\.png$/, '-aria.txt'), (await page.locator('body').ariaSnapshot()) + '\n');
        continue;
      }
      // film=6:300: six screenshots, one every 300 ms, saved as <out>-1.png … <out>-6.png (a filmstrip of a motion).
      // film=0,200,500: one screenshot at each of those moments, in ms after the step before it.
      if (kind === 'film') {
        const times = name.includes(',')
          ? name.split(',').map(Number)
          : Array.from({ length: +name.split(':')[0] }, (_, k) => k * +name.split(':')[1]);
        const start = Date.now();
        for (const [k, at] of times.entries()) {
          await sleep(Math.max(0, start + at - Date.now()));
          await page.screenshot({ path: out.replace(/\.png$/, `-${k + 1}.png`) });
        }
        continue;
      }
      // reload=1: close the app and open it again, as a person would; what it saved must still be there.
      if (kind === 'reload') {
        await page.reload();
        await sleep(+a4);
        if (needsTree(untilReload(i + 1))) await tree();
        continue;
      }
      if (kind === 'at') { const [x, y] = name.split(',').map(Number); await page.mouse.click(x, y); await sleep(900); continue; }
      if (kind === 'keys') { await page.keyboard.type(name, { delay: 30 }); await sleep(500); continue; }
      if (kind === 'type') {
        // type=Label=>text: click the text field with that label, and type as a person would.
        const [label, text] = name.split('=>');
        const re = new RegExp('^' + label.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'));
        await page.getByRole('textbox', { name: re }).first().click({ force: true });
        await sleep(900);
        await page.keyboard.type(text, { delay: 30 });
        await sleep(500);
        continue;
      }
      // A line of the label starts with the name: a list tile's label is its title, a line break, then its
      // subtitle; a tab with a badge starts with the badge's number.
      const escaped = name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
      // A tab's label may carry its badge's number before or after the name.
      const starts = new RegExp((kind === 'tab' ? '' : '(^|\\n)') + escaped);
      const target = page.getByRole(kind === 'text' ? 'button' : kind, { name: starts });
      await target.first().click();
    }
    // A filmstrip starts right after the step that starts the motion.
    if (!(tokens[i + 1] || '').startsWith('film=')) await sleep(700);
  }
  await page.mouse.move(1, 1);
  await sleep(byLabel ? 2500 : 800);
  await page.screenshot({ path: out });
  await b.close();
  srv.close();
}

(a3 === '--live' ? live() : serve()).catch(e => { console.error(e); process.exit(1); });
