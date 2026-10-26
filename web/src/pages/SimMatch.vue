<template>
  <main class="mx-auto flex min-h-dvh max-w-[1500px] flex-col gap-3 px-3 py-3 md:px-5">
    <header class="flex flex-wrap items-center gap-2">
      <RouterLink :to="league ? '/match' : '/sim'" class="flex items-center gap-2">
        <BrandMark size="sm" />
      </RouterLink>
      <span v-if="!league" class="rounded-pill bg-gold/15 px-3 py-1 text-xs font-bold text-gold">المحاكي · بذرة <span class="font-numbers">{{ view?.seed }}</span></span>
      <div class="flex-1" />
      <template v-if="live">
        <span class="flex h-touch items-center gap-2 rounded-md bg-live/15 px-3 text-sm font-bold text-[#FF8A8A]"><span class="size-2 rounded-full bg-live" />مباشر · {{ mine ? 'تدير ' + view?.clubs[mine].name : 'مشاهدة' }}</span>
        <button v-if="friendLink" type="button" class="h-touch rounded-md bg-surface px-3 text-sm" @click="share">{{ copied ? 'نُسخ الرابط' : 'رابط الصديق' }}</button>
      </template>
      <div v-else class="flex items-center gap-1 rounded-lg bg-surface p-1" role="group" aria-label="سرعة المحاكاة">
        <button type="button" class="size-10 rounded-sm bg-surface-raised" :aria-label="playing ? 'إيقاف مؤقت' : 'تشغيل'" @click="togglePlay">
          <svg v-if="playing" viewBox="0 0 24 24" class="mx-auto size-4" fill="currentColor" aria-hidden="true"><rect x="6" y="5" width="4" height="14" rx="1" /><rect x="14" y="5" width="4" height="14" rx="1" /></svg>
          <svg v-else viewBox="0 0 24 24" class="mx-auto size-4" fill="currentColor" aria-hidden="true"><path d="M7 5l12 7-12 7z" /></svg>
        </button>
        <button v-for="s in [1, 2, 4]" :key="s" type="button" class="h-10 min-w-11 rounded-sm font-numbers text-lg" :class="speed === s ? 'bg-gold text-on-gold' : 'text-text-soft'" :aria-pressed="speed === s" dir="ltr" @click="speed = s">×{{ s }}</button>
        <button type="button" class="h-10 rounded-sm px-3 text-sm text-text-soft" :disabled="finished" @click="skipMoment">تخطَّ اللقطة</button>
        <button type="button" class="h-10 rounded-sm px-3 text-sm text-text-soft" :disabled="skipping" @click="skip">{{ skipping ? '...' : 'تخطٍّ للنهاية' }}</button>
      </div>
      <button type="button" class="h-touch rounded-md bg-surface px-3 text-sm" :aria-pressed="soundOn" @click="toggleSound">{{ soundOn ? 'الصوت: يعمل' : 'تشغيل الصوت' }}</button>
      <button type="button" class="h-touch rounded-md bg-surface px-3 text-sm" @click="toggleCommentary">التعليق: {{ ({ ar: 'عربي', en: 'English', off: 'متوقف' })[commentary] }}</button>
      <button v-if="commentary === 'ar'" type="button" class="h-touch rounded-md bg-surface px-3 text-sm" @click="nextArVoice">المعلق: {{ arVoiceName(arVoice) }}</button>
      <button type="button" class="h-touch rounded-md bg-surface px-3 text-sm" :aria-pressed="viewing.chosenView.value === 'unity'" @click="switchView">العرض: {{ viewing.chosenView.value === 'unity' ? 'المطوّر' : 'الكرتوني' }}</button>
      <button type="button" class="h-touch rounded-md bg-surface px-3 text-sm" :title="PERF_HINT" @click="nextPerf">الأداء: {{ PERF_NAMES[perfPref] }}{{ perfPref === 'auto' ? (smooth ? ' (سلس)' : ' (كامل)') : '' }}</button>
      <a v-if="mine" href="#coach" class="flex h-touch items-center rounded-md bg-surface px-3 text-sm lg:hidden">لوحة المدرب</a>
      <button v-if="!league" type="button" class="h-touch rounded-md bg-surface px-3 text-sm text-text-muted" :aria-pressed="dev" @click="dev = !dev">لوحة المطور</button>
    </header>

    <nav v-if="others.length > 1" class="flex flex-wrap items-center gap-2" aria-label="مبارياتك المباشرة">
      <span class="text-sm text-text-muted">مبارياتك الآن:</span>
      <RouterLink v-for="o in others" :key="o.id" :to="{ name: 'league-match', params: { id: o.id } }" class="flex h-touch items-center rounded-md px-3 font-numbers text-sm" :class="String(o.id) === id ? 'bg-gold text-on-gold' : 'bg-surface'" :aria-current="String(o.id) === id ? 'page' : undefined" dir="ltr">{{ o.home }} - {{ o.away }}</RouterLink>
    </nav>

    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-2 text-sm text-[#FF8A8A]">{{ error }}</p>
    <p v-if="viewing.chosenView.value === 'unity' && viewing.playing.value === 'cartoon'" class="rounded-lg bg-surface px-4 py-2 text-sm text-text-soft" role="status">المحاكي المطوّر (Unity) قريباً. تُعرض المباراة الآن بالمحاكي الكرتوني بنفس التوقيت.</p>

    <div v-if="view" class="grid items-start gap-3 lg:grid-cols-[minmax(0,1fr)_360px]">
      <div class="flex min-w-0 flex-col gap-3 lg:col-start-1">
        <section v-if="live && !started && mine" aria-label="بدء المباراة المباشرة" class="flex flex-col items-center gap-3 rounded-xl border border-gold/40 bg-surface p-4 text-center">
          <span class="font-display text-2xl font-extrabold">مباراة مباشرة مع صديق</span>
          <p class="max-w-md text-sm text-text-soft">أرسل الرابط لصديقك ليدير {{ $nm(view?.clubs[other].name) }} من جهازه، ثم ابدأ حين يكون جاهزاً.</p>
          <div v-if="friendLink" class="flex w-full max-w-md gap-2">
            <input :value="friendLink" readonly dir="ltr" aria-label="رابط الصديق" class="h-touch min-w-0 flex-1 rounded-md border border-text/10 bg-surface-sunk px-3 text-xs" @focus="($event.target as HTMLInputElement).select()" />
            <button type="button" class="h-touch rounded-md bg-surface-raised px-4 text-sm" @click="share">{{ copied ? 'نُسخ' : 'نسخ' }}</button>
          </div>
          <button type="button" class="h-12 rounded-md bg-gold px-8 font-display font-bold text-on-gold disabled:opacity-50" :disabled="starting" @click="startLive">{{ starting ? '...' : 'ابدأ المباراة' }}</button>
          <span class="text-xs text-text-muted">أي من المدربين يستطيع البدء.</span>
        </section>

        <section class="relative w-full overflow-hidden rounded-xl border border-text/10 bg-bg-deep" style="height: min(80dvh, 780px); min-height: 460px" aria-label="المباراة">
          <MatchFeed ref="pitch" :kits="feedKits" :clubs="{ home: view.clubs.home.name, away: view.clubs.away.name }" :codes="{ home: view.clubs.home.code, away: view.clubs.away.code }" :strength="{ home: view.clubs.home.strength ?? 0, away: view.clubs.away.strength ?? 0 }" :coaches="view.coaches" :countdown="countdown" :teams="teams" :seed="view.seed" :speed="live ? 1 : speed" :minute="minuteText" :score="score" :mine="mine" :lang="commentary" :intro="intro" :live="live" @cue="onCue" @sound="onSound" @say="(line) => voice.say(line)" @real="(kind) => voice.real(kind as any)" @intro-done="endIntro" />

                    <div v-if="(halftime || finished || windowOn) && !highlighting" dir="rtl" class="absolute inset-0 z-20 flex flex-col items-center justify-center gap-4 bg-bg-deep/85 p-4 text-center">
            <span class="text-sm font-bold text-gold">{{ finished ? 'نهاية المباراة' : windowOn ? `فترة توقف · الدقيقة ${minute[0]}` : 'الاستراحة' }}</span>
            <span class="font-numbers text-6xl" dir="ltr">{{ score.away }} – {{ score.home }}</span>
            <span v-if="shootout" class="text-sm text-text-soft">ركلات الترجيح: {{ shootout.home }} - {{ shootout.away }}</span>
            <div class="flex flex-wrap justify-center gap-2">
              <span v-if="halftime && live" class="text-sm text-text-soft">الشوط الثاني بعد <b class="font-numbers text-lg text-gold">{{ halftimeLeft }}</b> ثانية · غيّر خطتك الآن</span>
              <span v-if="windowOn && !finished" class="text-sm text-text-soft">تُستأنف المباراة بعد <b class="font-numbers text-lg text-gold">{{ halftimeLeft }}</b> ثانية · غيّر خطتك أو أجرِ تبديلاتك الآن</span>
              <a v-if="(halftime || windowOn) && live && mine" href="#coach" class="flex h-12 items-center rounded-md bg-gold px-5 font-display font-bold text-on-gold lg:hidden">لوحة المدرب</a>
              <button v-if="halftime && !live" type="button" class="h-12 rounded-md bg-gold px-6 font-display font-bold text-on-gold" @click="endHalftime">ابدأ الشوط الثاني <span class="font-numbers">({{ halftimeLeft }})</span></button>
              <button v-if="finished && keyTicks.length" type="button" class="h-12 rounded-md bg-surface-raised px-5 font-display font-bold" @click="highlights">ملخص المباراة · {{ keyTicks.length }} لقطة</button>
              <RouterLink v-if="finished && !league" :to="{ name: 'sim-report', params: { id }, query: mine ? { side: mine } : {} }" class="flex h-12 items-center rounded-md bg-gold px-6 font-display font-bold text-on-gold">تقرير المباراة</RouterLink>
              <RouterLink v-if="finished && league && mine" :to="{ name: 'league-report', params: { id } }" class="flex h-12 items-center rounded-md bg-gold px-6 font-display font-bold text-on-gold">تقرير المباراة</RouterLink>
              <RouterLink v-if="finished && league" to="/match" class="flex h-12 items-center rounded-md bg-surface-raised px-5">المباراة القادمة</RouterLink>
              <RouterLink v-if="finished && !league" to="/sim" class="flex h-12 items-center rounded-md bg-surface-raised px-5">مباراة جديدة</RouterLink>
            </div>
            <!-- The league's half-time: room kept for an advert (none in v1). -->
            <div v-if="halftime && league" class="flex h-24 w-full max-w-md items-center justify-center rounded-lg border border-dashed border-text/20 text-xs text-text-muted" aria-hidden="true">مساحة إعلانية</div>
          </div>

          <GoalReplay v-if="replayTick" :key="replayTick.tick" :tick="replayTick" :players="playersById" :clubs="{ home: view.clubs.home.name, away: view.clubs.away.name }" :seed="view.seed" @done="replayTick = null" />
          <p v-if="offline" class="absolute inset-x-3 top-24 z-30 rounded-lg bg-warning/90 px-3 py-2 text-center text-sm font-bold text-bg-deep" role="status">انقطع الاتصال، نعيد المحاولة... ولن يفوتك شيء</p>
        </section>

        <!-- Live: the two coaches cheer and tease each other; every screen sees it at once. In a league every member who
             watches may react, and cheer or boo one side once in half a minute [X24]. -->
        <section v-if="live && (mine || league) && !finished" class="flex flex-col gap-2 rounded-xl bg-surface p-2" aria-label="تفاعل مع المباراة">
          <div class="flex gap-1.5 overflow-x-auto">
            <button v-for="r in REACTIONS" :key="r.key" type="button" class="flex h-touch shrink-0 items-center gap-1 rounded-pill bg-surface-sunk px-3 text-sm font-bold hover:bg-surface-raised disabled:opacity-40" :disabled="reactWait" :aria-label="r.label" @click="react(r.key)">
              <span class="text-lg" aria-hidden="true">{{ r.emoji }}</span><span v-if="r.text">{{ r.text }}</span>
            </button>
          </div>
          <div v-if="league" class="grid grid-cols-2 gap-1.5 sm:grid-cols-4">
            <template v-for="s in (['home', 'away'] as const)" :key="s">
              <button type="button" class="flex h-touch items-center justify-center gap-1 truncate rounded-lg bg-success/15 px-2 text-sm font-bold text-success disabled:opacity-40" :disabled="cheerLeft > 0" @click="react('cheer', s)">📣 <span class="truncate">{{ $nm(view.clubs[s].name) }}</span></button>
              <button type="button" class="flex h-touch items-center justify-center gap-1 truncate rounded-lg bg-live/15 px-2 text-sm font-bold text-[#FF8A8A] disabled:opacity-40" :disabled="cheerLeft > 0" @click="react('boo', s)">👎 <span class="truncate">{{ $nm(view.clubs[s].name) }}</span></button>
            </template>
          </div>
          <p v-if="league && cheerLeft > 0" class="text-center text-xs text-text-muted">التشجيع والاستهجان بعد <span class="font-numbers">{{ cheerLeft }}</span> ثانية</p>
        </section>
      </div>

      <div class="flex min-w-0 flex-col gap-3 lg:col-start-1 lg:row-start-2">
        <section class="rounded-xl bg-surface px-4 py-3" aria-label="الزخم">
          <div class="mb-1 flex justify-between text-xs text-text-muted"><span class="font-display text-sm font-bold text-text">الزخم</span><span>أعلى: {{ $nm(view.clubs.home.name) }} · أسفل: {{ $nm(view.clubs.away.name) }}</span></div>
          <div class="h-20"><Momentum :values="momentum" :home-color="kits.home" /></div>
        </section>

        <section class="rounded-xl bg-surface p-4" aria-label="الإحصائيات">
          <StatsGrid :home="teams.home.stats" :away="teams.away.stats" :home-color="kits.home" />
        </section>

        <section v-if="dev" class="rounded-xl border border-gold/40 bg-surface-sunk p-4 font-mono text-xs leading-6" dir="ltr" aria-label="لوحة المطور">
          <div>tick {{ last?.tick }} · period {{ last?.period }} · danger {{ last?.danger }} · rate {{ last?.debug?.initiative?.rate }} · home share {{ last?.debug?.initiative?.home_share }}</div>
          <div v-for="(a, i) in lastAttacks" :key="i">{{ a.team }} {{ a.plan }}{{ a.counter ? ' (counter)' : '' }} → {{ a.result }} · {{ a.phases.map((p: any) => `${p.n}:${p.p ?? '-'}${p.ok ? '✓' : '✗'}`).join(' ') }}</div>
          <div>home tactics {{ JSON.stringify(teams.home.tactics) }}</div>
          <div>away tactics {{ JSON.stringify(teams.away.tactics) }}</div>
        </section>
      </div>

      <aside class="row-start-2 flex min-w-0 flex-col gap-3 lg:col-start-2 lg:row-span-2 lg:row-start-1">
        <section id="coach" class="flex scroll-mt-3 flex-col gap-3 rounded-xl bg-surface p-3" aria-label="لوحة المدرب">
          <div class="flex items-center gap-2">
            <h2 class="flex-1 font-display text-base font-bold">لوحة المدرب<span v-if="mine"> · {{ $nm(view.clubs[mine].name) }}</span></h2>
            <span v-if="live && mine" class="rounded-pill bg-surface-sunk px-2 py-1 text-xs text-text-muted">تكتيك {{ $nm(view.clubs[other].name) }} سري</span>
            <div v-if="!live && view.control.home === 'me' && view.control.away === 'me'" class="flex gap-1 rounded-md bg-surface-sunk p-1">
              <button v-for="s in (['home', 'away'] as const)" :key="s" type="button" class="h-9 rounded-sm px-2 text-xs font-bold" :class="mine === s ? 'bg-gold text-on-gold' : 'text-text-soft'" @click="chosen = s">{{ view.clubs[s].code }}</button>
            </div>
            <span v-if="mine" class="text-xs text-text-muted">التبديلات <b class="font-numbers text-base text-text" dir="ltr">{{ teams[mine].subs_used }}/{{ teams[mine].subs_max }}</b></span>
          </div>

          <p v-if="!mine" class="text-sm text-text-muted">{{ live ? 'أنت تشاهد فقط: كل مدرب يدير فريقه من جهازه.' : 'الحاسوب يدير الفريقين. اختر "أنا" لأحدهما في شاشة الإعداد لتديره.' }}</p>

          <template v-else>
            <p v-if="!canChange && !finished" class="rounded-md bg-surface-sunk px-3 py-2 text-xs leading-5 text-text-muted" role="status">التغيير في فترات التوقف فقط: الدقائق 15 و30 و60 و75 والاستراحة.<span v-if="nextWindow"> القادمة: <b class="font-numbers text-text">{{ nextWindow }}</b>'</span></p>
            <div role="tablist" class="grid grid-cols-4 gap-1 rounded-md bg-surface-sunk p-1">
              <button v-for="t in tabs" :key="t.id" type="button" role="tab" :aria-selected="tab === t.id" class="h-10 rounded-sm text-sm font-bold" :class="tab === t.id ? 'bg-gold text-on-gold' : 'text-text-soft'" @click="tab = t.id">{{ t.label }}</button>
            </div>

            <div v-if="tab === 'quick'" class="grid grid-cols-2 gap-2">
              <button v-for="q in quickOrders" :key="q.label" type="button" class="flex min-h-16 flex-col gap-0.5 rounded-md border border-text/10 bg-surface-sunk px-3 py-2 text-start hover:border-gold disabled:opacity-40 disabled:hover:border-text/10" :disabled="finished || !canChange" @click="sendTactics(q.label, q.tactics)">
                <span class="font-display text-sm font-bold">{{ q.label }}</span>
                <span class="text-xs leading-5 text-text-muted">{{ q.hint }}</span>
              </button>
            </div>

            <div v-if="tab === 'subs'" class="flex flex-col gap-2">
              <span class="text-xs text-text-muted">{{ subOut ? 'اختر البديل' : 'اختر من يخرج (الأقل لياقة أولاً)' }}</span>
              <button v-for="p in subOut ? bench : onPitch" :key="p.id" type="button" :disabled="!canChange" class="flex min-h-11 items-center gap-2 rounded-md px-2 disabled:opacity-40" :class="subOut?.id === p.id ? 'bg-warning/15' : 'bg-surface-sunk hover:bg-surface-raised'" @click="subOut ? sendSub(p) : (subOut = p)">
                <span class="w-8 rounded-sm px-1 text-center text-xs font-bold" :class="lineClass(p.line)">{{ p.pos }}</span>
                <span class="flex-1 truncate text-start text-sm">{{ $nm(p.name) }}</span>
                <span v-if="p.yc" class="h-3.5 w-2.5 rounded-[2px] bg-[#F5D90A]" aria-label="بطاقة صفراء" />
                <span class="w-12 text-start font-numbers" :class="fitClass(p.fit)">{{ subOut ? p.ovr : p.fit + '%' }}</span>
              </button>
              <button v-if="subOut" type="button" class="h-10 rounded-md bg-surface-raised text-sm" @click="subOut = null">رجوع</button>
            </div>

            <div v-if="tab === 'tactics'" class="flex flex-col gap-3 text-sm">
              <label class="flex items-center justify-between gap-2">خطة اللعب
                <select v-model="draft.plan" class="h-10 rounded-md bg-surface-sunk px-2"><option v-for="p in plans" :key="p.v" :value="p.v">{{ p.label }}</option></select>
              </label>
              <label class="flex items-center justify-between gap-2">قطع الكرة
                <select v-model.number="draft.tackling" class="h-10 rounded-md bg-surface-sunk px-2"><option v-for="(t, i) in tackles" :key="t" :value="i">{{ t }}</option></select>
              </label>
              <label v-for="k in (['pressing', 'style', 'tempo'] as const)" :key="k" class="flex flex-col gap-1">
                <span class="flex justify-between"><span>{{ sliderLabels[k] }}</span><b class="font-numbers text-gold">{{ draft[k] }}</b></span>
                <input v-model.number="draft[k]" type="range" min="0" max="100" class="accent-gold" />
              </label>
              <label v-for="l in (['att', 'mid', 'def'] as const)" :key="l" class="flex items-center justify-between gap-2">{{ lineNames[l] }}
                <select v-model="draft[l]" class="h-10 rounded-md bg-surface-sunk px-2"><option v-for="o in positioning[l]" :key="o.v" :value="o.v">{{ o.label }}</option></select>
              </label>
              <div class="flex gap-2">
                <UiToggle v-model="draftTrap" class="flex-1" label="مصيدة التسلل" />
                <UiToggle v-model="draftMan" class="flex-1" label="رقابة رجل لرجل" />
              </div>
              <button type="button" class="h-11 rounded-md bg-gold font-display font-bold text-on-gold disabled:opacity-40" :disabled="finished || !canChange" @click="applyDraft">طبّق في الدقيقة التالية</button>
            </div>

            <div v-if="tab === 'shape'" class="flex flex-wrap gap-2">
              <button v-for="f in view.formations" :key="f" type="button" class="h-11 rounded-md border px-3 font-numbers text-lg disabled:opacity-40" :class="teams[mine].formation === f ? 'border-gold bg-gold/15 text-gold' : 'border-text/10 bg-surface-sunk'" dir="ltr" :disabled="finished || !canChange" @click="sendFormation(f)">{{ formationLabel(f) }}</button>
            </div>

            <div v-for="o in pending" :key="o.key" class="flex items-center gap-3 rounded-lg border border-gold/45 bg-gold/10 px-3 py-2 text-sm">
              <span class="flex-1"><b>{{ o.label }}</b></span><span class="text-gold">{{ minute[0] === 0 ? 'يُطبق مع صافرة البداية' : 'يُطبق في الدقيقة القادمة' }}</span>
            </div>
            <div v-for="o in applied" :key="o.key" class="rounded-lg border border-success/50 bg-success/15 px-3 py-2 text-sm"><b>{{ o.label }}</b> طُبّق في الدقيقة {{ o.minute }}</div>
            <div v-for="r in rejected" :key="r" class="rounded-lg bg-live/15 px-3 py-2 text-sm text-[#FF8A8A]">{{ r }}</div>
          </template>
        </section>

        <section v-if="league && mine" class="flex max-h-[260px] flex-col gap-2 overflow-y-auto rounded-xl bg-surface p-3" aria-label="قراءة المساعد" aria-live="polite">
          <h2 class="font-display text-base font-bold">قراءة المساعد</h2>
          <p v-if="!readings.length" class="text-sm text-text-muted">يكتب لك المساعد ملاحظة كل ربع ساعة تقريباً، وبعد كل لحظة كبيرة.</p>
          <div v-for="r in readings" :key="r.id" class="flex gap-3 rounded-md bg-surface-sunk px-3 py-2 text-sm" :class="r.kind.startsWith('goal') || r.kind.startsWith('red') ? 'border-s-2 border-gold' : ''">
            <span class="w-8 shrink-0 font-numbers text-base text-gold">{{ r.minute }}'</span>
            <span>{{ r.text }}</span>
          </div>
        </section>

        <section v-if="league" class="flex flex-col gap-2 rounded-xl bg-surface p-3" aria-label="دردشة المشاهدين">
          <h2 class="font-display text-base font-bold">دردشة المشاهدين</h2>
          <div ref="chatBox" class="flex max-h-[240px] min-h-[64px] flex-col gap-1.5 overflow-y-auto" aria-live="polite">
            <p v-if="!chat.length" class="text-sm text-text-muted">مدربو الدوري الذين يتابعون يتكلمون هنا.</p>
            <p v-for="c in chat" :key="c.id" class="rounded-md bg-surface-sunk px-3 py-1.5 text-sm">
              <b :class="c.side ? 'text-gold' : 'text-text-soft'" dir="auto">{{ c.who }}</b><span class="text-text-muted">: </span><span dir="auto">{{ c.body }}</span>
            </p>
          </div>
          <form v-if="live && !finished" class="flex gap-2" @submit.prevent="sendChat">
            <input v-model="chatText" type="text" maxlength="140" class="h-touch min-w-0 flex-1 rounded-lg bg-surface-sunk px-3" placeholder="اكتب رسالة…" aria-label="رسالة" />
            <button type="submit" class="h-touch rounded-lg bg-gold px-4 font-bold text-on-gold disabled:opacity-40" :disabled="!chatText.trim() || chatWait">إرسال</button>
          </form>
          <p v-if="chatError" class="text-xs text-[#FF8A8A]" role="status">{{ chatError }}</p>
        </section>

        <section class="flex max-h-[420px] flex-col gap-1 overflow-y-auto rounded-xl bg-surface p-3" aria-label="مجريات المباراة">
          <h2 class="mb-1 font-display text-base font-bold">مجريات المباراة</h2>
          <div v-for="(f, i) in feed" :key="i" class="flex gap-3 border-b border-text/5 py-2 text-sm">
            <span class="w-10 shrink-0 font-numbers text-base" :class="f.important ? 'text-gold' : 'text-text-muted'">{{ f.minute }}</span>
            <span :class="f.important ? 'font-bold' : ''">{{ f.text }}</span>
          </div>
        </section>
      </aside>
    </div>
  </main>
</template>

<script setup lang="ts">
import UiToggle from '../components/ui/UiToggle.vue'
import { computed, onActivated, onBeforeUnmount, onDeactivated, onMounted, reactive, ref, shallowRef, watch } from 'vue'
import { useBroadcast } from '../stores/broadcast'
import { nm } from '../lib/names'
import { useRoute, useRouter } from 'vue-router'
import MatchFeed from '../match/feed/MatchFeed.vue'
import GoalReplay from '../match/feed/GoalReplay.vue'
import Momentum from '../components/Momentum.vue'
import StatsGrid from '../components/StatsGrid.vue'
import { clubColors, leagueMatch, seats, sim, type ChatLine, type LiveSync, type Reaction, type MatchEvent, type Reading, type MatchView, type Side, type TeamPlayer, type TeamSnapshot, type Tick, type Tactics } from '../api/sim'
import { line } from '../match/commentary'
import { MatchSound } from '../match/sound'
import { AR_VOICES, arVoiceName, Commentator, type ArVoice, type Lang } from '../match/voice'
import { useViewing } from '../match/viewing'
import { perfPref, setPerfPref, smooth, type PerfPref } from '../match/perf'

// league: a league match from /api/v1/matches (Sprints 18 to 20), played by the server's clock: the coach's orders,
// the server's commentary, his assistant's readings, and catching up after a lost connection.
const props = defineProps<{ id: string; league?: boolean }>()
const source = computed(() => (props.league ? leagueMatch : sim))
const route = useRoute()
const router = useRouter()

const view = ref<MatchView | null>(null)
const teams = ref<Record<Side, TeamSnapshot>>({} as any)
const score = ref({ home: 0, away: 0 })
const shootout = ref<{ home: number; away: number } | null>(null)
const minute = ref<[number, number]>([0, 0])
const last = shallowRef<Tick | null>(null)
const momentum = ref<number[]>([])
const feed = ref<{ minute: string; text: string; important: boolean }[]>([])
const error = ref('')
const playing = ref(true)
const speed = ref(Number(route.query.speed) || 1)
const halftime = ref(false)
const halftimeLeft = ref(30)
// [X42] The coach's window (live): play stops after minutes 15, 30, 60 and 75; its countdown shares halftimeLeft.
const windowOn = ref(false)
const windows = computed(() => (live.value ? view.value?.timing.windows ?? [] : []))
/** A coach may change now: always without windows; live, before kick-off, at half-time or in a window (not its last 2 s). */
const canChange = computed(() => !windows.value.length || !started.value || minute.value[0] === 0 || halftime.value || (windowOn.value && halftimeLeft.value > 2))
const nextWindow = computed(() => [...windows.value, 45].sort((a, b) => a - b).find((w) => w > minute.value[0]) ?? null)
const finished = ref(false)
const skipping = ref(false)
const dev = ref(false)
const soundOn = ref(false)
const pitch = ref<any>()
const sound = new MatchSound()
const voice = new Commentator()
// The crowd steps back under the commentator's voice [Sprint 35].
voice.onTalk = (talking) => sound.duck(talking)
const commentary = ref<Lang | 'off'>(readPref())
const intro = ref(true)
const highlighting = ref(false)
const keyTicks: Tick[] = []

const buffer: Tick[] = []
let fetching = false
let timer = 0
let htTimer = 0
let waited = 0

const minuteText = computed(() => (minute.value[1] ? `${minute.value[0]}+${minute.value[1]}'` : `${minute.value[0]}'`))
// The feed's kits: shirt, the ink on it and the trim, per side.
const feedKits = computed(() => ({
  home: { kit: bkits.value.home.shirt, ink: bkits.value.home.text, trim: bkits.value.home.trim, name: bkits.value.home.name },
  away: { kit: bkits.value.away.shirt, ink: bkits.value.away.text, trim: bkits.value.away.trim, name: bkits.value.away.name },
}))
// Score bug and stats colours follow the kits (with the away change kit on a clash).
const kits = computed(() => ({ home: bkits.value.home.shirt, homeText: bkits.value.home.text, away: bkits.value.away.shirt, awayText: bkits.value.away.text }))
// Kits for the 3D broadcast: shirt and trim from the club colours, shorts from the trim when it contrasts.
const bkits = computed(() => {
  const lum = (hex: string) => (parseInt(hex.slice(1, 3), 16) * 299 + parseInt(hex.slice(3, 5), 16) * 587 + parseInt(hex.slice(5, 7), 16) * 114) / 1000
  const make = (side: Side, shirt: string, trim: string, gk: string) => {
    const club = view.value?.clubs[side]
    const shorts = Math.abs(lum(shirt) - lum(trim)) > 60 ? trim : shirt
    return { shirt, trim, shorts, socks: shirt, text: lum(shirt) > 150 ? '#0A1F42' : '#FFFFFF', gk, name: club?.name ?? '', coach: 'مدرب ' + (club?.name ?? '') }
  }
  const h = clubColors(view.value?.clubs.home ?? ({} as any)), a = clubColors(view.value?.clubs.away ?? ({} as any))
  // Two similar shirts (Arsenal and Liverpool are both red): the away side changes to its second colour, or to white or navy.
  const rgb = (hex: string) => [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16))
  const far = (x: string, y: string) => rgb(x).reduce((d, v, i) => d + Math.abs(v - rgb(y)[i]), 0) > 160
  let away = a.primary, awayTrim = a.secondary
  if (!far(h.primary, away)) {
    away = far(h.primary, a.secondary) ? a.secondary : far(h.primary, '#F3F0E6') ? '#F3F0E6' : '#1C2333'
    awayTrim = a.primary
  }
  return { home: make('home', h.primary, h.secondary, '#2E8B57'), away: make('away', away, awayTrim, '#E9D70B') }
})
let pendingScore: Record<Side, number> | null = null
function onCue(name: string) {
  if (name === 'reveal') return reveal()
  if (name !== 'goal') return
  if (highlighting.value && hlScore) score.value = hlScore
  else if (pendingScore) { score.value = pendingScore; pendingScore = null }
}
function onSound(name: string) {
  if (name === 'kick') sound.kick(true)
  else if (name === 'thud') sound.kick(false)
  else if (name === 'whistle') sound.whistle(1)
  else if (name === 'whistle-long') sound.whistle(1)
  else if (name === 'roar' || name === 'net') { if (name === 'roar') sound.roar() }
  else if (name === 'groan' || name === 'murmur') sound.groan()
  else if (name === 'heart') sound.heart()
  else if (name === 'post') sound.post()
}

