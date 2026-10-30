<script setup lang="ts" generic="K extends string">
// [X61] Every screen's tab strip on Headless UI's TabGroup: the arrows, Home and End move between the tabs and screen
// readers hear a tab list. The panels stay the page's own (v-if on the key). On a narrow phone the strip scrolls
// sideways, snapping, faded at the edge that hides more, never cut.
import { Tab, TabGroup, TabList } from '@headlessui/vue'
import { computed } from 'vue'

export interface TabItem<T extends string = string> { key: T; label: string; n?: number | string | null }

const props = withDefaults(defineProps<{ items: TabItem<K>[]; label?: string; tone?: 'gold' | 'brand'; fill?: boolean; size?: 'md' | 'sm' }>(), { tone: 'gold', size: 'md' })
const model = defineModel<K>({ required: true })
const index = computed(() => Math.max(0, props.items.findIndex((t) => t.key === model.value)))
const ON = { gold: 'bg-gold text-on-gold', brand: 'bg-brand text-white' }
</script>

<template>
  <TabGroup :selected-index="index" manual @change="(i: number) => (model = items[i].key)">
    <TabList class="ui-tabs rounded-xl bg-surface p-1" :class="fill ? 'grid auto-cols-fr grid-flow-col' : 'flex snap-x overflow-x-auto'" :aria-label="label ? $t(label) : undefined">
      <Tab v-for="t in items" :key="t.key" v-slot="{ selected }" as="template">
        <button type="button" class="flex shrink-0 snap-start items-center justify-center gap-1.5 rounded-lg px-4 font-bold transition-colors duration-150 focus:outline-none focus-visible:ring-2 focus-visible:ring-gold/70"
          :class="[size === 'sm' ? 'h-10 text-xs sm:text-sm' : 'min-h-touch text-sm', selected ? ON[tone] : 'text-text-soft hover:bg-text/5']">
          {{ $t(t.label) }}<span v-if="t.n !== undefined && t.n !== null" class="min-w-6 rounded-pill px-1.5 font-numbers" :class="selected ? 'bg-on-gold/15' : 'bg-text/10'">{{ t.n }}</span>
        </button>
      </Tab>
    </TabList>
  </TabGroup>
</template>

<style scoped>
/* The scrolling strip fades at its ends, so a cut tab reads as "more this way"; no bar of its own. */
.ui-tabs.flex {
  scrollbar-width: none;
  mask-image: linear-gradient(to left, transparent 0, #000 1.25rem, #000 calc(100% - 1.25rem), transparent 100%);
}
.ui-tabs.flex::-webkit-scrollbar { display: none; }
</style>
