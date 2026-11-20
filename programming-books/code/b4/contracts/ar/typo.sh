# حقل مكتوب خطأ، يُمسك قبل أن يعمل الكود
$ npx tsc
src/wrong.ts(6,3): This comparison appears to be unintentional because the types '"confirmed" | "cancelled"' and '"canceled"' have no overlap.
src/wrong.ts(6,35): Property 'start_at' does not exist on type '{ id: number; staff_id: number; starts_at: string; ends_at: string; email: string; status: "confirmed" | "cancelled"; }'. Did you mean 'starts_at'?
