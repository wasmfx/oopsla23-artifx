with import <nixpkgs> {};

let llvm = llvmPackages_14.llvm; in
let clang = clang_14; in
pkgs.stdenv.mkDerivation {
  pname = "tinygo";
  version = "0.26.0";

  patches = [
    ./0001-Makefile.patch

    (substituteAll {
      src = ./0002-Add-clang-header-path.patch;
      clang_include = "${clang.cc.lib}/lib/clang/${clang.cc.version}/include";
    })

    #TODO(muscaln): Find a better way to fix build ID on darwin
    ./0003-Use-out-path-as-build-id-on-darwin.patch
  ];

  vendorSha256 = "";

  checkInputs = [ binaryen ];
  nativeBuildInputs = [ makeWrapper ];
  buildInputs = [ llvmPackages_14.llvm clang_14.cc go_1_18 ];

  #allowGoReference = true;
  #tags = [ "llvm14" ];
  ldflags = [ "-X github.com/tinygo-org/tinygo/goenv.TINYGOROOT=${placeholder "out"}/share/tinygo" ];
  #subPackages = [ "." ];

  # Output contains static libraries for different arm cpus
  # and stripping could mess up these so only strip the compiler
  stripDebugList = [ "bin" ];

  postPatch = ''
    substituteInPlace Makefile \
      --replace "\$(TINYGO)" "$(pwd)/build/tinygo" \
      --replace "@\$(MD5SUM)" "md5sum" \
      --replace "build/release/tinygo/bin" "$out/bin" \
      --replace "build/release/" "$out/share/"

    substituteInPlace builder/buildid.go \
      --replace "OUT_PATH" "$out"

    # TODO: Fix mingw and darwin
    # Disable windows and darwin cross-compile tests
    sed -i "/GOOS=windows/d" Makefile
    sed -i "/GOOS=darwin/d" Makefile

    # tinygo needs versioned binaries
    mkdir -p $out/libexec/tinygo
    ln -s ${lib.getBin clang.cc}/bin/clang $out/libexec/tinygo/clang-14
    ln -s ${lib.getBin lld}/bin/ld.lld $out/libexec/tinygo/ld.lld-14
    ln -s ${lib.getBin lld}/bin/wasm-ld $out/libexec/tinygo/wasm-ld-14
    ln -s ${gdb}/bin/gdb $out/libexec/tinygo/gdb-multiarch
  '' + lib.optionalString (stdenv.buildPlatform != stdenv.hostPlatform) ''
    substituteInPlace Makefile \
      --replace "./build/tinygo" "${buildPackages.tinygo}/bin/tinygo"
  '';

  preBuild = ''
    export PATH=$out/libexec/tinygo:$PATH
    export HOME=$TMPDIR
  '';

  postBuild = let
    tinygoForBuild = "build/tinygo"; in ''
    # Move binary
    mkdir -p build
    mv $GOPATH/bin/tinygo build/tinygo

    make gen-device

    export TINYGOROOT=$(pwd)
    finalRoot=$out/share/tinygo

    for target in thumbv6m-unknown-unknown-eabi-cortex-m0 thumbv6m-unknown-unknown-eabi-cortex-m0plus thumbv7em-unknown-unknown-eabi-cortex-m4; do
      mkdir -p $finalRoot/pkg/$target
      for lib in compiler-rt picolibc; do
        ${tinygoForBuild} build-library -target=''${target#*eabi-} -o $finalRoot/pkg/$target/$lib $lib
      done
    done
  '';

  meta = with lib; {
    homepage = "https://tinygo.org/";
    description = "Go compiler for small places";
    license = licenses.bsd3;
    maintainers = with maintainers; [ Madouura muscaln ];
  };
}
