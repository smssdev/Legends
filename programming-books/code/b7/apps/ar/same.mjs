import {hostedProvider, localProvider} from "./lib/providers.mjs";
import {fakeHostedApi} from "./lib/fake.mjs";
import {withRetry} from "./lib/retry.mjs";

const {server, port} = await fakeHostedApi();
const providers = [
  await localProvider(),
  hostedProvider({url: `http://localhost:${port}`, key: "test-key"}),
];

// The application code is the same for both.
for (const provider of providers) {
  const answer = await withRetry(
    () => provider.complete({system: "أنت تجيب عن أسئلة عملاء تطبيق مقهى. أجب في جملة أو جملتين قصيرتين.", prompt: "هل أستطيع استخدام بطاقة الولاء في الفرعين؟"}),
    {log: (line) => console.log(`[${provider.name}] ${line}`)},
  );
  console.log(`[${provider.name}] ${answer.trim()}`);
}
server.close();
