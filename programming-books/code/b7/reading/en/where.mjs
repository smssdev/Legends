import {execSync} from "node:child_process";
import {ask, readProject} from "./lib/ask.mjs";

console.log(await ask(`In this project, where is it decided that VIP customers pay less, and by how much? Name the file and quote the line.\n\n${readProject("legacy")}`));

// An answer about where something is can be checked in a second: search
// for it.
console.log("--- grep -rn VIP legacy/lib");
console.log(execSync("grep -rn VIP legacy/lib", {encoding: "utf8"}).trim());
