# Write on the primary, read on the replica
$ node --env-file=.env replica.ts
owner, just after booking, reads from primary: found
another user reads from replica: not found
~0 ms: not on the replica yet
~500 ms: not on the replica yet
~1000 ms: not on the replica yet
~1500 ms: not on the replica yet
~2000 ms: not on the replica yet
~2500 ms: not on the replica yet
booking 1: on the replica after ~3000 ms
