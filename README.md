# AMBEd / XLXd docker images

Docker images for the [LX3JL/xlxd](https://github.com/LX3JL/xlxd) XLX multiprotocol reflector (`xlxd`) and its AMBE transcoder (`ambed`), plus optional NXDN, P25 and YSF reflectors to peer into it, built for x86_64 and ARM64.


## Images

| Service | Docker Hub | GHCR | Architectures | Base Image |
| :------ | :--------- | :--- | :------------ | :--------- |
| AMBEd   | [cbodden/ambed-docker](https://hub.docker.com/r/cbodden/ambed-docker/tags) | `ghcr.io/cbodden/ambed-docker` | x86_64, ARM64/v8 | Ubuntu Latest |
| XLXd    | [cbodden/xlxd-docker](https://hub.docker.com/r/cbodden/xlxd-docker/tags)   | `ghcr.io/cbodden/xlxd-docker`  | x86_64, ARM64/v8 | Alpine Latest |
| NXDNReflector | [cbodden/nxdnreflector-docker](https://hub.docker.com/r/cbodden/nxdnreflector-docker/tags) | `ghcr.io/cbodden/nxdnreflector-docker` | x86_64, ARM64/v8 | Alpine Latest |
| P25Reflector  | [cbodden/p25reflector-docker](https://hub.docker.com/r/cbodden/p25reflector-docker/tags)   | `ghcr.io/cbodden/p25reflector-docker`  | x86_64, ARM64/v8 | Alpine Latest |
| NXDN dashboard | [cbodden/nxdndashboard-docker](https://hub.docker.com/r/cbodden/nxdndashboard-docker/tags) | `ghcr.io/cbodden/nxdndashboard-docker` | x86_64, ARM64/v8 | Alpine Latest |
| P25 dashboard  | [cbodden/p25dashboard-docker](https://hub.docker.com/r/cbodden/p25dashboard-docker/tags)   | `ghcr.io/cbodden/p25dashboard-docker`  | x86_64, ARM64/v8 | Alpine Latest |
| YSFReflector   | [cbodden/ysfreflector-docker](https://hub.docker.com/r/cbodden/ysfreflector-docker/tags)   | `ghcr.io/cbodden/ysfreflector-docker`  | x86_64, ARM64/v8 | Alpine Latest |
| YSF dashboard  | [cbodden/ysfdashboard2-docker](https://hub.docker.com/r/cbodden/ysfdashboard2-docker/tags) | `ghcr.io/cbodden/ysfdashboard2-docker` | x86_64, ARM64/v8 | Alpine Latest |
| YSF dashboard (pYSF3 classic) | [cbodden/ysfdashboard-docker](https://hub.docker.com/r/cbodden/ysfdashboard-docker/tags) | `ghcr.io/cbodden/ysfdashboard-docker` | x86_64, ARM64/v8 | Alpine Latest |

| Tag | Built from |
| :-- | :--------- |
| `latest` | `main` branch (also rebuilt weekly for base image updates) |
| `test`   | `testing` branch |
| `X.Y.Z`, `X.Y.Z-N` | `vX.Y.Z` / `vX.Y.Z-N` git tags - fixed, never move, use these to roll back |


### Versions
- AMBEd: 1.4.0
- XLXd: 2.6.1
- Dashboard: 2.4.7 (upstream `dashboard1`)
- NXDNReflector / P25Reflector: 20210912 (G4KLX - frozen, see [NXDN and P25 reflectors](#6-nxdn-and-p25-reflectors))
- NXDN / P25 / YSF reflector dashboards: ShaYmez Dashboard2 2.0.3
- YSFReflector + classic dashboard: IU5JAE pYSFReflector3 20260414 (see [YSF reflector](#8-ysf-reflector-and-dashboard))
- FTDI D2XX: 1.4.33
- S6 Overlay: 3.2.3.2
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

Dashboard pages and lists. Switches take `on`/`off` (also `true`/`false`, `enable`/`disable`, `yes`/`no`, `1`/`0`); every default is what the dashboard did before these existed. A value the image doesn't understand logs a `WARNING` and falls back to the default.

| Variable | Default | Description |
| :------- | :------ | :---------- |
| `REFLECTORS_PAGE` | `on` | "Reflectors list" page and menu entry |
| `IRCDDB_PAGE` | `off` | "D-Star live" page - live.ircddb.net, loaded through the dashboard's own proxy so it works on an https site |
| `IRCDDB_URL` | `http://live.ircddb.net:8080` | ircDDB live server to proxy |
| `TRAFFIC_PAGE` | `off` | "Traffic statistics" page; also starts `vnstatd` in the container to collect it (the container's `eth0` carries all reflector traffic). Mount `/var/lib/vnstat` to keep the history - see volumes |
| `LASTHEARD_LIMIT` | `39` | Stations on the last-heard list (1-999) |
| `REPEATERS_LIMIT` | `99` | Rows on the Repeaters / Nodes page (1-999) |
| `PEERS_LIMIT` | `99` | Rows on the Peers page (1-999) |
| `PAGE_REFRESH` | `10` | Dashboard auto-refresh in seconds (0-3600); `0` turns auto-refresh off |
| `IP_DISPLAY` | `hide` | How much of a repeater / peer IP to show: `hide`, `last1`, `last2`, `last3` (bytes) or `full` |

NXDN / P25 / YSF reflector peers - added to `xlxd.interlink` at every start (see [NXDN and P25 reflectors](#6-nxdn-and-p25-reflectors), [YSF reflector](#8-ysf-reflector-and-dashboard)):

| Variable | Default | Description |
| :------- | :------ | :---------- |
| `NXDN_PEER` | - | `<number> <host>:<port> <module>`, e.g. `31000 nxdnreflector:41400 E` |
| `NXDN_PEER_ENABLED` | `off` | Add the `NXDN_PEER` line |
| `P25_PEER` | - | `<number> <host>:<port> <module>`, e.g. `31000 p25reflector:41000 F` |
| `P25_PEER_ENABLED` | `off` | Add the `P25_PEER` line |
| `YSF_PEER` | - | `<number> <host>:<port> <module>`, e.g. `12345 ysfreflector:42000 A` - the number (1-99999) is the YSF reflector's registry id |
| `YSF_PEER_ENABLED` | `off` | Add the `YSF_PEER` line |

A malformed value logs a `WARNING` and isn't added; a peer already in `/config/xlxd.interlink` is left as it is.

The YSF / NXDN / P25 peer pages aren't switchable: they read the logs of YSF / NXDN / P25 reflectors running on the same host under systemd, which a container doesn't have.

The dashboard config is regenerated from these variables each time a new container is created, so change the stack instead of editing `config.inc.php`.

### 3. XLXd volumes

| Mount | Purpose |
| :---- | :------ |
| `/config` | Files copied into `/xlxd` at every start: `xlxd.whitelist`, `xlxd.blacklist`, `xlxd.interlink`, `xlxd.terminal`, and the calling-home hash `callinghome.php`. `log/xlxd.xml` here is restored at start so the dashboard has history immediately. Note the start-up copy is `cp /config/*.* /xlxd`: every file with a dot in its name is copied, so a leftover `main.h.customized`, `cysfprotocol.cpp.customized` or `config.inc.php` from an older install overwrites the image's reference copies in `/xlxd`. xlxd doesn't read those (the dashboard config is regenerated from the environment), but they're misleading - keep `/config` to the files above |
| `/var/www/xlxd/css/layout.css`, `/var/www/xlxd/img/<file>` | Optional dashboard theme - mount **single files** over the image's dashboard (see below) |
| `/var/lib/vnstat` | Optional, with `TRAFFIC_PAGE=on`: the vnstat database, so traffic history survives a new container. Without it, history starts over on every re-create |

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
| 41400 | UDP | NXDN reflector (nxdnreflector container, optional) |
| 41000 | UDP | P25 reflector (p25reflector container, optional) |
| 41500 | UDP | YSF reflector (ysfreflector container, optional - container port 42000) |
| 8081 / 8082 / 8083 | TCP | NXDN / P25 / YSF reflector dashboards (optional, usually behind a reverse proxy) |
| 8084 | TCP | pYSF3's classic YSF dashboard (optional) |

Only publish (and forward on the firewall) the ports of the modes you serve; M17 on 17000/UDP needs AMBEd 1.4.0+ for Codec2 transcoding, which this image has.

### 5. Build-time options

These are compiled in, so changing them means building the image with `--build-arg`:

| Build arg | Image | Default | Description |
| :-------- | :---- | :------ | :---------- |
| `YSF_AUTOLINK_MODULE` | XLXd | `A` | Module a YSF client is linked to when it doesn't pick one (upstream 2.6 uses `B`) |
| `IMRS_DEFAULT_MODULE` | XLXd | `A` | Default module for Yaesu IMRS (Wires-X) clients (upstream 2.6 uses `B`) |
| `USE_AGC` | AMBEd | `0` | `1` turns on the DVSI chips' automatic gain control |

### 6. NXDN and P25 reflectors

XLXd 2.6.x can't take NXDN or P25 radios directly - it only peers with NXDN / P25 reflectors. These two optional images run [G4KLX](https://github.com/g4klx)'s NXDNReflector and P25Reflector so NXDN and P25 users have a way in: they connect to the reflector, and xlxd peers that reflector onto one XLX module (one module per reflector - they're single-room).

- **NXDN** uses the same AMBE+2 codec as DMR / YSF - no transcoding.
- **P25** uses IMBE: AMBEd 1.4.0 does it in software, plus 2 DVSI channels per P25 <-> DMR / D-Star stream, shared with the other transcoding.
- **Frozen upstream:** G4KLX removed both reflectors from NXDNClients / P25Clients in Feb 2023. The images build the last commit that had them (version 20210912, `NXDN_GIT_REF` / `P25_GIT_REF`), so there's nothing for the upstream check to track.

Switch each one on with a single variable (see [`docker-compose-ambed_xlxd.yml`](./docker-compose-ambed_xlxd.yml)): `NXDN_REFLECTOR=1` / `P25_REFLECTOR=1` sets the service's `scale` (0 = no container) **and** the xlxd peer's `*_PEER_ENABLED`, so turning a reflector off also stops xlxd trying to reach it. xlxd reaches the reflector by service name on the stack's network, so only the reflector's own port needs publishing / forwarding for outside users.

| Variable | Image | Default | Description |
| :------- | :---- | :------ | :---------- |
| `NXDN_TG` | nxdnreflector | - | **Required.** The reflector's number / talkgroup (1-65535) - the same number goes in `NXDN_PEER` and in the NXDN host lists |
| `NXDN_PORT` | nxdnreflector | `41400` | UDP port |
| `NXDN_ID_URL` | nxdnreflector | radioid.net `nxdn.csv` | Id list for callsigns in the log; downloaded at start, the image has a fallback copy |
| `P25_PORT` | p25reflector | `41000` | UDP port |
| `P25_ID_URL` | p25reflector | pistar.uk `DMRIds.dat` | Id list (P25 uses DMR ids), downloaded at start, with a fallback copy |
| `*_ID_RELOAD` | both | `24` | Hours between id list reloads (0 = never) |
| `*_LOG_LEVEL` | both | `1` | 1 = everything .. 6 = fatal only, 0 = off |
| `*_DEBUG` | both | `0` | `1` logs network packets |

To be findable from a hotspot's NXDN / P25 menus, register the reflector's number, host and port with the host lists (they're published through [DVRef](https://dvref.com) / pistar.uk) - check the number is free first.

Optional log files for the dashboards below (both reflectors, `NXDN_` / `P25_` prefix):

| Variable | Default | Description |
| :------- | :------ | :---------- |
| `*_LOG_FILE` | `off` | `on` writes dated log files plus a copy of the ini to `/var/log/nxdnreflector` / `/var/log/p25reflector` - share that volume with the dashboard |
| `*_LOG_FILE_LEVEL` | `2` | File log level (2 = messages - what the dashboards read) |
| `*_LOG_KEEP_DAYS` | `7` | Log files older than this are deleted (at start and daily) |

### 7. NXDN and P25 reflector dashboards

`nxdndashboard` / `p25dashboard` / `ysfdashboard2` serve [ShaYmez](https://github.com/ShaYmez)'s [NXDNReflector-Dashboard2](https://github.com/ShaYmez/NXDNReflector-Dashboard2) / [P25Reflector-Dashboard2](https://github.com/ShaYmez/P25Reflector-Dashboard2) / [YSFReflector-Dashboard2](https://github.com/ShaYmez/YSFReflector-Dashboard2) (GPL-3.0, pinned by `DASH_GIT_REF`): linked repeaters / hotspots, last heard, live TX. They read the reflector's log files and ini, so turn on `*_LOG_FILE` on the NXDN / P25 reflector (the YSF reflector always writes them) and mount the same volume read-only into the dashboard (see [`docker-compose-ambed_xlxd.yml`](./docker-compose-ambed_xlxd.yml)). The config comes from the environment instead of the dashboard's setup wizard, which is removed. Linked repeaters show up after the reflector's next "Currently linked repeaters" log line (every couple of minutes).

| Variable | Default | Description |
| :------- | :------ | :---------- |
| `DASHBOARD_PORT` | `80` | Port Apache listens on in the container |
| `DASHBOARD_PATH` | `/` | Public path when served under a reverse-proxy prefix, e.g. `/nxdnreflector/` (the proxy strips it; this keeps the canonical / social links right) |
| `DASHBOARD_NAME` | `NXDN Reflector Dashboard` / `P25 Reflector Dashboard` / `YSF Reflector Dashboard` | Header and page title |
| `DASHBOARD_TAGLINE` | - | Line under the name |
| `DASHBOARD_LOGO` | - | Logo file in `img/` (mount your own over `/var/www/dashboard/img/<file>`) |
| `SHOW_QRZ` | `off` | Link callsigns to QRZ.com |
| `GDPR` | `off` | Anonymise callsigns |
| `LAST_HEARD_FIRST` | `off` | Last heard above the linked list |
| `SHOW_SYSTEM_INFO` | `off` | Uptime / load / disk panel (in a container it describes the container) |
| `SHOW_PROGRESS_BARS` | `on` | Progress bars in the system panel |
| `SHOW_OLD_MHEARD` | `7` | Days of last-heard history to show |
| `TZ` | `UTC` | Time zone the dashboard shows times in (the reflectors log in UTC; the image reads them as UTC and converts) |

Behind a reverse proxy on a sub-path, strip the prefix and redirect the bare path to the one with a trailing slash (the dashboard uses relative links). Traefik example for `xlx.example.com/nxdnreflector/`:

```yaml
http:
  routers:
    xlx-nxdn:
      rule: "Host(`xlx.example.com`) && PathPrefix(`/nxdnreflector`)"
      middlewares: [xlx-nxdn-slash, xlx-nxdn-strip]
      service: xlx-nxdn
  middlewares:
    xlx-nxdn-slash:
      redirectRegex: { regex: "^(https?://[^/]+/nxdnreflector)$", replacement: "${1}/", permanent: true }
    xlx-nxdn-strip:
      stripPrefix: { prefixes: ["/nxdnreflector"] }
  services:
    xlx-nxdn:
      loadBalancer: { servers: [{ url: "http://docker-host:8081" }] }
```

### 8. YSF reflector and dashboard

xlxd already takes YSF hotspots directly (port 42000, autolinked to module A - see [build options](#5-build-time-options)), but it isn't a YSF *room*: it doesn't show up in the YSF registry / hotspot host lists under its own name. The optional `ysfreflector` image runs [IU5JAE](https://github.com/iu5jae)'s [pYSFReflector3](https://github.com/iu5jae/pYSFReflector3) (GPL-3.0, pinned by `PYSF_GIT_REF` - G4KLX's YSFReflector was removed upstream in Feb 2023) as a registered YSF reflector, and xlxd peers it onto one module like the NXDN / P25 reflectors. YSF uses AMBE+2 like DMR / NXDN, so no transcoding.

Switch it on with `YSF_REFLECTOR=1` (service `scale` **and** xlxd's `YSF_PEER_ENABLED`, see [`docker-compose-ambed_xlxd.yml`](./docker-compose-ambed_xlxd.yml)). It listens on 42000 in the container, so publish it on another host port (the example uses 41500) - xlxd keeps 42000 and reaches the reflector by service name.

| Variable | Default | Description |
| :------- | :------ | :---------- |
| `YSF_NAME` | - | **Required.** Registry name (16 characters max - longer is cut with a warning) |
| `YSF_DESCRIPTION` | `YSF_NAME` | Registry description (14 characters max) |
| `YSF_ID` | `0` | Registry id answered in status polls. `0` = computed from `YSF_NAME` with the YSF registry's own hash, so it normally matches the id the registry assigns - the start-up status poll shows it (`YSFS<id><name>...`) |
| `YSF_CONTACT` / `YSF_WEB` | - | Contact e-mail / web site shown on the dashboard (`YSF_WEB` without `http://` - the dashboard adds it) |
| `YSF_PORT` | `42000` | UDP port in the container |
| `YSF_JSON_PORT` | `42223` | UDP port of the json feed the dashboard reads (stack network only - don't publish it) |
| `YSF_DGID_LIST` | `1,9,50` | DG-IDs allowed on the reflector |
| `YSF_DGID_DEFAULT` | `50` | DG-ID a gateway lands on, and that radios on DG-ID 00 use - the XLX peer is here too |
| `YSF_DGID_LOCAL` | `1` | DG-ID that stays on the user's own repeater |
| `YSF_TIMEOUT` | `190` | Transmit timeout in seconds |
| `YSF_CHECK_CALLSIGN` | `on` | Drop transmissions whose callsign doesn't look like one |
| `YSF_APRS` | `off` | Send positions to APRS-IS (`YSF_APRS_SERVER`, `YSF_APRS_PORT`, `YSF_APRS_SSID`) |
| `YSF_LOG_LEVEL` | `1` | 0 = everything, 1 = normal, 2-4 = less, 5 = nothing. The log goes to dated (UTC) files in `/var/log/ysfreflector`, which `docker logs` follows (`ysfdashboard2` needs 1 or lower) |
| `YSF_LOG_KEEP_DAYS` | `7` | Log files older than this are deleted (at start and daily) |

Mount `/opt/pysfreflector` to keep the deny list (`deny.db`, see upstream's `ACL_rules.txt`), the return-home list (`home.db`) and each gateway's last DG-ID across re-creates. Both `.db` files are seeded on first start and are yours to edit after that.

Register the reflector at [register.ysfreflector.de](https://register.ysfreflector.de) with its public host and port; it then reaches the YSF host lists that hotspots download. Use its id as the `YSF_PEER` number (it's only a label on the XLX peers page), and set `YSF_ID` only if the registry's id differs from the computed one.

Mount `/var/log/ysfreflector` as a volume and share it read-only with `ysfdashboard2` - the reflector also writes a G4KLX style `YSFReflector.ini` (name, description, registry id) there for it. `ysfdashboard2` is the [ShaYmez Dashboard2](#7-nxdn-and-p25-reflector-dashboards) for YSF, with the same variables; it switches with `YSF_DASHBOARD` (follows `YSF_REFLECTOR`). It has no DG-ID view.

`ysfdashboard` serves pYSF3's own "classic" dashboard (IK5XMK's collector + pages): last heard, linked gateways with their DG-ID, blocked calls. Opt-in in the example (`YSF_DASHBOARD_CLASSIC=1`, port 8084). Its collector reads the reflector's json feed into SQLite, so it only needs the reflector's address - no shared volume. Linked gateways show up after the reflector's next list (every 2 minutes).

| Variable | Default | Description |
| :------- | :------ | :---------- |
| `YSF_JSON_HOST` | `ysfreflector` | Reflector service / container name |
| `YSF_JSON_PORT` | `42223` | Reflector json port |
| `DASHBOARD_PORT` | `80` | Port Apache listens on in the container |

Its links are relative, so it works under a reverse-proxy sub-path the same way as the NXDN / P25 dashboards above.


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
| push a `vX.Y.Z` tag | `:X.Y.Z` + a GitHub release |
| weekly (Monday) | `:latest` rebuilt from `main` for base image updates |

Changes are listed in [`CHANGELOG.md`](./CHANGELOG.md). Add them under `## [Unreleased]` with the change; when tagging, rename that heading to the version (`## [2.6.2] - YYYY-MM-DD`), add a new empty `## [Unreleased]` above it and the compare links at the bottom. A tag push runs [`release.yml`](./.github/workflows/release.yml), which creates the GitHub release with that version's section as the notes - it fails if the section is missing. Re-run it from the Actions tab with the tag to create or refresh the release of an existing tag (it then reads `CHANGELOG.md` from `main`).

Only changes under `AMBEd/`, `XLXd/`, `NXDNReflector/`, `P25Reflector/`, `NXDNDashboard/`, `P25Dashboard/` or the workflow itself trigger a build. The workflow needs the repository secrets `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` (a Docker Hub personal access token with Read & Write).

Build notes:
- ftdichip.com refuses scripted downloads, so the AMBEd build falls back to the libftd2xx 1.4.33 files in the previously published `cbodden/ambed-docker:latest` (`FTDI_FALLBACK_IMAGE`). The image keeps `/usr/local/lib/libftd2xx.so.*` and `/usr/local/include/{ftd2xx,WinTypes}.h` for this - don't drop them.
- AMBEd is a two-stage build: the `build` stage compiles ambed and lays out `/rootfs` (ambed, libftd2xx, s6-overlay), the final image is a clean Ubuntu with `/rootfs` and the runtime packages only. Libraries ambed needs at runtime go in its `apt install`; the build fails if `ldd` reports one missing.
- The GitHub amd64 runners use Azure's Ubuntu mirror for AMBEd (`UBUNTU_MIRROR` build arg); local builds use the default archive.

### Upgrading

A second workflow, [`upstream-check.yml`](./.github/workflows/upstream-check.yml), runs every Monday and compares the pins with upstream:

- LX3JL/xlxd `master` vs `XLXD_GIT_REF` (`AMBEd/Dockerfile`, `XLXd/Dockerfile`)
- the latest s6-overlay release vs `S6_OVERLAY_VERSION` (same two Dockerfiles)
- iu5jae/pYSFReflector3 vs `PYSF_GIT_REF` (`YSFReflector/Dockerfile`, `YSFDashboard/Dockerfile`)
- ShaYmez NXDN / P25 / YSF Reflector-Dashboard2 vs `DASH_GIT_REF` (`NXDNDashboard/`, `P25Dashboard/`, `YSFDashboard2/Dockerfile`)

The NXDN / P25 reflector pins aren't checked - G4KLX deleted both reflectors upstream (see [NXDN and P25 reflectors](#6-nxdn-and-p25-reflectors)). The reflector / dashboard entries are the `GIT_PINS` list in [`upstream-check.sh`](./.github/scripts/upstream-check.sh). When one has moved it opens a PR into `testing` from `upstream/<name>-<version>` that bumps the pin in every Dockerfile that has it. The description has the version change, a compare link / CHANGELOG / recent commits, the changed files (bold where the Dockerfile patches or depends on them), and the checklist with what to try on 005; a docker images build runs on the branch as a check (it publishes no tags). A newer version closes the older PR as superseded, and closing a PR without merging stops that version being proposed again. Nothing merges or deploys on its own. It needs "Allow GitHub Actions to create and approve pull requests" on in the repository settings. Run it by hand from the Actions tab (`dry_run` reports only), or locally:

```
DRY_RUN=true REPO=cbodden/ambed-xlxd-docker bash .github/scripts/upstream-check.sh
```

To upgrade:
1. Wait for the build check on the upstream PR, read it, and merge it into `testing` - CI publishes `:test`; run it against real hardware
2. Merge `testing` into `main` - CI publishes `:latest`
3. Move the `## [Unreleased]` entries in `CHANGELOG.md` under the new version (via `testing` -> `main` like any change)
4. Tag the release, e.g. `git tag v2.6.2 origin/main && git push origin v2.6.2` - CI publishes `:2.6.2` and the GitHub release

To bump a pin by hand instead, set the `ARG` in every Dockerfile that has it and push to `testing`; any open upstream PR for it is closed on the next run.


## License

XLXd && AMBEd:
- Copyright (C) 2016 Jean-Luc Deltombe LX3JL and Luc Engelmann LX1IQ

All other work:
- Copyright (C) 2026 cbodden NK2I

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the [GNU General Public License](./LICENSE) for more details.
