# 1. One PostgreSQL database for the whole product

Status: Accepted
Date: 2026-02-03 · Deciders: Mona, Karim, Sara

## Context
Three developers, one product, fewer than 1,000 bookings a day.
Bookings must never be double-sold (Chapter 6).

## Decision
All modules share one managed PostgreSQL database, each in its own schema.

## Options considered
- One database: one backup, real transactions; modules can couple through tables.
- A database per service: independent deploys; no transactions across them.

## Consequences
Easier: transactions, reports, operations. Harder: keeping schemas apart.
A module reads another module's tables only through its code, never directly.
Revisit when one module needs to scale or deploy on its own.
