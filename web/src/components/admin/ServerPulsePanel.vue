<script setup lang="ts">
// [Sprint 66 B3] The server's pulse (GET /admin/server): how fast the live match answers over the last five minutes
// (half the answers under the median, 95 in 100 under the second figure), the jobs waiting in the queue, and the
// sockets Reverb holds. A part the server cannot read shows a dash. Asked again every 30 seconds while on screen.
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { api } from '../../api/client'
import type { paths } from '../../api/schema'
import UiCard from '../ui/UiCard.vue'

type Pulse = paths['/admin/server']['get']['responses']['200']['content']['application/json']
const pulse = ref<Pulse | null>(null)
const load = async () => {
  pulse.value = (await api.GET('/admin/server')).data ?? null
}
let timer = 0
onMounted(() => {
  void load()
  timer = window.setInterval(load, 30_000)
})
onBeforeUnmount(() => window.clearInterval(timer))
const ms = (v: number | null | undefined) => (v == null ? '—' : `${v} ms`)
const n = (v: number | null | undefined) => (v == null ? '—' : String(v))
</script>

<template>
  <UiCard title="صحة الخادم">
    <dl v-if="pulse" class="pulse">
      <div>
        <dt>{{ $t('المباراة المباشرة: الوسيط') }}</dt>
        <dd class="font-numbers" dir="ltr">{{ ms(pulse.live.p50_ms) }}</dd>
      </div>
      <div>
        <dt>{{ $t('المباراة المباشرة: 95%') }}</dt>
        <dd class="font-numbers" dir="ltr">{{ ms(pulse.live.p95_ms) }}</dd>
      </div>
      <div>
        <dt>{{ $t('الطابور') }}</dt>
        <dd class="font-numbers" dir="ltr">{{ n(pulse.queue) }}</dd>
      </div>
      <div>
        <dt>{{ $t('اتصالات البث') }}</dt>
        <dd class="font-numbers" dir="ltr">{{ n(pulse.reverb_connections) }}</dd>
      </div>
    </dl>
    <p v-if="pulse" class="text-caption text-text-muted">{{ $t('من {v0} طلباً في آخر 5 دقائق', { v0: pulse.live.samples }) }}</p>
  </UiCard>
</template>

<style scoped>
.pulse {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(9rem, 1fr));
  gap: var(--space-sm);
  margin-block-end: var(--space-sm);
}
.pulse div {
  border-radius: var(--radius-lg);
  background: var(--color-surface-sunk);
  padding: var(--space-sm);
}
.pulse dt {
  color: var(--color-text-muted);
  font-size: var(--text-caption);
}
.pulse dd {
  font-size: var(--text-title);
  font-weight: 700;
}
</style>
