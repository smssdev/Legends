import { config } from "./config.ts";
import { createApp } from "./app.ts";
import { log } from "./log.ts";

const server = createApp();
server.requestTimeout = 30_000;
server.listen(config.PORT, () => {
  log("info", `يستمع على http://localhost:${config.PORT}`);
});

function shutdown(signal: string): void {
  log("info", `${signal}: لا اتصالات جديدة، وننهي الطلبات الجارية`);
  server.close(() => {
    // توقف عن قبول الاتصالات، ودع الطلبات الجارية تنتهي
    log("info", "انتهت كل الطلبات، إلى اللقاء");
    process.exit(0);
  });
  // أغلق الاتصالات المفتوحة التي لا تفعل شيئاً
  server.closeIdleConnections();
  setTimeout(() => {
    log("error", "ما زالت طلبات تعمل بعد 10 ثوانٍ، نتوقف على أي حال");
    process.exit(1);
  }, 10_000).unref(); // لا تعلق إلى الأبد
}
process.once("SIGTERM", () => shutdown("SIGTERM"));
process.once("SIGINT", () => shutdown("SIGINT"));

// العملية في حال مجهولة: سجّل وتوقف، والمشرف يعيد تشغيلها
process.on("unhandledRejection", (error) => {
  log("error", `خطأ غير متوقع، نتوقف: ${String(error)}`);
  process.exit(1);
});
