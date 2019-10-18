#!/usr/bin/env bash

for x in echo $(ls target/linux32/lib/*.a); do
  ./common/copy-lib.sh $(basename $x);
done