// ---------------------------------------------------------------- studio and highlights
// The studio opens the match; the first minute starts when it closes.
let introTimer = 0
function endIntro() {
  // The tap that closes the preview also turns the sound and the commentator on.
  if (!soundOn.value) toggleSound()
  if (!intro.value || live.value) return
  intro.value = false
  clearTimeout(introTimer)
  schedule(300)
}
// After the final whistle: the goals and the big moments again, scene by scene.
const KEY_KINDS = ['goal', 'penalty', 'free_kick', 'red', 'save']
let hlScore: Record<Side, number> | null = null
async function highlights() {
  highlighting.value = true
  const finalScore = { ...score.value }
  for (const t of keyTicks) {
    if (!highlighting.value) break
    minute.value = t.minute
    hlScore = t.score
    pitch.value?.play(t)
    await new Promise((r) => window.setTimeout(r, momentMs(t) + 400))
  }
  pitch.value?.skip()
  score.value = finalScore
  highlighting.value = false
}
function momentMs(t?: Tick) {
  return (t?.moment?.ms ?? view.value?.timing.tick_ms ?? 3000) / speed.value
}
function skipMoment() {
  pitch.value?.skip()
  reveal()
  voice.stop()
  if (!live.value) { clearTimeout(timer); schedule(120) }
}
// The server's commentary line (Sprint 20 B1); the simulator's own table for a minute that has none.
const say = (e: MatchEvent) => e.text ?? line(e, nameOf, clubName)
// The goal replay (live) and its players by id.
const replayTick = shallowRef<Tick | null>(null)
let lastGoal: Tick | null = null
const LOW_END = (navigator.hardwareConcurrency ?? 8) <= 4
const playersById = computed(() => {
  const m: Record<number, { name: string; no: number; side: Side }> = {}
  for (const side of ['home', 'away'] as const) for (const p of teams.value[side]?.players ?? []) m[p.id] = { name: p.name, no: p.no, side }
  return m
})
// The assistant's notes to this coach (league), newest first.
const readings = ref<Reading[]>([])
const offline = ref(false)
const nameOf = (side: Side, id?: number) => teams.value[side]?.players.find((p) => p.id === id)?.name ?? ''
const clubName = (side: Side) => view.value?.clubs[side].name ?? ''

