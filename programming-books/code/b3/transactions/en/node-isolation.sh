# READ COMMITTED (PostgreSQL's default)
$ node node/isolation.ts
A reads the price: 45000
B sets the price to 50000 and commits
A reads it again: 50000
A adds 1000 to the price: 51000
# REPEATABLE READ
$ node node/isolation.ts 'REPEATABLE READ'
A reads the price: 45000
B sets the price to 50000 and commits
A reads it again: 45000
A adds 1000 to the price: ERROR could not serialize access due to concurrent update
