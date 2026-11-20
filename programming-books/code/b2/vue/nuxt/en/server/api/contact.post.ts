import * as z from "zod";

const schema = z.object({
  name: z.string().trim().min(1, "Please write your name."),
  message: z.string().trim().min(10, "Please write at least 10 characters."),
});

export default defineEventHandler(async (event) => {
  // The server checks every field: the browser's checks can be switched off by anyone
  const result = schema.safeParse(await readBody(event));
  if (!result.success) {
    const errors: Record<string, string> = {};
    for (const issue of result.error.issues) errors[String(issue.path[0])] ??= issue.message;
    throw createError({ statusCode: 422, data: { errors } });
  }
  // Save the message, send an email… on the server, with secrets that never reach the browser
  return { message: "Thank you, {name}! We will reply soon.".replace("{name}", result.data.name) };
});
