<script setup lang="ts">
import Icon from '../Icon.vue'
// [X61] A choice from a list: a Select for a short list, a Combobox (typed to filter) for a long one (nationalities,
// leagues). The keyboard, Esc and the tap outside are its own; the list drops under its field and scrolls inside
// itself. `none` is the "any" choice (the empty value).
// [Sprint 54 W4] On reka-ui (Headless UI is gone). reka refuses an empty item value, so the "any" choice is carried
// inside as NONE and handed out as '' again.
import {
  ComboboxAnchor, ComboboxContent, ComboboxEmpty, ComboboxInput, ComboboxItem, ComboboxRoot, ComboboxTrigger, ComboboxViewport,
  SelectContent, SelectItem, SelectItemIndicator, SelectItemText, SelectPortal, SelectRoot, SelectTrigger, SelectViewport,
} from 'reka-ui'
import { computed, ref } from 'vue'
import { t } from '../../lib/i18n'

export type Option = { value: string; label: string }
const props = defineProps<{ options: Option[]; label: string; none?: string; searchable?: boolean; ltr?: boolean }>()
const model = defineModel<string>({ default: '' })
const NONE = '\u0000none'
const inner = computed({ get: () => model.value || (props.none ? NONE : ''), set: (v: string) => (model.value = v === NONE ? '' : v) })
const all = computed<Option[]>(() => (props.none ? [{ value: NONE, label: t(props.none) }, ...props.options] : props.options))
const labelOf = (v: string) => all.value.find((o) => o.value === v)?.label ?? ''
const query = ref('')
const fold = (s: string) => s.toLocaleLowerCase().normalize('NFKD').replace(/[̀-ͯ]/g, '')
const filtered = computed(() => (query.value ? all.value.filter((o) => fold(o.label).includes(fold(query.value))) : all.value))
const FIELD = 'ui-field flex h-touch w-full items-center gap-2 rounded-md bg-surface-sunk px-3 text-start text-text focus:outline-none focus-visible:ring-2 focus-visible:ring-gold/70'
const PANEL = 'drop-panel z-[70] max-h-[min(60vh,18rem)] w-[var(--reka-popper-anchor-width)] overflow-y-auto overscroll-contain rounded-xl border border-text/10 bg-surface p-1 shadow-2xl focus:outline-none'
const ITEM = 'group flex min-h-touch cursor-pointer items-center gap-2 rounded-lg px-3 text-sm outline-none data-[highlighted]:bg-surface-raised'
</script>

<template>
  <ComboboxRoot v-if="searchable" v-model="inner" ignore-filter class="relative" @update:open="(o: boolean) => { if (!o) query = '' }">
    <ComboboxAnchor :class="FIELD">
      <ComboboxInput v-model="query" class="h-full min-w-0 flex-1 bg-transparent focus:outline-none" :dir="ltr ? 'ltr' : 'auto'" :aria-label="$t(label)"
        :display-value="(v: unknown) => labelOf(String(v ?? ''))" />
      <ComboboxTrigger class="grid size-8 place-items-center text-gold" :aria-label="$t(label)"><Icon name="chevron_down" :size="16" /></ComboboxTrigger>
    </ComboboxAnchor>
    <ComboboxContent position="popper" :side-offset="4" :class="PANEL">
      <ComboboxViewport>
        <ComboboxEmpty class="px-3 py-2 text-sm text-text-muted">{{ $t('لا نتائج') }}</ComboboxEmpty>
        <ComboboxItem v-for="o in filtered" :key="o.value" :value="o.value" :class="ITEM" :dir="ltr && o.value !== NONE ? 'ltr' : undefined">
          <span class="min-w-0 flex-1 truncate group-data-[state=checked]:font-bold group-data-[state=checked]:text-gold">{{ o.label }}</span>
          <span class="hidden text-gold group-data-[state=checked]:inline" aria-hidden="true">✓</span>
        </ComboboxItem>
      </ComboboxViewport>
    </ComboboxContent>
  </ComboboxRoot>

  <SelectRoot v-else v-model="inner">
    <SelectTrigger :class="FIELD" :aria-label="$t(label)">
      <span class="min-w-0 flex-1 truncate" :dir="ltr && model ? 'ltr' : undefined">{{ labelOf(inner) }}</span><span class="text-gold" aria-hidden="true"><Icon name="chevron_down" :size="16" /></span>
    </SelectTrigger>
    <SelectPortal>
      <SelectContent position="popper" :side-offset="4" :class="PANEL">
        <SelectViewport>
          <SelectItem v-for="o in all" :key="o.value" :value="o.value" :class="ITEM" :dir="ltr && o.value !== NONE ? 'ltr' : undefined">
            <SelectItemText class="min-w-0 flex-1 truncate group-data-[state=checked]:font-bold group-data-[state=checked]:text-gold">{{ o.label }}</SelectItemText>
            <SelectItemIndicator class="text-gold" aria-hidden="true">✓</SelectItemIndicator>
          </SelectItem>
        </SelectViewport>
      </SelectContent>
    </SelectPortal>
  </SelectRoot>
</template>
