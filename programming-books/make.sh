#!/bin/sh
# Builds every edition of every book from scratch, in the right order:
#   1. interiors (HTML), rendered to PDF
#   2. the page of every chapter is read from the PDFs, and the interiors are built again with
#      page numbers in the contents
#   3. the print covers, sized from the final page counts
# sh make.sh b7- renders only the files whose names contain b7- (the other books keep their PDFs).
set -e
ONLY="${1:--}"
cd "$(dirname "$0")"
[ -d code/b2/node_modules ] || (cd code/b2 && npm ci --silent)
[ -d code/b2/vue-check/node_modules ] || (cd code/b2/vue-check && npm ci --silent)
python3 build.py
node render.cjs "$ONLY"
python3 toc.py
python3 build.py
node render.cjs "$ONLY"
python3 cover.py
if [ "$ONLY" = "-" ]; then node render.cjs cover; else node render.cjs "${ONLY}"; fi
python3 plan.py
node render.cjs series-plan
