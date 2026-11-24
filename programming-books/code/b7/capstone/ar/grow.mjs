import {DOCS} from "./data.mjs";
import {assistant} from "./lib/assistant.mjs";

// مستند جديد يحوّل رفضاً إلى جواب.
const question = "كم يوم إجازة لدينا؟";
for (const docs of [DOCS, [...DOCS, ["vacation", "لكل مطور 21 يوم إجازة مدفوعة في السنة، تُحجز في تقويم الفريق."]]]) {
  const {text, cited} = await (await assistant(docs))(question);
  console.log(`${docs.length} documents: ${text}  (${cited.join(", ") || "no citation"})`);
}
