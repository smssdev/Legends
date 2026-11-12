<script setup lang="ts">
// [Sprint 43 W2] A store item as its card (Sprint43Drafts.html): the picture in one shape (16:9), the discount and an
// offer's end on it, the title, the description, the price and the price before, and the WhatsApp button.
import { computed } from 'vue'
import { intlLocale } from '../../lib/i18n'
import type { components } from '../../api/schema'

type Item = components['schemas']['StoreItem'] & { whatsapp_url?: string }
const props = defineProps<{ item: Item; small?: boolean }>()
const price = (n: number) => new Intl.NumberFormat(intlLocale()).format(n)
const until = computed(() => props.item.ends_at
  ? new Intl.DateTimeFormat(intlLocale(), { day: 'numeric', month: 'long' }).format(new Date(props.item.ends_at)) : null)
</script>

<template>
  <article class="flex flex-col overflow-hidden rounded-2xl border border-surface-raised bg-surface">
    <div class="relative aspect-video w-full overflow-hidden bg-surface-sunk">
      <img v-if="item.image_url" :src="item.image_url" :alt="item.title" class="size-full object-cover" loading="lazy" decoding="async" />
      <span v-if="item.discount" class="absolute start-2 top-2 rounded-full bg-live px-3 py-1 text-xs font-extrabold text-white" dir="ltr">-{{ item.discount }}%</span>
      <span v-if="until && !small" class="absolute bottom-2 end-2 rounded-full bg-shade/70 px-3 py-1 text-xs font-bold text-gold-light">{{ $t('حتى {d}', { d: until }) }}</span>
    </div>
    <div class="flex flex-1 flex-col gap-2" :class="small ? 'p-2.5' : 'p-3.5'">
      <b :class="small ? 'text-sm' : 'text-base'">{{ item.title }}</b>
      <p v-if="!small" class="line-clamp-2 text-sm leading-relaxed text-text-muted">{{ item.description }}</p>
      <div class="mt-auto flex items-baseline gap-2">
        <b class="font-numbers text-gold" :class="small ? 'text-lg' : 'text-2xl'"><span dir="ltr">{{ price(item.price) }}</span> {{ item.currency }}</b>
        <s v-if="item.old_price" class="text-sm text-text-muted"><span dir="ltr">{{ price(item.old_price) }}</span></s>
      </div>
      <a v-if="item.whatsapp_url" :href="item.whatsapp_url" target="_blank" rel="noopener"
        class="flex min-h-touch items-center justify-center gap-2 rounded-xl bg-brand px-3 font-bold text-white">
        <svg viewBox="0 0 24 24" class="size-5 fill-current" aria-hidden="true"><path d="M12 2a10 10 0 0 0-8.6 15.1L2 22l5-1.3A10 10 0 1 0 12 2zm0 18.2a8.2 8.2 0 0 1-4.2-1.2l-.3-.2-3 .8.8-2.9-.2-.3A8.2 8.2 0 1 1 12 20.2zm4.5-6.1c-.2-.1-1.5-.7-1.7-.8s-.4-.1-.6.1-.7.8-.8 1-.3.2-.5.1a6.7 6.7 0 0 1-3.3-2.9c-.3-.4.3-.4.7-1.3.1-.2 0-.3 0-.4l-.8-1.8c-.2-.5-.4-.4-.6-.4h-.5a1 1 0 0 0-.7.3 3 3 0 0 0-.9 2.2 5.2 5.2 0 0 0 1.1 2.7 11.8 11.8 0 0 0 4.5 4c1.7.7 2.3.8 3.2.6a2.7 2.7 0 0 0 1.8-1.2 2.2 2.2 0 0 0 .1-1.2c0-.1-.2-.2-.5-.3z"/></svg>
        {{ small ? $t('واتساب') : $t('اطلبه عبر واتساب') }}
      </a>
    </div>
  </article>
</template>
