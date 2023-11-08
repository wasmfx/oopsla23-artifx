#!/usr/bin/env sh
tinygo build -target wasi -o /tmp/tinygo.wasm "$1"
wasm2wat /tmp/tinygo.wasm > /tmp/preprocess.wat
raku effects.raku </tmp/preprocess.wat
