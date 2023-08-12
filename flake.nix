{
  inputs.crane.url = "github:ipetkov/crane";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  inputs.rust-overlay.url = "github:oxalica/rust-overlay";
inputs.wasmedge.url="github:wasmedge/wasmedge";

  outputs = {
    crane,
    flake-utils,
    nixpkgs,
    rust-overlay,
    self,
    wasmedge,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      overlays = [(import rust-overlay)];
      pkgs = import nixpkgs {inherit system overlays;};
      rust = pkgs.rust-bin.beta.latest.default.override {
        targets = ["wasm32-wasi"];
      };
      craneLib = (crane.mkLib pkgs).overrideToolchain rust;
      test = craneLib.buildPackage {
        src = craneLib.cleanCargoSource (craneLib.path ./.);
        cargoExtraArgs = "--target wasm32-wasi";
        doCheck = false;
      };
    in with pkgs; {
      devShells.default = pkgs.mkShell {
        buildInputs = [rust];
        LIBCLANG_PATH="${llvmPackages_latest.libclang.lib}/lib";
BINDGEN_EXTRA_CLANG_ARGS = "-isystem ${llvmPackages_latest.libclang.lib}/lib/clang/16/include";
LD_LIBRARY_PATH="${zlib}/lib:${stdenv.cc.cc.lib}/lib:${wasmedge.packages.${system}.default}/lib/api";
WASMEDGE_DIR="${wasmedge.packages.${system}.default}";
WASMEDGE_BUILD_DIR="${wasmedge.packages.${system}.default}/build";
      };
      packages.default = test;
    });
}
