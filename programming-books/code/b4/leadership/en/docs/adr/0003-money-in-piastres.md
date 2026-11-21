# 3. Money as whole piastres

Status: Accepted
Date: 2026-03-18 · Deciders: Sara, Mona

## Context
Deposits, refunds and reports add up amounts; floats give 0.30000000000000004.

## Decision
Store and compute money as integers (piastres), formatted only for display.

## Options considered
- Integers: exact, simple. Decimals: exact, slower, and each language differs.

## Consequences
Every amount in the API is an integer; the front end formats it.
