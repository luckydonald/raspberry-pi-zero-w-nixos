…
d with exit code 2.
       Output paths:
         /nix/store/nin3jaynvlgncif8g49awgas80hdz8va-linux-rpi-armv6l-unknown-linux-gnueabihf-6.12.75-1+rpt1
         /nix/store/pk43gwza0bc6g2mgwkhdidy85639fc1z-linux-rpi-armv6l-unknown-linux-gnueabihf-6.12.75-1+rpt1-dev
         /nix/store/qdhdv6biwwd4746w14yrc6asiwmsk2rk-linux-rpi-armv6l-unknown-linux-gnueabihf-6.12.75-1+rpt1-modules
       Last 25 log lines:
       >   CC [M]  drivers/iio/adc/ti-lmp92064.o
       >   CC [M]  drivers/iio/adc/ti-tlc4541.o
       >   CC [M]  drivers/iio/light/vl6180.o
       >   CC [M]  drivers/iio/adc/ti-tsc2046.o
       >   CC [M]  drivers/iio/light/zopt2201.o
       >   CC [M]  drivers/iio/adc/vf610_adc.o
       >   CC [M]  drivers/iio/adc/viperboard_adc.o
       >   CC [M]  drivers/iio/adc/xilinx-xadc-core.o
       >   CC [M]  drivers/iio/adc/xilinx-xadc-events.o
       >   LD [M]  fs/xfs/xfs.o
       >   LD [M]  drivers/iio/adc/xilinx-xadc.o
       >   AR      built-in.a
       >   AR      vmlinux.a
       >   LD      vmlinux.o
       >   OBJCOPY modules.builtin.modinfo
       >   GEN     modules.builtin
       >   GEN     .vmlinux.objs
       >   MODPOST Module.symvers
       > ERROR: modpost: "__aeabi_uldivmod" [drivers/pwm/pwm-rp1.ko] undefined!
       > ERROR: modpost: "__aeabi_uldivmod" [drivers/i2c/busses/i2c-designware-core.ko] undefined!
       > ERROR: modpost: "__aeabi_uldivmod" [drivers/media/platform/raspberrypi/rp1_cfe/rp1-cfe.ko] undefined!
       > ERROR: modpost: "__aeabi_ldivmod" [drivers/media/platform/raspberrypi/rp1_cfe/rp1-cfe.ko] undefined!
       > make[2]: *** [../scripts/Makefile.modpost:145: Module.symvers] Error 1
       > make[1]: *** [/build/source/Makefile:1906: modpost] Error 2
       > make: *** [../Makefile:224: __sub-make] Error 2
       For full logs, run:
         nix log /nix/store/rnq2p5g9k6vbjbgj15kjgws1kzbf28hh-linux-rpi-armv6l-unknown-linux-gnueabihf-6.12.75-1+rpt1.drv
error: Cannot build '/nix/store/p573gfaac5m6lbz20jfjmxxc97jzlglr-nixos-system-rpi-zero-w-sd-card-26.11.20260816.e5bdc4a.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/76n1gimxqnmfydm3bv6h2by5a1b3m6il-nixos-system-rpi-zero-w-sd-card-26.11.20260816.e5bdc4a
error: Cannot build '/nix/store/p1bm53vlkn6mmp5dkcirm2488zs0500q-ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/ki969lg0wxmrdi7mb5wjwx53nsh4kr2l-ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf
❌ path:/home/user/git/luckydonald/raspberry-pi-zero-w-nixos#nixosConfigurations.rpi-zero-w.config.system.build.sdImage
error: Cannot build '/nix/store/bnj8ymw4fa7bxffizbpy97akz93c229j-nixos-image-sd-card-26.11.20260816.e5bdc4a-armv6l-linux.img.zst-armv6l-unknown-linux-gnueabihf.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/cmwg1yr974z0qccz8zbbn3p5hprsbh2q-nixos-image-sd-card-26.11.20260816.e5bdc4a-armv6l-linux.img.zst-armv6l-unknown-linux-gnueabihf

[exited with code 1]