// ---------------------------------------------------------------- coach
const chosen = ref<Side | null>(null)
const mine = computed<Side | null>(() => {
  const c = view.value?.control
  if (!c) return null
  // Live: only the side this device's seat manages (the server checks it on every order).
  if (view.value?.mode === 'live') return view.value.you
  if (c.home === 'me' && c.away === 'me') return chosen.value ?? 'home'
  return c.home === 'me' ? 'home' : c.away === 'me' ? 'away' : null
})
const tabs = [{ id: 'quick', label: 'سريع' }, { id: 'subs', label: 'تبديل' }, { id: 'tactics', label: 'تكتيك' }, { id: 'shape', label: 'الطريقة' }] as const
const tab = ref<(typeof tabs)[number]['id']>('quick')
const plans = [{ v: 'passing', label: 'تمريرات' }, { v: 'wings', label: 'الأجنحة' }, { v: 'counter', label: 'هجوم مرتد' }, { v: 'long', label: 'كرات طويلة' }, { v: 'shots', label: 'تسديد من بعيد' }]
const tackles = ['قانوني', 'عادي', 'حماس', 'خشونة']
const sliderLabels = { pressing: 'الضغط على الخصم', style: 'الأسلوب (دفاعي إلى هجومي)', tempo: 'إيقاع اللعب' }
const lineNames = { att: 'المهاجمون', mid: 'الوسط', def: 'المدافعون' }
const positioning = {
  att: [{ v: 'back', label: 'ارتداد' }, { v: 'support', label: 'مساندة الوسط' }, { v: 'only', label: 'هجوم فقط' }],
  mid: [{ v: 'def', label: 'مساندة الدفاع' }, { v: 'stay', label: 'بقاء' }, { v: 'push', label: 'اندفاع' }],
  def: [{ v: 'stay', label: 'بقاء' }, { v: 'fullbacks', label: 'هجوم الظهيرين' }, { v: 'mid', label: 'مساندة الوسط' }],
}
const initial = ref<Tactics | null>(null)
const quickOrders = computed<{ label: string; hint: string; tactics: Partial<Tactics> }[]>(() => [
  { label: 'هجوم كامل', hint: 'أسلوب هجومي، إيقاع عالٍ، الظهيران يتقدمان', tactics: { style: 85, tempo: 70, def: 'fullbacks', att: 'only' } },
  { label: 'تأمين النتيجة', hint: 'دفاع متأخر، إيقاع هادئ، مهاجمون يرتدون', tactics: { style: 25, tempo: 30, mid: 'def', att: 'back', def: 'stay' } },
  { label: 'ضغط عالٍ', hint: 'الضغط 85 ومصيدة التسلل: لياقة أسرع', tactics: { pressing: 85, trap: 1 } },
  { label: 'إبطاء اللعب', hint: 'إيقاع 25 وتمريرات: نحتفظ بالكرة', tactics: { tempo: 25, plan: 'passing' } },
  { label: 'استغلال الأطراف', hint: 'خطة الأجنحة وهجوم الظهيرين', tactics: { plan: 'wings', def: 'fullbacks' } },
  { label: 'عودة للخطة', hint: 'تكتيك ما قبل المباراة', tactics: initial.value ?? {} },
])
const draft = reactive<Tactics>({} as Tactics)
const draftTrap = computed({ get: () => draft.trap === 1, set: (v) => (draft.trap = v ? 1 : 0) })
const draftMan = computed({ get: () => draft.marking === 'man', set: (v) => (draft.marking = v ? 'man' : 'zone') })
const onPitch = computed(() => (mine.value ? [...teams.value[mine.value].players].filter((p) => p.on).sort((a, b) => a.fit - b.fit) : []))
const bench = computed(() => (mine.value ? teams.value[mine.value].players.filter((p) => !p.on && p.out === '' && p.slot === null) : []))
const subOut = ref<TeamPlayer | null>(null)
const pending = ref<{ key: string; label: string; target: number }[]>([])
const applied = ref<{ key: string; label: string; minute: string }[]>([])
const rejected = ref<string[]>([])

