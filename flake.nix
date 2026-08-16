{
  description = "NixOS for the original Raspberry Pi Zero W (v1, armv6l)";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      # armv6l has no Hydra binary cache, so this always builds via true cross-compilation
      # from a regular x86_64-linux machine rather than natively on-device.
      buildSystem = "x86_64-linux";
      crossSystem = "armv6l-linux";

      mkRpiZeroW = extraModules:
        nixpkgs.lib.nixosSystem {
          system = buildSystem;
          modules = [
            { nixpkgs.crossSystem.system = crossSystem; }
            ./devices/rpi-zero-w/configuration.nix
          ] ++ extraModules;
        };
    in
    {
      nixosConfigurations = {
        # Part 1: the reusable base image. Boots, joins WiFi, is SSH-reachable. Nothing
        # app-specific.
        rpi-zero-w = mkRpiZeroW [ ];

        # Part 2: the base image plus the internet radio example (see example/radio/README.md).
        rpi-zero-w-radio = mkRpiZeroW [
          ./example/radio/module.nix
          ./example/radio/bluetooth.nix
        ];
      };
    };
}
