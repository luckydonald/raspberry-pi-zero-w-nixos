…
ng cache ./config.cache
armv6l-unknown-linux-gnueabihf-binutils> checking that generated files are newer than configure... done
armv6l-unknown-linux-gnueabihf-binutils> configure: creating ./config.status
armv6l-unknown-linux-gnueabihf-binutils> yes
building '/nix/store/lcjl3hn7gwqq1ccyf8c68831xv1627b2-linux-armv6l-unknown-linux-gnueabihf-6.18.44-modules-shrunk.drv'...
overlays.json> structuredAttrs is enabled
building '/nix/store/wyjk32ff6bsj9v48lnynjdj82kcpdcfg-device-tree-overlays.drv'...
armv6l-unknown-linux-gnueabihf-binutils> checking for uintptr_t... yes
linux-armv6l-unknown-linux-gnueabihf> kernel version is 6.18.44
linux-armv6l-unknown-linux-gnueabihf> root module: 3w-9xxx
linux-armv6l-unknown-linux-gnueabihf> modprobe: FATAL: Module 3w-9xxx not found in directory /nix/store/hhxblz9ja8hhzw2hwhmkmfsysmvhh1c1-linux-armv6l-unknown-linux-gnueabihf-6.18.44-modules/lib/modules/6.18.44
error: Cannot build '/nix/store/lcjl3hn7gwqq1ccyf8c68831xv1627b2-linux-armv6l-unknown-linux-gnueabihf-6.18.44-modules-shrunk.drv'.
       Reason: builder failed with exit code 1.
       Output paths:
         /nix/store/0g61pbg79h215az35bgyx15maid61kra-linux-armv6l-unknown-linux-gnueabihf-6.18.44-modules-shrunk
       Last 3 log lines:
       > kernel version is 6.18.44
       > root module: 3w-9xxx
       > modprobe: FATAL: Module 3w-9xxx not found in directory /nix/store/hhxblz9ja8hhzw2hwhmkmfsysmvhh1c1-linux-armv6l-unknown-linux-gnueabihf-6.18.44-modules/lib/modules/6.18.44
       For full logs, run:
         nix log /nix/store/lcjl3hn7gwqq1ccyf8c68831xv1627b2-linux-armv6l-unknown-linux-gnueabihf-6.18.44-modules-shrunk.drv
error: Cannot build '/nix/store/2yxwgxr673mcpb42ikhcs5xw6a83v3pl-initrd-linux-armv6l-unknown-linux-gnueabihf-6.18.44.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/98nb3gdpni1ibynpifzl0vv65ibmk3g0-initrd-linux-armv6l-unknown-linux-gnueabihf-6.18.44
error: Cannot build '/nix/store/ka8jr2pa310n90gpkg7wdmlsvzgq325n-nixos-system-rpi-zero-w-sd-card-26.11.20260816.e5bdc4a.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/0bayfvwqz258jj216z5bh7infblxgap5-nixos-system-rpi-zero-w-sd-card-26.11.20260816.e5bdc4a
error: Cannot build '/nix/store/qbrl1gbpspl0k7f92lxcdymhbhhv4f21-ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/jgllb5wzb455qvj5rr9dmg0s24ws16ad-ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf
❌ path:/home/user/git/luckydonald/raspberry-pi-zero-w-nixos#nixosConfigurations.rpi-zero-w.config.system.build.sdImage
error: Cannot build '/nix/store/x8vjhz4ix3xm0iqc7084ic1ixfdnj6q4-nixos-image-sd-card-26.11.20260816.e5bdc4a-armv6l-linux.img.zst-armv6l-unknown-linux-gnueabihf.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/v6z7z2bb726p37mk2c9dkb8kqiiqarl9-nixos-image-sd-card-26.11.20260816.e5bdc4a-armv6l-linux.img.zst-armv6l-unknown-linux-gnueabihf

[exited with code 1]
