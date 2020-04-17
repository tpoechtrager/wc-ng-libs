#!/usr/bin/env bash


libs=$(find . -name "*.a" -type f -exec basename {} \;|sort -u)

for x in echo $libs; do
  ./common/copy-lib.sh $(basename $x);
done