// The coach's other live matches (a league and a cup, or two leagues), to switch between them.
const others = ref<{ id: number; home: string; away: string }[]>([])
let othersTimer = 0
async function loadOthers() {
  if (!props.league) return
  othersTimer ||= window.setInterval(loadOthers, 30000)
  try {
    others.value = await leagueMatch.mine()
  } catch {
    /* the switcher is optional */
  }
}

const lineClass = (l: string) => ({ gk: 'bg-line-gk text-line-gk-fg', def: 'bg-line-def text-line-def-fg', mid: 'bg-line-mid text-line-mid-fg', att: 'bg-line-att text-line-att-fg' })[l] ?? ''
const fitClass = (f: number) => (f >= 75 ? 'text-success' : f >= 60 ? 'text-gold' : 'text-warning')

async function order(label: string, body: Record<string, unknown>) {
  if (!mine.value || finished.value) return
  try {
    const r = props.league ? await leagueMatch.order(props.id, body) : await sim.order(props.id, { team: mine.value, ...body })
    pending.value.push({ key: crypto.randomUUID(), label, target: r.target_tick })
  } catch (e: any) {
    error.value = e.message
  }
}
const sendTactics = (label: string, tactics: Partial<Tactics>) => order(label, { type: 'tactics', tactics })
const formationLabel = (f: string) => (f.startsWith('custom:') ? `خاصة ${f.slice(7)}` : f)
const sendFormation = (f: string) => order(`الطريقة ${formationLabel(f)}`, { type: 'formation', formation: f })
function sendSub(p: TeamPlayer) {
  const out = subOut.value!
  subOut.value = null
  order(`${p.name} بدلاً من ${out.name}`, { type: 'sub', out: out.id, in: p.id })
}
function applyDraft() {
  const cur = (teams.value[mine.value!].tactics ?? {}) as any
  const changes = Object.fromEntries(Object.entries(draft).filter(([k, v]) => cur[k] !== v))
  if (Object.keys(changes).length) sendTactics('تعديل التكتيك', changes as Partial<Tactics>)
}

