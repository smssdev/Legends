#!/bin/sh
# Builds every edition of every book from scratch, in the right order:
#   1. interiors (HTML), rendered to PDF
#   2. the page of every chapter is read from the PDFs, and the interiors are built again with
#      page numbers in the contents
#   3. the print covers, sized from the final page counts
set -e
cd "$(dirname "$0")"
python3 build.py
node render.cjs -
python3 toc.py
python3 build.py
node render.cjs -
python3 cover.py
node render.cjs cover
python3 plan.py
node render.cjs series-plan
