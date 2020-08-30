{
  description = "A highly structured configuration database.";

  inputs =
    {
      master.url = "nixpkgs/master";
      nixos.url = "nixpkgs/release-20.03";
      home.url = "github:rycee/home-manager/bqv-flakes";
      qt515.url = "github:nrdxp/nixpkgs/qt515";
      futils.url = "github:numtide/flake-utils";
    };

  outputs = inputs@{ self, home, nixos, master, futils, qt515 }:
    let
      inherit (builtins) attrNames attrValues readDir;
      inherit (nixos) lib;
      inherit (lib) recursiveUpdate;
      inherit (utils) pathsToImportedAttrs overlaysToPkgs;
      inherit (futils.lib) eachSystem defaultSystems;

      utils = import ./lib/utils.nix { inherit lib; };

      systems = defaultSystems ++ [ "armv7l-linux" ];

      pkgImport = pkgs: system:
        import pkgs {
          inherit system;
          overlays = attrValues self.overlays;
          config = { allowUnfree = true; };
        };


      pkgset = system: {
        osPkgs = pkgImport nixos system;
        pkgs = pkgImport master system;
        qt515Pkgs = pkgImport qt515 system;
      };

      multiSystemOutputs = eachSystem systems (system:
        let
          pkgset' = pkgset system;
        in
        with pkgset';
        {
          devShell = import ./shell.nix {
            inherit pkgs;
          };

          packages = overlaysToPkgs self.overlays osPkgs;
        }
      );

      outputs =
        {
          nixosConfigurations =
            let
              system = "x86_64-linux";
              pkgset' = pkgset system;
            in
            import ./hosts (recursiveUpdate inputs {
              inherit lib system utils;
              pkgset = pkgset';
            }
            );

          nixosModules =
            let
              # binary cache
              cachix = import ./cachix.nix;
              cachixAttrs = { inherit cachix; };

              # modules
              moduleList = import ./modules/list.nix;
              modulesAttrs = pathsToImportedAttrs moduleList;

              # profiles
              profilesList = import ./profiles/list.nix;
              profilesAttrs = { profiles = pathsToImportedAttrs profilesList; };

            in
            recursiveUpdate
              (recursiveUpdate cachixAttrs modulesAttrs)
              profilesAttrs;

          overlay = import ./pkgs;

          overlays =
            let
              overlayDir = ./overlays;
              fullPath = name: overlayDir + "/${name}";
              overlayPaths = map fullPath (attrNames (readDir overlayDir));
            in
            pathsToImportedAttrs overlayPaths;

          defaultTemplate = self.templates.flk;

          templates = {
            flk = {
              path = ./.;
              description = "flk template";
            };
          };
        };
    in
    recursiveUpdate multiSystemOutputs outputs;
}
