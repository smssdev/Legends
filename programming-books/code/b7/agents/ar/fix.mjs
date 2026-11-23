import {runAgent, runTests} from "./lib/agent.mjs";

const {answer, log} = await runAgent({root: "cafe", system: "أنت وكيل برمجة يعمل في مشروع JavaScript صغير. استخدم الأدوات: انظر في الملفات، واقرأ ما تحتاجه، وغيّر الكود، وشغّل الاختبارات حتى تنجح. لا تغيّر الاختبارات. وحين تنتهي، قل ما غيّرته في جملة واحدة.", task: "الاختبارات تفشل. اجعلها تنجح."});
console.log(log.join("\n"));
console.log(`--- the agent: ${answer}`);

// الوكيل يقول إنه انتهى؛ والاختبارات تقرر.
console.log(`--- the tests, run by us: ${runTests("cafe").split("\n")[0]}`);
