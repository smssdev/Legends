import {REVIEWS} from "./data/reviews.mjs";
import {cachedAsk, stats} from "./lib/cache.mjs";

for (const [text] of REVIEWS.slice(0, 4)) {
  await cachedAsk(`صنّف هذا التقييم لمقهى بموضوعه (price أو taste أو service أو app) وشعوره (pos أو neg).\n\n${text}`);
}
console.log(`asked the model ${stats.asked} times, answered from the cache ${stats.cached} times`);
