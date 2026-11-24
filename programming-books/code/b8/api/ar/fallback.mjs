import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({maxRetries: 1});
const MODELS = ["claude-opus-5-5", "claude-sonnet-5-5"];

// إن كان النموذج المفضل مثقلاً، فانتقل إلى التالي.
async function ask(content) {
  for (const model of MODELS) {
    try {
      const r = await client.messages.create({model, max_tokens: 200, messages: [{role: "user", content}]});
      return {model, text: r.content[0].text};
    } catch (error) {
      if (!(error instanceof Anthropic.InternalServerError) || model === MODELS.at(-1)) throw error;
      console.log(`  ${model}: ${error.status} ${error.error?.error?.type}`);
    }
  }
}

const {model, text} = await ask("ترجم «oat milk» للقائمة.");
console.log(`${text}  (أجاب ${model})`);
