import * as z from "zod";

const schema = z.object({
  name: z.string().trim().min(1, "اكتب اسمك."),
  message: z.string().trim().min(10, "اكتب 10 أحرف على الأقل."),
});

export default defineEventHandler(async (event) => {
  // الخادم يتحقق من كل حقل: ففحوص المتصفح يستطيع أي أحد إطفاءها
  const result = schema.safeParse(await readBody(event));
  if (!result.success) {
    const errors: Record<string, string> = {};
    for (const issue of result.error.issues) errors[String(issue.path[0])] ??= issue.message;
    throw createError({ statusCode: 422, data: { errors } });
  }
  // احفظ الرسالة، وأرسل بريداً… على الخادم، بأسرار لا تصل إلى المتصفح أبداً
  return { message: "شكراً يا {name}! سنرد قريباً.".replace("{name}", result.data.name) };
});
