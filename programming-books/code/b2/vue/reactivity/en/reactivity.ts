import { computed, effect, reactive } from "vue";

const cart = reactive({
  lines: [] as { name: string; price: number; quantity: number }[],
  coupon: "",
});
const total = computed(() => cart.lines.reduce((sum, l) => sum + l.price * l.quantity, 0));

// Runs now, and again whenever something it read changes
effect(() => console.log(`Total: ${total.value}`));

cart.lines.push({ name: "Bit mug", price: 8, quantity: 1 });
cart.lines.push({ name: "Code from Zero", price: 25, quantity: 1 });
cart.lines[0]!.quantity = 3;
cart.coupon = "BIT10"; // Nothing printed: the total never read the coupon
