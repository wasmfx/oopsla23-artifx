BENCHMARK=c10m

# WASI SDK C/C++ compiler
WASICC=wasi-sdk-20.0/bin/clang
WASICC_FLAGS=-O3

# Asyncify compiler from WABT
WASM_OPT=wasm-opt
ASYNCIFY=$(WASM_OPT) -O2 --asyncify --pass-arg=asyncify-ignore-imports

# Wasmtime engine
WASMTIME=wasmtime
WASMTIMEC=$(WASMTIME) compile

# WasmFX enabled Wasmtime engine
WASMTIMEFX_FLAGS=--wasm-features=exceptions,function-references,typed-continuations
WASMFXTIMEC=$(WASMTIMEC) $(WASMTIMEFX_FLAGS)

# WasmFX reference interpreter
WASM_INTERP=wasm

.PHONY: all
all: $(BENCHMARK)_bespoke.cwasm $(BENCHMARK)_asyncify.cwasm $(BENCHMARK)_wasmfx.cwasm

$(BENCHMARK)_bespoke.wasm: $(BENCHMARK)_bespoke.c
	$(WASICC) $(WASICC_FLAGS) -o $(BENCHMARK)_bespoke.wasm $(BENCHMARK)_bespoke.c

$(BENCHMARK)_bespoke.cwasm: $(BENCHMARK)_bespoke.wasm
	$(WASMTIMEC) -o $(BENCHMARK)_bespoke.cwasm $(BENCHMARK)_bespoke.wasm

$(BENCHMARK)_asyncify.wasm: $(BENCHMARK).c asyncify.c
	$(WASICC) $(WASICC_FLAGS) -I . -o $(BENCHMARK)_asyncify.pre.wasm fiber_asyncify.c asyncify.c $(BENCHMARK).c
	$(ASYNCIFY) $(BENCHMARK)_asyncify.pre.wasm -o $(BENCHMARK)_asyncify.wasm

$(BENCHMARK)_asyncify.cwasm: $(BENCHMARK)_asyncify.wasm
	$(WASMTIMEC) -o $(BENCHMARK)_asyncify.cwasm $(BENCHMARK)_asyncify.wasm

## TODO(dhil): Currently $(BENCHMARK)_wasmfx.wast is assembled by hand. We
## should have a tool do the assembling.
$(BENCHMARK)_wasmfx.wasm: $(BENCHMARK)_wasmfx.wast
	$(WASM_INTERP) -d -i $(BENCHMARK)_wasmfx.wast -o $(BENCHMARK)_wasmfx.wasm
	chmod +x $(BENCHMARK)_wasmfx.wasm

$(BENCHMARK)_wasmfx.cwasm: $(BENCHMARK)_wasmfx.wasm
	$(WASMFXTIMEC) -o $(BENCHMARK)_wasmfx.cwasm $(BENCHMARK)_wasmfx.wasm

.PHONY: clean
clean:
	rm -f $(BENCHMARK)_asyncify.pre.wasm $(BENCHMARK)_asyncify.wasm $(BENCHMARK)_bespoke.wasm $(BENCHMARK)_wasmfx.wasm
	rm -f $(BENCHMARK)_asyncify.cwasm $(BENCHMARK)_bespoke.cwasm $(BENCHMARK)_wasmfx.cwasm

