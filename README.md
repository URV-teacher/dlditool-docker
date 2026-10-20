# dlditool-docker
dlditool in Docker, to patch NDS ROMs with DLDI drivers so they can use the FAT library, with the patch used by the
course (`mpcf.dldi`). It is used by the `bmde patch` command of [bmde](https://github.com/URV-teacher/bmde), but can be
used on its own:

```shell
docker run --rm -v "$PWD:/input" aleixmt/dlditool mpcf.dldi program.nds
```

## Build and installation
`scripts/install_dlditool.sh` installs dlditool and `mpcf.dldi` into `/URV/bmde/dlditool`, with its environment (`PATH`)
in `/etc/profile.d/bmde-dlditool.sh`. The image is built with it, and it installs dlditool in an Ubuntu / Debian host
too. Test the installation with `scripts/test_dlditool.sh`, which patches the `libfatdir` example of devkitPro. It
builds the example with the local devkitARM if there is one, or else with the devkitARM image (`aleixmt/bmde-linux`, see
[devkitarm-nds-docker](https://github.com/URV-teacher/devkitarm-nds-docker)); set `LIBFATDIR_NDS` to use an already
built ROM instead. To build the image:

```shell
docker build -t aleixmt/dlditool .
```
