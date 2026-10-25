<script setup lang="ts">
// The username as it is typed [X11]: English letters and digits from a letter, checked on the server a moment after
// the last key, with free names to pick when it is taken or refused.
import { onBeforeUnmount, ref, watch } from 'vue'
import { api } from '../api/client'
import TextField from './TextField.vue'

const props = defineProps<{ error?: string; current?: string }>()
const model = defineModel<string>({ default: '' })
const reason = ref('')
const ok = ref(false)
const suggestions = ref<string[]>([])
let timer = 0
let inFlight: Promise<unknown> = Promise.resolve()

function clean(v: string) {
  model.value = v.replace(/[^A-Za-z0-9]/g, '').replace(/^\d+/, '').slice(0, 20)
}

watch(model, (v) => {
  clearTimeout(timer)
  reason.value = ''
  ok.value = false
  suggestions.value = []
  if (v.length < 3 || v.toLowerCase() === props.current?.toLowerCase()) return
  timer = window.setTimeout(async () => {
    const asked = api.GET('/auth/username', { params: { query: { u: v } } }).catch(() => ({ data: undefined }))
    inFlight = asked
    const { data } = await asked
    if (!data || v !== model.value) return
    ok.value = data.available
    reason.value = data.reason ?? ''
    suggestions.value = data.suggestions
  }, 400)
})
onBeforeUnmount(() => clearTimeout(timer))

/**
 * Call before signing up: no check left waiting, and none still on its way. A check's answer carries the guest's
 * session cookie, and one landing after the sign-up's would sign the new account out.
 */
async function settle() {
  clearTimeout(timer)
  await inFlight
}
defineExpose({ settle })
</script>

<template>
  <div class="flex flex-col gap-2">
    <TextField :model-value="model" label="اسم المستخدم" type="username" autocomplete="username" placeholder="hamza10" :error="error || reason" :hint="ok ? 'متاح ✓' : 'حروف إنجليزية وأرقام، من 3 إلى 20، ويبدأ بحرف'" @update:model-value="clean" />
    <div v-if="suggestions.length" class="flex flex-wrap items-center gap-2 text-sm">
      <span class="text-text-muted">جرّب:</span>
      <button v-for="s in suggestions" :key="s" type="button" class="h-touch rounded-pill bg-surface-raised px-4 font-bold" dir="ltr" @click="model = s">{{ s }}</button>
    </div>
  </div>
</template>