// ---------------------------------------------------------------- clock

async function fetchNext(count = 1) {
  if (fetching || finished.value) return
  fetching = true
  try {
    const res = await sim.ticks(props.id, count)
    buffer.push(...res.ticks)
  } catch (e: any) {
    error.value = e.message
  } finally {
    fetching = false
  }
}

let fixedPace = false
function schedule(ms: number) {
  clearTimeout(timer)
  timer = window.setTimeout(step, ms)
}

async function step() {
  if (!playing.value || halftime.value || finished.value) return
  // Let the commentator finish his sentence (a little), so lines are never cut short.
  // At the broadcast's fixed pace the clock never waits for him [X35]: his lines queue instead.
  const talk = fixedPace ? 0 : voice.remainingMs()
  if (talk > 250 && waited < 2500) { waited += Math.min(talk, 500); return schedule(Math.min(talk, 500)) }
  waited = 0
  if (!buffer.length) {
    await fetchNext()
    if (!buffer.length) return schedule(500)
  }
  const t = buffer.shift()!
  fixedPace = !!t.moment && t.moment.ms <= 3400 && t.moment.kind !== 'shootout'
  show(t)
  if (!t.finished && buffer.length === 0) fetchNext()
  if (!halftime.value && !finished.value) schedule(momentMs(t))
}

