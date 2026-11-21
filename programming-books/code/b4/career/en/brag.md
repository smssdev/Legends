# Brag document: Sara Hassan, 2026

## Impact (what changed because of my work)
- Moved background jobs to PostgreSQL (ADR 4): lost jobs went from 2 incidents
  to 0 in six months; Redis now serves only the cache.
- Led the postmortem of the day-17 outage; 5 of 5 actions done within 3 weeks.
- Cut the booking page's P85 load time from 2.4 s to 1.1 s.

## Decisions I drove
- ADR 4 (jobs in PostgreSQL): wrote the design doc, ran the review, approver Mona.
- Fitness function for module boundaries, now in every pipeline run.

## People
- Mentored Omar from his first PR to owning the reports module.
- Interviewed 9 candidates; wrote the system design rubric now used by the team.

## Learned
- OpenTelemetry in production; estimating with ranges and forecasts.

## Next
- Lead the deposits project end to end, including the plan with product.
