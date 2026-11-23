import {getLlama, LlamaLogLevel, resolveModelFile} from "node-llama-cpp";
import {loadModel} from "./model.mjs";

// A small model made for embeddings: Qwen3 Embedding 0.6B (Apache 2.0),
// 640 MB, downloaded once.
export const EMBEDDER = "hf:Qwen/Qwen3-Embedding-0.6B-GGUF:Q8_0";

// Embeddings: each text becomes a list of numbers; similar meanings,
// nearby lists.
export async function embedder(which = "embedding") {
  const llama = await getLlama({gpu: false, logLevel: LlamaLogLevel.error});
  const model =
    which === "chat" ? await loadModel() : await llama.loadModel({modelPath: await resolveModelFile(EMBEDDER)});
  const context = await model.createEmbeddingContext({contextSize: 512});
  return async (text) => (await context.getEmbeddingFor(text)).vector;
}

export function cosine(a, b) {
  let dot = 0;
  let na = 0;
  let nb = 0;
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  return dot / Math.sqrt(na * nb);
}

// The k documents closest to a question.
export async function nearest(embed, docs, question, k = 2) {
  const vectors = docs.vectors ?? (docs.vectors = await Promise.all(docs.map(([, text]) => embed(text))));
  const q = await embed(question);
  return vectors
    .map((v, i) => ({id: docs[i][0], text: docs[i][1], score: cosine(q, v)}))
    .sort((a, b) => b.score - a.score)
    .slice(0, k);
}
