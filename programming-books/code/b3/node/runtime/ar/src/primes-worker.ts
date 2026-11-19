// يعمل في خيط خاص به، فلا يوقف العدّ الطويل حلقة الأحداث أبداً.
import { parentPort, workerData } from "node:worker_threads";
import { countPrimes } from "./primes.ts";

parentPort?.postMessage(countPrimes(workerData as number));
