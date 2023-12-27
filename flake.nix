{
  description = "Dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";
    unstable.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { nixpkgs, unstable, flake-utils, ... }:
    let utils = flake-utils;
    in utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        unstable_pkgs = unstable.legacyPackages.${system};
      in {
        formatter = pkgs.nixpkgs-fmt;

        devShell = pkgs.mkShell {
          nativeBuildInputs = with pkgs;
            let
              frameworks = darwin.apple_sdk.frameworks;
              inherit (lib) optional optionals;
            in [
              # Dev environment
              elixir
              elixir_ls
              nodejs
              erlang
              rebar3
            ] ++ optionals stdenv.isDarwin [
              # Dev environment
              flyctl
              (postgresql_15.withPackages (p: [ p.age p.pgrouting p.pgvector ]))
              docker
            ] ++ optionals stdenv.isLinux [
              # Docker build
              (python3.withPackages (ps: with ps; [ pip numpy ]))
              stdenv
              gcc
              gnumake
              bazel
              glibc
              gcc
              glibcLocales
            ] ++ optionals stdenv.isDarwin [
              # add macOS headers to build mac_listener and ELXA
              frameworks.CoreServices
              frameworks.CoreFoundation
              frameworks.Foundation
            ];

          shellHook = ''
            export PGDATA=$(pwd)/.pg_data/knowit_dev
            pg_ctl -D $PGDATA -l logfile restart
            psql knowit_dev -tAc 'ALTER ROLE postgres WITH SUPERUSER' || true

            printf '\u001b[32m
            Know-it!
            \e[0m
            '
          '';
        };
      });
}
