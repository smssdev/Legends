// The rules of a Conventional Commits message, checked one by one.
export function lintCommit(message) {
  const [subject = "", blank, ...body] = message.split("\n");
  const problems = [];
  if (!/^(feat|fix|docs|refactor|test|chore|perf|build|ci|style)(\([\w-]+\))?!?: \S/.test(subject)) {
    problems.push("subject is not type(scope): text");
  }
  if (subject.length > 72) {
    problems.push(`subject is ${subject.length} characters, more than 72`);
  }
  if (subject.endsWith(".")) {
    problems.push("subject ends with a full stop");
  }
  if (body.length > 0 && blank !== "") {
    problems.push("no blank line after the subject");
  }
  if (/```|\*\*/.test(message)) {
    problems.push("markdown in the message");
  }
  return problems;
}
