import { createApp } from "vue";
import Status from "./Status.vue";

createApp(Status).mount("#app");
window.dispatchEvent(new Event("offline")); // for the screenshot: pretend the network just dropped
