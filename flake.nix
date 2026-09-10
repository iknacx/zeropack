{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    esp-idf.url = "github:mirrexagon/nixpkgs-esp-dev";
  };

  outputs = { nixpkgs, esp-idf, ... }: let
    forAllSystems = f:
      builtins.mapAttrs
      (system: pkgs: f pkgs esp-idf.packages.${system})
      nixpkgs.legacyPackages;

  in {
    devShells = forAllSystems (pkgs: idf: {
      default = pkgs.mkShell.override {
        stdenv = pkgs.llvmPackages.stdenv;
      } {
        name = "zeropack";
        packages = with pkgs; [
          typst tinymist socat
          python3Packages.bpython
          bun typescript-language-server
          clang-tools idf.esp-idf-full 
        ];
      };
    });
  };
}
