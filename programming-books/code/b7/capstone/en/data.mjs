export const DOCS = [
 [
  "conventions",
  "We use ES modules and named exports. Tests live next to the code in .test.mjs files and run with node --test."
 ],
 [
  "reviews",
  "Every pull request needs one approval and passing tests. Never merge your own pull request."
 ],
 [
  "deploy",
  "We deploy from the main branch on Tuesdays and Thursdays at 11:00, with npm run deploy. We never deploy on Fridays."
 ],
 [
  "oncall",
  "This week the on-call developer is Omar. Call him only for production incidents."
 ],
 [
  "secrets",
  "API keys live in the team vault. Never put a key in the code, in a commit or in a chat."
 ],
 [
  "commits",
  "Commit messages follow Conventional Commits: type(scope): subject, at most 72 characters."
 ]
];

export const EVAL = [
 [
  "How do I run the tests?",
  "conventions",
  "node --test"
 ],
 [
  "Can I deploy on a Friday?",
  "deploy",
  "no"
 ],
 [
  "On which days do we deploy?",
  "deploy",
  "tuesday"
 ],
 [
  "May I merge my own pull request?",
  "reviews",
  "no"
 ],
 [
  "Who is on call this week?",
  "oncall",
  "omar"
 ],
 [
  "Where should I keep an API key?",
  "secrets",
  "vault"
 ],
 [
  "What format do commit messages use?",
  "commits",
  "conventional"
 ],
 [
  "How many vacation days do we get?",
  null,
  null
 ]
];

// Other words a right answer may use, by document.
export const MORE_WORDS = {"reviews": ["never"], "commits": ["type(scope)"]};
