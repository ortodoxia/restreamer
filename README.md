<h1 align="center">Restreamer</h1>
<h3 align="center">A really nice and free alternative for handling live streams.</h3>
<p align="center">
<a href="https://github.com/ortodoxia/restreamer/blob/2.x/LICENSE" target="_blank"><img src="https://img.shields.io/github/license/ortodoxia/restreamer" alt="License" /></a>
<a href="https://github.com/ortodoxia/restreamer/actions/workflows/build_bundle.yaml" target="_blank"><img src="https://github.com/ortodoxia/restreamer/actions/workflows/build_bundle.yaml/badge.svg" alt="Build and publish" /></a>
<a href="https://github.com/ortodoxia/restreamer/pkgs/container/restreamer" target="_blank">GitHub Container Registry</a>
<a href="https://docs.datarhei.com/restreamer/getting-started/quick-start" target="_blank"><img src="https://img.shields.io/badge/documentation-get%20started-green" alt="Documentation" /></a>
</p>
<p align="center"><a href="https://demo.datarhei.com/ui" target="_blank">Try live demo</a><br />
<a href="https://demo.datarhei.com/ui" target="_blank"><img src="https://img.shields.io/badge/username-admin-blue" alt="demo username" /></a>
<a href="https://demo.datarhei.com/ui" target="_blank"><img src="https://img.shields.io/badge/password-demo-blue" alt="demo password" /></a>

<p align="center">
  <a href="https://datarhei.com">
    <img src="https://github.com/datarhei/restreamer/blob/2.x/readme-promo.gif" alt="Restreamer Promo Video" />
  </a>
</p>

<p align="center">Self-hosting solution to stream live to your website and publish to many like YouTube-Live, Twitter, Twitch, Vimeo, and other platforms or services. Our Docker-Image is easy to install and runs on Linux environments (MacOS/Windows by Docker Desktop). Moreover, combine the Restreamer with single-board computers like Raspberry Pi or GPU powered systems for Video-Encoding.</p>
<br />
<hr />

## Features

- Simplified User-Interface
- Easy wizard configuration
- Multiple audio/video inputs, outputs, protocols, and codecs
- ReStreaming to platforms such as YouTube-Live, to software such as Wowza Media Server, and others based on protocols such as RTMP, SRT, ...
- Option to mux a separate audio channel to the video
- Build-in VideoJS-Player for your Website
- Configurable publication website for streaming without player embedding
- Content license with Creative Commons
- HTTP/S- (HLS), RTMP/S- & SRT-Streaming Server
- Automatic Let's Encrypt HTTPS certification
- Viewer/Bandwidth Monitoring and limiting
- Raspberry Pi (MMAL/OMX), Nvidia Cuda, Intel VAAPI support
- Support for Hardware- and Virtual-Devices
- FFmpeg Video-Processing (as native as possible)
- REST-API (JSON) and 100% Swagger documented
- Resource Monitoring (optionally by Prom-Metrics)
- Server- and Process-Logging
- GDPR compliant without third-party providers and does not save audience data

## Quick setup

### AMD64/ARMv7/ARM64:
```sh
docker run -d --restart=always --name restreamer \
   -v /opt/restreamer/config:/core/config -v /opt/restreamer/data:/core/data \
   -p 8080:8080 -p 8181:8181 \
   -p 1935:1935 -p 1936:1936 \
   -p 6000:6000/udp \
   ghcr.io/ortodoxia/restreamer:latest
```

*`--privileged` just for local devices like usb cameras.*    
*Try `--security-opt seccomp=unconfined` if no network source can be reached.*

### ARMv7/ARM64 Raspberry Pi:
```sh
docker run -d --restart=always --name restreamer \
   -v /opt/restreamer/config:/core/config -v /opt/restreamer/data:/core/data \
   --privileged \
   -p 8080:8080 -p 8181:8181 \
   -p 1935:1935 -p 1936:1936 \
   -p 6000:6000/udp \
   ghcr.io/ortodoxia/restreamer:latest
```

