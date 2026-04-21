# bolo-releases

Signed binary releases for [Bolo](https://bolo.app) — P2P substrate + Home Intelligence (camera security) on [Iroh](https://iroh.computer).

**The Bolo source code is private.** This repository holds only signed release artifacts and update manifests consumed by the in-app auto-updater (`bolod` + Tauri desktop shell).

## Layout

```
pubkeys/
  bolod.pub        — minisign public key baked into the bolod binary
  desktop.pub      — minisign public key used by the Tauri updater (same key for MVP)

{stable,beta,nightly}/
  bolod-latest.json[.minisig]     — daemon auto-update manifest for that channel
  desktop-latest.json[.minisig]   — Tauri desktop auto-update manifest for that channel

install.sh         — headless one-line installer (target of `curl get.bolo.app | sh`)
```

Per-version artifacts (`bolod-<triple>.tar.gz`, `Bolo-<version>.dmg`, `.msi`, `.AppImage`, etc.) are attached as assets to the corresponding GitHub Release, not committed to this repo.

## Verifying a release

Every release artifact is signed with [minisign](https://jedisct1.github.io/minisign/). To verify a download:

```sh
# one-time: save the public key
curl -sSLO https://raw.githubusercontent.com/counterpunchtech/bolo-releases/main/pubkeys/bolod.pub

# verify an artifact
minisign -Vm bolod-aarch64-apple-darwin.tar.gz -p bolod.pub
```

Expected public key:

```
RWTruTWtUg9mdaBQVIJYsjZAdjb1H8pjMNIvK/VvipdjMbrZOxMEKpsR
```

## Channels

- **stable** — tagged `vX.Y.Z` releases. What end users run by default.
- **beta** — tagged `vX.Y.Z-beta.N` prereleases. Early-access, but expected to be functional.
- **nightly** — automated builds from the private source repo's `main` branch. No stability guarantees.

## Reporting issues

Since the source is private, please report issues via the support channels on [bolo.app](https://bolo.app) rather than opening issues on this artifact repository.
