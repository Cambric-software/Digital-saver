# Download page

The static page every Cambric app publishes beside its releases. It is plain
HTML, CSS and JavaScript: no build step, no framework and no external requests.

## Before publishing

Replace these placeholders in `index.html`:

| Placeholder | Replace with |
|---|---|
| `__APP_NAME__` | The product name, e.g. `Digital Saver` |
| `__TAGLINE__` | One sentence describing what the app does |
| `__REPO__` | GitHub repository name, e.g. `Digital-Saver` |
| `__WINDOWS_ASSET__` | Release asset filename, e.g. `MyApp-1.2.3-setup.exe` |
| `__LINUX_ASSET__` | Release asset filename, e.g. `MyApp-1.2.3-x86_64.AppImage` |
| `__ANDROID_ASSET__` | Release asset filename, e.g. `MyApp-1.2.3-arm64.apk` |

The `sha256sum` example uses the same asset placeholder; replace it too.

All download links use the version-independent GitHub alias:

```text
https://github.com/<owner>/<repo>/releases/latest/download/<asset>
```

That alias always resolves to the newest published release, so the page never
needs to be rebuilt when a version changes. The asset filenames on the release
must match exactly, including case.

## Version chip

The chip stays hidden unless a version is supplied. Either:

- link to the page with `?version=1.2.3`, or
- set `data-version="1.2.3"` on `<body>`.

Never hard-code a version in the HTML. An offline visitor must not see a release
that does not exist.

## Checksums

The page deliberately does not list hashes. It links to the release page, where
the hashes are published with the build, so the page cannot show a hash that
belongs to a different binary.

## Style

The palette, radii and card shapes are the Cambric product family, matching the
Max Tools download page and the app theme. Tokens live at the top of
`styles.css`. Cards are opaque with a hairline border; do not add blur or glass
here unless that product has deliberately chosen it.

The layout is checked at 390 px and 1440 px. It uses `prefers-color-scheme` and
`prefers-reduced-motion`, and all interactive elements have a visible focus
state.

## Deploying

Copy this folder to any static host. On GitHub Pages, publish the folder as the
site root, or put it behind a route such as `/download/`. Nothing in the page
requires a server.
