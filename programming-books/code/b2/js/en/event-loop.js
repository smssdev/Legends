console.log("1 synchronous code runs first");

setTimeout(() => console.log("5 a timer: a task, after all microtasks"), 0);

Promise.resolve().then(() => console.log("3 a promise callback: a microtask"));
queueMicrotask(() => console.log("4 another microtask, in order"));

console.log("2 still synchronous");
