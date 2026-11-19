// Pretend third-party widget: about 300 ms of work on a fast computer
const end = performance.now() + 300;
let n = 0;
while (performance.now() < end) n += Math.sqrt(n + 1);
window.widgetReady = n > 0;
