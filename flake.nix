{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    utils,
    rust-overlay,
    ...
  }:
    utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [rust-overlay.overlays.default];
        };
        # default profile: rustc, cargo, clippy, rustfmt (rustlings shells out to cargo + clippy)
        toolchain = pkgs.rust-bin.stable.latest.default;
        rustPlatform = pkgs.makeRustPlatform {
          cargo = toolchain;
          rustc = toolchain;
        };
        rustlings = rustPlatform.buildRustPackage {
          pname = "rustlings";
          version = "6.5.0";
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;
          # shortcut: these run exercise bins from target/debug, but nixpkgs sets CARGO_BUILD_TARGET
          # (bins land in target/<triple>/debug); they pass under plain `cargo test`, re-enable if rustlings honors the triple dir
          checkFlags = ["--skip=run_compilation_success" "--skip=run_test_success"];
        };
      in {
        packages.default = rustlings;

        devShells.default = pkgs.mkShell {
          packages = [rustlings toolchain pkgs.git];
        };
      }
    );
}
