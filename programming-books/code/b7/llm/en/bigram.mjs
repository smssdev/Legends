// No neural network: count which word follows which, then pick the next
// word from those counts.
const corpus = [
  "the café opens at eight .",
  "the café sells coffee and tea .",
  "the café sells cake .",
  "customers drink coffee in the morning .",
  "customers drink tea at night .",
  "the barista makes coffee .",
  "the barista makes tea and cake .",
];
const words = corpus.join(" ").split(" ");

const next = new Map();
for (let i = 0; i < words.length - 1; i++) {
  const followers = next.get(words[i]) ?? new Map();
  followers.set(words[i + 1], (followers.get(words[i + 1]) ?? 0) + 1);
  next.set(words[i], followers);
}

function show(word) {
  const followers = [...next.get(word)].sort((a, b) => b[1] - a[1]);
  const total = followers.reduce((sum, [, count]) => sum + count, 0);
  return followers
    .map(([w, count]) => `${w} ${Math.round((100 * count) / total)}%`)
    .join(", ");
}

// A small seeded random generator (mulberry32), so you get the book's
// sentences.
let seed = 2026;
function random() {
  seed = (seed + 0x6d2b79f5) | 0;
  let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
  t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
}

function pick(word) {
  const followers = [...next.get(word)];
  const total = followers.reduce((sum, [, count]) => sum + count, 0);
  let left = random() * total;
  for (const [w, count] of followers) {
    left -= count;
    if (left < 0) {
      return w;
    }
  }
  return followers.at(-1)[0];
}

console.log(`after "the": ${show("the")}`);
for (let line = 0; line < 3; line++) {
  let word = "the";
  const sentence = [word];
  while (word !== "." && sentence.length < 12) {
    word = pick(word);
    sentence.push(word);
  }
  console.log(sentence.join(" "));
}
