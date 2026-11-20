"use server";

import { revalidatePath } from "next/cache";
import { requireUser } from "@/lib/auth";
import { cancelBooking } from "@/lib/owner";

// الإجراء يفحص من جديد: هو نقطة نهاية عامة بذاته
export async function cancelAction(form: FormData) {
  const user = await requireUser(["owner"]);
  await cancelBooking(user, Number(form.get("id")));
  revalidatePath("/owner");
}
