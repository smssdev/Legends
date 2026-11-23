import {REVIEWS} from "./data/reviews.mjs";
import {cachedAsk, stats} from "./lib/cache.mjs";

for (const [text] of REVIEWS.slice(0, 4)) {
  await cachedAsk(`Label this café review with its topic (price, taste, service or app) and its sentiment (pos or neg).\n\n${text}`);
}
console.log(`asked the model ${stats.asked} times, answered from the cache ${stats.cached} times`);
