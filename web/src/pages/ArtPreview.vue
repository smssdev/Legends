<script setup lang="ts">
// W14b: the developer's preview of the match art. Every sequence plays here in any club's colours,
// with guides that show a jump between frames before the art reaches the scene engine.
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { drawFrame, loadManifest, loadPages, plateUrl, type ArtFrame, type ArtManifest, type ArtPages, type ArtSize } from '../match/art'

const manifest = ref<ArtManifest | null>(null)
const loading = ref(true)
const size = ref<ArtSize>('hd')
const pages = ref<ArtPages | null>(null)
const seq = ref('')
const frame = ref(0)
const playing = ref(true)
const speed = ref(1)
const kit = ref<string | null>('#C8102E')
const custom = ref('#7A263A')
const backdrop = ref('pitch')
const guides = ref(true)
const onion = ref(false)
const canvas = ref<HTMLCanvasElement | null>(null)
const box = ref<HTMLElement | null>(null)
const plate = ref<HTMLImageElement | null>(null)

const kits = [
  { label: 'الأصل', value: null },
  { label: 'أحمر', value: '#C8102E' },
  { label: 'أزرق', value: '#1D428A' },
  { label: 'سماوي', value: '#6CABDD' },
  { label: 'أصفر', value: '#FDE100' },
  { label: 'أخضر', value: '#00843D' },
  { label: 'أسود', value: '#2B2B2B' },
]

const names = computed(() => Object.keys(manifest.value?.sequences ?? {}).sort())
const groups = computed(() => {
  const g: Record<string, string[]> = {}
  for (const n of names.value) (g[n.slice(0, n.lastIndexOf('/'))] ??= []).push(n)
  return g
})
const current = computed(() => (seq.value && manifest.value ? manifest.value.sequences[seq.value] : null))
const frames = computed<ArtFrame[]>(() => current.value?.frames[size.value] ?? [])
const player = computed(() => manifest.value?.sizes[size.value].player ?? 384)
const plates = computed(() => Object.keys(manifest.value?.plates ?? {}).sort())

/** Frames that may jump: height or ground line far from the frame before (the loop closes on the first). */
const warnings = computed(() => {
  const f = frames.value
  const out: string[] = []
  if (f.length < 2) return out
  const H = player.value
  f.forEach((a, k) => {
    const b = f[(k + 1) % f.length]
    if (k === f.length - 1 && f.length < (current.value?.total ?? 0)) return
    const dh = Math.abs(a.h - b.h) / H
    const dg = Math.abs((a.ay - a.h) - (b.ay - b.h)) / H
    if (dh > 0.06) out.push(`الطول يتغير ${Math.round(dh * 100)}% بين الإطارين ${a.i} و${b.i}`)
    if (dg > 0.04) out.push(`القدمان تبتعدان عن الأرض ${Math.round(dg * 100)}% بين الإطارين ${a.i} و${b.i} (طبيعي في القفز والارتماء فقط)`)
  })
  return out
})

onMounted(async () => {
  manifest.value = await loadManifest()
  loading.value = false
  if (!manifest.value) return
  const saved = location.hash.slice(1)
  seq.value = names.value.includes(decodeURIComponent(saved)) ? decodeURIComponent(saved) : names.value[0] ?? ''
  pages.value = await loadPages(manifest.value, size.value)
  start()
})

watch(size, async (s) => {
  if (!manifest.value) return
  pages.value = await loadPages(manifest.value, s)
  loadPlate()
})
watch(seq, (s) => {
  frame.value = 0
  history.replaceState(null, '', `#${encodeURIComponent(s)}`)
})
watch(backdrop, loadPlate)

function loadPlate() {
  plate.value = null
  if (backdrop.value === 'pitch' || backdrop.value === 'checker') return
  const img = new Image()
  img.onload = () => (plate.value = img)
  img.src = plateUrl(backdrop.value, size.value)
}

function step(d: number) {
  playing.value = false
  const n = frames.value.length
  if (n) frame.value = (frame.value + d + n) % n
}

let raf = 0
let last = 0
let acc = 0
function start() {
  const tick = (t: number) => {
    const fps = (manifest.value?.fps ?? 12) * speed.value
    if (playing.value && frames.value.length) {
      acc += Math.min(t - last, 250)
      while (acc >= 1000 / fps) {
        acc -= 1000 / fps
        frame.value = (frame.value + 1) % frames.value.length
      }
    }
    last = t
    draw()
    raf = requestAnimationFrame(tick)
  }
  raf = requestAnimationFrame((t) => {
    last = t
    tick(t)
  })
}
onBeforeUnmount(() => cancelAnimationFrame(raf))

