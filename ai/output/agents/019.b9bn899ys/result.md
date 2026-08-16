…
      > checking how to hardcode library paths into programs... immediate
       > checking whether stripping libraries is possible... yes
       > checking if libtool supports shared libraries... yes
       > checking whether to build shared libraries... yes
       > checking whether to build static libraries... no
       > checking pkg-config m4 macros... yes
       > checking pkg-config is at least version 0.9.0... yes
       > checking for execinfo.h... yes
       > checking for stdatomic.h... yes
       > checking for eventfd... yes
       > checking for pipe2... yes
       > checking for splice... yes
       > checking for library containing clock_gettime... none required
       > checking for library containing pow... -lm
       > checking for library containing pthread_create... none required
       > checking for alsa... yes
       > checking for bluez >= 5.51... yes
       > checking for dbus-1 >= 1.6... yes
       > checking for gio-unix-2.0... yes
       > checking for glib-2.0 >= 2.58.2... yes
       > checking for sbc >= 1.5... yes
       > checking for gdbus-codegen... no
       > configure: error: gdbus-codegen not found
       For full logs, run:
         nix log /nix/store/61w2bsjx0xfn4lcis3rrxcz8x7vvrxra-bluez-alsa-armv6l-unknown-linux-gnueabihf-4.3.1.drv
error: Cannot build '/nix/store/lmav8y6prhv9hrfz3m9885q6kfnj4693-unit-bluealsa.service.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/sacdp504lbh6wy155sp3v7k74plbxf28-unit-bluealsa.service
error: Cannot build '/nix/store/g55q3y6ngw670nyh4qpslk1x5wwhx84l-system-units.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/b0rnfzz03mgwjn6zjqsq6nicb25gks0m-system-units
error: Cannot build '/nix/store/b7dnsdw4mcv5jpkg08a94f6phj5pyk9w-etc.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/gajqwfvfpihc7if2nh77c3m8k8rb0xqf-etc
error: Cannot build '/nix/store/8ylmrcqbppvmr6javyl1n2w804ig7s54-nixos-system-rpi-zero-w-sd-card-26.11.20260816.e5bdc4a.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/zgcx721zq2pld4jgv324mclzm7vn9m2w-nixos-system-rpi-zero-w-sd-card-26.11.20260816.e5bdc4a
error: Cannot build '/nix/store/5x1y91605ixzqixc5d1gc6xavn3z3zki-ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/f3kxrhhxi9pk3aizz0ih4kamxs04hpdd-ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf
❌ path:/home/user/git/luckydonald/raspberry-pi-zero-w-nixos#nixosConfigurations.rpi-zero-w-radio.config.system.build.sdImage
error: Cannot build '/nix/store/plvizzv1b7app4hqxl06dnpdm435m5v7-nixos-image-sd-card-26.11.20260816.e5bdc4a-armv6l-linux.img.zst-armv6l-unknown-linux-gnueabihf.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/nslcpdi3lrw6g2wjk7c7r503fgvxjizd-nixos-image-sd-card-26.11.20260816.e5bdc4a-armv6l-linux.img.zst-armv6l-unknown-linux-gnueabihf

[exited with code 1]
