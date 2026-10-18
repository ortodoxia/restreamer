# syntax=docker/dockerfile:1.7
ARG GO_IMAGE=golang:1.26-alpine3.23@sha256:6750308561953d451210ed1a8086d36c8c8bdcbf672d38d9d0d424b8a7a0216c
ARG NODE_IMAGE=node:24-alpine3.23@sha256:e44c87c7dd212720eb00469aeac89504ca2be77b8f0d6dbffb30665d5fcc59e1
ARG ALPINE_IMAGE=alpine:3.23@sha256:85fe1e81d6758c208f3e1eed4338a1997e19d4be002d4dd32d3100c9a8c010a0

FROM --platform=$BUILDPLATFORM $GO_IMAGE AS core
WORKDIR /src
ADD --checksum=sha256:9310a796d1c378d3ded2a879e68d219f8a5dd7cdd35316280ea0f2238b768c0e https://codeload.github.com/datarhei/core/tar.gz/82047280aa76accb58ec24c44897b7084d299c8e /tmp/core.tar.gz
RUN tar -xzf /tmp/core.tar.gz --strip-components=1 && apk add --no-cache patch
COPY build/core/go.mod build/core/go.sum ./
COPY build/core/source.patch /tmp/source.patch
RUN patch -p1 < /tmp/source.patch
ARG TARGETOS TARGETARCH TARGETVARIANT
ENV CGO_ENABLED=0 GOFLAGS=-mod=readonly GOTOOLCHAIN=local
RUN --mount=type=cache,target=/go/pkg/mod --mount=type=cache,target=/root/.cache/go-build \
    export GOOS=$TARGETOS GOARCH=$TARGETARCH GOARM=${TARGETVARIANT#v}; \
    go build -trimpath -ldflags='-s -w -X github.com/datarhei/core/v16/app.Commit=82047280aa76accb58ec24c44897b7084d299c8e -X github.com/datarhei/core/v16/app.Branch=ortodoxia' -o /out/core . && \
    go build -trimpath -ldflags='-s -w' -o /out/import ./app/import && \
    go build -trimpath -ldflags='-s -w' -o /out/ffmigrate ./app/ffmigrate

FROM --platform=$BUILDPLATFORM $NODE_IMAGE AS ui
WORKDIR /ui
ADD --checksum=sha256:ae02a32bfac12d0ec2509c8faba2fdde0362d7f6f041e90b6af8b46051d9c23d https://codeload.github.com/datarhei/restreamer-ui/tar.gz/7164b38cb3a8655f7cd896e941093a1ca166b19b /tmp/ui.tar.gz
RUN tar -xzf /tmp/ui.tar.gz --strip-components=1 && rm public/index.html yarn.lock .yarnrc.yml
COPY build/ui/package.json build/ui/package-lock.json build/ui/vite.config.js build/ui/index.html ./
RUN --mount=type=cache,target=/root/.npm npm ci && npm audit --audit-level=high && npm run build

FROM $ALPINE_IMAGE AS ffmpeg-build
RUN apk upgrade --no-cache && apk add --no-cache build-base pkgconf nasm linux-headers patch xz \
    openssl-dev zlib-dev freetype-dev harfbuzz-dev libxml2-dev libsrt-dev \
    x264-dev x265-dev libvpx-dev lame-dev opus-dev libvorbis-dev \
    dav1d-dev rav1e-dev aom-dev libxcb-dev alsa-lib-dev v4l-utils-dev libva-dev
WORKDIR /src/ffmpeg
ADD --checksum=sha256:d4fcb164028dd3beee5d92c0ac72e46aac6973c75ea12dc14de07bf8f407370a https://ffmpeg.org/releases/ffmpeg-6.1.6.tar.xz /tmp/ffmpeg.tar.xz
ADD --checksum=sha256:64f48d749249b01e3ddf2d7979a8bd3c85c7e0a603462faf53dcab56f8461ea8 https://codeload.github.com/datarhei/ffmpeg/tar.gz/b37fc95733529ace2b0b617dea92b4593a9fb4dd /tmp/patches.tar.gz
ADD --checksum=sha256:2fefaa227d2a3b4170797796425a59d1dd2ed5fd231db9b4244468ba327acd0b https://codeload.github.com/FFmpeg/nv-codec-headers/tar.gz/refs/tags/n12.1.14.0 /tmp/nv-headers.tar.gz
COPY build/ffmpeg/source.patch /tmp/ffmpeg-source.patch
RUN tar -xJf /tmp/ffmpeg.tar.xz --strip-components=1 && \
    mkdir /patches && tar -xzf /tmp/patches.tar.gz -C /patches --strip-components=1 && \
    patch -p1 < /patches/contrib/ffmpeg-jsonstats.patch && \
    patch -p1 < /patches/contrib/ffmpeg-hls.patch && \
    patch -p1 < /tmp/ffmpeg-source.patch && \
    mkdir /nv-headers && tar -xzf /tmp/nv-headers.tar.gz -C /nv-headers --strip-components=1 && \
    make -C /nv-headers PREFIX=/usr install
RUN ./configure --prefix=/usr --extra-version=ortodoxia --enable-gpl --enable-version3 \
    --enable-openssl --enable-libxml2 --enable-libv4l2 --enable-vaapi \
    --enable-v4l2_m2m --enable-libfreetype --enable-libharfbuzz --enable-alsa \
    --enable-libsrt --enable-libx264 --enable-libx265 --enable-libvpx \
    --enable-libmp3lame --enable-libopus --enable-libvorbis \
    --enable-libdav1d --enable-librav1e --enable-libaom --enable-libxcb \
    --disable-ffplay --disable-debug --disable-doc --disable-shared && \
    make -j2 && make install

FROM $ALPINE_IMAGE AS runtime
RUN apk upgrade --no-cache && apk add --no-cache ca-certificates tzdata \
    openssl zlib freetype harfbuzz libxml2 libsrt x264-libs x265-libs libvpx \
    lame-libs opus libvorbis dav1d rav1e-libs aom-libs libxcb alsa-lib v4l-utils \
    libva mesa-va-gallium && \
    if [ "$(apk --print-arch)" = x86_64 ]; then \
      apk add --no-cache intel-media-driver libva-intel-driver; \
    fi
COPY --from=ffmpeg-build /usr/bin/ffmpeg /usr/bin/ffmpeg
COPY --from=ffmpeg-build /usr/bin/ffprobe /usr/bin/ffprobe
COPY --from=core /out/ /core/bin/
COPY --from=core /src/mime.types /core/mime.types
COPY --from=core /src/LICENSE /usr/share/licenses/restreamer-core/LICENSE
COPY --from=ui /ui/LICENSE /usr/share/licenses/restreamer-ui/LICENSE
COPY --from=ffmpeg-build /src/ffmpeg/COPYING.GPLv3 /usr/share/licenses/ffmpeg/COPYING.GPLv3
COPY --from=ffmpeg-build /tmp/ffmpeg.tar.xz /usr/share/restreamer/sources/ffmpeg-6.1.6.tar.xz
COPY --from=ffmpeg-build /tmp/patches.tar.gz /usr/share/restreamer/sources/datarhei-ffmpeg-patches.tar.gz
COPY --from=ffmpeg-build /tmp/nv-headers.tar.gz /usr/share/restreamer/sources/nv-codec-headers.tar.gz
COPY build/ffmpeg/source.patch Dockerfile /usr/share/restreamer/sources/
COPY --from=ui /ui/build /core/ui
COPY CHANGELOG.md /core/ui/CHANGELOG.md
COPY --chmod=755 run.sh /core/bin/run.sh
COPY ui-root /core/ui-root
RUN mkdir -p /core/config /core/data && ffmpeg -buildconf

ENV CORE_CONFIGFILE=/core/config/config.json \
    CORE_DB_DIR=/core/config \
    CORE_ROUTER_UI_PATH=/core/ui \
    CORE_STORAGE_DISK_DIR=/core/data
EXPOSE 8080/tcp
EXPOSE 8181/tcp
EXPOSE 1935/tcp
EXPOSE 1936/tcp
EXPOSE 6000/udp

VOLUME ["/core/data", "/core/config"]
ENTRYPOINT ["/core/bin/run.sh"]
WORKDIR /core
