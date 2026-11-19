import { config } from "./config.ts";
import { createApp } from "./app.ts";
import { log } from "./log.ts";

const server = createApp();
server.requestTimeout = 30_000;
server.listen(config.PORT, () => {
  log("info", `Listening on http://localhost:${config.PORT}`);
});

function shutdown(signal: string): void {
  log("info", `${signal}: no new connections, finishing requests in progress`);
  server.close(() => {
    // stop accepting, let running requests finish
    log("info", "all requests finished, bye");
    process.exit(0);
  });
  // close kept-alive connections that are doing nothing
  server.closeIdleConnections();
  setTimeout(() => {
    log("error", "requests still running after 10 s, stopping anyway");
    process.exit(1);
  }, 10_000).unref(); // never hang forever
}
process.once("SIGTERM", () => shutdown("SIGTERM"));
process.once("SIGINT", () => shutdown("SIGINT"));

// the process is in an unknown state: log and stop; the supervisor restarts it
process.on("unhandledRejection", (error) => {
  log("error", `unexpected error, stopping: ${String(error)}`);
  process.exit(1);
});
