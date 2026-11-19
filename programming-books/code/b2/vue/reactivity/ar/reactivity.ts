import { computed, effect, reactive } from "vue";

const cart = reactive({
  lines: [] as { name: string; price: number; quantity: number }[],
  coupon: "",
});
const total = computed(() => cart.lines.reduce((sum, l) => sum + l.price * l.quantity, 0));

// تعمل الآن، ومن جديد كلما تغير شيء قرأته
effect(() => console.log(`المجموع: ${total.value}`));

cart.lines.push({ name: "كوب بِت", price: 8, quantity: 1 });
cart.lines.push({ name: "البرمجة من الصفر", price: 25, quantity: 1 });
cart.lines[0]!.quantity = 3;
cart.coupon = "BIT10"; // لا شيء يُطبع: المجموع لم يقرأ الكوبون أبداً
