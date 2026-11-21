# 2. Background jobs in a Redis queue

Status: Superseded by 0004
Date: 2026-03-10 · Deciders: Karim, Omar

## Context
Reminders and receipts must not slow down the booking request.

## Decision
Use a Redis-based queue for every background job.

## Options considered
- Redis queue: fast, popular; one more service to run.
- PostgreSQL queue: no new service; we were unsure it would be fast enough.

## Consequences
One more service to back up, upgrade and watch.
