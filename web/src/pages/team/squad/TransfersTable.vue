<script setup lang="ts">
// [Sprint 48 T2] The league's transfers this season, newest first (the owner's screenshots, our own look): who, his
// position, from and to which club, the price paid and his value now, and when. A move of my club stands out in gold.
import { money } from '../../../lib/format'
import type { SeasonTransfer } from './squad'

const props = defineProps<{ transfers: SeasonTransfer[]; club: string }>()
const mine = (t: SeasonTransfer) => t.from === props.club || t.to === props.club
const when = (iso: string) => {
  const d = new Date(iso)
  return d.toDateString() === new Date().toDateString()
    ? d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    : d.toLocaleDateString([], { day: 'numeric', month: 'short' })
}
</script>

<template>
  <p v-if="!transfers.length" class="rounded-2xl ui-card px-4 py-10 text-center text-text-muted">
    {{ $t('لا انتقالات في الدوري هذا الموسم بعد.') }}
  </p>
  <div v-else class="overflow-x-auto rounded-2xl ui-card">
    <table class="w-full min-w-[46rem] border-collapse text-sm">
      <thead>
        <tr class="head">
          <th scope="col" class="px-3 py-2 text-start">{{ $t('اللاعب') }}</th>
          <th scope="col" class="px-2 py-2 text-center">{{ $t('المركز') }}</th>
          <th scope="col" class="px-2 py-2 text-start">{{ $t('من') }}</th>
          <th scope="col" class="px-2 py-2 text-start">{{ $t('إلى') }}</th>
          <th scope="col" class="px-2 py-2 text-end">{{ $t('السعر') }}</th>
          <th scope="col" class="px-2 py-2 text-end">{{ $t('القيمة') }}</th>
          <th scope="col" class="px-3 py-2 text-end">{{ $t('الوقت') }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="t in transfers" :key="t.id" class="border-b border-text/5 last:border-0" :class="mine(t) ? 'mine' : ''">
          <td class="px-3 py-2.5 font-display font-extrabold">{{ $nm(t.name) }}</td>
          <td class="px-2 text-center text-text-soft" dir="ltr">{{ t.position }}</td>
          <td class="px-2" :class="t.from === club ? 'font-bold text-gold' : ''">{{ t.from ? $nm(t.from) : $t('خارج الدوري') }}</td>
          <td class="px-2" :class="t.to === club ? 'font-bold text-gold' : ''">{{ t.to ? $nm(t.to) : $t('خارج الدوري') }}</td>
          <td class="px-2 text-end font-numbers font-bold">{{ t.price ? money(t.price) : $t('مبادلة') }}</td>
          <td class="px-2 text-end font-numbers text-text-soft">{{ money(t.value) }}</td>
          <td class="px-3 text-end font-numbers text-xs text-text-muted" dir="ltr">{{ when(t.at) }}</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<style scoped>
.head {
  background: linear-gradient(90deg, var(--color-brand-dark), var(--color-brand));
  color: var(--color-broadcast-white);
  font-size: 0.75rem;
}
.mine {
  background: color-mix(in srgb, var(--color-gold) 12%, transparent);
}
</style>
