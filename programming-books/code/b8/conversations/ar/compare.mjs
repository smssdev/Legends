import Anthropic from "@anthropic-ai/sdk";
import {block, text} from "./lib/files.mjs";

const client = new Anthropic();

const question = "ما الذي تغيّر بين العقد الأول والثاني؟";

// مستندان في رسالة واحدة، لكل منهما عنوان يُشار إليه به.
const response = await client.messages.create({
  model: "claude-opus-5-5",
  max_tokens: 1000,
  messages: [{role: "user", content: [
    block("files/contract.pdf", "Contract, first version"),
    block("files/contract-v2.pdf", "Contract, second version"),
    {type: "text", text: question},
  ]}],
});
console.log(text(response));
