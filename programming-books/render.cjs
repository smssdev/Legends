// Prints every out/<book>-<lang>.html to a 7 x 10 in PDF (sizes come from the CSS @page rule),
// then writes page previews to out/preview/ with pdftoppm.
const { chromium } = require('playwright');
const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

(async () => {
  const out = path.join(__dirname, 'out');
  const prev = path.join(out, 'preview');
  fs.mkdirSync(prev, { recursive: true });
  const only = process.argv[2];
  const browser = await chromium.launch();
  const page = await browser.newPage();
  for (const f of fs.readdirSync(out).filter((f) => f.endsWith('.html'))) {
    if (only && !f.startsWith(only)) continue;
    const name = f.replace(/\.html$/, '');
    await page.goto('file://' + path.join(out, f));
    await page.evaluate(() => document.fonts.ready);
    const pdf = path.join(out, name + '.pdf');
    await page.pdf({ path: pdf, preferCSSPageSize: true, printBackground: true, displayHeaderFooter: false });
    execFileSync('pdftoppm', ['-r', '60', '-png', pdf, path.join(prev, name)]);
    const pages = execFileSync('pdfinfo', [pdf]).toString().match(/Pages:\s+(\d+)/)[1];
    console.log(`${name}.pdf: ${pages} pages`);
  }
  await browser.close();
})();
