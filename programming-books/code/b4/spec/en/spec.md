# Bit Booking: one-page spec

**Status:** draft for review · **Owner:** product + tech lead · **Updated:** 2026-11-20

## Problem
Small businesses (salons, clinics, tutors) take bookings by phone and chat.
Owners lose about an hour a day answering, and 1 booking in 8 is a no-show.

## Users
- **Owner:** sets services, staff and opening hours; sees the day.
- **Staff:** sees their own day; marks a booking done or no-show.
- **Customer:** books, moves or cancels, without an account.

## Stories (MVP)
- **US-1** As a customer, I see free slots for a service and a staff member.
  - Given Mona works 10:00-14:00 and has a booking 10:00-10:30,
    when I ask for a 30-minute haircut, then 10:00 is not offered and 10:30 is.
- **US-2** As a customer, I book a slot.
  - Given two customers ask for the same slot at the same time,
    then exactly one booking is made and the other sees "taken".
- **US-3** As a customer, I get a confirmation email, and a reminder 24 h before.
- **US-4** As a customer, I cancel up to 2 h before, from the link in the email.
- **US-5** As an owner, I see today's bookings for every staff member.

## Not in the MVP
Online payment (deposits come in version 2), mobile apps, several branches.

## Quality
- Availability 99.9% a month; booking page p95 < 300 ms.
- 2,000 businesses in year one; 25 bookings a business a day.
- Personal data kept 2 years after the last visit, then deleted.

## Risks and open questions
- Time zones: a business and its customers may be in different zones.
- Do customers need an account to see their history? (decide by 2026-12-01)