function draw() {
  const c = canvas.value
  const p = pages.value
  if (!c || !p || !box.value) return
  const dpr = window.devicePixelRatio || 1
  const W = box.value.clientWidth
  const H = Math.round(Math.min(W * 0.75, 520))
  if (c.width !== W * dpr || c.height !== H * dpr) {
    c.width = W * dpr
    c.height = H * dpr
    c.style.height = `${H}px`
  }
  const ctx = c.getContext('2d')!
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
  background(ctx, W, H)
  const f = frames.value
  if (!f.length) return
  const scale = (H * 0.78) / player.value
  const x = W / 2
  const y = H * 0.9
  if (guides.value) {
    ctx.strokeStyle = 'rgba(255,255,255,.55)'
    ctx.setLineDash([6, 6])
    ctx.lineWidth = 1
    ctx.beginPath()
    ctx.moveTo(0, y)
    ctx.lineTo(W, y)
    ctx.moveTo(x, 0)
    ctx.lineTo(x, H)
    ctx.moveTo(0, y - player.value * scale)
    ctx.lineTo(W, y - player.value * scale)
    ctx.stroke()
    ctx.setLineDash([])
  }
  const k = frame.value % f.length
  if (onion.value && f.length > 1) {
    ctx.globalAlpha = 0.3
    drawFrame(ctx, p, f[(k - 1 + f.length) % f.length], x, y, kit.value, scale)
    ctx.globalAlpha = 1
  }
  const cur = f[k]
  drawFrame(ctx, p, cur, x, y, kit.value, scale)
  if (guides.value) {
    ctx.strokeStyle = 'rgba(232,184,75,.9)'
    ctx.strokeRect(x - cur.ax * scale, y - cur.ay * scale, cur.w * scale, cur.h * scale)
  }
}

function background(ctx: CanvasRenderingContext2D, W: number, H: number) {
  if (backdrop.value === 'checker') {
    for (let yy = 0; yy < H; yy += 16)
      for (let xx = 0; xx < W; xx += 16) {
        ctx.fillStyle = (xx + yy) % 32 ? '#3a3a3a' : '#2a2a2a'
        ctx.fillRect(xx, yy, 16, 16)
      }
    return
  }
  if (plate.value) {
    const img = plate.value
    const s = Math.max(W / img.width, H / img.height)
    ctx.drawImage(img, (W - img.width * s) / 2, (H - img.height * s) / 2, img.width * s, img.height * s)
    return
  }
  const g = ctx.createLinearGradient(0, 0, 0, H)
  g.addColorStop(0, getComputedStyle(document.documentElement).getPropertyValue('--color-pitch-dark') || '#14532d')
  g.addColorStop(1, getComputedStyle(document.documentElement).getPropertyValue('--color-pitch') || '#1f7a3a')
  ctx.fillStyle = g
  ctx.fillRect(0, 0, W, H)
}

function setCustom(e: Event) {
  custom.value = (e.target as HTMLInputElement).value
  kit.value = custom.value
}
function label(n: string) {
  return n.slice(n.lastIndexOf('/') + 1)
}
</script>

