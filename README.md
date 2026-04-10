<!-- Fresco image -->
![Fresco](https://pub-d60dc12417c74d04b3dd6a1ed43e02c4.r2.dev/fresco/latest)

# Fresco

**AI-generated images for any project.**

Fresco is a composable CLI for generating images with the Google Gemini Imagen API and publishing them to Cloudflare R2. Pair it with a GitHub Actions workflow to keep a fresh image in your README, gallery, or anywhere else.

The banner image above is updated by Fresco. Browse the [Gallery](gallery.md) for the full image history.

---

## Install

```bash
brew install argylebits/tap/fresco
```

---

## Quick start

```bash
# Copy the template and fill in your values
cp fresco.template.env .env

# Generate an image (writes to /tmp/{slug}/, prints the path)
fresco generate

# Generate and upload
fresco upload $(fresco generate)
```

---

## Commands

### `fresco generate`

Generates an image and writes it to `/tmp/{slug}/`. Prints the local file path. The file extension is auto-detected from the image data (PNG or JPEG).

```bash
fresco generate                                          # use configured prompt
fresco generate --prompt "A sunset over the Hill Country" # override prompt
fresco generate --append "Celebrating release v2.1.0"    # extend configured prompt
```

### `fresco upload`

Uploads a local image to R2. Prints the public URL.

```bash
fresco upload /tmp/my-project/2026-04-02-120000.png                                        # keep original filename
fresco upload /tmp/my-project/2026-04-02-120000.png latest.png                               # upload as latest.png
fresco upload /tmp/my-project/2026-04-02-120000.png --cache-control "public, max-age=300"    # custom cache policy
```

R2 key and public URL are composed as:

```
R2 key:     {FRESCO_SLUG}/{filename}
Public URL: {R2_PUBLIC_BASE_URL}/{FRESCO_SLUG}/{filename}
```

### `fresco remote copy`

Copies an object within R2 (server-side, no download).

```bash
fresco remote copy 2026-04-02-120000.png latest.png
fresco remote copy 2026-04-02-120000.png latest.png --cache-control "public, max-age=300"  # override cache policy
```

### Composable workflows

The commands are designed to compose via shell substitution:

```bash
# Generate and preview (macOS)
open $(fresco generate)

# Generate and preview (Linux)
xdg-open $(fresco generate)

# Generate and upload (keeps original filename)
fresco upload $(fresco generate)

# Generate, upload dated, then alias to latest (preserves extension)
IMAGE=$(fresco generate)
fresco upload "$IMAGE"
fresco remote copy "$(basename "$IMAGE")" "latest.${IMAGE##*.}" --cache-control "public, max-age=300"
```

Use `basename` to extract the filename from a local path, and `${IMAGE##*.}` to extract the extension — this ensures the stable alias always matches the actual image format.

---

## Configuration

All config can be passed as flags, environment variables, or via a `.env` file. Flags take precedence over env vars, which take precedence over `.env`.

See [`fresco.template.env`](fresco.template.env) for the full variable list.

### Generate

| Flag | Env var | Description |
|---|---|---|
| `--prompt` | `FRESCO_PROMPT` | Image generation prompt |
| `--slug` | `FRESCO_SLUG` | Project slug (used in filenames and R2 paths) |
| `--gemini-api-key` | `GEMINI_API_KEY` | Google Gemini API key |

### Upload and remote copy

| Flag | Env var | Description |
|---|---|---|
| `--slug` | `FRESCO_SLUG` | Project slug (used in R2 paths) |
| `--r2-account-id` | `R2_ACCOUNT_ID` | Cloudflare account ID |
| `--r2-access-key-id` | `R2_ACCESS_KEY_ID` | R2 access key ID |
| `--r2-secret-access-key` | `R2_SECRET_ACCESS_KEY` | R2 secret access key |
| `--r2-bucket` | `R2_BUCKET` | R2 bucket name |
| `--r2-public-base-url` | `R2_PUBLIC_BASE_URL` | Public base URL for R2 images |
| `--cache-control` | — | Cache-Control header (default: `public, max-age=31536000`) |

---

## Workflow examples

The [`Examples/`](Examples/) directory has ready-to-use GitHub Actions workflows. Copy one into `.github/workflows/` and add your secrets. The snippets below are excerpts — see the linked files for complete workflows.

**Scheduled generate + upload** ([`fresco-cron.yml`](Examples/fresco-cron.yml)):

```yaml
on:
  schedule:
    - cron: '0 3 * * *'

steps:
  - uses: actions/checkout@v4
  - run: brew install argylebits/tap/fresco
  - name: Generate and upload
    run: fresco upload $(fresco generate)
    env:
      FRESCO_PROMPT:  ${{ secrets.FRESCO_PROMPT }}
      FRESCO_SLUG:    ${{ secrets.FRESCO_SLUG }}
      GEMINI_API_KEY: ${{ secrets.GEMINI_API_KEY }}
      # ... R2 secrets
```

**On release** ([`fresco-release.yml`](Examples/fresco-release.yml)):

```yaml
on:
  release:
    types: [published]
```

**Manual dispatch** ([`fresco-dispatch.yml`](Examples/fresco-dispatch.yml)):

```yaml
on:
  workflow_dispatch:
    inputs:
      prompt:
        description: 'Override the default prompt'
```

There are also step snippets for updating a README image, maintaining a gallery, and copying to a stable `latest` URL. See [`Examples/SETUP.md`](Examples/SETUP.md) for the full list and setup instructions.

---

## License

[Apache License 2.0](LICENSE)
