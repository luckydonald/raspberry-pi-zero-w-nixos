…
.
ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf> Creating an EXT4 image of 2407559168 bytes (numInodes=144139, numDataBlocks=299505)
ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf> mke2fs 1.47.4 (6-Mar-2025)
ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf> Discarding device blocks:      0/588032             done
ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf> Creating filesystem with 588032 4k blocks and 147168 inodes
ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf> Filesystem UUID: 44444444-4444-4444-8888-888888888888
ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf> Superblock backups stored on blocks:
ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf>         32768, 98304, 163840, 229376, 294912
ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf> 
ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf> Allocating group tables:  0/18     done
ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf> Writing inode tables:  0/18     done
ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf> Creating journal (16384 blocks): done
ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf> 
ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf> 
ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf> 
error: Cannot build '/nix/store/zn45jskxkzdcmdycz848777winmpziny-ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf.drv'.
       Reason: builder failed with exit code 1.
       Output paths:
         /nix/store/zibv4lqbahxygxmxh3zrh1g1kd29bgqr-ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf
       Last 16 log lines:
       > /nix/store/xaic0pyy6hv6922ygp5wc3l9g8dlng88-extlinux-conf-builder.sh: line 145: cd: /nix/var/nix/profiles: No such file or directory
       > Preparing store paths for image...
       > Creating an EXT4 image of 2407559168 bytes (numInodes=144139, numDataBlocks=299505)
       > mke2fs 1.47.4 (6-Mar-2025)
       > Discarding device blocks:      0/588032             done
       > Creating filesystem with 588032 4k blocks and 147168 inodes
       > Filesystem UUID: 44444444-4444-4444-8888-888888888888
       > Superblock backups stored on blocks:
       >     32768, 98304, 163840, 229376, 294912
       >
       > Allocating group tables:  0/18     done
       > Writing inode tables:  0/18     done
       > Creating journal (16384 blocks): done
       >
       >
       >
       For full logs, run:
         nix log /nix/store/zn45jskxkzdcmdycz848777winmpziny-ext4-fs.img.zst-armv6l-unknown-linux-gnueabihf.drv
❌ path:/home/user/git/luckydonald/raspberry-pi-zero-w-nixos#nixosConfigurations.rpi-zero-w.config.system.build.sdImage
error: Cannot build '/nix/store/ai52j325ldmhwvf9lwi4lk8bj60hyzc5-nixos-image-sd-card-26.11.20260816.e5bdc4a-armv6l-linux.img.zst-armv6l-unknown-linux-gnueabihf.drv'.
       Reason: 1 dependency failed.
       Output paths:
         /nix/store/b0wgfc7wf1a9gjxxdf2h7dyn5qk1q722-nixos-image-sd-card-26.11.20260816.e5bdc4a-armv6l-linux.img.zst-armv6l-unknown-linux-gnueabihf

[exited with code 1]
