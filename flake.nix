{
  description = "A basic gomod2nix flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  inputs.gomod2nix.url = "github:nix-community/gomod2nix";
  inputs.gomod2nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.gomod2nix.inputs.flake-utils.follows = "flake-utils";

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    gomod2nix,
  }: (
    flake-utils.lib.eachDefaultSystem
    (system: let
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (pkgs) lib;

      # The current default sdk for macOS fails to compile go projects, so we use a newer one for now.
      # This has no effect on other platforms.
      callPackage = pkgs.darwin.apple_sdk_11_0.callPackage or pkgs.callPackage;
    in {
      packages = rec {
        default = webdavplugin;

        webdavplugin = callPackage ./. {
          inherit (gomod2nix.legacyPackages.${system}) buildGoApplication;
        };

        docker = pkgs.dockerTools.buildImage {
          name = "webdavplugin";
          tag = "latest";
          contents = pkgs.buildEnv {
            name = "webdavplugin";
            paths = [pkgs.davfs2];
          };
          config.Cmd = ["${webdavplugin}/bin/webdav"];
        };
      };
      devShells.default = callPackage ./shell.nix {
        inherit (gomod2nix.legacyPackages.${system}) mkGoEnv gomod2nix;
      };

      formatter = pkgs.alejandra;
    })
  );
}
