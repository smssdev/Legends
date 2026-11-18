# Edit index.html in VS Code, then:
# What changed since the last commit?
$ git diff
diff --git a/index.html b/index.html
index 5ab23b1..96fec82 100644
--- a/index.html
+++ b/index.html
@@ -1 +1,2 @@
 <h1>Sara Khan</h1>
+<p>Beginner web developer</p>
$ git commit -am "Add tagline"
[main 8be4da4] Add tagline
 1 file changed, 1 insertion(+)
# The history, newest first
$ git log --oneline
8be4da4 Add tagline
96c0a17 Add profile page
