# 4. Background jobs in PostgreSQL

Status: Accepted
Date: 2026-09-02 · Deciders: Karim, Omar, Sara

## Context
The Redis queue lost jobs twice when Redis restarted (incidents 14 and 19).
We run 9,000 jobs a day; load tests show PostgreSQL handles 200 a second.
Supersedes 0002.

## Decision
Run background jobs from a PostgreSQL table, with SKIP LOCKED.

## Options considered
See the decision matrix in the design doc: PostgreSQL queue 4.55,
Redis queue 3.45, cloud queue 3.15.

## Consequences
Jobs are created in the same transaction as the booking: none are lost.
Redis remains for caching only. Revisit above 100 jobs a second.
