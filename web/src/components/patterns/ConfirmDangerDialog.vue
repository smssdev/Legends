<script setup lang="ts">
// [Sprint 30 P2, Q2] One confirmation for every action that cannot be undone: the window names what goes, and the
// button wakes only when the exact name (or number) is typed, as deleting an account does. On Headless UI's Dialog
// (UiDialog): the focus stays inside and Esc closes it. Without `expected`: a plain «are you sure» with the button.
import { ref, watch } from 'vue'
import UiButton from '../ui/UiButton.vue'
import UiDialog from '../ui/UiDialog.vue'

// [X87] tone 'gold': a spend of coins, not a danger; remember: the «لا تسألني مرة أخرى» box.
const props = defineProps<{
  open: boolean
  title: string
  text?: string
  expected?: string
  action: string
  busy?: boolean
  tone?: 'danger' | 'gold'
  remember?: boolean
}>()
const emit = defineEmits<{ close: []; confirm: [remember: boolean] }>()
const typed = ref('')
const again = ref(false)
watch(
  () => props.open,
  () => {
    typed.value = ''
    again.value = false
  },
)
const matches = () => !props.expected || typed.value.trim() === props.expected.trim()
</script>

<template>
  <UiDialog :open="open" :title="title" @close="emit('close')">
    <form class="flex flex-col gap-3" @submit.prevent="matches() && emit('confirm', again)">
      <p v-if="text" class="text-sm text-text-muted">{{ $t(text) }}</p>
      <label v-if="expected" class="flex flex-col gap-1 text-sm">
        <span
          >{{ $t('للتأكيد اكتب:') }}
          <b class="select-all" dir="auto"
            ><bdi>{{ expected }}</bdi></b
          ></span
        >
        <input
          v-model="typed"
          dir="auto"
          autocomplete="off"
          class="h-touch rounded-lg bg-surface-sunk px-3"
          :aria-label="$t('للتأكيد اكتب:')"
        />
      </label>
      <label v-if="remember" class="flex min-h-touch items-center gap-2 text-sm text-text-muted">
        <input v-model="again" type="checkbox" class="size-4 accent-[var(--color-gold)]" />{{ $t('لا تسألني مرة أخرى') }}
      </label>
      <div class="flex gap-2">
        <UiButton type="submit" :variant="tone === 'gold' ? 'primary' : 'danger'" block :disabled="!matches()" :loading="busy">{{
          $t(action)
        }}</UiButton>
        <UiButton variant="quiet" @click="emit('close')">{{ $t('إلغاء') }}</UiButton>
      </div>
    </form>
  </UiDialog>
</template>
