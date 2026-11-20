// عميل WebSocket الخاص بـ Node (الواجهة نفسها التي في المتصفحات)
const [url = "ws://localhost:3000/live", ms = "2000"] = process.argv.slice(2);
const socket = new WebSocket(url);
socket.addEventListener("open", () => socket.send(JSON.stringify({ watch: 1001 })));
socket.addEventListener("message", (event) => console.log("ws:", event.data));
setTimeout(() => socket.close(), Number(ms));
