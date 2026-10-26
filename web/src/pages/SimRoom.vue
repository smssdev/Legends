<template>
  <main class="mx-auto flex min-h-dvh max-w-xl flex-col gap-5 px-4 py-5">
    <header class="flex items-center gap-3">
      <RouterLink to="/sim" class="flex items-center gap-2">
        <BrandMark />
      </RouterLink>
      <span class="rounded-pill bg-gold/15 px-3 py-1 text-sm font-bold text-gold">مباراة مع صديق</span>
    </header>

    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]">{{ error }}</p>

    <!-- The host waits: share the link, the match starts when the friend joins. -->
    <section v-if="room && isHost" class="flex flex-col items-center gap-4 rounded-xl bg-surface p-5 text-center">
      <Crest :code="room.host.club.code" :primary="clubColors(room.host.club).primary" :secondary="clubColors(room.host.club).secondary" :size="64" />
      <div>
        <div class="font-display text-2xl font-extrabold">{{ $nm(room.host.name) }} · {{ $nm(room.host.club.name) }}</div>
        <p class="mt-1 text-sm text-text-muted">أرسل الرابط لصديقك. حين يكتب اسمه ويختار فريقه تبدأ المباراة عندكما معاً.</p>
      </div>
      <div class="flex w-full gap-2">
        <input :value="link" readonly dir="ltr" aria-label="رابط الغرفة" class="h-touch min-w-0 flex-1 rounded-md border border-text/10 bg-surface-sunk px-3 text-xs" @focus="($event.target as HTMLInputElement).select()" />
        <button type="button" class="h-touch rounded-md bg-gold px-4 font-bold text-on-gold" @click="share">{{ copied ? 'نُسخ' : 'مشاركة' }}</button>
      </div>
      <span class="flex items-center gap-2 text-sm text-text-soft"><span class="size-2 animate-pulse rounded-full bg-gold" />بانتظار صديقك...</span>
    </section>

    <!-- A full room on a device that did not join. -->
    <section v-else-if="room && room.guest" class="rounded-xl bg-surface p-5 text-center">
      <div class="font-display text-xl font-extrabold">الغرفة ممتلئة</div>
      <p class="mt-1 text-sm text-text-muted">{{ $nm(room.host.name) }} و{{ $nm(room.guest.name) }} يلعبان الآن. افتح غرفة جديدة لتلعب.</p>
      <RouterLink :to="{ name: 'sim-room-new' }" class="mt-3 inline-flex h-touch items-center rounded-md bg-gold px-5 font-bold text-on-gold">غرفة جديدة</RouterLink>
    </section>

    <!-- Open a room (host) or join one (guest): a name and a club. -->
    <template v-else-if="!props.room || room">
      <div v-if="room" class="flex items-center gap-3 rounded-xl border border-gold/40 bg-gold/10 p-4">
        <Crest :code="room.host.club.code" :primary="clubColors(room.host.club).primary" :secondary="clubColors(room.host.club).secondary" :size="48" />
        <div><b class="font-display text-lg">{{ $nm(room.host.name) }}</b> يتحداك بفريق <b>{{ $nm(room.host.club.name) }}</b>. اكتب اسمك واختر فريقك.</div>
      </div>
      <div v-else>
        <h1 class="font-display text-3xl font-extrabold">العب مع صديق</h1>
        <p class="mt-1 text-text-muted">اكتب اسمك واختر فريقك، ثم أرسل الرابط لصديقك.</p>
      </div>

      <label class="flex flex-col gap-1.5">
        <span class="text-sm font-bold">اسمك</span>
        <input v-model="name" maxlength="24" autocomplete="nickname" class="h-touch rounded-md border border-text/10 bg-surface px-3 text-lg" placeholder="مثلاً: سليمان" />
      </label>

      <section class="flex flex-col gap-2 rounded-xl bg-surface p-3" aria-label="اختر فريقك">
        <label class="sr-only" for="q">ابحث عن نادٍ</label>
        <input id="q" v-model="q" type="search" placeholder="ابحث عن نادٍ: ريال، ليفربول، الهلال..." class="h-touch rounded-md border border-text/10 bg-surface-sunk px-3" @input="search" />
        <div class="flex max-h-72 flex-col gap-1 overflow-y-auto pe-1">
          <button
            v-for="c in results.filter((c) => c.id !== room?.host.club.id)"
            :key="c.id"
            type="button"
            class="flex min-h-touch items-center gap-3 rounded-md px-2 text-start"
            :class="club?.id === c.id ? 'bg-gold/15 ring-1 ring-gold' : 'hover:bg-surface-raised'"
            @click="club = c"
          >
            <Crest :code="c.code" :primary="clubColors(c).primary" :secondary="clubColors(c).secondary" :size="28" />
            <span class="flex-1 truncate font-semibold">{{ $nm(c.name) }}</span>
            <span class="text-xs text-text-muted">{{ $ln(c.league_name) }}</span>
            <span class="w-10 text-start font-numbers text-lg text-gold">{{ ((c.strength_cp ?? 0) / 100).toFixed(1) }}</span>
          </button>
        </div>
      </section>

      <button type="button" class="sticky bottom-3 h-14 rounded-xl bg-gold font-display text-lg font-extrabold text-on-gold shadow-lg disabled:opacity-50" :disabled="!ready || busy" @click="go">
        {{ busy ? '...' : room ? 'ادخل المباراة' : 'افتح الغرفة' }}
      </button>
      <p v-if="!ready" class="-mt-3 text-center text-xs text-text-muted">{{ name.trim().length < 2 ? 'اكتب اسمك (حرفان على الأقل)' : 'اختر فريقك' }}</p>
    </template>
  </main>
