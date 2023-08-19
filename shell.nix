{ pkgs ? import <nixpkgs> {} }:
let
    frameworks = pkgs.darwin.apple_sdk.frameworks;
in pkgs.mkShell {
        nativeBuildInputs = [ 
            pkgs.buildPackages.elixir 
            pkgs.buildPackages.elixir_ls
            pkgs.buildPackages.nodejs 
            pkgs.buildPackages.erlang 
            pkgs.buildPackages.rebar3
            pkgs.buildPackages.flyctl
            pkgs.buildPackages.postgresql
            # add macos header to build mac_listener 
            frameworks.CoreServices
            frameworks.CoreFoundation
            frameworks.Foundation
        ];
}