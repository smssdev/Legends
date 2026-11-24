import Anthropic from "@anthropic-ai/sdk";

const client = new Anthropic({maxRetries: 1});
const MODELS = ["claude-opus-5-5", "claude-sonnet-5-5"];

// If the preferred model is overloaded, fall back to the next one.
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

const {model, text} = await ask("Translate 'oat milk' for the menu.");
console.log(`${text}  (answered by ${model})`);
