# dlditool-docker
dlditool in Docker, to patch NDS ROMs with DLDI drivers so they can use the FAT library, with the patch used by the
course (`mpcf.dldi`). It is used by the `bmde patch` command of [bmde](https://github.com/URV-teacher/bmde), but can be
used on its own:

```shell
docker run --rm -v "$PWD:/input" aleixmt/dlditool mpcf.dldi program.nds
```

## Build and installation
`scripts/download_assets.sh` downloads dlditool and `mpcf.dldi` into `assets/`, and builds the ROM used by the test (the
`libfatdir` example of devkitPro) with the local devkitARM if there is one, or else with the devkitARM image
(`aleixmt/devkitarm-nds`, see [devkitarm-nds-docker](https://github.com/URV-teacher/devkitarm-nds-docker)). Every asset is
checked against its SHA-256 (see [external
resources](https://github.com/URV-teacher/bmde/blob/master/docs/development/external-resources.md) of bmde).

Then `src/install_dlditool.sh` installs dlditool and `mpcf.dldi` into `/URV/bmde/dlditool`, with its environment
(`PATH`) in `/etc/profile.d/bmde-dlditool.sh`, taking the files only from `src/` and `assets/`. The image is built with
it, and it installs dlditool in an Ubuntu / Debian host too. Test the installation with `test/test_dlditool.sh`, which
patches the `libfatdir` ROM. To build the image:

```shell
scripts/download_assets.sh  # The image is built from the assets
docker build -t aleixmt/dlditool .
```
