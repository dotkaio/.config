#!/bin/bash
# Usage: ./resolve-ins.sh inputfile > outputfile

# This script removes git conflict markers and keeps only the "IN" (first) side.
awk '
  /^<<<<<<< / { in_conflict=1; next }    # start conflict
  /^=======/  { in_conflict_keep=0; next }  # switch to OUT side
  /^>>>>>>>/  { in_conflict=0; next }    # end conflict
  {
    if (in_conflict) {
      if (in_conflict_keep != 0) print $0   # only print the first side
    } else {
      print $0
    }
  }
' "$1"