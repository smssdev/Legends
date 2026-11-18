# Oops: an edit you did not mean to make
$ git status --short
 M journal.md
# Throw away the change in this file
$ git restore journal.md
$ git status --short
# Now write Day 3 properly, then:
$ git commit -q -am "Day 3"
# A commit you regret, already saved
$ git add quote.md
$ git commit -q -m "Add a random quote"
# Undo it with a new commit, keeping the history honest
$ git revert --no-edit HEAD
[main 8a28f85] Revert "Add a random quote"
 1 file changed, 1 deletion(-)
 delete mode 100644 quote.md
$ git log --oneline
8a28f85 Revert "Add a random quote"
4b00ed1 Add a random quote
30896b9 Day 3
31670a5 Day 2
62eacf9 Day 1
b7c860c Start the journal
