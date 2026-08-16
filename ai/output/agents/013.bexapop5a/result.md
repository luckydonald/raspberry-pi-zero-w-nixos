…
^^
device-tree-overlays>   File "/nix/store/6n167fwsadywrqia9h1sk864gg0sz9yn-apply_overlays.py", line 79, in process_dtb
device-tree-overlays>     dt = apply_overlay(dt, overlay.fdt)
device-tree-overlays>   File "/nix/store/6n167fwsadywrqia9h1sk864gg0sz9yn-apply_overlays.py", line 58, in apply_overlay
device-tree-overlays>     raise FdtException(err)
device-tree-overlays> libfdt.FdtException: pylibfdt error -1: FDT_ERR_NOTFOUND
linux-armv6l-unknown-linux-gnueabihf>   copying dependency: /nix/store/hhxblz9ja8hhzw2hwhmkmfsysmvhh1c1-linux-armv6l-unknown-linux-gnueabihf-6.18.44-modules/lib/modules/6.18.44/kernel/drivers/mmc/core/mmc_block.ko.xz
error: Cannot build '/nix/store/wyjk32ff6bsj9v48lnynjdj82kcpdcfg-device-tree-overlays.drv'.
       Reason: builder failed with exit code 1.
       Output paths:
         /nix/store/sn7z7l38di5k6bmgaz2ywf644zgsjy4m-device-tree-overlays
       Last 14 log lines:
       > Processing source device tree bcm2835-rpi-b.dtb...
       >   Applying overlay rpi-zero-w-i2c-spi
       > Traceback (most recent call last):
       >   File "/nix/store/6n167fwsadywrqia9h1sk864gg0sz9yn-apply_overlays.py", line 121, in <module>
       >     main()
       >     ~~~~^^
       >   File "/nix/store/6n167fwsadywrqia9h1sk864gg0sz9yn-apply_overlays.py", line 112, in main
       >     process_dtb(rel_path, source, destination, overlays_data)
       >     ~~~~~~~~~~~^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
       >   File "/nix/store/6n167fwsadywrqia9h1sk864gg0sz9yn-apply_overlays.py", line 79, in process_dtb
       >     dt = apply_overlay(dt, overlay.fdt)
       >   File "/nix/store/6n167fwsadywrqia9h1sk864gg0sz9yn-apply_overlays.py", line 58, in apply_overlay
       >     raise FdtException(err)
       > libfdt.FdtException: pylibfdt error -1: FDT_ERR_NOTFOUND
       For full logs, run:
         nix log /nix/store/wyjk32ff6bsj9v48lnynjdj82kcpdcfg-device-tree-overlays.drv
error: Cannot build '/nix/store/brhkg869iq0xcc5rw3mrjrknpmrbmh5p-nixos-system-rpi-zero-w-sd-card-26.11.20260816.e5bdc4a.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/38glxd4fyklvpgdqi98cppzavj4ay31s-nixos-system-rpi-zero-w-sd-card-26.11.20260816.e5bdc4a
error: Cannot build '/nix/store/7rariihiw63wk35c423ap9acbm77mljv-ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/97xfhxaalf34p71wychxhi2ic1jf5fcr-ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf
❌ path:/home/user/git/luckydonald/raspberry-pi-zero-w-nixos#nixosConfigurations.rpi-zero-w.config.system.build.sdImage
error: Cannot build '/nix/store/g7jmpcipq41wha4sfgrhgvl64yaqhhsf-nixos-image-sd-card-26.11.20260816.e5bdc4a-armv6l-linux.img.zst-armv6l-unknown-linux-gnueabihf.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/70dvy1v419hni994w0lmsydkd4kxjv7k-nixos-image-sd-card-26.11.20260816.e5bdc4a-armv6l-linux.img.zst-armv6l-unknown-linux-gnueabihf

[exited with code 1]
