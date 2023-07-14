#!/usr/bin/env bash
rm coroutines.wat
cp "$1" /tmp/e2e.go
wat=`cd ../tinygo && ./e2e.sh /tmp/e2e.go`
echo "$wat" >coroutines.wat
wasm -d -i coroutines.wat -o "$(basename -s .go "$1")-wasmfx.wasm"
