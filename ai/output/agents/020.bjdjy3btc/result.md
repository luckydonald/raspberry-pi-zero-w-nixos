…
checking for library containing clock_gettime... none required
       > checking for library containing pow... -lm
       > checking for library containing pthread_create... none required
       > checking for alsa... yes
       > checking for bluez >= 5.51... yes
       > checking for dbus-1 >= 1.6... yes
       > checking for gio-unix-2.0... yes
       > checking for glib-2.0 >= 2.58.2... yes
       > checking for sbc >= 1.5... yes
       > checking for gdbus-codegen... /nix/store/lfrjb7zz2g8mkm1g1jjg2hxwd1crryf6-glib-2.88.3-dev/bin/gdbus-codegen
       > checking for libbsd >= 0.8... yes
       > checking for fdk-aac >= 0.1.1... yes
       > checking for systemd >= 200... no
       > configure: error: Package requirements (systemd >= 200) were not met:
       >
       > No package 'systemd' found
       >
       > Consider adjusting the PKG_CONFIG_PATH environment variable if you
       > installed software in a non-standard prefix.
       >
       > Alternatively, you may set the environment variables SYSTEMD_CFLAGS
       > and SYSTEMD_LIBS to avoid the need to call pkg-config.
       > See the pkg-config man page for more details.
       For full logs, run:
         nix log /nix/store/79nc6qf5wxj73ib0x29gyvnl67bp1p7i-bluez-alsa-armv6l-unknown-linux-gnueabihf-4.3.1.drv
error: Cannot build '/nix/store/bl5yy2wajmwgpfd09rb6c5bmr2njpq5l-unit-bluealsa.service.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/lsc10c3cy5bml5gb3pa2rsyrfhn59k6z-unit-bluealsa.service
error: Cannot build '/nix/store/i2kmsaaz4cdj3wnz02ps4lr89z562jgm-system-units.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/492plcn9y0ql4hjm7sjbknsmdzff7l3k-system-units
error: Cannot build '/nix/store/l6i96jww57wibpdppfh9hf1a827zzi0a-etc.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/9wwx3m3dq5mpvl1j5zsybafdnq5305ms-etc
error: Cannot build '/nix/store/gqfg2ap3xgskaglx0wkrra569dnfzqy2-nixos-system-rpi-zero-w-sd-card-26.11.20260816.e5bdc4a.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/923zg6bwx13mhl4rrrk5fmmsqk0k0cgc-nixos-system-rpi-zero-w-sd-card-26.11.20260816.e5bdc4a
error: Cannot build '/nix/store/27sx0mba3r5b6h74amnkvf1bfqaa1yxs-ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/8hk5qd0w6j4x5130ad5f5w8rc0826zgs-ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf
❌ path:/home/user/git/luckydonald/raspberry-pi-zero-w-nixos#nixosConfigurations.rpi-zero-w-radio.config.system.build.sdImage
error: Cannot build '/nix/store/0g6r66pbdz4pig8zqi0ww6irh6ps62aa-nixos-image-sd-card-26.11.20260816.e5bdc4a-armv6l-linux.img.zst-armv6l-unknown-linux-gnueabihf.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/ici2mpqpj8qc9fb4z5m87ygw9wx61dh5-nixos-image-sd-card-26.11.20260816.e5bdc4a-armv6l-linux.img.zst-armv6l-unknown-linux-gnueabihf

[exited with code 1]
