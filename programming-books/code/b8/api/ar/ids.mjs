import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({maxRetries: 0});

// لكل رد ولكل خطأ معرّف طلب: سجّله.
const {data, response} = await client.messages
  .create({model: "claude-opus-5-5", max_tokens: 200, messages: [{role: "user", content: "صِف اللاتيه بالورد للوحة القائمة في جملتين."}]})
  .withResponse();
console.log(`ok     ${data.id}  request-id: ${response.headers.get("request-id")}`);
try {
  await client.messages.create({model: "claude-opus-5-5", max_tokens: 200,
    messages: [{role: "user", content: "اسرد ثلاث طرق لتقصير الطابور وقت الغداء."}]});
} catch (error) {
  console.log(`${error.status}    request-id: ${error.requestID}`);
}
