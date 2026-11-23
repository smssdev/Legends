import {execFileSync} from "node:child_process";

// Runs node's test runner on one file, with the TAP reporter.
export function runTests(file) {
  try {
    const output = execFileSync("node", ["--test", "--test-reporter=tap", file], {
      encoding: "utf8",
    });
    return {ok: true, summary: summarize(output), output};
  } catch (error) {
    const output = `${error.stdout}${error.stderr}`;
    return {ok: false, summary: summarize(output), output};
  }
}

function summarize(output) {
  const count = (name) => output.match(new RegExp(`^# ${name} (\\d+)`, "m"))?.[1];
  return `${count("pass")} passed, ${count("fail")} failed`;
}

// Each failing test, with the first line of its error, expected and
// actual,
// and the error of a test file that does not load.
export function failures(output) {
  const lines = output.split("\n");
  const kept = [];
  lines.forEach((line, i) => {
    if (/^\s*not ok/.test(line)) {
      kept.push(line.trim());
    }
    // A file that cannot even load reports its error as a comment.
    if (/^# \w*Error: /.test(line)) {
      kept.push(`  ${line.slice(2)}`);
    }
    const field = line.match(/^\s*(error|expected|actual): (.*)$/);
    if (field) {
      const value = field[2] === "|-" ? lines[i + 1].trim() : field[2];
      kept.push(`  ${field[1]}: ${value}`);
    }
  });
  return kept.slice(0, 16).join("\n");
}

// True when the test file fails before it tests anything.
export function broken(output) {
  return /is not a function|SyntaxError|Cannot find|ReferenceError|not ok \d+ - \S+\.test\.mjs/.test(
    output,
  );
}
