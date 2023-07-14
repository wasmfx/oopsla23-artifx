#!/usr/bin/env bash

echo "compiling main-kjp.go with wasmfx"
./e2e.sh main-kjp.go
echo "compiling main-kjp.go with asyncify"
tinygo build -target wasi -o main-kjp-asyncify.wasm main-kjp.go
# Print the binary size of the emitted Wasm modules
ls -lh main-kjp-*.wasm
echo "compiling coroutines.go with wasmfx"
./e2e.sh coroutines.go
echo "compiling coroutines.go with asyncify"
tinygo build -target wasi -o coroutines-asyncify.wasm coroutines.go
# Print the binary size of the emitted Wasm modules
ls -lh coroutines-*.wasm

