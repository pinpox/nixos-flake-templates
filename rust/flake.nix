{
  description = "A simple Rust package";

  # Nixpkgs / NixOS version to use.
  inputs.nixpkgs.url = "nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let

      # to work with older version of flakes
      lastModifiedDate = self.lastModifiedDate or self.lastModified or "19700101";

      # Generate a user-friendly version number.
      version = builtins.substring 0 8 lastModifiedDate;

      # System types to support.
      supportedSystems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
        "aarch64-darwin"
      ];

      # Helper function to generate an attrset '{ x86_64-linux = f "x86_64-linux"; ... }'.
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;

      # Nixpkgs instantiated for supported system types.
      nixpkgsFor = forAllSystems (system: import nixpkgs { inherit system; });

    in
    {
      # Provide some binary packages for selected system types.
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {

          # The default package for 'nix build'. This makes sense if the
          # flake provides only one package or there is a clear "main"
          # package.
          default = pkgs.rustPlatform.buildRustPackage {
            pname = "hello-rust";
            inherit version;
            src = ./.;

            # This hash locks the dependencies of this package. To begin with
            # it is recommended to set this, but one must remember to bump this
            # hash when your dependencies change.
            cargoHash = pkgs.lib.fakeSha256;
          };
        }
      );

      # Add dependencies that are only needed for development
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgsFor.${system};
        in
        {
          default = pkgs.mkShellNoCC {
            RUST_SRC_PATH = pkgs.rustPlatform.rustLibSrc;
            buildInputs = with pkgs; [
              cargo
              rustc
              rustfmt
              pre-commit
              rustPackages.clippy
            ];
          };
        }
      );
    };
}
