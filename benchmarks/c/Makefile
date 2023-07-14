CC=wasi-sdk-20.0/bin/clang -O3
WTC=wasmtime compile

.PHONY: all
all: wasmfx.cwasm asyncify.cwasm bespoke.cwasm

wasmfx.wat: coroutines.c wasmfx.pl
	$(CC) coroutines.c -o wasmfx.wasm -Wl,--allow-undefined,--export=a_coroutine
	wasm2wat wasmfx.wasm >wasmfx_import.wat
	raku wasmfx.pl <wasmfx_import.wat >wasmfx.wat

asyncify_import.wasm: coroutines.c asyncify.c
	$(CC) coroutines.c asyncify.c -o asyncify_import.wasm -Wl,--allow-undefined,--export=first_resume,--export=resume_again,--export=suspend

asyncify.cwasm: asyncify_import.wasm
	wasm-opt -O --asyncify asyncify_import.wasm -o asyncify.wasm
	$(WTC) asyncify.wasm

bespoke.cwasm: coroutines_bespoke.c save_state.c
	$(CC) coroutines_bespoke.c save_state.c -o bespoke.wasm
	$(WTC) bespoke.wasm

wasmfx.cwasm: wasmfx.wat
	wasm -d -i wasmfx.wat -o wasmfx.wasm
	$(WTC) --wasm-features typed-continuations,function-references,exceptions wasmfx.wasm

.PHONY: clean
clean:
	rm -f wasmfx.wasm wasmfx.wat wasmfx_import.wat asyncify.wasm asyncify_import.wasm bespoke.wasm
	rm -f wasmfx.cwasm asyncify.cwasm bespoke.cwasm
