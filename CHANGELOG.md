# Changelog

Notable changes to the images in this repository. Versions follow the git tags: `vX.Y.Z` is the xlxd release
the images are built from, `-N` counts the releases of this repository on top of it. Pushing a `vX.Y.Z[-N]` tag
publishes the `:X.Y.Z[-N]` images and a GitHub release whose notes are that version's section below, so add the
section before tagging (see [Building and releasing](./README.md#building-and-releasing)).

Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).


## [Unreleased]

### Added
- NXDNReflector / P25Reflector images (`cbodden/nxdnreflector-docker`, `cbodden/p25reflector-docker`): G4KLX's
  reflectors built from the last NXDNClients / P25Clients commits that had them (removed upstream Feb 2023,
  version 20210912, pinned by `NXDN_GIT_REF` / `P25_GIT_REF`), ini written from the environment, peered into
  xlxd with `NXDN_PEER` / `P25_PEER` (#10)
- NXDN / P25 reflector dashboards (`cbodden/nxdndashboard-docker`, `cbodden/p25dashboard-docker`): ShaYmez
  NXDNReflector-Dashboard2 / P25Reflector-Dashboard2 2.0.3, config from the environment, `DASHBOARD_PATH` for a
  reverse-proxy prefix; optional dated reflector log files for them (#11)
- Optional YSF reflector (`cbodden/ysfreflector-docker`, IU5JAE's pYSFReflector3, pinned `PYSF_GIT_REF`) and its
  pYSF3 dashboard (`cbodden/ysfdashboard-docker`), peered into xlxd (#12)
- `cbodden/ysfdashboard2-docker`: ShaYmez YSFReflector-Dashboard2 2.0.3 for the YSF reflector (#13)
- XLXd dashboard switches from the environment: `REFLECTORS_PAGE`, `IRCDDB_PAGE` / `IRCDDB_URL`, `TRAFFIC_PAGE`
  (vnstatd s6 service), `LASTHEARD_LIMIT`, `REPEATERS_LIMIT`, `PEERS_LIMIT`, `PAGE_REFRESH`, `IP_DISPLAY` (#9)
- Weekly upstream check also watches pYSFReflector3 and the three Dashboard2 repos (#14)
- This changelog, and a GitHub release for each `v*` tag

### Changed
- AMBEd: two-stage build - ambed is compiled in a build stage and the image is a clean ubuntu with only ambed,
  libftd2xx, s6-overlay and `kmod` / `lsof` / `sudo`. The compiler (~168 MiB compressed) is no longer shipped;
  `curl` / `wget` are gone from the image. The build fails if ambed or libftd2xx is missing a runtime library (#16)
- XLXd: YSF auto-link and IMRS default module are `A` again, set by the new build args `YSF_AUTOLINK_MODULE` /
  `IMRS_DEFAULT_MODULE` - upstream 2.6 moved both to `B`, the parrot module on XLX349 (#8)

### Fixed
- Dashboard2 (NXDN / P25 / YSF) last-heard and linked times shown in the right time zone (#13)


## [2.6.1-3] - 2026-11-09

### Changed
- s6-overlay 3.2.1.0 -> 3.2.3.2 in AMBEd and XLXd; services registered in the new
  `/etc/s6-overlay/user-bundles.d` location (#6, #7)
- Weekly upstream check opens a pin-bump PR into `testing` instead of an issue, and also checks s6-overlay
  releases (#5)


## [2.6.1-2] - 2026-11-09

### Added
- XLXd `AMBED` env var for the transcoder host (default `ambed`); startup warns when it doesn't resolve (#4)

### Fixed
- Transcoding was silently off when the AMBEd service wasn't named `ambed` - the host was hardcoded (#4)
- `COMMENT` was never applied to the dashboard (#4)
- Example compose: duplicate services key dropped xlxd, quoted list values, missing `/config` volume (#4)

### Changed
- README rewritten for the current setup: images and tags, host setup, env vars, volumes, ports, CI (#4)


## [2.6.1-1] - 2026-11-08

### Added
- Weekly upstream check of LX3JL/xlxd against `XLXD_GIT_REF` (#2)

### Fixed
- Module names past E: `MODULEA`..`MODULEZ` all apply, and F / G no longer show without a title (#3)
- `ENV` defaults: the legacy `ENV key value` form set `CALLHOME` / `MODULES` to junk strings; real defaults now
  (`CALLHOME=false`, `PORT=80`, `TZ=UTC`, `MODULES=26`) (#3)
- Dashboard 2.4.7 html-escapes module names: `<br>` in a module name works again (#3)
- Dashboard header image alt text is `XLXNUM` (#3)


## [2.6.1] - 2026-11-08

### Changed
- xlxd 2.6.1 / AMBEd 1.4.0 (LX3JL/xlxd pinned at `a978f03`)
- XLXd uses the classic dashboard (dashboard1, 2.4.7) from the upstream split; adds `php84-curl`
- M17 17000/udp exposed and in the example compose

### Added
- GitHub Actions builds of AMBEd and XLXd for amd64 + arm64 on native runners, pushed to Docker Hub and GHCR:
  `testing` -> `:test`, `main` -> `:latest`, `vX.Y.Z` tags -> `:X.Y.Z`, weekly rebuild of `main`
- AMBEd: libftd2xx 1.4.33 falls back to the previously published image when ftdichip.com refuses the download;
  optional `UBUNTU_MIRROR` build arg


[Unreleased]: https://github.com/cbodden/ambed-xlxd-docker/compare/v2.6.1-3...HEAD
[2.6.1-3]: https://github.com/cbodden/ambed-xlxd-docker/compare/v2.6.1-2...v2.6.1-3
[2.6.1-2]: https://github.com/cbodden/ambed-xlxd-docker/compare/v2.6.1-1...v2.6.1-2
[2.6.1-1]: https://github.com/cbodden/ambed-xlxd-docker/compare/v2.6.1...v2.6.1-1
[2.6.1]: https://github.com/cbodden/ambed-xlxd-docker/releases/tag/v2.6.1
