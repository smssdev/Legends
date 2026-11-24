import {chat, loadProject, text} from "./lib/project.mjs";

const support = loadProject("support");

// Three chats in the same project: the knowledge is written to the cache
// once, then read.
for (const [i, question] of ["How much is the rose latte?", "Does anything contain nuts?", "Is there parking at the Zamalek branch?"].entries()) {
  const response = await chat(support, question);
  const u = response.usage;
  console.log(`> ${question}\n${text(response)}`);
  console.log(`  (chat ${i + 1}: ${u.cache_creation_input_tokens} written to cache, ` +
    `${u.cache_read_input_tokens} read from cache, ${u.input_tokens} new)`);
}
