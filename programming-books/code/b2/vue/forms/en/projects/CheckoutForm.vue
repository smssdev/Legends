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
const cities = { cairo: "Cairo", alexandria: "Alexandria", giza: "Giza" };

function next() {
  if (checkFields(STEPS[step.value]!.fields)) step.value++;
}
const place = handleSubmit(async () => {
  placed.value = true;
});
</script>

<template>
  <p v-if="placed" class="card done" role="status">Order placed!</p>
  <form v-else novalidate @submit.prevent="place">
    <ol class="steps">
      <li v-for="(s, i) in STEPS" :key="s.title" :aria-current="i === step ? 'step' : undefined">{{ s.title }}</li>
    </ol>
    <template v-if="step === 0">
      <FormField id="city" v-slot="attrs" label="City" :error="errors.city">
        <select v-bind="attrs" v-model="values.city" @blur="blur('city')">
          <option value="" disabled>Choose…</option>
          <option v-for="(name, value) in cities" :key="value" :value="value">{{ name }}</option>
        </select>
      </FormField>
      <FormField id="street" v-slot="attrs" label="Street and number" :error="errors.street">
        <input v-bind="attrs" v-model="values.street" autocomplete="street-address" @blur="blur('street')" />
      </FormField>
      <FormField id="phone" v-slot="attrs" label="Mobile number" :error="errors.phone">
        <input v-bind="attrs" v-model="values.phone" type="tel" autocomplete="tel" dir="ltr" @blur="blur('phone')" />
      </FormField>
    </template>
    <fieldset v-else-if="step === 1" class="field">
      <legend>Payment method</legend>
      <label class="check"><input v-model="values.method" type="radio" value="card" /> Card</label>
      <label class="check"><input v-model="values.method" type="radio" value="cash" /> Cash on delivery</label>
    </fieldset>
    <dl v-else>
      <dt>Delivery</dt>
      <dd>{{ cities[values.city] }}, {{ values.street }} · <span dir="ltr">{{ values.phone }}</span></dd>
      <dt>Payment</dt>
      <dd>{{ values.method === "card" ? "Card" : "Cash on delivery" }}</dd>
    </dl>
    <div class="row">
      <button type="button" class="secondary" :disabled="step === 0" @click="step--">Back</button>
      <button v-if="step < STEPS.length - 1" key="next" type="button" @click="next">Next</button>
      <button v-else key="place" type="submit">Place order</button>
    </div>
  </form>
</template>
