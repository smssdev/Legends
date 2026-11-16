const { chromium } = require('playwright');
const path = require('path');
(async () => {
  const dir = __dirname;
  const b = await chromium.launch();
  const p = await b.newPage({ viewport: { width: 816, height: 1056 } });
  for (const name of ['cover', 'interior']) {
    await p.goto('file://' + path.join(dir, name + '.html'));
    await p.evaluate(() => document.fonts.ready);
    await p.pdf({ path: path.join(dir, name + '.pdf'), width: '8.5in', height: '11in', printBackground: true });
    const pages = await p.$$('.page');
    for (let i = 0; i < pages.length; i++) await pages[i].screenshot({ path: path.join(dir, 'prev', `${name}-${i}.png`) });
  }
  await b.close();
})();
