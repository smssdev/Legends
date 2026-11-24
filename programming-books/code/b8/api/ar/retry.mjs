import Anthropic from "@anthropic-ai/sdk";

// تعيد الحزمة الطلب المحدود بنفسها؛ وغلاف حول fetch يعدّ المحاولات.
const statuses = [];
const counting = async (url, init) => {
  const response = await fetch(url, init);
  statuses.push(response.status);
  return response;
};

for (const [question, maxRetries] of [["اقترح اسماً لمشروبنا المثلج الجديد.", 2], ["اسرد ثلاث طرق لتقصير الطابور وقت الغداء.", 0]]) {
  statuses.length = 0;
  const client = new Anthropic({fetch: counting, maxRetries});
  try {
    const r = await client.messages.create({
      model: "claude-opus-5-5",
      max_tokens: 200,
      messages: [{role: "user", content: question}],
    });
    console.log(r.content[0].text);
  } catch (error) {
    console.log(`${error.constructor.name}: ${error.status}`);
  }
  console.log(`  maxRetries ${maxRetries}, المحاولات: ${statuses.join(" → ")}`);
}
