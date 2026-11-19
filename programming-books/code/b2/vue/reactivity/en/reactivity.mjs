// vue/reactivity/en/reactivity.ts
import { computed, effect, reactive } from "vue";
var cart = reactive({
  lines: [],
  coupon: ""
});
var total = computed(() => cart.lines.reduce((sum, l) => sum + l.price * l.quantity, 0));
effect(() => console.log(`Total: ${total.value}`));
cart.lines.push({ name: "Bit mug", price: 8, quantity: 1 });
cart.lines.push({ name: "Code from Zero", price: 25, quantity: 1 });
cart.lines[0].quantity = 3;
cart.coupon = "BIT10";
