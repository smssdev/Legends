<script setup lang="ts">
// [Sprint 29] A group's link: the coach who opens it joins, then lands in the group.
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { api, asApiError, ensureCsrf } from '../../api/client'

const props = defineProps<{ code: string }>()
const router = useRouter()
const error = ref('')
onMounted(async () => {
  try {
    await ensureCsrf()
    const { data } = await api.POST('/groups/join/{code}', { params: { path: { code: props.code } } })
    await router.replace({ name: 'group', params: { id: data!.group.id } })
  } catch (e) {
    error.value = asApiError(e).message
  }
})
</script>

<template>
  <div class="flex flex-col items-center gap-3 py-12 text-center">
    <p v-if="error" class="rounded-lg bg-live/15 px-4 py-3 text-sm text-danger" role="alert">{{ $t(error) }}</p>
    <p v-else class="text-text-muted">{{ $t('ينضم إلى الجروب…') }}</p>
    <RouterLink :to="{ name: 'groups' }" class="font-bold text-gold">{{ $t('الجروبات') }}</RouterLink>
  </div>
</template>
