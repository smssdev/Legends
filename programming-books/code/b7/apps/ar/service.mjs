import http from "node:http";
import {localProvider} from "./lib/providers.mjs";
import {deadline} from "./lib/retry.mjs";

const provider = await localProvider();
const system = "أنت تجيب عن أسئلة عملاء تطبيق مقهى. أجب في جملة أو جملتين قصيرتين.";

// الخدمة تبث الرموز حين تصل، فتظهر الكلمات الأولى فوراً.
const server = http.createServer(async (request, response) => {
  const url = new URL(request.url, "http://x");
  const question = url.searchParams.get("q") ?? "";
  response.writeHead(200, {"content-type": "text/plain; charset=utf-8"});
  try {
    await provider.complete({
      system,
      prompt: question,
      signal: deadline(60_000),
      onText: (text) => response.write(text),
    });
  } catch (error) {
    response.write(`\n[error: ${error.message}]`);
  }
  response.end();
});
server.listen(8765, () => console.log("listening on 8765"));
