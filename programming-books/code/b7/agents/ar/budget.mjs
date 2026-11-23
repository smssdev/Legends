import {runAgent, runTests} from "./lib/agent.mjs";

// المهمة نفسها بميزانية ثلاثة استدعاءات للأدوات.
const {answer, log} = await runAgent({root: "cafe3", system: "أنت وكيل برمجة يعمل في مشروع JavaScript صغير. استخدم الأدوات: انظر في الملفات، واقرأ ما تحتاجه، وغيّر الكود، وشغّل الاختبارات حتى تنجح. لا تغيّر الاختبارات. وحين تنتهي، قل ما غيّرته في جملة واحدة.", task: "الاختبارات تفشل. اجعلها تنجح.", maxSteps: 3});
console.log(log.join("\n"));
console.log(`--- the agent: ${answer}`);
console.log(`--- the tests, run by us: ${runTests("cafe3").split("\n")[0]}`);
