#!/usr/bin/env bash

set -e

for p in /patches/*.patch
do
     echo "Applying $p"
     git apply $p
done
