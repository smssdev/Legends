<script setup lang="ts" generic="K extends string">
// [X61] Every screen's tab strip: the arrows, Home and End move between the tabs and screen readers hear a tab list.
// [Sprint 54 W4] On reka-ui's Tabs (Headless UI is gone). The panels stay the page's own (v-if on the key). On a
// narrow phone the strip scrolls sideways, snapping, faded at the edge that hides more, never cut.
import { TabsList, TabsRoot, TabsTrigger } from 'reka-ui'

export interface TabItem<T extends string = string> { key: T; label: string; n?: number | string | null }

withDefaults(defineProps<{ items: TabItem<K>[]; label?: string; tone?: 'gold' | 'brand'; fill?: boolean; size?: 'md' | 'sm' }>(), { tone: 'gold', size: 'md' })
const model = defineModel<K>({ required: true })
const ON = { gold: 'data-[state=active]:bg-gold data-[state=active]:text-on-gold', brand: 'data-[state=active]:bg-brand data-[state=active]:text-on-gold' }
</script>

<template>
  <TabsRoot :model-value="model" activation-mode="manual" @update:model-value="(k) => (model = k as K)">
    <TabsList class="ui-tabs rounded-xl bg-surface p-1" :class="fill ? 'grid auto-cols-fr grid-flow-col' : 'flex snap-x overflow-x-auto'" :aria-label="label ? $t(label) : undefined">
      <TabsTrigger v-for="t in items" :key="t.key" :value="t.key"
        class="group flex shrink-0 snap-start items-center justify-center gap-1.5 rounded-lg px-4 font-bold transition-colors duration-150 focus:outline-none focus-visible:ring-2 focus-visible:ring-gold/70 data-[state=inactive]:text-text-soft data-[state=inactive]:hover:bg-text/5"
        :class="[size === 'sm' ? 'min-h-touch px-3 text-xs sm:text-sm' : 'min-h-touch text-sm', ON[tone]]">
        {{ $t(t.label) }}<span v-if="t.n !== undefined && t.n !== null" class="min-w-6 rounded-pill bg-text/10 px-1.5 font-numbers group-data-[state=active]:bg-on-gold/15">{{ t.n }}</span>
      </TabsTrigger>
    </TabsList>
  </TabsRoot>
</template>

<style scoped>
/* The scrolling strip fades at its ends, so a cut tab reads as "more this way"; no bar of its own. */
.ui-tabs.flex {
  scrollbar-width: none;
  mask-image: linear-gradient(to left, transparent 0, #000 1.25rem, #000 calc(100% - 1.25rem), transparent 100%);
}
.ui-tabs.flex::-webkit-scrollbar { display: none; }
</style>
