#!/usr/bin/env bash

# Run the C benchmarks
cd $CBENCH
./benches.sh

# Build Go benchmarks
cd /artifact/go-compile-and-size
./benches.sh 2> /dev/null
