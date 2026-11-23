// The book's model: Qwen3 4B Instruct (2507), an open model under the
// Apache 2.0 license, quantized to 4 bits by Unsloth (2.5 GB). It is
// downloaded once, the first time an example runs, into
// ~/.node-llama-cpp/models; then everything runs on your computer, offline.
import {getLlama, LlamaLogLevel, resolveModelFile} from "node-llama-cpp";

export const MODEL = "hf:unsloth/Qwen3-4B-Instruct-2507-GGUF:Q4_K_M";

export async function loadModel() {
  const llama = await getLlama({gpu: false, logLevel: LlamaLogLevel.error});
  return llama.loadModel({modelPath: await resolveModelFile(MODEL)});
}
