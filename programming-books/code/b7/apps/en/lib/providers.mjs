import {LlamaChatSession} from "node-llama-cpp";
import {loadModel} from "./model.mjs";

// Every provider has the same shape: a prompt in, text out, optionally
// streamed.
// complete({system, prompt, grammar, onText, signal}) -> Promise<string>

// The book's model, on this computer.
export async function localProvider() {
  const model = await loadModel();
  const context = await model.createContext({contextSize: 4096});
  return {
    name: "local",
    model,
    async complete({system, prompt, grammar, onText, signal}) {
      const session = new LlamaChatSession({
        contextSequence: context.getSequence(),
        autoDisposeSequence: true,
        systemPrompt: system,
      });
      try {
        return await session.prompt(prompt, {
          temperature: 0,
          maxTokens: 300,
          grammar,
          signal,
          onTextChunk: onText,
        });
      } finally {
        session.dispose();
      }
    },
  };
}

// A hosted model behind an OpenAI-style HTTP API: the URL and key come
// from the environment.
export function hostedProvider({url = process.env.AI_URL, key = process.env.AI_KEY, model = "any"} = {}) {
  return {
    name: "hosted",
    async complete({system, prompt, signal}) {
      const response = await fetch(`${url}/v1/chat/completions`, {
        method: "POST",
        headers: {"content-type": "application/json", authorization: `Bearer ${key}`},
        body: JSON.stringify({
          model,
          temperature: 0,
          messages: [
            {role: "system", content: system},
            {role: "user", content: prompt},
          ],
        }),
        signal,
      });
      if (!response.ok) {
        const error = new Error(`HTTP ${response.status}`);
        error.status = response.status;
        throw error;
      }
      return (await response.json()).choices[0].message.content;
    },
  };
}
