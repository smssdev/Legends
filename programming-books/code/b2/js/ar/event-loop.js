console.log("1 الكود المتزامن يعمل أولاً");

setTimeout(() => console.log("5 مؤقت: مهمة، بعد كل المهام الدقيقة"), 0);

Promise.resolve().then(() => console.log("3 رد وعد: مهمة دقيقة"));
queueMicrotask(() => console.log("4 مهمة دقيقة أخرى، بالترتيب"));

console.log("2 ما زال متزامناً");
