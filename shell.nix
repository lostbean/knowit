{ pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/refs/tags/23.05.tar.gz") {} }:
with pkgs;

let
    frameworks = darwin.apple_sdk.frameworks;
    inherit (lib) optional optionals;
in mkShell {
        nativeBuildInputs = [ 
            buildPackages.elixir 
            buildPackages.elixir_ls
            buildPackages.nodejs 
            buildPackages.erlang 
            buildPackages.rebar3
        ] ++ optionals stdenv.isDarwin [
            # Dev environment
            buildPackages.flyctl
            buildPackages.postgresql
            buildPackages.docker
        ] ++ optionals stdenv.isLinux [
            # Docker build
            (python3.withPackages(ps: with ps; [ pip numpy ]))
            buildPackages.stdenv
            buildPackages.gcc
            buildPackages.gnumake
            buildPackages.bazel
            buildPackages.glibc
            buildPackages.gcc
            buildPackages.glibcLocales
        ] ++ optionals stdenv.isDarwin [
            # add macOS headers to build mac_listener and ELXA
            frameworks.CoreServices
            frameworks.CoreFoundation
            frameworks.Foundation
        ];
}