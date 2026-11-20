import { readFileSync } from "node:fs";

// عميل يتكلم بروتوكول Pusher الذي يستخدمه Reverb؛ وفي المتصفح يفعل Laravel Echo هذا
// مفتاح التطبيق من .env: يقول بأي تطبيق نتصل (وليس سراً)
const key = /^REVERB_APP_KEY=(.*)$/m.exec(readFileSync("shop/.env", "utf8"))?.[1];
const socket = new WebSocket(`ws://localhost:8080/app/${key}?protocol=7`);

socket.addEventListener("message", (event) => {
  const message = JSON.parse(event.data);
  if (message.event === "pusher:connection_established") {
    // بعد الاتصال، اطلب القناة
    const subscribe = { event: "pusher:subscribe", data: { channel: "orders.1001" } };
    socket.send(JSON.stringify(subscribe));
  } else {
    console.log(message.event, message.channel ?? "", message.data ?? "");
  }
});
setTimeout(() => socket.close(), Number(process.argv[2] ?? 3000));
