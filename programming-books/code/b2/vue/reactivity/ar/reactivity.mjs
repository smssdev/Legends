// vue/reactivity/ar/reactivity.ts
import { computed, effect, reactive } from "vue";
var cart = reactive({
  lines: [],
  coupon: ""
});
var total = computed(() => cart.lines.reduce((sum, l) => sum + l.price * l.quantity, 0));
effect(() => console.log(`\u0627\u0644\u0645\u062C\u0645\u0648\u0639: ${total.value}`));
cart.lines.push({ name: "\u0643\u0648\u0628 \u0628\u0650\u062A", price: 8, quantity: 1 });
cart.lines.push({ name: "\u0627\u0644\u0628\u0631\u0645\u062C\u0629 \u0645\u0646 \u0627\u0644\u0635\u0641\u0631", price: 25, quantity: 1 });
cart.lines[0].quantity = 3;
cart.coupon = "BIT10";
