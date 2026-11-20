const wait = (ms, value, fail = false) =>
  new Promise((resolve, reject) =>
    setTimeout(() => (fail ? reject(new Error(value)) : resolve(value)), ms),
  );

const results = await Promise.allSettled([
  wait(30, "الملف الشخصي"),
  wait(10, "فشلت الطلبات", true),
  wait(20, "الرسائل"),
]);
for (const r of results) {
  console.log(r.status, r.value ?? r.reason.message);
}

// any: أول من ينجح
const fastest = await Promise.any([wait(40, "النسخة أ"), wait(15, "النسخة ب")]);
console.log("الأسرع:", fastest);

// race: أول من ينتهي، نجاحاً أو فشلاً
const timeout = (ms) => wait(ms, "انتهت المهلة بعد 50 ملي ثانية", true);
try {
  await Promise.race([wait(100, "رد بطيء"), timeout(50)]);
} catch (error) {
  console.log(error.message);
}
