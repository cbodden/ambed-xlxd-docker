# AMBEd / XLXd docker images

Docker images for the [LX3JL/xlxd](https://github.com/LX3JL/xlxd) XLX multiprotocol reflector (`xlxd`) and its AMBE transcoder (`ambed`), built for x86_64 and ARM64.


## Images

| Service | Docker Hub | GHCR | Architectures | Base Image |
| :------ | :--------- | :--- | :------------ | :--------- |
| AMBEd   | [cbodden/ambed-docker](https://hub.docker.com/r/cbodden/ambed-docker/tags) | `ghcr.io/cbodden/ambed-docker` | x86_64, ARM64/v8 | Ubuntu Latest |
| XLXd    | [cbodden/xlxd-docker](https://hub.docker.com/r/cbodden/xlxd-docker/tags)   | `ghcr.io/cbodden/xlxd-docker`  | x86_64, ARM64/v8 | Alpine Latest |

| Tag | Built from |
| :-- | :--------- |
| `latest` | `main` branch (also rebuilt weekly for base image updates) |
| `test`   | `testing` branch |
| `X.Y.Z`, `X.Y.Z-N` | `vX.Y.Z` / `vX.Y.Z-N` git tags - fixed, never move, use these to roll back |


### Versions
- AMBEd: 1.4.0
- XLXd: 2.6.1
- Dashboard: 2.4.7 (upstream `dashboard1`)
- FTDI D2XX: 1.4.33
- S6 Overlay: 3.2.1.0
- Alpine: Latest
- Ubuntu: Latest

Both images build from the same pinned upstream commit, `ARG XLXD_GIT_REF` in `AMBEd/Dockerfile` and `XLXd/Dockerfile`, so rebuilds are reproducible and upstream changes only come in on purpose (see [Upgrading](#upgrading)).


## AMBEd hardware

FTDI testing done with:
- 2 x DVSI AMBE3000
- 1 x DVMEGA DVstick 33
```
Starting AMBEd 1.4.0

Initializing vocodecs:
Detected 3 USB-FTDI devices

Description : ThumbDV	 Serial : D30CDTY5
Description : DVstick-33	 Serial : DOATDZAD
Description : ThumbDV	 Serial : D30CBZH8

Opening ThumbDV:D30CDTY5 device
ReadDeviceVersion : AMBE3000R V120.E100.XXXX.C106.G514.R009.B0010411.C0020208

Opening ThumbDV:D30CBZH8 device
ReadDeviceVersion : AMBE3000R V120.E100.XXXX.C106.G514.R009.B0010411.C0020208

Opening DVstick-33:DOATDZAD device
Trying DF2ET-3003 soft reset
DF2ET-3003 soft reset succeeded
ReadDeviceVersion : AMBE3003F V120.E100.XXXX.C106.G514.R008.A0030608.C0020208

Codec interfaces initialized successfully : 4 channels available

Software vocoders : 2 IMBE (P25), 2 Codec2 (M17)

Initializing controller

Max concurrent streams: 2 (from 4 vocoder channels)

AMBEd started and listening on 0.0.0.0
```

AMBEd 1.4.0 also includes software IMBE (P25) and Codec2 (M17) vocoders, so P25 and M17 transcoding work alongside the DVSI hardware.


## Usage

A full example is in [`docker-compose-ambed_xlxd.yml`](./docker-compose-ambed_xlxd.yml).

### 1. Host setup for AMBEd

AMBEd talks to the sticks through the FTDI D2XX library, so the kernel serial drivers must let go of them. Add a udev rule on the host, then replug the sticks:

```
# /etc/udev/rules.d/99-ambed.rules
ACTION=="add", ATTRS{idVendor}=="0403", ATTRS{idProduct}=="6015", MODE="0666", RUN+="/bin/sh -c 'rmmod ftdi_sio && rmmod usbserial'"
```

Give the container the USB devices, either with `privileged: true` or by passing the bus through:

```yaml
    devices:
      - "/dev/bus/usb/001/:/dev/bus/usb/001/"
    device_cgroup_rules:
      - 'c 188:* rwm'
```

### 2. XLXd environment

| Variable | Default | Description |
| :------- | :------ | :---------- |
| `XLXNUM` | - | **Required.** Reflector name, e.g. `XLX349` |
| `URL` | - | **Required.** Dashboard host name, used for the calling-home dashboard link and Apache `ServerName` |
| `PORT` | `80` | Dashboard port, used in the calling-home dashboard link |
| `AMBED` | `ambed` | Host name or IP of the AMBEd container. **Must resolve from the xlxd container**: use the AMBEd service / container name. If it doesn't resolve, xlxd logs a warning and transcoding is disabled |
| `CALLSIGN` | - | Dashboard author meta tag |
| `EMAIL` | - | Dashboard contact address, Apache `ServerAdmin` |
| `COUNTRY` | - | Calling-home country |
| `DESCRIPTION` | - | Calling-home comment and dashboard header text |
| `COMMENT` | - | Dashboard meta description |
| `CALLHOME` | `false` | `true` registers the reflector with the XLX network |
| `TZ` | `UTC` | Container time zone |
| `MODULES` | `26` | Number of modules shown on the dashboard |
| `MODULEA` .. `MODULEZ` | dashboard default | Module names on the dashboard. Use `<br>` for a line break, e.g. `HKC<br>BM 3166218`. Any other HTML is escaped. Unset keeps the dashboard default (`MODULES` is the count, so module S can't be named this way) |

The dashboard config is regenerated from these variables each time a new container is created, so change the stack instead of editing `config.inc.php`.

### 3. XLXd volumes

| Mount | Purpose |
| :---- | :------ |
| `/config` | Files copied into `/xlxd` at every start: `xlxd.whitelist`, `xlxd.blacklist`, `xlxd.interlink`, `xlxd.terminal`, and the calling-home hash `callinghome.php`. `log/xlxd.xml` here is restored at start so the dashboard has history immediately |
| `/var/www/xlxd/css/layout.css`, `/var/www/xlxd/img/<file>` | Optional dashboard theme - mount **single files** over the image's dashboard (see below) |

Keep `callinghome.php` in `/config` once the reflector has called home: it holds the hash that identifies the reflector to the XLX network. After the first call home, copy it out with `docker cp xlxd:/xlxd/callinghome.php ./config/`.

### 4. Ports

| Port | Protocol | Service |
| :--- | :------- | :------ |
| 80 | TCP | Dashboard |
| 8080 | TCP | RepNet (optional) |
| 8880 | UDP | DMR+ DMO mode |
| 10001 | UDP | JSON interface |
| 10002 | UDP | XLX interlink |
| 12345-12346 | UDP | Icom Terminal |
| 17000 | UDP | M17 |
| 20001 | UDP | DPlus |
| 21110 | UDP | Yaesu IMRS |
| 30001 | UDP | DExtra |
| 30051 | UDP | DCS |
| 40000 | UDP | Icom Terminal DV |
| 42000 | UDP | YSF |
| 62030 | UDP | MMDVM |
| 10100 | UDP | AMBEd controller (ambed container) |
| 10101-10199 | UDP | AMBEd transcoding streams (ambed container) |


## Dashboard

The image serves upstream's classic dashboard (`dashboard1`, v2.4.7). Upstream escapes HTML in module names; the image keeps that escaping but lets `<br>` through so multi-line module names still work.

To theme it, mount individual files over the image's copy rather than the whole `/var/www/xlxd` directory. A full directory mount freezes the dashboard at whatever version was copied and hides every later dashboard update:

```yaml
    volumes:
      - ./custom/layout.css:/var/www/xlxd/css/layout.css
      - ./custom/header.jpg:/var/www/xlxd/img/header.jpg
```

`layout.css` is the same in dashboard 2.4.1 and 2.4.7, so a customized copy from an older dashboard still fits. The header image alt text is set to `XLXNUM` automatically.


## Building and releasing

Images are built by GitHub Actions ([`.github/workflows/docker-images.yml`](./.github/workflows/docker-images.yml)) on native amd64 and arm64 runners and pushed to Docker Hub and GHCR as multi-arch tags:

| Event | Publishes |
| :---- | :-------- |
| push to `testing` | `:test` |
| merge / push to `main` | `:latest` |
| push a `vX.Y.Z` tag | `:X.Y.Z` |
| weekly (Monday) | `:latest` rebuilt from `main` for base image updates |

Only changes under `AMBEd/`, `XLXd/` or the workflow itself trigger a build. The workflow needs the repository secrets `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` (a Docker Hub personal access token with Read & Write).

Build notes:
- ftdichip.com refuses scripted downloads, so the AMBEd build falls back to the libftd2xx 1.4.33 files in the previously published `cbodden/ambed-docker:latest` (`FTDI_FALLBACK_IMAGE`).
- The GitHub amd64 runners use Azure's Ubuntu mirror for AMBEd (`UBUNTU_MIRROR` build arg); local builds use the default archive.

### Upgrading

A second workflow, [`upstream-check.yml`](./.github/workflows/upstream-check.yml), runs every Monday and compares the pins with upstream:

- LX3JL/xlxd `master` vs `XLXD_GIT_REF`
- the latest s6-overlay release vs `S6_OVERLAY_VERSION`

(both pinned in `AMBEd/Dockerfile` and `XLXd/Dockerfile`). When one has moved it opens a PR into `testing` from `upstream/<name>-<version>` that bumps the pin in both Dockerfiles. The description has the version change, a compare link / CHANGELOG, the changed files that have affected this build before, and the checklist; a docker images build runs on the branch as a check (it publishes no tags). A newer version closes the older PR as superseded, and closing a PR without merging stops that version being proposed again. Nothing merges or deploys on its own. It needs "Allow GitHub Actions to create and approve pull requests" on in the repository settings. Run it by hand from the Actions tab (`dry_run` reports only), or locally:

```
DRY_RUN=true REPO=cbodden/ambed-xlxd-docker bash .github/scripts/upstream-check.sh
```

To upgrade:
1. Wait for the build check on the upstream PR, read it, and merge it into `testing` - CI publishes `:test`; run it against real hardware
2. Merge `testing` into `main` - CI publishes `:latest`
3. Tag the release, e.g. `git tag v2.6.2 origin/main && git push origin v2.6.2` - CI publishes `:2.6.2`

To bump a pin by hand instead, set the `ARG` in both Dockerfiles and push to `testing`; any open upstream PR for it is closed on the next run.


## License

XLXd && AMBEd:
- Copyright (C) 2016 Jean-Luc Deltombe LX3JL and Luc Engelmann LX1IQ

All other work:
- Copyright (C) 2026 cbodden

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the [GNU General Public License](./LICENSE) for more details.
