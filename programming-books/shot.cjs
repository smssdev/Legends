// Screenshots an example web page for the book: node shot.cjs <page.html> <out.png> <width> [actions]
// actions, run before the screenshot, separated by ';': click:<selector>, fill:<selector>|<text>, press:<selector>|<key>, wait:<ms>
// The page is shown as a browser would show it. Only the default font is swapped for the book's
// serif fonts, because the build machine's default fonts differ from the readers' (who mostly see
// Times New Roman, or an Arabic system font).
const { chromium } = require('playwright');
const path = require('path');
const http = require('http');
const fs = require('fs');

// Pages are served over http from their own folder, like on a real server, so fetch() works.
const TYPES = { '.html': 'text/html', '.css': 'text/css', '.js': 'text/javascript', '.json': 'application/json', '.svg': 'image/svg+xml', '.png': 'image/png' };
function serve(dir) {
  return new Promise((resolve) => {
    const server = http.createServer((req, res) => {
      const file = path.join(dir, decodeURIComponent(req.url.split('?')[0]));
      if (!file.startsWith(dir) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
        res.writeHead(404);
        return res.end();
      }
      res.writeHead(200, { 'Content-Type': (TYPES[path.extname(file)] || 'application/octet-stream') + '; charset=utf-8' });
      fs.createReadStream(file).pipe(res);
    });
    server.listen(0, () => resolve(server));
  });
}

(async () => {
  const [page, out, width, actions = ''] = process.argv.slice(2);
  const fonts = path.join(__dirname, 'fonts');
  const browser = await chromium.launch();
  const tab = await browser.newPage({ viewport: { width: Number(width), height: 200 }, deviceScaleFactor: 2 });
  const server = await serve(path.dirname(path.resolve(page)));
  await tab.goto(`http://localhost:${server.address().port}/${path.basename(page)}`);
  await tab.waitForLoadState('networkidle');
  await tab.addStyleTag({
    content: `
      @font-face { font-family: 'Book Serif'; font-weight: 400; src: url(file://${fonts}/source-serif-4-latin-400-normal.woff2); }
      @font-face { font-family: 'Book Serif'; font-weight: 700; src: url(file://${fonts}/source-serif-4-latin-700-normal.woff2); }
      @font-face { font-family: 'Book Naskh'; font-weight: 400; src: url(file://${fonts}/noto-naskh-arabic-arabic-400-normal.woff2); }
      @font-face { font-family: 'Book Naskh'; font-weight: 700; src: url(file://${fonts}/noto-naskh-arabic-arabic-700-normal.woff2); }
      html { font-family: 'Book Serif', 'Book Naskh', serif; }
      html:lang(ar) { font-family: 'Book Naskh', 'Book Serif', serif; }`,
  });
  await tab.evaluate(() => document.fonts.ready);
  for (const step of actions.split(';').filter(Boolean)) {
    const [kind, rest] = [step.slice(0, step.indexOf(':')), step.slice(step.indexOf(':') + 1)];
    const [selector, text] = rest.split('|');
    if (kind === 'click') await tab.click(selector);
    if (kind === 'fill') await tab.fill(selector, text);
    if (kind === 'press') await tab.press(selector, text);
    if (kind === 'wait') await tab.waitForTimeout(Number(rest));
  }
  await tab.waitForTimeout(100);
  await tab.screenshot({ path: out, fullPage: true });
  await browser.close();
  server.close();
})();
