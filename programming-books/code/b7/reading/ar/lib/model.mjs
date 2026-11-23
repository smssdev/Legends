// نموذج الكتاب: Qwen3 4B Instruct (2507)، نموذج مفتوح برخصة Apache 2.0،
// ضغطته Unsloth إلى 4 بتات (2.5 GB). يُنزَّل مرة، أول مرة يعمل فيها مثال،
// في ~/.node-llama-cpp/models؛ ثم يعمل كل شيء على حاسوبك، دون اتصال.
import {getLlama, LlamaLogLevel, resolveModelFile} from "node-llama-cpp";

export const MODEL = "hf:unsloth/Qwen3-4B-Instruct-2507-GGUF:Q4_K_M";

export async function loadModel() {
  const llama = await getLlama({gpu: false, logLevel: LlamaLogLevel.error});
  return llama.loadModel({modelPath: await resolveModelFile(MODEL)});
}
