{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell rec {
  buildInputs = with pkgs; [
    tinygo
    go_1_18
    nodejs
    wabt
    binaryen
    clang_14
    clang-tools_14
    llvmPackages_14.bintools-unwrapped
    llvmPackages_14.llvm
    llvmPackages_14.libclang
    rakudo
  ];
  LD_LIBRARY_PATH = with pkgs; lib.makeLibraryPath [ llvmPackages_14.llvm llvmPackages_14.libclang ];
}
