<script setup lang="ts">
// [Sprint 43 W2] The store (Sprint43Drafts.html): the timed offers first, then the packages, each ordered by WhatsApp.
// What they are and how they work is in the guide (App\Assistant\Guide, «store»).
import { computed, onMounted, ref } from 'vue'
import { api, asApiError } from '../api/client'
import StoreCard from '../components/store/StoreCard.vue'
import EmptyState from '../components/ui/EmptyState.vue'

const items = ref<any[] | null>(null)
const error = ref('')
const offers = computed(() => (items.value ?? []).filter((i) => i.kind === 'offer'))
const packages = computed(() => (items.value ?? []).filter((i) => i.kind === 'package'))

onMounted(async () => {
  try { items.value = (await api.GET('/store')).data!.items } catch (e) { error.value = asApiError(e).message; items.value = [] }
})
</script>

<template>
  <div class="flex flex-col gap-5">
    <header>
      <h1 class="font-display text-3xl font-extrabold">{{ $t('العروض') }}</h1>
      <p class="text-sm text-text-muted">{{ $t('اطلب عبر واتساب') }}</p>
    </header>
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>
    <p v-if="items === null" class="text-text-muted">{{ $t('جارٍ التحميل...') }}</p>
    <EmptyState v-else-if="!items.length" icon="megaphone" :title="$t('لا عروض الآن')" :text="$t('تابعنا، فالعروض الجديدة تظهر هنا.')" />
    <template v-else>
      <section v-if="offers.length" :aria-label="$t('عروض لمدة محددة')" class="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        <StoreCard v-for="i in offers" :key="i.id" :item="i" />
      </section>
      <section v-if="packages.length" :aria-label="$t('الباقات')" class="flex flex-col gap-2">
        <h2 class="font-display text-xl font-bold">{{ $t('الباقات') }}</h2>
        <div class="grid grid-cols-2 gap-3 md:grid-cols-3 lg:grid-cols-4">
          <StoreCard v-for="i in packages" :key="i.id" :item="i" small />
        </div>
      </section>
    </template>
  </div>
</template>
