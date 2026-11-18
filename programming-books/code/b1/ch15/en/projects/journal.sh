# A new folder for your journal
$ git init
Initialized empty Git repository in /Users/sara/code/journal/.git/
# Create journal.md with a heading, then:
$ git add journal.md
$ git commit -q -m "Start the journal"
# Add the Day 1 line, then:
$ git commit -q -am "Day 1"
# Add the Day 2 line, then:
$ git commit -q -am "Day 2"
# Three snapshots, newest first
$ git log --oneline
31670a5 Day 2
62eacf9 Day 1
b7c860c Start the journal
# What exactly changed in the last commit?
$ git show --stat --format=%s HEAD
Day 2

 journal.md | 1 +
 1 file changed, 1 insertion(+)
