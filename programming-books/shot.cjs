// Screenshots an example web page for the book: node shot.cjs <page.html> <out.png> <width> [actions]
// actions, run before the screenshot, separated by ';': click:<selector>, fill:<selector>=<text>, press:<selector>=<key>
// The page is shown as a browser would show it. Only the default font is swapped for the book's
// serif fonts, because the build machine's default fonts differ from the readers' (who mostly see
// Times New Roman, or an Arabic system font).
const { chromium } = require('playwright');
const path = require('path');

(async () => {
  const [page, out, width, actions = ''] = process.argv.slice(2);
  const fonts = path.join(__dirname, 'fonts');
  const browser = await chromium.launch();
  const tab = await browser.newPage({ viewport: { width: Number(width), height: 200 }, deviceScaleFactor: 2 });
  await tab.goto('file://' + path.resolve(page));
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
    const [selector, text] = rest.split('=');
    if (kind === 'click') await tab.click(selector);
    if (kind === 'fill') await tab.fill(selector, text);
    if (kind === 'press') await tab.press(selector, text);
  }
  await tab.waitForTimeout(100);
  await tab.screenshot({ path: out, fullPage: true });
  await browser.close();
})();