</template>

<script setup lang="ts">
// A match between two friends (docs/MATCH_VIEW.md 8): the host opens a room with
// a name and a club and shares the link; the friend opens it, writes a name and
// picks another club, and the live match starts on both screens.
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import Crest from '../components/Crest.vue'
import { clubColors, seats, sim, type Club, type Room } from '../api/sim'

const props = defineProps<{ room?: string }>()
const router = useRouter()
const room = ref<Room | null>(null)
const name = ref(read('legends.name') ?? '')
const q = ref('')
const results = ref<Club[]>([])
const club = ref<Club | null>(null)
const busy = ref(false)
const error = ref('')
const copied = ref(false)
let timer = 0

// Which seat this device has in which room: kept in the browser, so a refresh keeps the seat.
const seat = computed(() => (props.room ? read(`legends.room.${props.room}`) : null))
const isHost = computed(() => seat.value === 'host')
const ready = computed(() => name.value.trim().length >= 2 && !!club.value)
const link = computed(() => `${location.origin}/sim/room/${props.room}`)

function read(k: string) { try { return localStorage.getItem(k) } catch { return null } }
function write(k: string, v: string) { try { localStorage.setItem(k, v) } catch {} }

let searchTimer = 0
function search() {
  clearTimeout(searchTimer)
  searchTimer = window.setTimeout(async () => { try { results.value = await sim.clubs({ q: q.value }) } catch (e: any) { error.value = e.message } }, 200)
}

async function go() {
  busy.value = true
  error.value = ''
  write('legends.name', name.value.trim())
  try {
    if (!room.value) {
      const r = await sim.openRoom(name.value.trim(), club.value!.id)
      write(`legends.room.${r.id}`, 'host')
      write(`legends.roomseat.${r.id}`, r.seat!)
      await router.replace({ name: 'sim-room', params: { room: r.id } })
    } else {
      const r = await sim.joinRoom(room.value.id, name.value.trim(), club.value!.id)
      write(`legends.room.${r.id}`, 'guest')
      seats.set(r.match_id!, r.seat!)
      await router.replace({ name: 'sim-match', params: { id: r.match_id! } })
    }
  } catch (e: any) {
    error.value = e.message
  } finally {
    busy.value = false
  }
}

async function load() {
  clearTimeout(timer)
  if (!props.room) { room.value = null; return }
  try {
    room.value = await sim.room(props.room)
    // Both go to the match once it exists, each with his own seat: the host manages home, the guest away.
    if (room.value.match_id && seat.value) {
      const mine = read(`legends.roomseat.${props.room}`)
      if (seat.value === 'host' && mine && !seats.get(room.value.match_id)) seats.set(room.value.match_id, mine)
      return router.replace({ name: 'sim-match', params: { id: room.value.match_id } })
    }
    if (isHost.value) timer = window.setTimeout(load, 1500)
  } catch (e: any) {
    error.value = e.message
  }
}

async function share() {
  try {
    if (navigator.share) await navigator.share({ title: 'Legends', text: `${name.value} يتحداك في Legends`, url: link.value })
    else await navigator.clipboard.writeText(link.value)
    copied.value = true
    window.setTimeout(() => (copied.value = false), 2000)
  } catch {
    /* the share sheet was closed */
  }
}

watch(() => props.room, load)
onMounted(() => { load(); search() })
onBeforeUnmount(() => clearTimeout(timer))
</script>
