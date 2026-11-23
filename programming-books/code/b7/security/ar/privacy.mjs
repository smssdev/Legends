import {ask} from "./lib/ask.mjs";
import {redact, restore} from "./lib/pii.mjs";

const message = "مرحباً، معكم منى حسن (mona.hassan@example.com، 0101 234 5678). بطاقتي 4111 1111 1111 1111 خُصم منها مرتين للطلب 41.";
const {safe, found} = redact(message);
console.log(`what leaves the machine:\n  ${safe}`);
const summary = await ask(`لخّص رسالة العميل هذه في جملة واحدة لفريق الدعم، مع إبقاء العلامات البديلة كما هي بالضبط.\n\n${safe}`);
console.log(`the answer that comes back:\n  ${summary}`);
console.log(`shown to the support team:\n  ${restore(summary, found)}`);
