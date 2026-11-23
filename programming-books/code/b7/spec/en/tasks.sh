$ node tasks.mjs
T1      8 h  Implement loyalty card creation and account binding  []
T2     10 h  Track paid hot drink purchases and increment stamp counter  [T1]
T3      6 h  Validate drink eligibility: hot drink and price below large latte threshold  [T2]
T4      6 h  Handle refund logic: remove stamp when a drink is refunded  [T2]
T5      4 h  Ensure loyalty card is valid across both branches  [T1]
T6      6 h  Enforce one active card per account (reject duplicate cards)  [T1]
T7      8 h  Unit tests for all loyalty card rules and edge cases  [T1, T2, T3, T4, T5, T6]
total: 48 hours
dependencies: ok
an order: T1 T2 T3 T4 T5 T6 T7
