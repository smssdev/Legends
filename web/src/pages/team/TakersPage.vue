<script setup lang="ts">
// [Sprint 48 T4] The specialists (the owner's screenshots, our own look): the captain and the penalty, free-kick and
// corner takers, a big card each with the player, his strength and his skill at it, and «تبديل اللاعب» to choose from
// the whole squad (or leave it to the server: the best of the eleven). Was a row at the foot of the lineup (Sprint 27 W5).
import UiButton from '../../components/ui/UiButton.vue'
import { computed, onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../../api/client'
import UiDialog from '../../components/ui/UiDialog.vue'
import NationChip from '../../components/ui/NationChip.vue'
import { useTeam, type SquadPlayer } from './team'

const { leagueId, team, error, loaded, load } = useTeam()
onMounted(load)

const ROLES = {
  captain: { label: 'قائد الفريق', skill: 'القيادة', icon: 'M5 4h14l-2 6 2 6H5l2-6z' },
  penalty: { label: 'ضربات الجزاء', skill: 'الجزاء', icon: 'M12 3a9 9 0 1 0 0 18 9 9 0 0 0 0-18zM12 7l3.5 2.5-1.3 4h-4.4l-1.3-4z' },
  free_kick: { label: 'الضربات الحرة', skill: 'الحرة', icon: 'M7 20V9M12 20V9M17 20V9M7 9a2 2 0 1 1 0-4 2 2 0 0 1 0 4zM12 9a2 2 0 1 1 0-4 2 2 0 0 1 0 4zM17 9a2 2 0 1 1 0-4 2 2 0 0 1 0 4z' },
  corner: { label: 'الركنيات', skill: 'العرضيات', icon: 'M6 21V3l10 4-10 4' },
} as const
type Role = keyof typeof ROLES
const roles = Object.keys(ROLES) as Role[]

const players = computed(() => new Map((team.value?.players ?? []).map((p) => [p.id, p])))
const holder = (r: Role): SquadPlayer | null => players.value.get(team.value?.takers[r]?.player_id ?? 0) ?? null
const skillOf = (r: Role, id: number | null | undefined) => team.value?.takers[r]?.candidates?.find((c) => c.id === id)?.skill ?? null

const choosing = ref<Role | null>(null)
const message = ref('')
async function setTaker(role: Role, value: number | null) {
  choosing.value = null
  if (!leagueId.value || !team.value) return
  const body: Record<string, number | null> = {}
  for (const r of roles) body[r] = r === role ? value : (team.value.takers[r]?.chosen_id ?? null)
  try {
    await ensureCsrf()
    const { data } = await api.PUT('/leagues/{league}/team/takers', { params: { path: { league: leagueId.value } }, body })
    team.value = data as typeof team.value
    message.value = ''
  } catch (e) {
    message.value = asApiError(e).message
  }
}
</script>

<template>
  <div class="flex flex-col gap-4 pb-6">
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>
    <div v-else-if="loaded && !team" class="rounded-xl ui-card p-8 text-center">
      <p class="mb-3 text-text-muted">{{ $t('ليس لديك فريق بعد.') }}</p>
      <RouterLink :to="{ name: 'leagues' }" class="font-bold text-gold">{{ $t('دورياتي') }}</RouterLink>
    </div>
    <template v-else-if="team">
      <header class="flex flex-wrap items-center justify-between gap-3">
        <div>
          <h1 class="font-display text-3xl font-extrabold">{{ $t('المتخصصون') }}</h1>
          <p class="text-sm text-text-muted">{{ $t('عيّن قائدك ومنفذي الكرات الثابتة. «تلقائي» يختار الأفضل من الأساسيين في كل مباراة.') }}</p>
        </div>
        <RouterLink :to="{ name: 'lineup' }" class="flex h-11 items-center rounded-lg bg-surface px-4 text-sm font-bold">{{ $t('التشكيلة ›') }}</RouterLink>
      </header>
      <p v-if="message" class="rounded-lg bg-live/15 px-3 py-2 text-sm text-danger" role="alert">{{ $t(message) }}</p>

      <div class="grid grid-cols-2 gap-4 xl:grid-cols-4">
        <section v-for="r in roles" :key="r" class="flex flex-col items-center gap-3" :aria-labelledby="`role-${r}`">
          <h2 :id="`role-${r}`" class="font-display text-lg font-extrabold">{{ $t(ROLES[r].label) }}</h2>
          <div class="relative mt-4 w-full max-w-[15rem]">
          <span class="role-badge absolute -top-5 left-1/2 grid size-12 -translate-x-1/2 place-items-center rounded-full" aria-hidden="true">
            <svg viewBox="0 0 24 24" class="size-6" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path :d="ROLES[r].icon" /></svg>
          </span>
          <div class="taker-card" :class="{ 'is-chosen': !team.takers[r]?.auto }">
            <template v-if="holder(r)">
              <div class="flex flex-col items-center px-4 pb-10 pt-9 text-center">
                <b class="w-full truncate font-display text-xl font-extrabold" dir="auto">{{ $nm(holder(r)!.name) }}</b>
                <span class="text-sm text-white/75">{{ $t('السن: {v0}', { v0: holder(r)!.age }) }} · <span dir="ltr">{{ holder(r)!.position }}</span></span>
                <div class="my-4 flex w-full items-center justify-between">
                  <NationChip :nation="holder(r)!.nation ?? null" :name="holder(r)!.nationality" class="[&_span]:!text-white/80" />
                  <span class="flex flex-col items-end leading-none"><small class="text-xs text-white/70">{{ $t('القوة') }}</small><b class="font-numbers text-4xl text-gold-light">{{ holder(r)!.overall }}</b></span>
                </div>
                <div class="w-full">
                  <div class="mb-1 flex justify-between text-xs text-white/80"><span>{{ $t(ROLES[r].skill) }}</span><b class="font-numbers">{{ skillOf(r, holder(r)!.id) ?? '—' }}</b></div>
                  <div class="h-2.5 overflow-hidden rounded-full bg-black/30" role="meter" :aria-label="$t(ROLES[r].skill)" :aria-valuenow="skillOf(r, holder(r)!.id) ?? 0" aria-valuemin="0" aria-valuemax="99">
                    <span class="block h-full rounded-full bg-gradient-to-r from-gold to-gold-light" :style="{ width: `${Math.min(99, skillOf(r, holder(r)!.id) ?? 0)}%` }" />
                  </div>
                </div>
                <span class="mt-3 rounded-pill px-3 py-0.5 text-xs font-bold" :class="team.takers[r]?.auto ? 'bg-white/15 text-white/85' : 'bg-gold text-on-gold'">{{ team.takers[r]?.auto ? $t('تلقائي') : $t('اختيارك') }}</span>
              </div>
            </template>
            <p v-else class="px-4 py-16 text-center text-white/80">{{ $t('لا أحد بعد') }}</p>
          </div>
          </div>
          <UiButton variant="brand" block class="max-w-[15rem]" @click="choosing = r">{{ $t('تبديل اللاعب') }}</UiButton>
        </section>
      </div>
    </template>
    <p v-else class="text-text-muted">{{ $t('جارٍ التحميل…') }}</p>

    <!-- Anyone in the squad, the best at it first; or «تلقائي». -->
    <UiDialog :open="!!choosing" :title="choosing ? $t(ROLES[choosing].label) : ''" @close="choosing = null">
      <ul v-if="choosing && team" class="flex max-h-[65vh] flex-col gap-1 overflow-y-auto">
        <li>
          <button type="button" class="flex min-h-touch w-full items-center justify-between rounded-lg px-3 font-bold" :class="team.takers[choosing]?.chosen_id ? 'bg-surface' : 'bg-gold/15 text-gold'" @click="setTaker(choosing!, null)">
            {{ $t('تلقائي: الأفضل من الأساسيين') }}
          </button>
        </li>
        <li v-for="c in team.takers[choosing]?.candidates ?? []" :key="c.id">
          <button type="button" class="flex min-h-touch w-full items-center gap-2 rounded-lg px-3 py-2 text-start" :class="team.takers[choosing]?.chosen_id === c.id ? 'bg-gold/15' : 'bg-surface'" @click="setTaker(choosing!, c.id)">
            <span class="w-8 font-numbers text-lg font-bold text-gold">{{ c.skill }}</span>
            <span class="min-w-0 flex-1 truncate text-sm font-bold">{{ $nm(players.get(c.id)?.name) }}</span>
            <span class="text-xs" :class="c.on ? 'text-success' : 'text-text-muted'">{{ c.on ? $t('أساسي') : $t('ليس أساسياً') }}</span>
          </button>
        </li>
      </ul>
      <p v-if="choosing" class="mt-2 text-xs text-text-muted">{{ $t('الرقم: {v0}', { v0: $t(ROLES[choosing].skill) }) }}</p>
    </UiDialog>
  </div>
</template>

<style scoped>
/* A tall card cut like a shield: the night's blue with a floodlight at its top and a silver rim; gold when chosen. */
.taker-card {
  color: var(--color-broadcast-white);
  clip-path: polygon(0 6%, 50% 0, 100% 6%, 100% 86%, 50% 100%, 0 86%);
  background:
    radial-gradient(90% 45% at 50% 0%, rgb(255 255 255 / 0.28), transparent 70%),
    linear-gradient(170deg, var(--color-brand) 0%, var(--color-brand-dark) 55%, var(--color-bg-deep) 100%);
  box-shadow: inset 0 0 0 3px rgb(255 255 255 / 0.45);
  min-height: 17rem;
}
.taker-card.is-chosen { box-shadow: inset 0 0 0 3px var(--color-gold); }
.role-badge { background: var(--color-brand-dark); color: var(--color-gold-light); box-shadow: 0 0 0 3px var(--color-gold); z-index: 2; }
</style>
