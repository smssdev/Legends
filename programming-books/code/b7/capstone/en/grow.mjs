import {DOCS} from "./data.mjs";
import {assistant} from "./lib/assistant.mjs";

// A new document turns a refusal into an answer.
const question = "How many vacation days do we get?";
for (const docs of [DOCS, [...DOCS, ["vacation", "Every developer gets 21 days of paid vacation a year, booked in the team calendar."]]]) {
  const {text, cited} = await (await assistant(docs))(question);
  console.log(`${docs.length} documents: ${text}  (${cited.join(", ") || "no citation"})`);
}
