#!/bin/bash
#
# Runs the testsuites of the reference interpreter, wasm-tools, and wasmtime

# Sync opam environment
echo ">> Syncing opam environment"
eval $(opam env)
# Run reference interpreter testsuite
cd $REFINTERP
echo ">> Running reference interpreter testsuite (cwd: $(pwd))"
make test
echo ">> ######################################################"

# Run wasm-tools testsuite
cd $WASMTOOLS
echo ">> Syncing cargo environment"
. "$HOME/.cargo/env"
echo ">> Running wasm-tools testsuite (cwd: $(pwd))"
cargo test
echo ">> ######################################################"

# Run wasmtime testsuite
cd $WASMTIME
echo ">> Running wasmtime testsuite (cwd: $(pwd))"
cargo test
