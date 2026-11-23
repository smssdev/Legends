import {loadModel} from "./lib/model.mjs";

const model = await loadModel();
const LIMIT = 200;

// Refuse input that is too long before it reaches the model, by counting
// tokens.
export function check(text) {
  const tokens = model.tokenize(text).length;
  return tokens <= LIMIT ? {ok: true, tokens} : {ok: false, tokens, error: `too long: ${tokens} tokens, limit ${LIMIT}`};
}

const short = "Can I use my loyalty card in both branches?";
const long = "Please summarise this: " + "Can I use my loyalty card in both branches? ".repeat(40);
for (const text of [short, long]) {
  console.log(JSON.stringify(check(text)));
}
