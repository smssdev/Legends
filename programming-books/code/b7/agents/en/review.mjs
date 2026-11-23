import {execFileSync} from "node:child_process";

// Everything the agent changed, as a diff, for review.
const before = "cafe4/src/price.mjs";
try {
  execFileSync("diff", ["-u", before, "cafe/src/price.mjs"], {encoding: "utf8"});
  console.log("no change");
} catch (error) {
  console.log(error.stdout);
}
