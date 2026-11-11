<script setup lang="ts" generic="T extends Record<string, unknown>">
// A data table (design: WebHome "الترتيب"): numbers in Barlow, a solid blue header and the user's club in gold [X32].
// Columns marked `hideSm` drop out on the phone.
defineProps<{ rows: T[]; columns: { key: string; label: string; numeric?: boolean; hideSm?: boolean }[]; highlight?: (row: T) => boolean; caption?: string }>()
</script>

<template>
  <div class="overflow-x-auto">
    <table class="ui-table w-full border-separate border-spacing-y-1 text-body">
      <caption v-if="caption" class="sr-only">{{ caption }}</caption>
      <thead>
        <tr>
          <th v-for="c in columns" :key="c.key" scope="col" class="px-3 py-2 font-semibold" :class="[c.numeric ? 'text-center' : 'text-start', c.hideSm ? 'hidden sm:table-cell' : '']">{{ $t(c.label) }}</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="(row, i) in rows" :key="i" :class="highlight?.(row) ? 'is-mine' : ''">
          <td v-for="c in columns" :key="c.key" class="px-3 py-2.5 first:rounded-s-lg last:rounded-e-lg" :class="[c.numeric ? 'text-center font-numbers text-lg' : '', c.hideSm ? 'hidden sm:table-cell' : '']">
            <slot :name="c.key" :row="row">{{ row[c.key] }}</slot>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>
