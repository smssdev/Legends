import { readFileSync } from "node:fs";

// a client speaking the Pusher protocol, which Reverb uses; in a browser, Laravel Echo does this
// the app key from .env: it says which application we connect to (it is not a secret)
const key = /^REVERB_APP_KEY=(.*)$/m.exec(readFileSync("shop/.env", "utf8"))?.[1];
const socket = new WebSocket(`ws://localhost:8080/app/${key}?protocol=7`);

socket.addEventListener("message", (event) => {
  const message = JSON.parse(event.data);
  if (message.event === "pusher:connection_established") {
    // once connected, ask for the channel
    const subscribe = { event: "pusher:subscribe", data: { channel: "orders.1001" } };
    socket.send(JSON.stringify(subscribe));
  } else {
    console.log(message.event, message.channel ?? "", message.data ?? "");
  }
});
setTimeout(() => socket.close(), Number(process.argv[2] ?? 3000));
