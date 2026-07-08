{
  description = "librepods-dms dev environment (it was built specifically for my configuration, might not work on yours).";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        vscodeWithQml = pkgs.vscode-with-extensions.override {
          vscode = pkgs.vscodium;
          vscodeExtensions = pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "QML";
            publisher = "bbenoist";
            version = "1.0.0";
            sha256 = "sha256-tphnVlD5LA6Au+WDrLZkAxnMJeTCd3UTyTN1Jelditk=";
          }
          ];
        };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = [
            vscodeWithQml
            pkgs.qt6.qtdeclarative
          ];

          shellHook = ''
            echo "librepods-dms dev shell: VS Code with QML extension available as 'code'"
          '';
        };
      });
}
