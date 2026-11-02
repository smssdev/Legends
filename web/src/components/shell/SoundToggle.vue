<script setup lang="ts">
// [Sprint 39 N2] The notification sound on the top bar: one tap mutes it, another turns it on (and plays it once, so the
// coach hears what it is). The same switch as the account page's (lib/tone.ts), kept on this device.
import Icon from '../Icon.vue'
import { setTone, toneOn } from '../../lib/tone'
</script>

<template>
  <button type="button" class="bar-icon" :aria-pressed="toneOn" :aria-label="toneOn ? $t('صوت الإشعارات يعمل: اضغط لكتمه') : $t('صوت الإشعارات مكتوم: اضغط لتشغيله')" :title="toneOn ? $t('كتم صوت الإشعارات') : $t('تشغيل صوت الإشعارات')" @click="setTone(!toneOn)">
    <Icon :name="toneOn ? 'sound' : 'muted'" />
  </button>
</template>
