<!-- Fresco image -->
![Fresco](https://pub-d60dc12417c74d04b3dd6a1ed43e02c4.r2.dev/fresco/2026-03-25-141039.jpg)

# Fresco

**Scheduled AI-generated images for any project.**

Fresco is a CLI that generates images using the Google Gemini Imagen API, uploads them to Cloudflare R2, and prints the URL. Pair it with a GitHub Actions workflow to keep a fresh image in your README, gallery, or anywhere else.

The banner image above is updated by Fresco.

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

# Generate an image
fresco generate

# Preview locally without uploading
fresco generate --preview
```

---

## Configuration

All config can be passed as flags, environment variables, or via a `.env` file. Flags take precedence over env vars, which take precedence over `.env`.

See [`fresco.template.env`](fresco.template.env) for the full variable list.

| Flag | Env var | Description |
|---|---|---|
| `--prompt` | `FRESCO_PROMPT` | Image generation prompt |
| `--slug` | `FRESCO_SLUG` | Project slug (used in R2 paths) |
| `--gemini-api-key` | `GEMINI_API_KEY` | Google Gemini API key |
| `--r2-account-id` | `R2_ACCOUNT_ID` | Cloudflare account ID |
| `--r2-access-key-id` | `R2_ACCESS_KEY_ID` | R2 access key ID |
| `--r2-secret-access-key` | `R2_SECRET_ACCESS_KEY` | R2 secret access key |
| `--r2-bucket` | `R2_BUCKET` | R2 bucket name |
| `--r2-public-base-url` | `R2_PUBLIC_BASE_URL` | Public base URL for R2 images |

---

## Usage

```bash
fresco generate                                          # use configured prompt
fresco generate --prompt "A sunset over the Hill Country" # override prompt
fresco generate --append "Celebrating release v2.1.0"    # extend configured prompt
fresco generate --preview                                # generate locally, no upload
```

---

## Workflow examples

The [`Examples/`](Examples/) directory has ready-to-use GitHub Actions workflows. Copy one into `.github/workflows/` and add your secrets. The snippets below are excerpts — see the linked files for complete workflows.

**Scheduled generation** ([`fresco-cron.yml`](Examples/fresco-cron.yml)):

```yaml
on:
  schedule:
    - cron: '0 3 * * *'

steps:
  - uses: actions/checkout@v4
  - run: brew install argylebits/tap/fresco
  - run: fresco generate
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

There are also step snippets for updating a README image, maintaining a gallery, and copying to a stable `latest.jpg` URL. See [`Examples/SETUP.md`](Examples/SETUP.md) for the full list and setup instructions.

---

## License

[Apache License 2.0](LICENSE)
