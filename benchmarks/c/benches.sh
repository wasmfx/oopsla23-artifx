#!/usr/bin/env bash

function bench() {
  rexprtime="median("
  rexprmem="median("
  for i in {1..5}; do
    num=`{ \time -f '%e %M' $@ >/dev/null; } 2>&1`
    echo $num
    tm=`echo "$num" | cut -f1 -d' '`
    mm=`echo "$num" | cut -f2 -d' '`
    rexprtime="$rexprtime$tm,"
    rexprmem="$rexprmem$mm,"
  done
  echo "$rexprtime)" >>benches.r
  echo "$rexprmem)" >>benches.r
}

echo >benches.r
make all >/dev/null 2>/dev/null
echo "bespoke opt"
echo "# bespoke opt" >> benches.r
bench wasmtime --allow-precompiled bespoke.cwasm
echo "asyncify opt"
echo "# asyncify opt" >> benches.r
bench wasmtime --allow-precompiled asyncify.cwasm
echo "wasmfx opt"
echo "# wasmfx opt" >> benches.r
bench wasmtime --wasm-features=typed-continuations,exceptions,function-references --allow-precompiled wasmfx.cwasm

