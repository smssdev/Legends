import { computed, nextTick, reactive, ref, watch } from "vue";
import type * as z from "zod";

type Errors<K extends PropertyKey> = Partial<Record<K, string>>;

// composable صغير للنماذج: القيم والأخطاء والحقول الملموسة والإرسال، حول مخطط واحد
export function useForm<S extends z.ZodObject>(schema: S, initial: z.input<S>) {
  type Key = keyof z.input<S> & string;
  const values = reactive({ ...initial }) as z.input<S>;
  const allErrors = ref<Errors<Key>>({});
  const touched = reactive(new Set<string>());
  const submitted = ref(false);
  const submitting = ref(false);

  function check(): z.output<S> | undefined {
    const result = schema.safeParse(values);
    const next: Errors<Key> = {};
    for (const issue of result.success ? [] : result.error.issues) next[issue.path[0] as Key] ??= issue.message;
    allErrors.value = next;
    return result.success ? result.data : undefined;
  }
  watch(values, check, { deep: true });

  // اعرض خطأ الحقل فقط بعد أن يغادره المستخدم مرة، أو يحاول الإرسال
  const errors = computed(() => {
    const shown: Errors<Key> = {};
    for (const [key, message] of Object.entries(allErrors.value) as [Key, string][]) {
      if (submitted.value || touched.has(key)) shown[key] = message;
    }
    return shown;
  });

  async function focusFirstError() {
    await nextTick();
    document.querySelector<HTMLElement>("[aria-invalid='true']")?.focus();
  }

  /** Checks some fields only (one step of a longer form), and shows their errors. */
  function checkFields(fields: readonly Key[]) {
    fields.forEach((f) => touched.add(f));
    check();
    const ok = fields.every((f) => !allErrors.value[f]);
    if (!ok) void focusFirstError();
    return ok;
  }

  function handleSubmit(send: (data: z.output<S>) => Promise<Errors<Key> | void>) {
    return async () => {
      submitted.value = true;
      const data = check();
      if (!data) return focusFirstError();
      submitting.value = true;
      try {
        const fromServer = await send(data);
        // الأخطاء التي لا يعرفها إلا الخادم تذهب تحت الحقل الصحيح، كغيرها
        if (fromServer) {
          allErrors.value = fromServer;
          void focusFirstError();
        }
      } finally {
        submitting.value = false;
      }
    };
  }

  return { values, errors, submitting, checkFields, handleSubmit, blur: (field: Key) => touched.add(field) };
}
