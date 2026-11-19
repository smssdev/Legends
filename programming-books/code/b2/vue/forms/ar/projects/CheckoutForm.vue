<script setup lang="ts">
import { ref } from "vue";
import FormField from "../FormField.vue";
import { useForm } from "../useForm";
import { checkoutSchema, STEPS } from "./checkout-schema";

const { values, errors, blur, checkFields, handleSubmit } = useForm(checkoutSchema, {
  city: "" as "cairo",
  street: "",
  phone: "",
  method: "cash",
});
const step = ref(0);
const placed = ref(false);
const cities = { cairo: "القاهرة", alexandria: "الإسكندرية", giza: "الجيزة" };

function next() {
  if (checkFields(STEPS[step.value]!.fields)) step.value++;
}
const place = handleSubmit(async () => {
  placed.value = true;
});
</script>

<template>
  <p v-if="placed" class="card done" role="status">تم الطلب!</p>
  <form v-else novalidate @submit.prevent="place">
    <ol class="steps">
      <li v-for="(s, i) in STEPS" :key="s.title" :aria-current="i === step ? 'step' : undefined">{{ s.title }}</li>
    </ol>
    <template v-if="step === 0">
      <FormField id="city" v-slot="attrs" label="المدينة" :error="errors.city">
        <select v-bind="attrs" v-model="values.city" @blur="blur('city')">
          <option value="" disabled>اختر…</option>
          <option v-for="(name, value) in cities" :key="value" :value="value">{{ name }}</option>
        </select>
      </FormField>
      <FormField id="street" v-slot="attrs" label="الشارع ورقم المبنى" :error="errors.street">
        <input v-bind="attrs" v-model="values.street" autocomplete="street-address" @blur="blur('street')" />
      </FormField>
      <FormField id="phone" v-slot="attrs" label="رقم الجوال" :error="errors.phone">
        <input v-bind="attrs" v-model="values.phone" type="tel" autocomplete="tel" dir="ltr" @blur="blur('phone')" />
      </FormField>
    </template>
    <fieldset v-else-if="step === 1" class="field">
      <legend>طريقة الدفع</legend>
      <label class="check"><input v-model="values.method" type="radio" value="card" /> بطاقة</label>
      <label class="check"><input v-model="values.method" type="radio" value="cash" /> الدفع عند الاستلام</label>
    </fieldset>
    <dl v-else>
      <dt>التوصيل</dt>
      <dd>{{ cities[values.city] }}، {{ values.street }} · <span dir="ltr">{{ values.phone }}</span></dd>
      <dt>الدفع</dt>
      <dd>{{ values.method === "card" ? "بطاقة" : "الدفع عند الاستلام" }}</dd>
    </dl>
    <div class="row">
      <button type="button" class="secondary" :disabled="step === 0" @click="step--">رجوع</button>
      <button v-if="step < STEPS.length - 1" key="next" type="button" @click="next">التالي</button>
      <button v-else key="place" type="submit">أكّد الطلب</button>
    </div>
  </form>
</template>
