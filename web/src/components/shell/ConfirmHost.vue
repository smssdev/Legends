<script setup lang="ts">
// [Sprint 30 Q2] The one confirmation window for the whole game (stores/confirm).
import ConfirmDangerDialog from '../patterns/ConfirmDangerDialog.vue'
import { useConfirm } from '../../stores/confirm'

const c = useConfirm()
</script>

<template>
  <ConfirmDangerDialog :open="!!c.current" :title="c.current?.title ?? ''" :text="c.current?.text" :expected="c.current?.expected" :action="c.current?.action ?? ''"
    @close="c.settle(false)" @confirm="c.settle(true)" />
</template>
