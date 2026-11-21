# Postmortem: bookings failed for 35 minutes (day 17)

Status: final · Severity: SEV-1 · Incident commander: Mona · Written by: Karim

## Summary
From 20:15 to 20:50, one booking request in four failed with "Server error".
1,822 of 7,289 requests failed: 22% of the month's error budget in 35 minutes.

## Impact
- Customers: 1,822 failed requests; an estimated 270 people could not book.
- Business: about 90 bookings lost, on a busy evening.
- Budget left this month: 66%; releases go on, after the actions below.

## Timeline (Cairo time)
- 20:00  Release 4.12 deployed; it opens a new database connection for each report.
- 20:15  The connection pool is exhausted; requests start to fail.
- 20:18  The fast burn-rate alert pages the on-call engineer (Karim).
- 20:21  Karim declares a SEV-1; Mona takes incident command; status page updated.
- 20:34  Rolling back 4.12 does not help: the open connections remain.
- 20:46  Reports are switched off with their feature flag; failures stop.
- 20:50  Error rate back to normal; monitoring for 30 minutes.
- 21:20  Incident closed; status page resolved.

## Root cause and why it was possible
- Reports opened a connection per request instead of using the pool.
- The load test used 10 reports a minute; real evenings have 400.
- The database had no limit per application user, so reports used every connection.

## What went well
- The alert paged three minutes after the start.
- Roles were clear; the status page was updated within 6 minutes.

## What went badly
- 13 minutes were spent on a rollback that could not work.
- The runbook did not mention the reports feature flag.

## Actions
| Action                                             | Owner  | Due    |
|----------------------------------------------------|--------|--------|
| Use the shared pool for reports                    | Karim  | day 19 |
| Connection limit per database user                 | Sara   | day 21 |
| Load test with production-like report volume       | Omar   | day 24 |
| Runbook: "database connections exhausted"          | Mona   | day 20 |
| Alert when the pool is 80% used                    | Sara   | day 21 |