<template>
  <main class="mx-auto flex min-h-dvh max-w-6xl flex-col gap-4 px-4 py-5 md:px-6">
    <header class="flex flex-wrap items-center gap-3">
      <BrandMark size="sm" />
      <span class="rounded-pill bg-gold/15 px-3 py-1 text-sm font-bold text-gold">للمطور</span>
      <h1 class="font-display text-2xl font-extrabold">معاينة الصور</h1>
    </header>

    <p v-if="loading" class="text-text-muted">جارٍ التحميل…</p>
    <div v-else-if="!manifest" class="flex flex-col gap-2 rounded-xl bg-surface p-4">
      <p class="font-bold">لم تُبنَ الصور بعد.</p>
      <p class="text-sm text-text-muted">شغّل هذا الأمر من جذر المستودع، ثم حدّث الصفحة:</p>
      <code dir="ltr" class="rounded-md bg-surface-sunk px-3 py-2 text-start font-numbers">python3 tools/art/build.py</code>
    </div>

    <div v-else class="grid gap-4 md:grid-cols-[16rem_1fr]">
      <nav aria-label="الحركات" class="flex max-h-[70dvh] flex-col gap-3 overflow-y-auto rounded-xl bg-surface p-3 max-md:max-h-56">
        <div v-for="(list, who) in groups" :key="who" class="flex flex-col gap-1">
          <span class="px-2 text-xs font-bold text-text-muted" dir="ltr">{{ who }}</span>
          <button
            v-for="n in list"
            :key="n"
            type="button"
            class="flex min-h-touch items-center justify-between gap-2 rounded-md px-3 text-start"
            :class="seq === n ? 'bg-gold/15 ring-1 ring-gold' : 'hover:bg-surface-raised'"
            @click="seq = n"
          >
            <span dir="ltr" class="truncate">{{ label(n) }}</span>
            <span class="font-numbers text-sm" :class="manifest.sequences[n].missing.length ? 'text-warning' : 'text-success'">
              {{ manifest.sequences[n].total - manifest.sequences[n].missing.length }}/{{ manifest.sequences[n].total }}
            </span>
          </button>
        </div>
      </nav>

      <section class="flex min-w-0 flex-col gap-3">
        <div ref="box" class="overflow-hidden rounded-xl bg-surface-sunk">
          <canvas ref="canvas" class="block w-full" :aria-label="`الحركة ${seq}، الإطار ${frames[frame]?.i ?? ''}`" />
        </div>

        <div class="flex flex-wrap items-center gap-2">
          <button type="button" class="h-touch min-w-touch rounded-md bg-surface px-3" aria-label="الإطار السابق" @click="step(-1)">›</button>
          <button type="button" class="h-touch min-w-24 rounded-md bg-gold px-4 font-bold text-on-gold" @click="playing = !playing">{{ playing ? 'إيقاف' : 'تشغيل' }}</button>
          <button type="button" class="h-touch min-w-touch rounded-md bg-surface px-3" aria-label="الإطار التالي" @click="step(1)">‹</button>
          <span dir="ltr" class="font-numbers text-lg">{{ frames[frame]?.i ?? '-' }} / {{ current?.total ?? '-' }}</span>
          <div role="radiogroup" aria-label="السرعة" class="ms-auto flex gap-1">
            <button v-for="s in [0.25, 0.5, 1]" :key="s" type="button" role="radio" :aria-checked="speed === s" dir="ltr" class="h-touch min-w-touch rounded-md px-2 font-numbers" :class="speed === s ? 'bg-gold/20 text-gold' : 'bg-surface'" @click="speed = s">{{ s }}×</button>
          </div>
        </div>

        <div v-if="current?.missing.length" class="rounded-lg bg-warning/15 px-4 py-2 text-sm">
          إطارات ناقصة: <span class="font-numbers">{{ current.missing.join('، ') }}</span>. ارفع لوحاتها ثم أعد بناء الصور.
        </div>
        <ul v-if="warnings.length" class="flex flex-col gap-1 rounded-lg bg-live/10 px-4 py-2 text-sm" aria-label="قفزات محتملة">
          <li v-for="w in warnings" :key="w">{{ w }}</li>
        </ul>
        <p v-else-if="frames.length > 1" class="text-sm text-success">لا قفزات في الطول ولا في خط الأرض.</p>

        <div class="flex gap-2 overflow-x-auto pb-1" aria-label="كل الإطارات">
          <button
            v-for="(f, k) in frames"
            :key="f.i"
            type="button"
            class="flex h-touch min-w-touch shrink-0 items-center justify-center rounded-md font-numbers"
            :class="k === frame ? 'bg-gold text-on-gold' : 'bg-surface'"
            @click="playing = false; frame = k"
          >{{ f.i }}</button>
        </div>

        <div class="grid gap-3 rounded-xl bg-surface p-3 sm:grid-cols-2">
          <fieldset class="flex flex-col gap-2">
            <legend class="mb-1 text-sm font-bold text-text-muted">لون القميص</legend>
            <div class="flex flex-wrap gap-2">
              <button
                v-for="k in kits"
                :key="k.label"
                type="button"
                :aria-pressed="kit === k.value"
                class="flex h-touch items-center gap-2 rounded-md px-3 text-sm"
                :class="kit === k.value ? 'ring-2 ring-gold' : 'bg-surface-sunk'"
                @click="kit = k.value"
              >
                <span class="size-4 rounded-full border border-text/20" :style="{ background: k.value ?? '#f4f4f4' }" />{{ k.label }}
              </button>
              <label class="flex h-touch items-center gap-2 rounded-md bg-surface-sunk px-3 text-sm" :class="kit && !kits.some((k) => k.value === kit) ? 'ring-2 ring-gold' : ''">
                <input type="color" :value="custom" class="size-6 cursor-pointer bg-transparent" @input="setCustom" />أي لون
              </label>
            </div>
          </fieldset>
          <div class="flex flex-col gap-2">
            <label class="text-sm font-bold text-text-muted" for="backdrop">الخلفية</label>
            <select id="backdrop" v-model="backdrop" class="h-touch rounded-md border border-text/10 bg-surface-sunk px-3">
              <option value="pitch">عشب</option>
              <option value="checker">مربعات (لرؤية حواف القص)</option>
              <option v-for="p in plates" :key="p" :value="p" dir="ltr">{{ p }}</option>
            </select>
            <div class="flex flex-wrap gap-2">
              <label class="flex h-touch items-center gap-2 rounded-md bg-surface-sunk px-3 text-sm"><input v-model="guides" type="checkbox" class="size-5" />خطوط الأرض والارتكاز</label>
              <label class="flex h-touch items-center gap-2 rounded-md bg-surface-sunk px-3 text-sm"><input v-model="onion" type="checkbox" class="size-5" />الإطار السابق شفافاً</label>
              <div role="radiogroup" aria-label="الدقة" class="flex gap-1">
                <button v-for="s in (['hd', 'sd'] as const)" :key="s" type="button" role="radio" :aria-checked="size === s" class="h-touch rounded-md px-3 text-sm" :class="size === s ? 'bg-gold/20 text-gold' : 'bg-surface-sunk'" @click="size = s">{{ s === 'hd' ? 'الكمبيوتر' : 'الجوال' }}</button>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  </main>
</template>
