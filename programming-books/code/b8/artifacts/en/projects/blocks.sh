$ node blocks.mjs && cat artifacts/block-1.mmd
saved artifacts/block-1.mmd: 5 lines
flowchart LR
  A[Customer orders] --> B[Barista makes drink]
  B --> C{Right drink?}
  C -- yes --> D[Served]
  C -- no --> B
