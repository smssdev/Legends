<script setup lang="ts">
import Alert from "./Alert.vue";
import Badge from "./Badge.vue";
</script>

<template>
  <div class="gallery">
    <div class="row">
      <b>Order #1042</b>
      <Badge tone="success">Paid</Badge>
      <Badge tone="warning">Pending</Badge>
      <Badge tone="danger">Refunded</Badge>
      <Badge>New</Badge>
    </div>
    <div>
      <Alert>Your order ships tomorrow.</Alert>
      <Alert tone="success">Payment received. Thank you!</Alert>
      <Alert tone="warning">Only 2 left in stock.</Alert>
      <Alert tone="danger">The card was declined. Please try another one.</Alert>
    </div>
  </div>
</template>