// What a minute tells (the feed lines, the stats, the half-time card) waits until its
// scene has played, so a shot's end is never known before the ball gets there.
let pendingReveal: (() => void) | null = null
let shownAt = 0
function reveal() {
  const r = pendingReveal
  pendingReveal = null
  r?.()
}

/** startAt (live): when the minute starts, on performance.now(), so the scene plays in step with the other screen. */
function show(t: Tick, animate = true, startAt?: number) {
  reveal()
  intro.value = false
  last.value = t
  minute.value = t.minute
  if (pendingScore) score.value = pendingScore
  pendingScore = null
  // The score changes when the ball crosses the line in the shot, not at the start of the minute.
  if (animate && t.events.some((e) => e.type === 'goal')) pendingScore = t.score
  else score.value = t.score
  // Live: the next minute has started, so the half-time break is over.
  if (live.value && halftime.value) { halftime.value = false; clearInterval(htTimer) }
  windowOn.value = false
  if (t.moment && KEY_KINDS.includes(t.moment.kind) && (t.moment.kind !== 'save' || t.events.some((e) => e.type === 'attack' && e.quality === 'big'))) keyTicks.push(t)
  // Live: the goal again in a small frame while the next minute plays (not on a slow phone).
  // Not after a goal whose long minute already played its replay [X41].
  if (live.value && animate && lastGoal && (lastGoal.moment?.ms ?? 0) < 15000 && !t.events.some((e) => e.type === 'period') && !LOW_END) replayTick.value = lastGoal
  lastGoal = live.value && t.events.some((e) => e.type === 'goal' && (e.kind ?? 'open') === 'open') ? t : null
  sound.danger(t.danger)
  // The stands sing: after a goal, and now and then in a quiet spell (every 13 minutes of play) [Sprint 35].
  if (animate && t.events.some((e) => e.type === 'goal')) sound.chant(6)
  else if (animate && t.moment?.kind === 'quiet' && t.minute?.[0] % 13 === 7) sound.chant()
  pendingReveal = () => tell(t, animate)
  shownAt = performance.now()
  if (animate) pitch.value?.play(t, startAt)
  else reveal()
}

function tell(t: Tick, animate: boolean) {
  if (t.teams) teams.value = t.teams
  momentum.value = [...momentum.value, t.danger]
  for (const e of t.events) {
    const text = say(e)
    const important = ['goal', 'card', 'penalty', 'period', 'sub'].includes(e.type)
    if (text) feed.value.unshift({ minute: minuteText.value, text, important })
    if (e.type === 'period') {
      sound.whistle(e.name === 'fulltime' ? 3 : 2)
      // [X41] A goal in the half's last minute has its replay first: the break waits for the minute to end.
      if (e.name === 'halftime' && animate) {
        const left = t.events.some((g) => g.type === 'goal') ? momentMs(t) - (performance.now() - shownAt) - 200 : 0
        if (left > 0) window.setTimeout(startHalftime, left)
        else startHalftime()
      }
    } else if (e.type === 'shootout') {
      shootout.value = e.score
    }
  }
  // [X42] The coach's window opens when the minute's scene has played (its goal's replay too).
  if (live.value && t.window && animate) {
    const left = t.events.some((g) => g.type === 'goal') ? momentMs(t) - (performance.now() - shownAt) - 200 : 0
    const open = () => { if (last.value === t) { windowOn.value = true; clockTick() } }
    if (left > 0) window.setTimeout(open, left)
    else open()
  }
  for (const p of pending.value.filter((o) => t.tick >= o.target)) {
    applied.value.unshift({ key: p.key, label: p.label, minute: minuteText.value })
    window.setTimeout(() => (applied.value = applied.value.filter((a) => a.key !== p.key)), 4000)
  }
  pending.value = pending.value.filter((o) => t.tick < o.target)
  rejected.value = (t.rejected ?? []).map((r) => `رُفض الأمر: ${({ no_subs_left: 'لا تبديلات متبقية', bad_players: 'اللاعب غير متاح', bad_tactics: 'تكتيك غير صالح', bad_formation: 'طريقة غير صالحة' } as Record<string, string>)[r.reason] ?? r.reason}`)
  if (t.finished) { if (animate) window.setTimeout(() => (finished.value = true), 1600); else finished.value = true }
  const own = mine.value ? teams.value[mine.value]?.tactics : null
  if (draft.plan === undefined && own) {
    Object.assign(draft, own)
    initial.value ??= { ...own }
  }
}

function startHalftime() {
  halftime.value = true
  // Live: the clock ticker counts down to the second half from the server's time.
  if (live.value) return
  halftimeLeft.value = Math.round((view.value!.timing.halftime_seconds || 30) / speed.value)
  clearInterval(htTimer)
  htTimer = window.setInterval(() => {
    halftimeLeft.value--
    if (halftimeLeft.value <= 0) endHalftime()
  }, 1000)
}

function endHalftime() {
  clearInterval(htTimer)
  halftime.value = false
  schedule(200)
}

function togglePlay() {
  playing.value = !playing.value
  if (playing.value) schedule(100)
  else clearTimeout(timer)
}

async function skip() {
  skipping.value = true
  clearTimeout(timer)
  halftime.value = false
  clearInterval(htTimer)
  try {
    while (!finished.value) {
      const res = await sim.ticks(props.id, 200)
      buffer.push(...res.ticks)
      while (buffer.length) show(buffer.shift()!, false)
      if (!res.ticks.length) break
    }
  } catch (e: any) {
    error.value = e.message
  } finally {
    skipping.value = false
  }
}

