<script setup lang="ts">
// The wallet and the shop (Sprint 34 W1, docs/features/premium.md): the coins, today's reward, what was spent this
// season in each league against the cap, the movements, and the shop whose buying comes after v1 ("قريباً").
import { intlLocale } from '../lib/i18n'
import { onMounted, ref } from 'vue'
import { api, asApiError, ensureCsrf } from '../api/client'
import { useWallet } from '../stores/wallet'

const wallet = useWallet()
const error = ref('')
const busy = ref(false)
const when = (iso: string) => new Intl.DateTimeFormat(intlLocale(), { day: 'numeric', month: 'short', hour: '2-digit', minute: '2-digit' }).format(new Date(iso))

async function daily() {
  busy.value = true
  error.value = ''
  try {
    await ensureCsrf()
    wallet.view = (await api.POST('/wallet/daily')).data!
  } catch (e) {
    error.value = asApiError(e).message
  }
  busy.value = false
}
onMounted(() => wallet.load())
</script>

<template>
  <div class="flex flex-col gap-4">
    <h1 class="font-display text-3xl font-extrabold">{{ $t('المحفظة والمتجر') }}</h1>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-[#FF8A8A]" role="alert">{{ $t(error) }}</p>
    <p v-if="!wallet.view" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>
    <template v-else>
      <section :aria-label="$t('الرصيد')" class="flex flex-wrap items-center gap-4 rounded-xl border border-gold/30 bg-surface p-5">
        <img src="/brand/coin.svg" alt="" class="size-14" />
        <div class="flex-1">
          <span class="block text-sm text-text-muted">{{ $t('رصيدك من الكوينز') }}</span>
          <b class="font-numbers text-4xl text-gold" dir="ltr">{{ wallet.view.balance }}</b>
        </div>
        <button type="button" class="h-12 rounded-md bg-gold px-5 font-display font-bold text-on-gold disabled:opacity-40" :disabled="busy || wallet.view.daily.claimed" @click="daily">
          {{ wallet.view.daily.claimed ? $t('استلمت مكافأة اليوم') : $t('استلم مكافأة اليوم · {v0}', { v0: wallet.view.daily.amount }) }}
        </button>
      </section>

      <section v-if="wallet.view.leagues.length" :aria-label="$t('الصرف في كل دوري')" class="flex flex-col gap-2 rounded-xl bg-surface p-4">
        <h2 class="font-display text-lg font-bold">{{ $t('الصرف هذا الموسم') }}</h2>
        <div v-for="l in wallet.view.leagues" :key="l.id" class="flex flex-col gap-1">
          <div class="flex items-center justify-between text-sm"><span class="font-bold">{{ $nm(l.name) }}</span>
            <span v-if="l.fair" class="text-text-muted">{{ $t('دوري نزيه: لا كوينز فيه') }}</span>
            <span v-else class="font-numbers text-text-muted" dir="ltr">{{ l.spent }} / {{ wallet.view.cap }}</span></div>
          <div v-if="!l.fair" class="h-2 overflow-hidden rounded-full bg-surface-sunk"><div class="h-full rounded-full bg-gold" :style="{ width: Math.min(100, (l.spent * 100) / wallet.view.cap) + '%' }" /></div>
        </div>
      </section>

      <section :aria-label="$t('المتجر')" class="flex flex-col gap-3 rounded-xl bg-surface p-4">
        <h2 class="font-display text-lg font-bold">{{ $t('المتجر') }}</h2>
        <div class="grid gap-2 sm:grid-cols-3">
          <div v-for="p in wallet.view.shop" :key="p.coins" class="flex flex-col items-center gap-2 rounded-lg bg-surface-sunk p-4">
            <img src="/brand/coin.svg" alt="" class="size-10" />
            <b class="font-numbers text-2xl" dir="ltr">{{ p.coins }}</b>
            <span class="text-sm text-text-muted">{{ $t(p.label) }}</span>
            <button type="button" disabled class="h-touch w-full rounded-md bg-surface-raised font-bold text-text-muted">{{ $t('قريباً') }}</button>
          </div>
        </div>
      </section>

      <section :aria-label="$t('الحركات')" class="flex flex-col gap-1 rounded-xl bg-surface p-4">
        <h2 class="font-display text-lg font-bold">{{ $t('الحركات') }}</h2>
        <p v-if="!wallet.view.transactions.length" class="text-sm text-text-muted">{{ $t('لا حركات بعد.') }}</p>
        <div v-for="(t, i) in wallet.view.transactions" :key="i" class="flex min-h-touch items-center gap-2 border-b border-text/5 text-sm last:border-0">
          <span class="flex-1">{{ $t(t.label) }}</span>
          <span class="text-xs text-text-muted">{{ when(t.at) }}</span>
          <b class="w-14 text-end font-numbers" :class="t.amount > 0 ? 'text-success' : 'text-[#FF8A8A]'" dir="ltr">{{ t.amount > 0 ? '+' : '' }}{{ t.amount }}</b>
        </div>
      </section>
    </template>
  </div>
</template>
