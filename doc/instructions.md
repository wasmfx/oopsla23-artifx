# Artifact Evaluation Instructions

This document describes how to reproduce the experiments in Section
5.1 of the paper:

*Luna Phipps-Costin, Andreas Rossberg, Arjun Guha, Daan Leijen, Daniel Hillerström, KC Sivaramakrishnan, Matija Pretnar, Sam Lindley, "Continuing WebAssembly with Effect Handlers", Proc. ACM Program. Lang. 7(OOPSLA2), 2023*.

**Note**: The empirical data presented in the paper were measured on a
particular reference machine available at the time of writing. In
order to reproduce this data, it would be necessary to have access to
the particular reference machine (or a virtually identical one). The
purpose of this document is to describe how to obtain measurements
like those reported in the paper.

This document is best viewed on GitHub
(https://github.com/wasmfx/oopsla23-artifx).

## Overview of the Artifact

The artifact is structured as follows

1. The section [Getting Started Guide](#getting-started-guide)
   enumerates the software and hardware requirements to build and run
   the artifact software.
2. The section [Step by Step Instructions](#step-by-step-instructions)
   is a detailed guide on how to run the experiments inside a Docker
   container running the provided Docker image.
3. The section [Inspecting the Source
   Files](#inspecting-the-source-files) highlights some relevant
   source files with our WasmFX additions.
4. The section [The WasmFX Toolchains](#the-wasmfx-toolchains)
   describes how our "toolchains" work.
5. The section [Reference Machine
   Specification](#reference-machine-specification) contains some
   detailed information about the reference machine used to conduct
   the experiments.

The directory structure of the artifact is as follows

* `benchmarks/c/` contains the source code for the C benchmarks.
* `benchmarks/go` contains the source code for the TinyGo binary size benchmarks.
* `doc/` contains alternate formats of this document and a build for generating them.
* `Dockerfile` is the Docker build script.
* `LICENSE` is the license which the provided code -- if not stated
  otherwise -- is licensed under.
* `patch/` contains the changesets for our forks of wasm-spec, wasm-tools, and wasmtime.
* `README.md` is a copy of this document.
* `run-experiments.sh` is a script to automate running the experiments
* `run-tests.sh` is a script to automate running the testsuites
* `run-tests.sh.reference` contains a sample output of running `run-tests.sh`
* `tinygo/` contains our fork of TinyGo
* `wasm-spec` is our fork of the WebAssembly reference interpreter
* `wasmtime` is our fork of the Bytecode Alliance's wasmtime (it's the
  Wasm compiler and runtime).
* `wasm-tools` is our fork of the Bytecode Alliance's wasm-tools (it's
  binary parser and typechecker used by wasmtime).

The entire source code of this artifact is available on GitHub
(https://github.com/wasmfx/oopsla23-artifx).

## Getting Started Guide

To conduct the experiments you will need the following software
components:

1. An x86_64 Debian 11 (bookworm) or equivalent Linux system
   (e.g. Ubuntu 22.04 LTS).
2. The WebAssembly reference interpreter.
3. Our WasmFX extension patch to the reference interpreter.
4. The wasm-tools and wasmtime toolchains from the Bytecode Alliance.
5. Our WasmFX extension patches to wasm-tools and wasmtime.
6. The WASI SDK version 20.0 for Linux.
7. Go version 18.
8. TinyGo version 0.26.
9. Our WasmFX extension patch to TinyGo.
10. The Clang toolchain version 14.
11. The Rust toolchain version 1.71.
13. OPAM version 2.1.2.
14. WebAssembly Binary Toolkit (wabt) version 1.0.32-1.
15. Binaryen version 108-1.
16. Rakudo version 2022.12-1.
17. GNU time.
18. Our benchmark suite.

For your convenience, we provide all of the above in a
[Docker](https://www.docker.com/) image. Please consult [the official
Docker documentation](https://docs.docker.com/engine/install/) for
instructions on to install and configure Docker for your operating
system.

**Note** To successfully run the experiments you will also need an
x86_64 machine (or emulator) as our WasmFX extension to wasmtime is
currently only compatible with x86_64 architectures.

**Note** Every machine that we have used for testing this artifact has
had at minimum 8GB of RAM.

## Step by Step Instructions

The following instructions assume you want to evaluate the artifact
using the provided Docker image. If you want to build the artifact
from source, then please follow the detailed instructions in the
[Dockerfile](./Dockerfile). Nonetheless, the Dockerfile should be
considered as an addendum to these instructions as it contains
additional commentary on the compilation flags necessary to reproduce
the experiments.

### Step 0: Unpack the artifact

If you obtained the artifact via the distributed tar-ball, then you
must first unpack it

```
$ tar xvf paper-195.tar.gz
```

Alternatively, you may check it out from the git repository

```
$ git clone https://github.com/wasmfx/oopsla23-artifx.git paper-195
```

In either case, you should now have the following files on your
machine

```
$ cd paper-195 && ls -m
benchmarks, Dockerfile, LICENSE, patch, README.md, run-experiments.sh, run-tests.sh,
run-tests.sh.reference, tinygo, wasm-spec, wasmtime, wasm-tools
```

### Step 1: Obtain the Docker Image

You can either download a prepared image or build it yourself from
scratch.

#### Downloading the image

You can download the prepared image (built for x86_64 architectures)
by issuing the following command

```
$ docker pull wasmfx/oopsla23-artifact:latest
$ docker tag wasmfx/oopsla23-artifact wasmfx-oopsla23-artifact
```

The last command creates an alias for the image, which we will use
exclusively throughout this guide.

#### Building from Source

To build the image from scratch you may use provided
[Dockerfile](./Dockerfile) build script. Depending on your hardware
the build process may take upwards an hour, though, any reasonable
modern workstation ought to be able to finish the process within 5
minutes. If you are using an x86_64 machine, then you may build the
image by issuing the following command

```
$ docker build -t wasmfx-oopsla23-artifact .
```

If you are on an Arm-powered machine, then you may try to cross build
the image

```
$ docker buildx build --platform linux/amd64 -t wasmfx-oopsla23-artifact .
```

In either case, if the build is successful then the last line of the
console ought to read

```
Successfully tagged wasmfx-oopsla23-artifact:latest
```

### Step 2: Launch the Image inside a Container

To test image, we can launch it inside a container. If you are on an
x86_64 machine, then invoke the following command to launch the image
and drop you into an interactive shell

```
$ docker run -it wasmfx-oopsla23-artifact /bin/bash
```

If you are on an Arm-powered device then you may try to use the
emulation layer, e.g.

```
$ docker run --platform linux/amd64 -it wasmfx-oopsla23-artifact /bin/bash
```

Nonetheless, once the shell has been launched you should be able to
see the following files

```
# ls -m
go-compile-and-size, run-experiments.sh, run-tests.sh, switching-throughput, tinygo, wasm-spec, wasm-tools, wasmtime
```

To exit the container again, simply type

```
# exit
```

### Step 3: Run the Testsuites (Optional)

As a soundness check you may want to run the testsuites of the
reference interpreter, wasm-tools, and wasmtime to check that they
have been built and installed properly during Step 1. We provide a
test runner script, which automates the process. Though, do note that
the first time the script is run (in the current container instance)
it will trigger the debug builds of wasm-tools and wasmtime. To run
the testsuite simply invoke

```
$ docker run -t wasmfx-oopsla23-artifact ./run-tests.sh
```

A successful run should not report any errors. The file
[run-tests.sh.reference](./run-tests.sh.reference) contains an output
of the process obtained on the reference machine. Though, do note that
this output may differ slightly from the one you just obtained, as the
wasmtime testsuite is multi-threaded, meaning the order of test result
reports is not deterministic.

### Step 4: Run the Experiments

We provide a experiment runner script which runs the experiments
described in Section 5.1 of the paper. You may launch this script by
running

```
$ docker run -t wasmfx-oopsla23-artifact ./run-experiments.sh
```

The output of this command should look similar to the following

```
bespoke opt
1.06 14116
1.08 14172
1.08 13964
1.05 13912
1.03 14308
asyncify opt
0.49 63936
0.50 64048
0.48 63988
0.49 63852
0.52 63976
wasmfx opt
2.28 63252
2.34 63668
2.45 63660
2.35 63904
2.36 63384
compiling main-kjp.go with wasmfx
compiling main-kjp.go with asyncify
-rwxr-xr-x 1 root root 479K Jul 14 18:05 main-kjp-asyncify.wasm
-rw-r--r-- 1 root root 152K Jul 14 18:05 main-kjp-wasmfx.wasm
compiling coroutines.go with wasmfx
compiling coroutines.go with asyncify
-rwxr-xr-x 1 root root  52K Jul 14 18:05 coroutines-asyncify.wasm
-rw-r--r-- 1 root root 7.2K Jul 14 18:05 coroutines-wasmfx.wasm
```

The `bespoke opt`, `asyncify opt`, and `wasmfx opt` entries display
the run time and memory consumption measurements which forms the basis
for Figure 7a in Section 5.1 of the paper. There are two columns of
data under each entry. The first column is the elapsed wall time in
seconds, whilst the second column is the memory footprint in bytes.

Note that the measurements will differ slightly from the ones reported
in the paper, in particular for the case of the run time performance
of WasmFX, as the version of the compiler and runtime included here
has a performance regression due to our own refactorings and upstream
changes. Another side effect of these changes is that the memory
footprint of the asyncify programs has been improved. We will update
the numbers accordingly in the camera-ready version of the paper.

The file size column in file listings under `compiling main-kjp.go
with asyncify` and `compiling coroutines.go with asyncify` form the
basis for the data in Figure 7b in Section 5.1 of the paper.

### Step 5: Modifying the Experiment Parameters (Optional)

To modify the parameters of the coroutines benchmark from Figure 7a in
Section 5.1 of the paper, you should first install your favourite
editor, e.g.

```
$ docker run -it wasmfx-oopsla23-artifact /bin/bash
# apt install emacs
```

Afterwards navigate to the directory `switching-throughput` and open
the file `parameters.h`

```
# cd switching-throughput
# emacs parameters.h
```

Here you may modify the right hand side of each variable assignment to
change the benchmark parameters.

```c
// This parameter controls the total number of spawned coroutines.
static const unsigned int NUM_COROUTINES = 10000000;
// This parameter controls the number of coroutines that may run
// simultaneously.
static const unsigned int NUM_SIMULTANEOUS = 10000;
```

Save your changes (in Emacs C-x C-s) and quit the editor (in Emacs C-x
C-c). And then rebuild and run the benchmarks

```
# make clean && make all
# ../run-experiments.sh
```

To compile another TinyGo program, copy it into `go-compile-and-size`
directory. Suppose your TinyGo program is named `awesome.go` then you
can compile with Asyncify and WasmFX as follows

```
# cd go-compile-and-size
# tinygo build -target wasi -o awesome-asyncify.wasm awesome.go
# ./e2e.sh awesome.go
# ls -m | grep awesome
awesome.go, awesome-asyncify.wasm, awesome-wasmfx.wasm
```

## Inspecting the Source Files

This artifact contains a lot of code. Most of this code is written by
the open source community. We have chosen to include our changesets to
the toolchains in the directory [patch/](./patch). These changesets
were obtained by running `git diff` of our forks against the, at the
time of writing, respective recent upstream main branch.

* [patch/spec-wasmfx.patch](./patch/spec-wasmfx.patch) contains the
  changeset for our WasmFX extension to the WebAssembly reference
  interpreter **with the function references extension**. Note our
  changeset also includes parts of the exception handling extension.
* [patch/wasm-tools-wasmfx.patch](./patch/wasm-tools-wasmfx.patch)
  contains the changeset for our WasmFX extension to wasm-tools.
* [patch/wasmtime-wasmfx.patch](./patch/wasmtime-wasmfx.patch)
  contains the changeset for our WasmFX extension to wasmtime.
* [patch/tinygo-wasmfx.patch](./patch/tinygo-wasmfx.patch) contains
  the changeset to make the TinyGo compiler emit WasmFX instructions.

If you want to look at the source files themselves, then the following
enumeration highlights the most relevant files

* Reference interpreter
  - `wasm-spec/interpreter/text/parser.mly`: the parser (look for
    productions involving keywords `resume` and `cont`).
  - `wasm-spec/interpreter/syntax/{ast,types}.ml`: the abstract syntax
    for terms and types.
  - `wasm-spec/interpreter/valid/valid.ml`: the type checker.
  - `wasm-spec/interpreter/binary/encode.ml`: the binary encoder.
  - `wasm-spec/interpreter/exec/eval.ml`: the evaluator.
* wasm-tools
  - `wasm-tools/crates/wasmparser/src/core/types.rs`: the type structure.
  - `wasm-tools/crates/wasmparser/src/validator/core/operators.rs`: the type checker.
  - `wasm-tools/crates/wasmparser/src/lib.rs`: a macro for generating the abstract term syntax.
* wasmtime
  - `wasmtime/cranelift/wasm/src/code_translator.rs`: the translator from wasm-tools term syntax to the cranelift intermediate representation.
  - `wasmtime/crates/cranelift/src/func_environ.rs`: translation utilities.
  - `wasmtime/crates/runtime/src/continuation.rs`: the implementation of continuation related libcalls.
  - `wasmtime/crates/fibre/src/unix/x86_64.rs`: the x86_64 code for stack switching.
  - `wasmtime/crates/types/src/lib.rs`: mapping from wasm-tools types to wasmtime types.

If you plan to make changes to the wasm-tools or wasmtime source
flags, or want to try different compilation flags, then we recommend
doing a `cargo clean` in the root of the respective toolchain before
running `cargo build` to clear the build cache.

## The WasmFX Toolchains

Our work does not include a fully developed toolchain. Instead, we
leverage existing toolchains by performing textual substitution on
their outputs. The "compiler" (it is really an oversized regex) for
our benchmarks operate on wast files and relies on the assumption that
certain names are present. Therefore it is important that toolchains
to not optimise occurrences of these names away.

For example, in the [benchmarks/c/Makefile](./benchmarks/c/Makefile)
the rule for generating the precompiled module `wasmfx.cwasm` is
defined as follows

```Makefile
CC=wasi-sdk-20.0/bin/clang -O3
WTC=wasmtime compile

wasmfx.wat: coroutines.c wasmfx.pl
	$(CC) coroutines.c -o wasmfx.wasm -Wl,--allow-undefined,--export=a_coroutine
	wasm2wat wasmfx.wasm >wasmfx_import.wat
	raku wasmfx.pl <wasmfx_import.wat >wasmfx.wat

wasmfx.cwasm: wasmfx.wat
	wasm -d -i wasmfx.wat -o wasmfx.wasm
	$(WTC) --wasm-features typed-continuations,function-references,exceptions wasmfx.wasm
```

The line `$(CC) coroutines.c ...` contains the option
`--export=a_coroutines` which makes sure the procedure `a_coroutine`
from [benchmarks/c/coroutines.c](./benchmarks/c/coroutines.c) is
publicly visible. The output is an optimised binary. Thus we use the
utility `wasm2wat` (from wabt) to turn the binary into a textual Wasm
file named `wasmfx_import.wat` (see the perl script
[benchmarks/c/wasmfx.pl](./benchmarks/c/wasmfx.pl) for the glorious
details). The next line applies the Raku script `wasmfx.pl` to
textually substitute in the required runtime components. The resulting
`wasmfx.wat` is translated back into binary file using the WasmFX
reference interpreter (called `wasm` in the above listing). Finally,
we use wasmtime to precompile the Wasm binary. Obviously, this is a
brittle "toolchain" as it relies on the internal naming scheme of
certain tools and on certain optimisations not being applied.

In the future we intend to develop a robust toolchain for compiling
some high-level language to Wasm extended with WasmFX instructions.

Our patched TinyGo compiler works as follows

1. Use the JavaScript runtime for WASI with a stub event handler.
2. Skip the Asyncify pass on Wasm modules produced by the TinyGo.
3. Instead, run the Raku script [tinygo/effects.raku](./tinygo/effects.raku). It:
  - Replaces the runtime scheduler with a WasmFX-powered scheduler
    similar to the one in Section 2.5 of the paper.
  - Replaces the runtime function `task.Pause` with the WasmFX
    instruction `suspend $scheduler` where `$scheduler` is the control
    tag for transferring control to the WasmFX-powered scheduler.
  - Replaces the runtime function `task.start` with both the WasmFX
    instruction `cont.new` and runtime function `enqueue` (the latter
    enqueues the continuation).

## Reference Machine Specification

```
$ docker --version
Docker version 20.10.21, build 20.10.21-0ubuntu1~22.04.3
$ uname -rsvpo
Linux 5.19.0-46-generic #47~22.04.1-Ubuntu SMP PREEMPT_DYNAMIC Wed Jun 21 15:35:31 UTC 2 x86_64 GNU/Linux
$ cat /etc/debian_version
bookworm/sid
$ free -m -t
               total        used        free      shared  buff/cache   available
Mem:           31997        6131       14927          85       10938       25327
Swap:          16383        7815        8568
Total:         48381       13947       23496
$ cat /proc/cpuinfo
processor	: 0
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 2877.493
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 0
cpu cores	: 12
apicid		: 0
initial apicid	: 0
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 1
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 2200.000
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 1
cpu cores	: 12
apicid		: 2
initial apicid	: 2
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 2
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 2200.000
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 2
cpu cores	: 12
apicid		: 4
initial apicid	: 4
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 3
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 2877.365
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 3
cpu cores	: 12
apicid		: 6
initial apicid	: 6
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 4
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 2200.000
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 4
cpu cores	: 12
apicid		: 8
initial apicid	: 8
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 5
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 2972.402
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 5
cpu cores	: 12
apicid		: 10
initial apicid	: 10
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 6
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 2199.412
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 8
cpu cores	: 12
apicid		: 16
initial apicid	: 16
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 7
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 2198.822
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 9
cpu cores	: 12
apicid		: 18
initial apicid	: 18
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 8
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 2198.539
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 10
cpu cores	: 12
apicid		: 20
initial apicid	: 20
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 9
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 2199.127
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 11
cpu cores	: 12
apicid		: 22
initial apicid	: 22
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 10
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 2199.217
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 12
cpu cores	: 12
apicid		: 24
initial apicid	: 24
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 11
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 2199.677
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 13
cpu cores	: 12
apicid		: 26
initial apicid	: 26
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 12
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 2200.000
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 0
cpu cores	: 12
apicid		: 1
initial apicid	: 1
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 13
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 2200.000
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 1
cpu cores	: 12
apicid		: 3
initial apicid	: 3
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 14
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 2200.000
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 2
cpu cores	: 12
apicid		: 5
initial apicid	: 5
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 15
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 2862.367
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 3
cpu cores	: 12
apicid		: 7
initial apicid	: 7
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 16
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 4197.992
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 4
cpu cores	: 12
apicid		: 9
initial apicid	: 9
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 17
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 2200.000
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 5
cpu cores	: 12
apicid		: 11
initial apicid	: 11
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 18
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 2599.963
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 8
cpu cores	: 12
apicid		: 17
initial apicid	: 17
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 19
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 2878.316
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 9
cpu cores	: 12
apicid		: 19
initial apicid	: 19
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 20
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 2204.013
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 10
cpu cores	: 12
apicid		: 21
initial apicid	: 21
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 21
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 3364.610
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 11
cpu cores	: 12
apicid		: 23
initial apicid	: 23
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 22
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 3598.710
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 12
cpu cores	: 12
apicid		: 25
initial apicid	: 25
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]

processor	: 23
vendor_id	: AuthenticAMD
cpu family	: 25
model		: 33
model name	: AMD Ryzen 9 5900X 12-Core Processor
stepping	: 0
microcode	: 0xa201016
cpu MHz		: 2504.055
cache size	: 512 KB
physical id	: 0
siblings	: 24
core id		: 13
cpu cores	: 12
apicid		: 27
initial apicid	: 27
fpu		: yes
fpu_exception	: yes
cpuid level	: 16
wp		: yes
flags		: fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov pat pse36 clflush mmx fxsr sse sse2 ht syscall nx mmxext fxsr_opt pdpe1gb rdtscp lm constant_tsc rep_good nopl nonstop_tsc cpuid extd_apicid aperfmperf rapl pni pclmulqdq monitor ssse3 fma cx16 sse4_1 sse4_2 movbe popcnt aes xsave avx f16c rdrand lahf_lm cmp_legacy svm extapic cr8_legacy abm sse4a misalignsse 3dnowprefetch osvw ibs skinit wdt tce topoext perfctr_core perfctr_nb bpext perfctr_llc mwaitx cpb cat_l3 cdp_l3 hw_pstate ssbd mba ibrs ibpb stibp vmmcall fsgsbase bmi1 avx2 smep bmi2 erms invpcid cqm rdt_a rdseed adx smap clflushopt clwb sha_ni xsaveopt xsavec xgetbv1 xsaves cqm_llc cqm_occup_llc cqm_mbm_total cqm_mbm_local clzero irperf xsaveerptr rdpru wbnoinvd arat npt lbrv svm_lock nrip_save tsc_scale vmcb_clean flushbyasid decodeassists pausefilter pfthreshold avic v_vmsave_vmload vgif v_spec_ctrl umip pku ospke vaes vpclmulqdq rdpid overflow_recov succor smca fsrm
bugs		: sysret_ss_attrs spectre_v1 spectre_v2 spec_store_bypass
bogomips	: 7399.89
TLB size	: 2560 4K pages
clflush size	: 64
cache_alignment	: 64
address sizes	: 48 bits physical, 48 bits virtual
power management: ts ttp tm hwpstate cpb eff_freq_ro [13] [14]
```