// ---------------------------------------------------------------- live (two devices)
// The server keeps the clock and makes each minute a moment before it starts,
// with its start time (tick.at). Each screen knows the server's time (offset
// below) and plays every minute at that instant: both screens show the same
// scene together, neither ahead nor behind.
const live = computed(() => view.value?.mode === 'live')
const started = ref(true)
const starting = ref(false)
const countdown = ref(0)
const copied = ref(false)
const other = computed<Side>(() => (mine.value === 'away' ? 'home' : 'away'))
const friendSeat = seats.get(`${props.id}.friend`)
const friendLink = computed(() => (friendSeat ? `${location.origin}/sim/${props.id}?seat=${friendSeat}` : ''))
let seen = 0
let pollTimer = 0
let clockTimer = 0
// The minutes waiting for their start: timer id → the minute and its start on performance.now().
const playTimers = new Map<number, { t: Tick; startAt: number }>()

// Server time = Date.now() + offset, from the reply that came back fastest.
let offset = 0
let bestRtt = Infinity
const serverNow = () => Date.now() + offset
function sample(sentAt: number, serverMs: number) {
  const back = Date.now(), rtt = back - sentAt
  bestRtt += 2 // older samples count a little less, so a drifting clock is followed
  if (rtt <= bestRtt) { bestRtt = rtt; offset = serverMs - (sentAt + back) / 2 }
}
let kickoffAt = 0
let resumeAt = 0
let breakAhead = false

async function share() {
  try {
    if (navigator.share) await navigator.share({ title: 'Legends', text: 'أدر فريقك في مباراتنا', url: friendLink.value })
    else await navigator.clipboard.writeText(friendLink.value)
    copied.value = true
    window.setTimeout(() => (copied.value = false), 2000)
  } catch {
    /* the user closed the share sheet */
  }
}

async function startLive() {
  starting.value = true
  try {
    const sent = Date.now()
    const r = await sim.start(props.id)
    sample(sent, r.server_now)
    handleSync(r)
  } catch (e: any) {
    error.value = e.message
  } finally {
    starting.value = false
  }
}

async function poll() {
  clearTimeout(pollTimer)
  if (finished.value) return
  let wait = 1000
  try {
    const sent = Date.now()
    const r = await source.value.live(props.id, seen)
    sample(sent, r.server_now)
    offline.value = false
    wait = handleSync(r)
  } catch (e: any) {
    // A lost connection: keep asking. The server keeps every minute, so coming back loses nothing (Sprint 20 W2).
    if (navigator.onLine === false || e instanceof TypeError) { offline.value = true; wait = 2000 }
    else error.value = e.message
  }
  if (!finished.value) pollTimer = window.setTimeout(poll, wait)
}
// Back on the page (a locked phone, another tab): catch up at once.
function onVisible() {
  if (!live.value || finished.value) return
  if (document.visibilityState !== 'visible') {
    // Away (a locked phone, another app): with the sound on the broadcast plays on, like a TV left running [X41];
    // without it the commentator stops rather than catching up later.
    if (!soundOn.value) voice.stop()
    return
  }
  catchUp()
  keepAwake()
  poll()
}

/**
 * Back from a locked screen (Sprint 21 W1): the minutes whose time came while away are told at once, without
 * their scenes, and only the one playing now animates, on the server's clock; the later ones keep their timers.
 */
function catchUp() {
  const now = performance.now()
  const late = [...playTimers.entries()].filter(([, p]) => p.startAt <= now).sort((a, b) => a[1].t.tick - b[1].t.tick)
  late.forEach(([id], i) => {
    clearTimeout(id)
    playTimers.delete(id)
    const { t, startAt } = late[i][1]
    if (i < late.length - 1) show(t, false)
    else show(t, true, startAt)
  })
}

// The screen stays on while a live match plays (Screen Wake Lock); the phone takes it back when the page
// is hidden, so it is asked again on every return.
let wakeLock: { released: boolean; release: () => Promise<void> } | null = null
async function keepAwake() {
  if (!live.value || finished.value || document.visibilityState !== 'visible' || !('wakeLock' in navigator)) return
  if (wakeLock && !wakeLock.released) return
  try {
    wakeLock = await (navigator as any).wakeLock.request('screen')
  } catch {
    /* refused (battery saver): the match still plays */
  }
}
function releaseAwake() {
  wakeLock?.release().catch(() => {})
  wakeLock = null
}
watch(finished, (done) => { if (done) releaseAwake() })

/** Schedules the new minutes on the shared clock and returns how long to wait before asking again. */
function handleSync(r: LiveSync): number {
  started.value = r.started
  error.value = ''
  // Back after a gap: the minutes missed tell their events in the feed, then the latest minutes play on.
  for (const m of r.missed ?? []) {
    if (m.tick <= seen) continue
    seen = m.tick
    for (const e of m.events) {
      const text = say(e)
      if (text) feed.value.unshift({ minute: `${m.minute}'`, text, important: ['goal', 'card', 'penalty', 'period', 'sub'].includes(e.type) })
      if (e.type === 'shootout') shootout.value = e.score
    }
  }
  for (const x of r.readings ?? []) if (!readings.value.some((y) => y.id === x.id)) readings.value.unshift(x)
  const fresh = r.ticks.filter((t) => t.tick > seen)
  fresh.forEach((t, i) => {
    seen = t.tick
    // The second half starts with the first minute after the break.
    if (breakAhead) { resumeAt = t.at ?? resumeAt; breakAhead = false }
    if (t.window || t.events.some((e) => e.type === 'period' && e.name === 'halftime')) breakAhead = true
    const at = t.at ?? serverNow()
    const delay = at - serverNow()
    const next = fresh[i + 1]
    // Already over (a locked screen, a slow phone): its result at once, no scene. Only the minute playing now animates.
    if (next?.at !== undefined && next.at <= serverNow()) return show(t, false)
    const startAt = performance.now() + delay
    if (delay <= 0) return show(t, true, startAt)
    const id = window.setTimeout(() => { playTimers.delete(id); show(t, true, startAt) }, delay)
    playTimers.set(id, { t, startAt })
  })
  if (r.tick === 0 && !fresh.length && seen === 0) kickoffAt = r.next_at ?? 0
  else if (fresh.length && fresh[0].tick === 1) kickoffAt = fresh[0].at ?? 0
  if (breakAhead && r.next_at) resumeAt = r.next_at
  for (const x of r.reactions ?? []) receive(x)
  for (const c of r.chat ?? []) hear(c)
  const left = r.next_at === null ? 1500 : r.next_at - r.server_now - 1100
  return Math.min(1000, Math.max(250, left))
}

// Countdown to the kick-off and to the second half, on the shared clock.
function clockTick() {
  const now = serverNow()
  countdown.value = kickoffAt > now ? Math.ceil((kickoffAt - now) / 1000) : 0
  if (halftime.value || windowOn.value) halftimeLeft.value = Math.max(0, Math.ceil((resumeAt - now) / 1000))
}

