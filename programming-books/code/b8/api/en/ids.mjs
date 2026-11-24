import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({maxRetries: 0});

// Every response and every error has a request id: log it.
const {data, response} = await client.messages
  .create({model: "claude-opus-5-5", max_tokens: 200, messages: [{role: "user", content: "Describe our rose latte for the menu board in two sentences."}]})
  .withResponse();
console.log(`ok     ${data.id}  request-id: ${response.headers.get("request-id")}`);
try {
  await client.messages.create({model: "claude-opus-5-5", max_tokens: 200,
    messages: [{role: "user", content: "List three ways to shorten the queue at lunch."}]});
} catch (error) {
  console.log(`${error.status}    request-id: ${error.requestID}`);
}
