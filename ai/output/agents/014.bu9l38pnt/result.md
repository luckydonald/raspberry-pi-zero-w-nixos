…
j9p3xfb0r78zc-linux-armv6l-unknown-linux-gnueabihf-6.18.44-modules-shrunk.drv'.
       Reason: builder failed with exit code 1.
       Output paths:
         /nix/store/gqmwpj3489xda1xf1xmqfp53g2cflxpz-linux-armv6l-unknown-linux-gnueabihf-6.18.44-modules-shrunk
       Last 14 log lines:
       > kernel version is 6.18.44
       > root module: autofs
       >   copying dependency: /nix/store/hhxblz9ja8hhzw2hwhmkmfsysmvhh1c1-linux-armv6l-unknown-linux-gnueabihf-6.18.44-modules/lib/modules/6.18.44/kernel/fs/autofs/autofs4.ko.xz
       > root module: efivarfs
       >   copying dependency: /nix/store/hhxblz9ja8hhzw2hwhmkmfsysmvhh1c1-linux-armv6l-unknown-linux-gnueabihf-6.18.44-modules/lib/modules/6.18.44/kernel/fs/efivarfs/efivarfs.ko.xz
       > root module: ext2
       >   builtin dependency: ext2
       > root module: ext4
       >   builtin dependency: ext4
       > root module: mmc_block
       >   copying dependency: /nix/store/hhxblz9ja8hhzw2hwhmkmfsysmvhh1c1-linux-armv6l-unknown-linux-gnueabihf-6.18.44-modules/lib/modules/6.18.44/kernel/drivers/misc/rpmb-core.ko.xz
       >   copying dependency: /nix/store/hhxblz9ja8hhzw2hwhmkmfsysmvhh1c1-linux-armv6l-unknown-linux-gnueabihf-6.18.44-modules/lib/modules/6.18.44/kernel/drivers/mmc/core/mmc_block.ko.xz
       > root module: tpm-crb
       > modprobe: FATAL: Module tpm-crb not found in directory /nix/store/hhxblz9ja8hhzw2hwhmkmfsysmvhh1c1-linux-armv6l-unknown-linux-gnueabihf-6.18.44-modules/lib/modules/6.18.44
       For full logs, run:
         nix log /nix/store/sxc2wb4zqap8j62zrn2j9p3xfb0r78zc-linux-armv6l-unknown-linux-gnueabihf-6.18.44-modules-shrunk.drv
error: Cannot build '/nix/store/rn2vavk432wipsc6y1pw5b8f564bijxn-initrd-linux-armv6l-unknown-linux-gnueabihf-6.18.44.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/9pw6ndhcpmhrx2gi6s83srqagn4hcv5h-initrd-linux-armv6l-unknown-linux-gnueabihf-6.18.44
error: Cannot build '/nix/store/58k4pnak9i444pi6gxjgf2y9i8hsyxrm-nixos-system-rpi-zero-w-sd-card-26.11.20260816.e5bdc4a.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/mjfqwzibzwbqza47193d8az75vd279bi-nixos-system-rpi-zero-w-sd-card-26.11.20260816.e5bdc4a
error: Cannot build '/nix/store/nyyf4l3kzvwgacc2ch8jy1ik332s7bvb-ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/yrdchz7w2sx683sxc478wf5ll8xz0mmz-ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf
❌ path:/home/user/git/luckydonald/raspberry-pi-zero-w-nixos#nixosConfigurations.rpi-zero-w.config.system.build.sdImage
error: Cannot build '/nix/store/z1izja8hb4vrffs3fpmpixw38h9x1m7c-nixos-image-sd-card-26.11.20260816.e5bdc4a-armv6l-linux.img.zst-armv6l-unknown-linux-gnueabihf.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/hssg7b3mj20c7mvlb1374y5b3nlazgqb-nixos-image-sd-card-26.11.20260816.e5bdc4a-armv6l-linux.img.zst-armv6l-unknown-linux-gnueabihf

[exited with code 1]
