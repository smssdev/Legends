"use server"; // إجراء خادم: دالة تعمل على الخادم ويستدعيها نموذج

import { z } from "zod";

const schema = z.object({
  name: z.string().trim().min(1, "اكتب اسمك."),
  message: z.string().trim().min(10, "اكتب 10 أحرف على الأقل."),
});

export type ContactState = { errors?: Partial<Record<"name" | "message", string>>; done?: string };

export async function sendMessage(_previous: ContactState, form: FormData): Promise<ContactState> {
  const parsed = schema.safeParse(Object.fromEntries(form));
  if (!parsed.success) {
    const errors: ContactState["errors"] = {};
    for (const issue of parsed.error.issues) errors[issue.path[0] as "name" | "message"] ??= issue.message;
    return { errors };
  }
  // احفظ الرسالة، وأرسل بريداً… على الخادم، بأسرار لا تصل إلى المتصفح أبداً
  return { done: `شكراً يا {name}! سنرد قريباً.`.replace("{name}", parsed.data.name) };
}
