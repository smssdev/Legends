import {execFileSync} from "node:child_process";

// كل ما غيّره الوكيل، كفرق، للمراجعة.
const before = "cafe4/src/price.mjs";
try {
  const labels = ["--label", "before", "--label", "after the agent"];
  execFileSync("diff", ["-u", ...labels, before, "cafe/src/price.mjs"], {encoding: "utf8"});
  console.log("no change");
} catch (error) {
  console.log(error.stdout);
}
