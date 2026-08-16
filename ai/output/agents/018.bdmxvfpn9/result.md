error:
       … while calling the 'seq' builtin
         at «github:NixOS/nixpkgs/e5bdc4a»/lib/modules.nix:401:18:
          400|         options = checked options;
          401|         config = checked (removeAttrs config [ "_module" ]);
             |                  ^
          402|         _module = checked (config._module);

       … while calling the 'throw' builtin
         at «github:NixOS/nixpkgs/e5bdc4a»/lib/modules.nix:373:13:
          372|           else
          373|             throw baseMsg
             |             ^
          374|         else

       error: The option `services.mpd.package' does not exist. Definition values:
       - In `/nix/store/nnr3zrvv130ckyhf239hxq110wgs8yfh-source/example/radio/module.nix': <derivation mpd-armv6l-unknown-linux-gnueabihf-0.24.14>

       Did you mean `services.mpd.dataDir', `services.mpd.dbFile' or `services.mpd.enable'?

[exited with code 1]
