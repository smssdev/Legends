const wait = (ms, value, fail = false) =>
  new Promise((resolve, reject) =>
    setTimeout(() => (fail ? reject(new Error(value)) : resolve(value)), ms),
  );

const results = await Promise.allSettled([
  wait(30, "profile"),
  wait(10, "orders failed", true),
  wait(20, "messages"),
]);
for (const r of results) {
  console.log(r.status, r.value ?? r.reason.message);
}

// any: the first one to succeed
const fastest = await Promise.any([wait(40, "mirror A"), wait(15, "mirror B")]);
console.log("Fastest:", fastest);

// race: the first one to finish, success or failure
const timeout = (ms) => wait(ms, "Timed out after 50 ms", true);
try {
  await Promise.race([wait(100, "slow answer"), timeout(50)]);
} catch (error) {
  console.log(error.message);
}