// ---------------------------------------------------------------- reactions (live)
const REACTIONS = [
  { key: 'fire', emoji: '🔥', text: '', label: 'نار' },
  { key: 'clap', emoji: '👏', text: '', label: 'تصفيق' },
  { key: 'wow', emoji: '😱', text: '', label: 'يا للهول' },
  { key: 'laugh', emoji: '😂', text: '', label: 'ضحك' },
  { key: 'angry', emoji: '😤', text: '', label: 'غضب' },
  { key: 'pray', emoji: '🤲', text: '', label: 'يا رب' },
  { key: 'unlucky', emoji: '😅', text: 'هاردلك', label: 'هاردلك' },
  { key: 'coming', emoji: '⚽', text: 'جاي الهدف', label: 'جاي الهدف' },
  { key: 'easy', emoji: '😎', text: 'سهلة', label: 'سهلة' },
  { key: 'focus', emoji: '🧠', text: 'ركّز', label: 'ركّز' },
]
// The league's boos and cheers for one side [X24].
const CHEERS = { cheer: { emoji: '📣', text: 'تشجيع' }, boo: { emoji: '👎', text: 'استهجان' } } as const
const shownReactions = new Set<number>()
const reactWait = ref(false)
const myReactions = new Set<number>()
function receive(x: Reaction) {
  if (shownReactions.has(x.id)) return
  shownReactions.add(x.id)
  const r = x.key in CHEERS ? CHEERS[x.key as keyof typeof CHEERS] : REACTIONS.find((r) => r.key === x.key)
  if (!r) return
  // A boo or a cheer rises on its target's side; a member who watches has no side: by turns.
  const side: Side = x.target ?? x.side ?? (x.id % 2 ? 'home' : 'away')
  const mineToo = myReactions.has(x.id) || (!props.league && x.side === mine.value)
  pitch.value?.react(side, r.emoji, r.text, mineToo ? 'أنت' : x.who ?? (x.side ? view.value?.coaches?.[x.side] ?? view.value?.clubs[x.side].name : ''))
  if (!mineToo) sound.pop()
}
const cheerLeft = ref(0)
let cheerTimer = 0
async function react(key: string, target?: Side) {
  const cheer = key in CHEERS
  if (!cheer) {
    reactWait.value = true
    window.setTimeout(() => (reactWait.value = false), 1300)
  }
  try {
    const x = props.league ? await leagueMatch.react(props.id, key, target) : await sim.react(props.id, key)
    myReactions.add(x.id)
    receive(x)
    if (cheer) {
      cheerLeft.value = 30
      window.clearInterval(cheerTimer)
      cheerTimer = window.setInterval(() => { if (--cheerLeft.value <= 0) window.clearInterval(cheerTimer) }, 1000)
    }
  } catch {
    /* too soon: the button comes back in a moment */
  }
}

// The side chat between the league's coaches who watch [X24].
const chat = ref<ChatLine[]>([])
const chatText = ref('')
const chatWait = ref(false)
const chatError = ref('')
const chatBox = ref<HTMLElement | null>(null)
function hear(c: ChatLine) {
  if (chat.value.some((x) => x.id === c.id)) return
  const box = chatBox.value
  const atEnd = !box || box.scrollHeight - box.scrollTop - box.clientHeight < 40
  chat.value = [...chat.value, c].slice(-50)
  if (atEnd) requestAnimationFrame(() => chatBox.value?.scrollTo({ top: chatBox.value.scrollHeight }))
}
async function sendChat() {
  const body = chatText.value.trim()
  if (!body) return
  chatWait.value = true
  chatError.value = ''
  try {
    hear(await leagueMatch.chat(props.id, body))
    chatText.value = ''
  } catch (e) {
    chatError.value = (e as Error).message
  } finally {
    window.setTimeout(() => (chatWait.value = false), 2000)
  }
}

function toggleSound() {
  sound.start()
  soundOn.value = !soundOn.value
  sound.setMuted(!soundOn.value)
  voice.setOn(soundOn.value && commentary.value !== 'off')
  if (soundOn.value) sound.whistle()
}
// The commentator speaks when the sound is on: Arabic (the default), English, or not at all.
function toggleCommentary() {
  commentary.value = ({ ar: 'en', en: 'off', off: 'ar' } as const)[commentary.value]
  voice.setOn(soundOn.value && commentary.value !== 'off')
  try { localStorage.setItem('legends.commentary', commentary.value) } catch {}
}
// The Arabic voice: the sixth (hafid) by default, or the coach's choice from their account [X9].
const viewing = useViewing()
const arVoice = ref<ArVoice>(viewing.commentator.value)
voice.setArVoice(arVoice.value)
watch(viewing.commentator, (v) => {
  arVoice.value = v
  voice.setArVoice(v)
})
function nextArVoice() {
  arVoice.value = AR_VOICES[(AR_VOICES.indexOf(arVoice.value) + 1) % AR_VOICES.length]
  voice.setArVoice(arVoice.value)
  void viewing.save({ commentator: arVoice.value }).catch(() => {})
}
// The simulator: cartoon or Unity, switched here or in the account [X10]. Until Unity's web build is deployed
// (Sprint 8) the cartoon one keeps playing, with a note.
// The smooth mode for weak phones [X30]: automatic by default, or forced either way by the coach.
const PERF_NAMES: Record<PerfPref, string> = { auto: 'تلقائي', smooth: 'سلس', full: 'كامل' }
const PERF_HINT = 'سلس: رسوم أخف وحركة أنعم على الجوالات الضعيفة. كامل: كل المؤثرات. تلقائي: يختار حسب جهازك.'
function nextPerf() {
  setPerfPref(({ auto: 'smooth', smooth: 'full', full: 'auto' } as const)[perfPref.value])
}
function switchView() {
  void viewing.save({ match_view: viewing.chosenView.value === 'unity' ? 'cartoon' : 'unity' }).catch(() => {})
}
// Arabic by default, now that the default commentator is an Arabic voice [X9].
function readPref(): Lang | 'off' {
  try { const v = localStorage.getItem('legends.commentary'); return v === 'en' || v === 'off' ? v : 'ar' } catch { return 'ar' }
}

onMounted(async () => {
  // A friend's link carries his seat once: keep it on this device and take it out of the address.
  const linkSeat = route.query.seat
  if (typeof linkSeat === 'string' && linkSeat) {
    seats.set(props.id, linkSeat)
    router.replace({ query: { ...route.query, seat: undefined } })
  }
  loadOthers()
  document.addEventListener('visibilitychange', onVisible)
  window.addEventListener('online', onVisible)
  try {
    view.value = await source.value.show(props.id)
    teams.value = view.value.teams
    voice.prepare([view.value.clubs.home.name, view.value.clubs.away.name])
    score.value = view.value.score
    const own = mine.value ? teams.value[mine.value].tactics : null
    if (own) {
      Object.assign(draft, own)
      initial.value = { ...own }
    }
    finished.value = view.value.finished
    if (live.value) {
      intro.value = !view.value.started || view.value.tick === 0
      started.value = view.value.started
      seen = view.value.tick
      clockTimer = window.setInterval(clockTick, 250)
      keepAwake()
      return poll()
    }
    await fetchNext()
    if (view.value.tick > 0 || finished.value) { intro.value = false; schedule(300) }
    else introTimer = window.setTimeout(endIntro, 11000)
  } catch (e: any) {
    error.value = e.message
  }
})

// [X41] The broadcast behind the other screens: this page stays alive (KeepAlive in App.vue) and tells the shell's
// bar the score and the minute; the bar brings the coach back or mutes it. A finished match leaves the bar soon after.
const broadcast = useBroadcast()
// This page's own address, taken now: the route object follows the coach to the other screens.
const ownPath = route.fullPath.split('?')[0]
watch(() => [view.value, score.value.home, score.value.away, minuteText.value, finished.value] as const, () => {
  if (!view.value) return
  broadcast.update({
    path: ownPath,
    title: `${nm(view.value.clubs.home.name)} - ${nm(view.value.clubs.away.name)}`,
    score: `${score.value.home} - ${score.value.away}`,
    minute: finished.value ? 'نهاية المباراة' : minuteText.value,
    live: !finished.value,
  })
  if (finished.value) window.setTimeout(() => { if (broadcast.away && finished.value) broadcast.end() }, 20000)
}, { immediate: true })
onActivated(() => { broadcast.away = false })
onDeactivated(() => { broadcast.away = !finished.value })
watch(() => broadcast.muteAsk, () => { if (soundOn.value) toggleSound() })

onBeforeUnmount(() => {
  broadcast.end()
  document.removeEventListener('visibilitychange', onVisible)
  window.removeEventListener('online', onVisible)
  window.clearInterval(othersTimer)
  window.clearInterval(cheerTimer)
  clearTimeout(timer)
  clearTimeout(pollTimer)
  clearInterval(clockTimer)
  playTimers.forEach((_, id) => clearTimeout(id))
  releaseAwake()
  clearInterval(htTimer)
  clearTimeout(introTimer)
  highlighting.value = false
  sound.stop()
  voice.stop()
})

const lastAttacks = computed(() => (last.value?.events ?? []).filter((e) => e.type === 'attack'))
</script>
