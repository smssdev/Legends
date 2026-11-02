<script setup lang="ts">
// [X61] The ticket price for the home matches to come, four levels (Headless UI's RadioGroup): each with its seat
// price, the crowd it would draw and what it would bring at the next home match, from the server. Cheap fills the
// stands, dear empties them; the gate is posted after each home match.
import { RadioGroup, RadioGroupLabel, RadioGroupOption } from '@headlessui/vue'
import { computed } from 'vue'
import { api } from '../api/client'
import { act, busy as isBusy } from '../lib/action'
import type { components } from '../api/schema'
import { money } from '../lib/format'
import { t } from '../lib/i18n'

type Tickets = components['schemas']['TicketLevels']
const props = defineProps<{ leagueId: number; tickets: Tickets }>()
const emit = defineEmits<{ changed: [Tickets] }>()
// [X92] Through lib/action: «تراجع» puts back the level before.
const busy = computed(() => isBusy('ticket-price'))
const set = (level: Tickets['level']) => api.PUT('/leagues/{league}/team/tickets', { params: { path: { league: props.leagueId } }, body: { level } }).then((r) => { if (r.data) emit('changed', r.data); return r })
async function pick(level: Tickets['level']) {
  if (level === props.tickets.level || busy.value) return
  const before = props.tickets.level
  await act('ticket-price', () => set(level), {
    success: (r) => t('سعر التذاكر الآن: {v0}', { v0: r.data?.levels.find((l) => l.level === level)?.name ?? '' }),
    undo: () => set(before),
  })
}
</script>

<template>
  <RadioGroup :model-value="tickets.level" :disabled="busy" class="flex flex-col gap-2" @update:model-value="pick">
    <RadioGroupLabel class="text-xs text-text-muted">{{ $t('سعر التذاكر لمبارياتك القادمة على أرضك') }}</RadioGroupLabel>
    <div class="grid grid-cols-2 gap-2">
      <RadioGroupOption v-for="l in tickets.levels" :key="l.level" v-slot="{ checked, active }" :value="l.level" as="template">
        <button type="button" class="flex min-h-touch flex-col items-start gap-0.5 rounded-lg border px-3 py-2 text-start transition duration-150 ease-soft active:scale-[0.98]"
          :class="[checked ? 'border-gold bg-gold/10' : 'border-text/10 bg-surface-sunk hover:border-text/25', active ? 'ring-2 ring-gold/60' : '']">
          <b class="text-sm" :class="checked ? 'text-gold' : ''">{{ l.name }}</b>
          <span class="font-numbers text-xs text-text-muted" dir="ltr">{{ money(l.price) }} · {{ Math.round(l.attendance_bp / 100) }}%</span>
          <span class="font-numbers text-xs text-success" dir="ltr">+{{ money(l.per_match) }}</span>
        </button>
      </RadioGroupOption>
    </div>
  </RadioGroup>
</template>
