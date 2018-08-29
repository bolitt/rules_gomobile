#!/bin/bash
emptydir=$(mktemp -d)
dirs=$(find . -type d -depth 1)

for d in ${dirs}; do
    rm ${d}/${d}.patch;
    (cd ${d} && diff -ruN ${emptydir} . | sed -e 's/BUILD\.bazel\.in/BUILD\.bazel/g' -e "s#${emptydir}#.#g" > ${d}.patch);
done
