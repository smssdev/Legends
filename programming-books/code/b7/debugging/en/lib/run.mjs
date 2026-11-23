import {spawnSync} from "node:child_process";

// Runs a Node file; returns its exit code and everything it printed.
export function run(file) {
  const result = spawnSync("node", [file], {encoding: "utf8"});
  return {code: result.status, output: `${result.stdout}${result.stderr}`};
}

// The "Name: message" line of the first error in an output.
export function errorLine(output) {
  return output.match(/^\w*Error: .*$/m)?.[0] ?? "(no error)";
}
