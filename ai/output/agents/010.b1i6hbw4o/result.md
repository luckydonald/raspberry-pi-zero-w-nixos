…
c14284484-extern.o): in function `atomic64_try_cmpxchg_acquire':
       >           /build/source/include/linux/atomic.h:302:(.text.atomic64_try_cmpxchg_acquire__extern+0x58): undefined reference to `__atomic_compare_exchange_8'
       >           /nix/store/cnijyfg11hc3n2f3b6q15h4v7p6zqy10-armv6l-unknown-linux-gnueabihf-binutils-2.46/bin/armv6l-unknown-linux-gnueabihf-ld.bfd: /build/source/target/arm-unknown-linux-gnueabihf/release/deps/libbcachefs_shim-8ccb411ac3ef7958.rlib(574793fc14284484-extern.o): in function `atomic64_try_cmpxchg_release':
       >           /build/source/include/linux/atomic.h:302:(.text.atomic64_try_cmpxchg_release__extern+0x58): undefined reference to `__atomic_compare_exchange_8'
       >           collect2: error: ld returned 1 exit status
       >
       >   = note: some `extern` functions couldn't be found; some native libraries may need to be installed or have their path specified
       >   = note: use the `-l` flag to specify native libraries to link
       >   = note: use the `cargo:rustc-link-lib` directive to specify the native libraries to link with Cargo (see https://doc.rust-lang.org/cargo/reference/build-scripts.html#rustc-link-lib)
       >
       > error: could not compile `bcachefs-tools` (bin "bcachefs") due to 1 previous error
       > make: *** [Makefile:274: bcachefs] Error 101
       For full logs, run:
         nix log /nix/store/vsy8ab2cgslljjqswhfrfyln7ib6m08h-bcachefs-tools-armv6l-unknown-linux-gnueabihf-1.39.1.drv
error: Cannot build '/nix/store/9ajbbbpl9iwshkd61vh8a9qv9i6blv0r-nixos-generate-config.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/44yc6pv1z3w38d3y54lkb25dbiwsx0my-nixos-generate-config
error: Cannot build '/nix/store/1ay5mjzhx20llfjhq3rxqvs2qk9h6ma7-system-path.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/bhxv31hc954702m6w63mpwpzk8zqgmx5-system-path
error: Cannot build '/nix/store/7qvh0zabba1j0qwygarzybh0ldf1ys7j-nixos-system-rpi-zero-w-sd-card-26.11.20260816.e5bdc4a.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/dqh5hv6frkr2x424rk0gdyw6l9iz490r-nixos-system-rpi-zero-w-sd-card-26.11.20260816.e5bdc4a
error: Cannot build '/nix/store/23mkh5j8d0hlmc6fngn1scw9aiqn08np-ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/gpxhnsdch4dwqf8frcm5n66cyl9n1kzw-ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf
❌ path:/home/user/git/luckydonald/raspberry-pi-zero-w-nixos#nixosConfigurations.rpi-zero-w.config.system.build.sdImage
error: Cannot build '/nix/store/zgn80mr755hcxffdb7a2xyxvz3pb0qpw-nixos-image-sd-card-26.11.20260816.e5bdc4a-armv6l-linux.img.zst-armv6l-unknown-linux-gnueabihf.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/jnlfdrz7wb2s4xgb6b4hph0kys3iy0al-nixos-image-sd-card-26.11.20260816.e5bdc4a-armv6l-linux.img.zst-armv6l-unknown-linux-gnueabihf

[exited with code 0]
