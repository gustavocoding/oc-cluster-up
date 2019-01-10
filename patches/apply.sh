#!/usr/bin/env bash

for p in /patches/*.patch
do
     echo "Applying $p"
     git apply $p
done
