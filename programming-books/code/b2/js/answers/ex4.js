const log = console.log;
setTimeout(() => log("A"));
Promise.resolve().then(() => log("B"));
log("C");