*`--privileged` just for local devices like usb cameras.*    
*Try `--security-opt seccomp=unconfined` if no network source can be reached.*

### AMD64 Nvidia NVENC/CUVID:
```sh
docker run -d --restart=always --name restreamer \
   -v /opt/restreamer/config:/core/config -v /opt/restreamer/data:/core/data \
   --gpus all \
   -p 8080:8080 -p 8181:8181 \
   -p 1935:1935 -p 1936:1936 \
   -p 6000:6000/udp \
   ghcr.io/ortodoxia/restreamer:latest
```

*`--privileged` just for local devices like usb cameras.*    
*Try `--security-opt seccomp=unconfined` if no network source can be reached.*

### AMD64 Intel VAAPI:
```sh
docker run -d --restart=always --name restreamer \
   -v /opt/restreamer/config:/core/config -v /opt/restreamer/data:/core/data \
   --device /dev/dri:/dev/dri \
   -p 8080:8080 -p 8181:8181 \
   -p 1935:1935 -p 1936:1936 \
   -p 6000:6000/udp \
   ghcr.io/ortodoxia/restreamer:latest
```

*`--privileged` just for local devices like usb cameras.*    
*Try `--security-opt seccomp=unconfined` if no network source can be reached.*

*For external access (http/s, rtmp/s, srt), port forwarding from your Internet-Router to the Restreamer's internal IP address may need to be set up.*

This fork publishes one multi-platform image for AMD64, ARM64, and ARMv7; the old `rpi-`, `cuda-`, and `vaapi-` tags are not published. Raspberry Pi uses V4L2 M2M rather than legacy MMAL/OMX. Nvidia requires the NVIDIA Container Toolkit and Linux driver 530.41.03 or newer; CUDA/NPP filter libraries are not bundled. Hardware encoding must be verified on the target machine.

Back up both persistent volumes before replacing an existing image. FFmpeg stays on the compatible 6.1 branch, patched to 6.1.6. FDK-AAC is excluded because it makes the GPL FFmpeg binary unredistributable; use native `aac` for any existing process configured with `libfdk_aac`.


## Documentation

