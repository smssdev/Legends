import {getLlama, LlamaLogLevel, resolveModelFile} from "node-llama-cpp";

const EMBEDDER = "hf:Qwen/Qwen3-Embedding-0.6B-GGUF:Q8_0";

export async function embedder() {
  const llama = await getLlama({gpu: false, logLevel: LlamaLogLevel.error});
  const model = await llama.loadModel({modelPath: await resolveModelFile(EMBEDDER)});
  const context = await model.createEmbeddingContext({contextSize: 512});
  return async (text) => (await context.getEmbeddingFor(text)).vector;
}

function cosine(a, b) {
  let [dot, na, nb] = [0, 0, 0];
  for (let i = 0; i < a.length; i++) {
    dot += a[i] * b[i];
    na += a[i] * a[i];
    nb += b[i] * b[i];
  }
  return dot / Math.sqrt(na * nb);
}

// An index over documents: embedded once, searched by meaning.
export async function index(docs) {
  const embed = await embedder();
  const vectors = await Promise.all(docs.map(([, text]) => embed(text)));
  return async (question, k = 2) => {
    const q = await embed(question);
    return vectors
      .map((v, i) => ({id: docs[i][0], text: docs[i][1], score: cosine(q, v)}))
      .sort((a, b) => b.score - a.score)
      .slice(0, k);
  };
}
