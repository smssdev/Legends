import {DOCS} from "./data.mjs";
import {assistant} from "./lib/assistant.mjs";

const answer = await assistant(DOCS);
for (const question of ["How do I run the tests?", "Can I deploy on a Friday?", "How many vacation days do we get?"]) {
  const {text, sources, ok, problems} = await answer(question, "mona@example.com");
  console.log(`> ${question}\n  ${text}\n  sources: ${sources.map((s) => s.id).join(", ")}; checks: ${ok ? "ok" : problems.join("; ")}`);
}
