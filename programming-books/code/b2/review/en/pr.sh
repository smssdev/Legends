# A new branch for the feature
$ git switch -c feature/discount-codes
Switched to a new branch 'feature/discount-codes'
# What changed, file by file
$ git diff --stat main
 src/cart/discount.ts |  11 ++
 src/ui/styles.css    | 300 ++++++++++++++++++++++++++++++++++++++++-----------
 2 files changed, 251 insertions(+), 60 deletions(-)
