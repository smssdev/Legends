// [Sprint 55] The drafts' viewer: each draft's screen (its <template id="screen">) inside the one frame (the 72px dock
// and the 42px bar, built here once), shown at the three sizes of the rule (667×375, 915×412, 1440×900), by night or
// day, in each state (D11), with the computer's two options for the frame (D1) and both directions.
(() => {
  const I = {
    office: 'M3 11l9-7 9 7v9a1 1 0 0 1-1 1h-5v-6H9v6H4a1 1 0 0 1-1-1z',
    team: 'M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8Zm-7 10v-1a6 6 0 0 1 12 0v1M16 3.5a4 4 0 0 1 0 7.5M22 21v-1a6 6 0 0 0-4-5.6',
    tactics: 'M4 6h10M18 6h2M4 12h4M12 12h8M4 18h12M20 18h0M14 4v4M8 10v4M16 16v4',
    match: 'M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18Zm0 4 4 3-1.5 5h-5L8 10z',
    market: 'M4 7h16l-1.5 11a2 2 0 0 1-2 2h-9a2 2 0 0 1-2-2zM9 7V5a3 3 0 0 1 6 0v2',
    club: 'M3 20h18M5 20V10l7-5 7 5v10M9 20v-5h6v5',
    more: 'M5 12h.01M12 12h.01M19 12h.01',
    bot: 'M12 3a7 7 0 0 0-7 7v3l-2 4h18l-2-4v-3a7 7 0 0 0-7-7ZM9 21h6',
    home: 'M3 11l9-7 9 7v9H3z',
    leagues: 'M12 3l2.6 5.3 5.9.9-4.3 4.1 1 5.8L12 16.4 6.8 19.1l1-5.8L3.5 9.2l5.9-.9z',
    plus: 'M12 5v14M5 12h14',
    trophy: 'M8 4h8v5a4 4 0 0 1-8 0zM5 5h3M16 5h3M12 13v4M8 20h8',
    inbox: 'M3 6h18v12H3zM3 7l9 6 9-6',
  }
  const svg = (k) => `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="${I[k]}"/></svg>`
  // D2: the six sections by the one name, web and app; «المزيد» holds the rest.
  const CLUB = [['office', 'المكتب'], ['team', 'الفريق'], ['tactics', 'التكتيك'], ['match', 'المباراة'], ['market', 'السوق'], ['club', 'النادي']]
  const OUT = [['home', 'الرئيسية'], ['leagues', 'دورياتي'], ['plus', 'أنشئ'], ['trophy', 'البطولات'], ['inbox', 'الرسائل']]

  function shell(t) {
    const out = t.dataset.outside !== undefined
    const items = out ? OUT : CLUB
    const on = t.dataset.section
    const dock = items.map(([k, l]) => `<a class="di${k === on ? ' on' : ''}" href="#">${svg(k)}${l}${k === 'match' && t.dataset.live !== undefined ? '<span class="dot">●</span>' : ''}${k === 'office' && !out ? '<span class="dot">3</span>' : ''}</a>`).join('')
    const row = items.map(([k, l]) => `<a class="${k === on ? 'on' : ''}" href="#">${l}</a>`).join('')
    const next = out ? '' : `<span class="chip next" title="المباراة القادمة"><span class="wide-only">ضد إلتشي ·</span><span class="num">06:45:12</span></span>`
    const cash = out ? '' : `<span class="pill cash num"><span class="caption wide-only" style="font-family:Tajawal">أموال النادي</span> 3.4M</span>`
    return `<div class="shell">
  <nav class="dock" aria-label="الأقسام"><div class="crest"><i></i><b>ريال مدريد<br><span class="caption">المركز 1 من 20</span></b></div>${dock}
    <a class="di" href="#">${svg('more')}المزيد</a><span class="spacer"></span><a class="di bot" href="#">${svg('bot')}المساعد</a></nav>
  <header class="bar"><h1>${t.dataset.title}</h1><span class="chip offline-chip">بلا اتصال · آخر تحديث 9:02</span><span class="grow"></span>${next}
    <span class="pill coins num">1,250</span>${cash}<span class="ib" title="الرسائل"><svg viewBox="0 0 24 24"><path d="${I.inbox}"/></svg><span class="dot"></span></span><span class="avatar">م<span class="dot" title="وثّق حسابك"></span></span></header>
  <nav class="row-nav">${row}<a href="#">المزيد ▾</a></nav>
  <main class="main"><div class="content" style="height:100%">${t.innerHTML}</div>${states(t)}</main>
</div>`
  }
  function states(t) {
    return `<div class="state loading" role="status" aria-label="جارٍ التحميل"><div class="skel half"></div><div class="skel big"></div><div class="skel"></div><div class="skel"></div></div>
<div class="state empty"><span class="ico">🗂️</span><b class="title">${t.dataset.empty || 'لا شيء هنا بعد'}</b><span class="caption">${t.dataset.emptyText || ''}</span>${t.dataset.emptyCta ? `<a class="btn primary" href="#">${t.dataset.emptyCta}</a>` : ''}</div>
<div class="state error"><span class="ico">⚠️</span><b class="title">تعذّر الاتصال بالخادم.</b><span class="caption">ما زال ناديك كما تركته. حاول بعد قليل.</span><a class="btn quiet" href="#">حاول مجدداً</a></div>`
  }

  const SIZES = [[667, 375, 'جوال صغير بالعرض'], [915, 412, 'جوال بالعرض'], [1440, 900, 'كمبيوتر']]
  const opts = { theme: 'night', state: 'normal', desk: 'a', dir: 'rtl', notes: 'on' }
  const tpl = document.getElementById('screen')
  const host = document.getElementById('frames')
  const base = new URL('.', location.href).href

  function doc() {
    const body = tpl.dataset.bare !== undefined ? `<div class="content" style="height:100vh">${tpl.innerHTML}</div>${states(tpl)}` : shell(tpl)
    return `<!doctype html><html lang="ar" dir="${opts.dir}" class="${opts.theme === 'day' ? 'day' : ''}"><head><meta charset="utf-8"><base href="${base}">
<link rel="preconnect" href="https://fonts.googleapis.com"><link href="https://fonts.googleapis.com/css2?family=Tajawal:wght@400;500;700;800&family=Barlow+Condensed:wght@600;700;800&display=swap" rel="stylesheet">
<link rel="stylesheet" href="tokens.css"><link rel="stylesheet" href="kit.css">${tpl.dataset.css ? `<style>${document.getElementById(tpl.dataset.css).textContent}</style>` : ''}</head>
<body data-state="${opts.state}" data-desk="${opts.desk}" data-notes="${opts.notes}">${body}</body></html>`
  }
  function render() {
    host.innerHTML = ''
    const html = doc()
    for (const [w, h, name] of SIZES) {
      const avail = Math.min(host.clientWidth || 1200, 1300)
      const scale = Math.min(1, avail / w)
      const fig = document.createElement('figure')
      fig.innerHTML = `<figcaption>${name} <span class="num">${w}×${h}</span>${scale < 1 ? ` · مصغّرة ${Math.round(scale * 100)}%` : ''}</figcaption>`
      const box = document.createElement('div')
      box.className = 'device'
      box.style.width = `${w * scale}px`
      box.style.height = `${h * scale}px`
      const f = document.createElement('iframe')
      f.title = `${tpl.dataset.title} ${w}×${h}`
      f.width = w
      f.height = h
      f.style.transform = `scale(${scale})`
      f.srcdoc = html
      box.append(f)
      fig.append(box)
      host.append(fig)
    }
  }
  document.querySelectorAll('[data-opt]').forEach((b) => b.addEventListener('click', () => {
    opts[b.dataset.opt] = b.dataset.val
    document.querySelectorAll(`[data-opt="${b.dataset.opt}"]`).forEach((x) => x.setAttribute('aria-pressed', String(x === b)))
    render()
  }))
  let t
  addEventListener('resize', () => { clearTimeout(t); t = setTimeout(render, 200) })
  render()
})()
