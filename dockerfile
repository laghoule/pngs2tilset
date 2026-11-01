##############################
# Multi-arch: the builder stage always runs on the build host's platform and
# Zig cross-compiles to the target platform (musl statically linked), so no
# QEMU emulation is involved. A Windows cross-compile stage is added: an
# image cannot run Windows binaries, so they are shipped as artifacts instead.
#
# Container image (linux/amd64 + linux/arm64):
#   docker buildx build --platform linux/amd64,linux/arm64 .
# Extract binaries (current host platform + Windows .exe) into zig-out/:
#   docker buildx build --target artifacts -o type=local,dest=zig-out .
FROM --platform=$BUILDPLATFORM alpine:3.24 AS build

ARG ZIG_VERSION=0.17.0

RUN apk add --no-cache curl tar xz

# Map the Docker target platform to a Zig target triple (the builder stage
# builds for the *target* platform, not its own). Without buildx, fall back
# to the host machine name. A stage cannot create ARGs, so the triple is
# handed over through a file.
RUN echo "${TARGETPLATFORM:-$(uname -m)}" > /buildplatform \
    && case "$(cat /buildplatform)" in \
        *x86_64*|*amd64*)   ZIG_ARCH="x86_64";  ZIG_TARGET="x86_64-linux-musl"  ;; \
        *aarch64*|*arm64*)  ZIG_ARCH="aarch64"; ZIG_TARGET="aarch64-linux-musl" ;; \
        *) echo "unsupported platform: $(cat /buildplatform)" >&2; exit 1 ;; \
    esac \
    && curl -sSL "https://ziglang.org/download/${ZIG_VERSION}/zig-${ZIG_ARCH}-linux-${ZIG_VERSION}.tar.xz" \
        | tar -xJp -C /usr/local --strip-components=1 \
    && echo "${ZIG_TARGET}" > /zig-target \
    && zig version

WORKDIR /src

COPY . .

# build.zig.zon fetches zigimg on first build; both cache dirs are redirected
# to cache mounts so only the binary, not the cache, ends up in the layer.
RUN --mount=type=cache,target=/zig-cache \
    --mount=type=cache,target=/zig-global-cache \
    ZIG_GLOBAL_CACHE_DIR=/zig-global-cache \
    zig build --cache-dir /zig-cache -Dtarget="$(cat /zig-target)" \
        -Doptimize=ReleaseFast -p /out

# Windows artifact: cross-compiled the same way (Mingw support ships inside
# Zig; no cross toolchain to install). The artifact stage extracts it.
FROM build AS windows
RUN --mount=type=cache,target=/zig-cache \
    --mount=type=cache,target=/zig-global-cache \
    ZIG_GLOBAL_CACHE_DIR=/zig-global-cache \
    zig build --cache-dir /zig-cache -Dtarget=x86_64-windows-gnu \
        -Doptimize=ReleaseFast -p /out-w

##############################
# Artifacts stage: extract binaries with
#   docker buildx build --target artifacts -o type=local,dest=zig-out .
FROM scratch AS artifacts
COPY --link --from=build /out/bin/pngs2tileset /bin/pngs2tileset
COPY --link --from=windows /out-w/bin/pngs2tileset.exe /bin/pngs2tileset.exe

##############################
FROM scratch

ARG VERSION

LABEL org.opencontainers.image.title="pngs2tileset" \
    org.opencontainers.image.vendor="laghoule" \
    org.opencontainers.image.licenses="GPLv3" \
    org.opencontainers.image.version="${VERSION}" \
    org.opencontainers.image.description="Converts RGBA PNG tiles and a GIMP palette into a raw 8-bit tileset (.til) and an assembly include file for the mquest engine." \
    org.opencontainers.image.url="https://github.com/laghoule/pngs2tileset/blob/main/README.md" \
    org.opencontainers.image.source="https://github.com/laghoule/pngs2tileset" \
    org.opencontainers.image.documentation="https://github.com/laghoule/pngs2tileset/blob/main/README.md"

USER 65534

COPY --link --from=build /out/bin/pngs2tileset /bin/pngs2tileset

ENTRYPOINT ["/bin/pngs2tileset"]
