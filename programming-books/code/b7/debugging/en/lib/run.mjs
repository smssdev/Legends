import {spawnSync} from "node:child_process";

// Runs a Node file; returns its exit code and everything it printed.
export function run(file) {
  const result = spawnSync("node", [file], {encoding: "utf8"});
  return {code: result.status, output: `${result.stdout}${result.stderr}`};
}

// The "Name: message" of the first error in an output, anywhere on its
// line
// (a log line starts with a time and a level).
export function errorLine(output) {
  const found = output.match(/\b(\w*Error): (.*)$/m);
  return found ? `${found[1]}: ${found[2]}` : "(no error)";
}
