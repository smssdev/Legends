"use server";

import { revalidatePath } from "next/cache";
import { requireUser } from "@/lib/auth";
import { cancelBooking } from "@/lib/owner";

// the action checks again: it is a public endpoint of its own
export async function cancelAction(form: FormData) {
  const user = await requireUser(["owner"]);
  await cancelBooking(user, Number(form.get("id")));
  revalidatePath("/owner");
}
