# dlditool, to patch NDS ROMs with DLDI drivers. The installation is done by the scripts in scripts/, the same ones used
# to install it in a host (see README.md).
# Base image of the BMDE images (docker-bake.hcl of bmde replaces this stage by the base image being built)
FROM aleixmt/bmde-base:latest AS bmde-base

FROM bmde-base

RUN --mount=type=bind,target=/component \
    /component/scripts/install_dlditool.sh \
    && rm -rf /var/lib/apt/lists/*

# Directory where the ROMs to patch are mounted
RUN mkdir -p /input
WORKDIR /input

ENTRYPOINT ["bmde-exec", "dlditool"]
CMD []