Documentation is available on [docs.datarhei.com/restreamer](https://docs.datarhei.com/restreamer). We give many pieces of information, from setting up a camera, embedding your player upon your website, and streaming to services like, e.g., YouTube-Live, and many more.

- [Quick start](https://docs.datarhei.com/restreamer/getting-started/quick-start)
- [Installation](https://docs.datarhei.com/restreamer/installing/minimum-requirements)
- [Manual](https://docs.datarhei.com/restreamer/knowledge-base/manual)
- [Guides](https://docs.datarhei.com/restreamer/knowledge-base/user-guides)

## Development

### Build the patched image

```sh
git clone https://github.com/ortodoxia/restreamer.git
cd restreamer
docker buildx build --load -t restreamer:local .
python3 build/smoke.py restreamer:local
docker run --rm -p 8080:8080 restreamer:local
```

The Dockerfile builds pinned upstream Core and UI source with the dependency locks and compatibility patches in `build/core` and `build/ui`. It uses Go 1.26.9, Node 24, Vite instead of Create React App, and a supported Alpine 3.23 runtime. Source downloads are SHA-256 checked; builder/base images are digest-pinned. Upstream's outdated Go vendor directory is not used. FFmpeg 6.1.6 retains datarhei's progress and HLS patches and uses package-managed codec libraries.

### Publish to GHCR

Push to `2.x`, push a `v*` tag, or dispatch **Build and publish patched Restreamer** on `2.x`. The weekly schedule rebuilds OS packages and audits the image. Pull requests build and verify without publishing. No Docker Hub credentials are required: publishing uses `GITHUB_TOKEN` with job-scoped `packages: write`.

Each architecture must pass a real container smoke run and Trivy's high/critical vulnerability gate for the image and Go/npm locks (including build tools). The smoke covers authentication, token refresh separation, UI assets, H.264/AAC HLS output, progress, and persisted stream restart. Only those exact verified image artifacts are pushed; the final manifest receives `latest`, `sha-<full-commit>`, and release tags. Audit reports and CycloneDX SBOMs are attached as workflow artifacts. Dependabot checks Actions, base images, Go, and npm weekly.

After the first successful publish, set the GHCR package visibility to **Public** for anonymous pulls, or authenticate with a token that has `read:packages`. GitHub organization package/Actions policies must allow publication. For production, deploy the image by digest rather than a mutable tag.

### Dependency maintenance limits

The legacy `@mui/styles` JSS layer is retained to avoid an unrelated visual rewrite; migrating it is separate from security patching. Lingui 4's build-time `lodash.get` dependency is still deprecated. A module-level OpenPGP advisory can appear against `golang.org/x/crypto`; `govulncheck` found no affected imported package or called symbol in the patched build. Neither this nor a clean vulnerability scan is a full application security audit.

### Facebook connector scope

`src/views/Publication/Services/Facebook.js` in the pinned UI is a manual RTMPS publisher, not a Facebook Graph API client. It accepts primary/backup stream keys, uses a fixed `live-api-s.facebook.com` ingest host, and requires H.264/AAC in FLV. Create/manage the broadcast in Facebook Live Producer; the channel's local title and description are not sent to Facebook.

Compared with Meta's [Live Video API](https://developers.facebook.com/documentation/live-video-api), it has no OAuth/Page selection, `live_videos` creation, scheduling/preview lifecycle, remote broadcast status/errors, token renewal, crossposting, or audience interactions. Its backup checkbox starts a second local output but does not enable Facebook backup ingest; that must already be configured in Live Producer or through `enable_backup_ingest=true` / `input_streams`. See Meta's [backup guide](https://developers.facebook.com/documentation/live-video-api/backup_stream).

Meta returns complete primary/backup RTMPS URLs and these can have different hosts. The connector cannot accept those URLs directly; use the generic RTMP publication service when an ingest URL differs from its fixed host. Do not paste a full RTMPS URL into the stream-key field. Keys are shown as ordinary text, so avoid screenshots or sharing configurations containing them.

The connector filters codecs/protocols but does not enforce Meta's [encoding settings](https://developers.facebook.com/documentation/live-video-api/reference): audio plus video, a recommended 2-second GOP (maximum 4), H.264 level/resolution/frame-rate limits, AAC-LC stereo at 44.1/48 kHz, and the 8-hour broadcast limit. Configure the encoding profile accordingly; matching H.264/AAC alone is insufficient. A full API integration needs a reviewed Meta app, appropriate User/Page permissions, and secure server-side token handling. This audit did not call authenticated Facebook APIs or publish a live broadcast.

### To add/fix translations in the [Restreamer interface](https://github.com/datarhei/restreamer-ui):

The Restreamer interface is currently translated in different languages, such as German, French, Italian, Spanish, and more. If you find errors in the translations or have better suggestions for some sentences, you can become a translation contributor on [poeditor.com](https://poeditor.com/join/project/ogATl3F48K).
There you can also start a translation into a language that is not yet available in the Restreamer interface.

Contribute to the translations on: [https://poeditor.com/join/project/ogATl3F48K](https://poeditor.com/join/project/ogATl3F48K)

## Community support

For general help using Restreamer, please refer to the official [documentation](https://docs.datarhei.com/restreamer). For additional support, you can use Github to ask a question (Bug reports, Contributions, Features).

## License
See the [LICENSE](./LICENSE) file for licensing information.

The container also contains FFmpeg under GPL-3.0-or-later. Its source archive, datarhei patches, local compatibility patch, codec headers, and build recipe are included in `/usr/share/restreamer/sources`; license notices are in `/usr/share/licenses`. Codec libraries come from Alpine packages. Preserve applicable notices and corresponding-source obligations when redistributing the image.

## Business inquiries
**We provide support for commercial requirements with professional support, agile software development, and consulting.** If you have a commercial request, be it a bug or a feature enhancement, please contact us directly at support@datarhei.com.
