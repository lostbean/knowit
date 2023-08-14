{ pkgs ? import <nixpkgs> {} }:
    pkgs.mkShell {
        nativeBuildInputs = [ 
            pkgs.buildPackages.elixir 
            pkgs.buildPackages.nodejs 
            pkgs.buildPackages.erlang 
            pkgs.buildPackages.rebar3
            pkgs.buildPackages.flyctl
            pkgs.buildPackages.postgresql
        ];
}