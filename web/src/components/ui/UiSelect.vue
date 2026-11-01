<script setup lang="ts">
// [X61] A choice from a list on Headless UI: a Listbox for a short list, a Combobox (typed to filter) for a long one
// (nationalities, leagues). The keyboard, Esc and the tap outside are its own; the list drops under its field and
// scrolls inside itself. `none` is the "any" choice (the empty value).
import { Combobox, ComboboxButton, ComboboxInput, ComboboxOption, ComboboxOptions, Listbox, ListboxButton, ListboxOption, ListboxOptions } from '@headlessui/vue'
import { computed, ref } from 'vue'
import { t } from '../../lib/i18n'

export type Option = { value: string; label: string }
const props = defineProps<{ options: Option[]; label: string; none?: string; searchable?: boolean; ltr?: boolean }>()
const model = defineModel<string>({ default: '' })
const all = computed<Option[]>(() => (props.none ? [{ value: '', label: t(props.none) }, ...props.options] : props.options))
const labelOf = (v: string) => all.value.find((o) => o.value === v)?.label ?? ''
const query = ref('')
const fold = (s: string) => s.toLocaleLowerCase().normalize('NFKD').replace(/[̀-ͯ]/g, '')
const filtered = computed(() => (query.value ? all.value.filter((o) => fold(o.label).includes(fold(query.value))) : all.value))
const FIELD = 'ui-field flex h-touch w-full items-center gap-2 rounded-md bg-surface-sunk px-3 text-start text-text focus:outline-none focus-visible:ring-2 focus-visible:ring-gold/70'
const PANEL = 'drop-panel absolute inset-x-0 top-full z-50 mt-1 max-h-[min(60vh,18rem)] overflow-y-auto overscroll-contain rounded-xl border border-text/10 bg-surface p-1 shadow-2xl focus:outline-none'
</script>

<template>
  <Combobox v-if="searchable" v-model="model" as="div" class="relative" @update:model-value="query = ''">
    <div :class="FIELD">
      <ComboboxInput class="h-full min-w-0 flex-1 bg-transparent focus:outline-none" :dir="ltr ? 'ltr' : 'auto'" :aria-label="$t(label)" :display-value="(v: unknown) => labelOf(String(v ?? ''))" @change="query = ($event.target as HTMLInputElement).value" />
      <ComboboxButton class="grid size-8 place-items-center text-gold" :aria-label="$t(label)">▾</ComboboxButton>
    </div>
    <Transition name="drop" @after-leave="query = ''">
      <ComboboxOptions :class="PANEL">
        <li v-if="!filtered.length" class="px-3 py-2 text-sm text-text-muted">{{ $t('لا نتائج') }}</li>
        <ComboboxOption v-for="o in filtered" :key="o.value" v-slot="{ active, selected }" :value="o.value" as="template">
          <li class="flex min-h-touch cursor-pointer items-center gap-2 rounded-lg px-3 text-sm" :class="active ? 'bg-surface-raised' : ''" :dir="ltr && o.value ? 'ltr' : undefined">
            <span class="min-w-0 flex-1 truncate" :class="selected ? 'font-bold text-gold' : ''">{{ o.label }}</span><span v-if="selected" class="text-gold" aria-hidden="true">✓</span>
          </li>
        </ComboboxOption>
      </ComboboxOptions>
    </Transition>
  </Combobox>

  <Listbox v-else v-model="model" as="div" class="relative">
    <ListboxButton :class="FIELD" :aria-label="$t(label)">
      <span class="min-w-0 flex-1 truncate" :dir="ltr && model ? 'ltr' : undefined">{{ labelOf(model) }}</span><span class="text-gold" aria-hidden="true">▾</span>
    </ListboxButton>
    <Transition name="drop">
      <ListboxOptions :class="PANEL">
        <ListboxOption v-for="o in all" :key="o.value" v-slot="{ active, selected }" :value="o.value" as="template">
          <li class="flex min-h-touch cursor-pointer items-center gap-2 rounded-lg px-3 text-sm" :class="active ? 'bg-surface-raised' : ''" :dir="ltr && o.value ? 'ltr' : undefined">
            <span class="min-w-0 flex-1 truncate" :class="selected ? 'font-bold text-gold' : ''">{{ o.label }}</span><span v-if="selected" class="text-gold" aria-hidden="true">✓</span>
          </li>
        </ListboxOption>
      </ListboxOptions>
    </Transition>
  </Listbox>
</template>
