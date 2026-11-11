<script setup lang="ts">
// The username as it is typed [X11]: English letters and digits from a letter, checked on the server a moment after
// the last key, with free names to pick when it is taken or refused.
import { onBeforeUnmount, ref, watch } from 'vue'
import { api } from '../api/client'
import UiInput from './ui/UiInput.vue'

const props = defineProps<{ error?: string; current?: string }>()
const model = defineModel<string>({ default: '' })
const reason = ref('')
const ok = ref(false)
const suggestions = ref<string[]>([])
let timer = 0
let inFlight: Promise<unknown> = Promise.resolve()

// [Sprint 30 P9] What was dropped is said at once, never a key that seems to do nothing.
const warn = ref('')
function clean(v: string) {
  const letters = v.replace(/[^A-Za-z0-9]/g, '')
  const cleaned = letters.replace(/^\d+/, '').slice(0, 20)
  warn.value = /[\u0600-\u06FF]/.test(v) ? 'الحروف العربية غير مدعومة في اسم المستخدم: اكتبه بحروف إنجليزية'
    : letters !== v ? 'الرموز والمسافات غير مدعومة: حروف إنجليزية وأرقام فقط'
      : /^\d/.test(letters) ? 'يبدأ اسم المستخدم بحرف لا برقم'
        : letters.length > 20 ? 'اسم المستخدم 20 حرفاً على الأكثر' : ''
  // The prop may not change (all of it dropped): the box shows what is kept all the same.
  const el = document.activeElement
  if (cleaned !== v && el instanceof HTMLInputElement) el.value = cleaned
  model.value = cleaned
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
    <UiInput :model-value="model" :label="$t('اسم المستخدم')" type="username" autocomplete="username" placeholder="hamza10" :error="error || warn || reason" :hint="ok ? $t('متاح ✓') : $t('حروف إنجليزية وأرقام، من 3 إلى 20، ويبدأ بحرف')" @update:model-value="clean" />
    <div v-if="suggestions.length" class="flex flex-wrap items-center gap-2 text-sm">
      <span class="text-text-muted">{{ $t('جرّب:') }}</span>
      <button v-for="s in suggestions" :key="s" type="button" class="h-touch rounded-pill bg-surface-raised px-4 font-bold" dir="ltr" @click="model = s">{{ s }}</button>
    </div>
  </div>
</template>
