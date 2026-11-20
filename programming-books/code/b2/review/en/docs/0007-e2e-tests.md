# 7. Use Playwright for end-to-end tests

Date: 2026-03-04
Status: Accepted

## Context

Bugs reached users twice last month through the checkout, which no test covers
end to end. We need tests that click through the real app in a real browser,
and run on every pull request in under five minutes.

## Options

- Playwright: 64 points in our matrix (decide.ts)
- Cypress: 62 points; easier to learn, and wins if that counts double
- Manual testing before each release: 38 points

## Decision

We use Playwright, because it fits our tools best (TypeScript, several
browsers, runs in parallel) and is free. The vote was close: two people
on the team will pair with the others on the first tests.

## Consequences

- Good: the checkout is tested on every pull request, in three browsers.
- Bad: one more tool to learn; the tests need a running app in CI.
- We will look again if the suite takes more than five minutes.
