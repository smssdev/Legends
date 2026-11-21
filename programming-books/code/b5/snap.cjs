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
  const page = await b.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: 2 });
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
  for (const t of a3.split(' ').filter(Boolean)) {
    const [x, y] = t.split(',').map(Number);
    await page.mouse.click(x, y);
    await sleep(400);
  }
  await sleep(800);
  await page.screenshot({ path: out });
  await b.close();
  srv.close();
}

(a3 === '--live' ? live() : serve()).catch(e => { console.error(e); process.exit(1); });
