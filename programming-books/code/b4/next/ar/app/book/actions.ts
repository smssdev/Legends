"use server";

import { revalidatePath } from "next/cache";
import { redirect } from "next/navigation";
import { z } from "zod";
import { book } from "@/lib/bookings";

const Input = z.object({
  staffId: z.coerce.number().int().positive(),
  startsAt: z.iso.datetime(),
  email: z.email().max(254),
});

export type BookState = { error?: string; email?: string };

// إجراء خادم: يناديه النموذج، على الخادم، بفحوص أي واجهة برمجية
export async function bookAction(
  _previous: BookState,
  form: FormData,
): Promise<BookState> {
  const parsed = Input.safeParse(Object.fromEntries(form));
  const email = String(form.get("email") ?? "");
  if (!parsed.success)
    return { error: "اختر وقتاً واكتب بريداً صحيحاً من فضلك.", email };
  const result = await book(parsed.data);
  // تغيرت الأوقات المتاحة في الحالين: ارسم الصفحة من جديد مع الإجابة
  revalidatePath(`/book/${parsed.data.staffId}`);
  if (!result.ok)
    return { error: "عذراً، حُجز هذا الوقت للتو. اختر وقتاً آخر من فضلك.", email };
  redirect(`/booking/${result.id}`);
}
