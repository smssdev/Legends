# Launch checklist: Bit Booking for every salon

## Product
- [x] Sign-up to first booking in under 5 minutes (measured with 5 salon owners)
- [x] Free plan limit explained before it is reached, with the upgrade path
- [x] Privacy policy and terms published; data export and deletion work

## Safety
- [x] Row-level security on every salon table; test fails if a policy is missing
- [x] Billing webhooks signed and idempotent; replay test passes
- [x] Backups restored into a fresh database this week, and timed

## Delivery
- [x] Pipeline: tests, contract check, image by commit, staged rollout
- [x] Infrastructure in code; staging rebuilt from nothing this week
- [x] Feature flag for sign-ups: can close sign-ups in one click

## Operations
- [x] SLOs: bookings 99.9% available, 99% under 400 ms; burn-rate alerts
- [x] On-call rota for launch week; runbooks for the five likeliest failures
- [x] Status page and support address ready

## After launch
- [ ] Day 1, 7, 30: activation, conversion to Pro, error budget, top complaints
