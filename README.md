# dieppon's App Store

A personal, curated app store for **ZimaOS** and **CasaOS**, maintained by
[dieppon]. Same format as popular community stores like
[big-bear-casaos](https://github.com/bigbeartechworld/big-bear-casaos), following the
[official ZimaOS app store docs](https://www.zimaspace.com/docs/developer/app-store-create-from-scratch)
(v2 protocol).

- **Store ID:** `com.dieppon.appstore` — this never changes once published.
- **Languages:** `en_US`

## Repository layout

```text
zimaos-app-store/
├── .github/workflows/
│   └── build-store.yml          # CI: builds dist/ and publishes to GitHub Pages
├── Apps/                        # one folder per app (the store's content)
│   ├── gluetun/
│   │   └── docker-compose.yml   # runtime config + x-casaos metadata
│   ├── musicbrainz-picard/
│   │   └── docker-compose.yml
│   ├── slskd-vpn/
│   │   └── docker-compose.yml
│   └── transmission-vpn/
│       └── docker-compose.yml
├── scripts/
│   ├── build_dist.sh            # build v2 store output (dist/) locally
│   └── new_app.sh               # scaffold a new app from the template
├── templates/
│   └── docker-compose.yml       # annotated skeleton for new apps
├── store-config.json            # store identity (v2)
├── supported-languages.json     # locales to generate output for
├── LICENSE                      # MIT
└── README.md
```

## Adding a new app

Fastest way:

```bash
./scripts/new_app.sh vaultwarden "Vaultwarden" Productivity "8080"
```

Then edit `Apps/vaultwarden/docker-compose.yml`: set the real image tag,
description, icon, and links. The rules that matter (also documented in
`templates/docker-compose.yml`):

| Field | Rule |
| --- | --- |
| `x-casaos.id` | Reverse-domain, e.g. `com.dieppon.vaultwarden`. **Never change it after publishing.** |
| `x-casaos.main` | Must be the name of a service in `services:` (the web UI one). |
| `x-casaos.port_map` | The web UI port — must be a **quoted string** (`"8080"`). |
| `x-casaos.title` | Locale-keyed object: `title: { en_US: My App }`, not a plain string. |
| `x-casaos.category` | One of: `Media`, `Productivity`, `Home`, `Networking`, `AI`, `Finance`, `Social`, `Developer`, `Others`. |
| `x-casaos.version` | Semver-style string. **Bump it every time you publish a meaningful change** — clients use it to decide whether users get an update. |
| Data paths | Put persistent data in `/DATA/AppData/<app-folder>/...` (the standard CasaOS/ZimaOS data location). |
| User mapping | Use `PUID: $PUID`, `PGID: $PGID`, `TZ: $TZ` — these are provided by CasaOS/ZimaOS. |

Icons: a PNG URL works best (e.g. from
[selfhst/icons](https://github.com/selfhst/icons)). SVG works too, but then the
build needs `rsvg-convert` (see below).

## Building the store output

The store is "built" from `Apps/*/docker-compose.yml` into static v2 files
(`index.json`, `store.json`, per-app `meta.json` + assets) using IceWhale's
official builder (`IceWhaleTech/build-appstore-action`), which this script runs
locally:

```bash
./scripts/build_dist.sh                              # placeholder base-url
./scripts/build_dist.sh https://your-host/dieppon-app-store
```

Requirements: `python3` and network access. If your apps use SVG icons you also
need `rsvg-convert` (`brew install librsvg` on macOS).

Output lands in `dist/`.

## Publishing

Everything is automated by `.github/workflows/build-store.yml`. On every push
to `master` (or a manual run) it:

1. builds the v2 store output from `Apps/*/docker-compose.yml` using IceWhale's
   official [`build-appstore-action`](https://github.com/IceWhaleTech/build-appstore-action),
   with `base-url` set to `https://dieppa.co.uk/zimaos-app-store`;
2. also produces a legacy v1 zip at `dist/store/main.zip` for older clients;
3. publishes the result to the `gh-pages` branch via GitHub Pages.

The store is then reachable at:

```text
https://dieppa.co.uk/zimaos-app-store
```

### One-time GitHub setup

- **Settings → Pages → Build and deployment → Source:** *Deploy from a branch*,
  branch **gh-pages**, folder **/ (root)**.
- **Custom domain:** `dieppa.co.uk/zimaos-app-store` is a sub-path, so the site
  must actually be served under that path (custom domain configured on the
  Pages/user site, or a proxy that maps that path to the Pages content). The
  first workflow run creates the `gh-pages` branch.
- Optional: add `DOCKERHUB_USERNAME` / `DOCKERHUB_TOKEN` repo secrets to avoid
  Docker Hub rate limits during image metadata lookups (the build works without
  them).

### Adding the store to ZimaOS / CasaOS

**App Store → Add Source** and paste the store URL:

```text
https://dieppa.co.uk/zimaos-app-store
```

For very old CasaOS/ZimaOS clients that only understand the legacy zip format,
use the hosted zip instead:

```text
https://dieppa.co.uk/zimaos-app-store/store/main.zip
```


## Included apps

| App | Category | Port | Image |
| --- | --- | --- | --- |
| Gluetun VPN | Networking | — (headless; publishes 8888/8388/9091/51413/5030/5031/50300) | `qmcgaw/gluetun:v3.41.3` |
| MusicBrainz Picard | Media | 5800 | `jlesage/musicbrainz-picard:v26.10.2` |
| Transmission | Media | 9091 (via Gluetun) | `linuxserver/transmission:4.1.3` |
| slskd | Media | 5030 (via Gluetun) | `slskd/slskd:0.26.1` |

> **VPN stack install order:** Gluetun VPN → Transmission / slskd. The latter two
> use `network_mode: container:gluetun`, so Gluetun must be installed and
> configured (WireGuard credentials) first.

When you bump an app's image tag, also bump `x-casaos.version` and
`update_at` in the same file.

## License

[MIT](LICENSE) © 2026 Victor Dieppa Garriga

## Credits

- Store format follows the [official ZimaOS app store documentation](https://www.zimaspace.com/docs/developer/app-store-create-from-scratch).
- Structure inspired by [big-bear-casaos](https://github.com/bigbeartechworld/big-bear-casaos) (MIT).
