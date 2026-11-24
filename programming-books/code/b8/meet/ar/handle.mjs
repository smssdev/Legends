import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic();

// ماذا تقول للمطور عن كل نوع من الأخطاء.
export function advice(error) {
  if (error instanceof Anthropic.APIConnectionError) return "لا اتصال: افحص الشبكة وANTHROPIC_BASE_URL.";
  if (error instanceof Anthropic.AuthenticationError) return "افحص ANTHROPIC_API_KEY: غائب، أو فيه خطأ، أو أُلغي.";
  if (error instanceof Anthropic.NotFoundError) return "قارن اسم النموذج بـ GET /v1/models.";
  if (error instanceof Anthropic.RateLimitError) return "طلبات كثيرة: انتظر المدة التي تقولها retry-after، ثم أعد المحاولة.";
  if (error instanceof Anthropic.BadRequestError) return "أصلح الطلب: اقرأ الرسالة، فهي تسمّي الحقل.";
  if (error instanceof Anthropic.InternalServerError) return "مشكلة في جهة الواجهة البرمجية: أعد المحاولة مع تباعد.";
  throw error;
}

const cases = [
  ["claude-opus-55", {}],
  ["claude-opus-5-5", {apiKey: "wrong-key"}],
  ["claude-opus-5-5", {baseURL: "http://127.0.0.1:9"}],
];
for (const [model, options] of cases) {
  const c = new Anthropic({maxRetries: 0, ...options});
  try {
    await c.messages.create({model, max_tokens: 100, messages: [{role: "user", content: "Hi"}]});
  } catch (error) {
    console.log(`${error.constructor.name.padEnd(20)} ${advice(error)}`);
  }
}
