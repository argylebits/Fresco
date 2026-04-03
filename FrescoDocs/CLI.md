# Fresco — CLI Reference

## Installation

```bash
brew install argylebits/tap/fresco
```

---

## Commands

### `fresco generate`

Generates an image and writes it to `/tmp`. Prints the local file path.

```bash
fresco generate
```

**What it does:**
1. Reads configuration from environment variables (via swift-configuration)
2. Calls Gemini Imagen API with the configured prompt (or overridden/appended prompt)
3. Writes the image to `/tmp/fresco/{slug}/{timestamp}.jpg`
4. Prints the file path to stdout

**Flags:**

| Flag | Description |
|---|---|
| `--prompt <prompt>` | Override `FRESCO_PROMPT` entirely for this run |
| `--append <text>` | Append text to `FRESCO_PROMPT` for this run |
| `--slug <slug>` | Override `FRESCO_SLUG` for this run |
| `--gemini-api-key <key>` | Override `GEMINI_API_KEY` for this run |

**Examples:**

```bash
# Standard generation
fresco generate

# One-off with a completely different prompt
fresco generate --prompt "A sunset over the Hill Country"

# Append version info to the configured prompt
fresco generate --append "Celebrating release v2.1.0"
```

---

### `fresco upload`

Uploads a local image to Cloudflare R2. Prints the public URL.

```bash
fresco upload <file> [destination]
```

**What it does:**
1. Reads the image file at the given path
2. Uploads it to R2 as `{slug}/{filename}` (or `{slug}/{destination}` if provided)
3. Prints the public URL to stdout

**Arguments:**

| Argument | Description |
|---|---|
| `file` | Path to the image file to upload |
| `destination` | Optional destination filename (defaults to the source filename) |

**Flags:**

| Flag | Description |
|---|---|
| `--slug <slug>` | Override `FRESCO_SLUG` for this run |
| `--r2-account-id <id>` | Override `R2_ACCOUNT_ID` |
| `--r2-access-key-id <id>` | Override `R2_ACCESS_KEY_ID` |
| `--r2-secret-access-key <key>` | Override `R2_SECRET_ACCESS_KEY` |
| `--r2-bucket <name>` | Override `R2_BUCKET` |
| `--r2-public-base-url <url>` | Override `R2_PUBLIC_BASE_URL` |

**Examples:**

```bash
# Upload with original filename
fresco upload /tmp/fresco/my-project/2026-04-02-120000.jpg

# Upload as a specific filename
fresco upload /tmp/fresco/my-project/2026-04-02-120000.jpg latest.jpg
```

---

### `fresco remote copy`

Copies an object within R2 (server-side, no download/re-upload).

```bash
fresco remote copy <source> <destination>
```

**What it does:**
1. Issues an S3 CopyObject request to copy `{slug}/{source}` to `{slug}/{destination}`
2. Prints the public URL of the destination object

**Arguments:**

| Argument | Description |
|---|---|
| `source` | Source filename (within your slug's namespace) |
| `destination` | Destination filename |

**Flags:**

| Flag | Description |
|---|---|
| `--slug <slug>` | Override `FRESCO_SLUG` for this run |
| `--r2-account-id <id>` | Override `R2_ACCOUNT_ID` |
| `--r2-access-key-id <id>` | Override `R2_ACCESS_KEY_ID` |
| `--r2-secret-access-key <key>` | Override `R2_SECRET_ACCESS_KEY` |
| `--r2-bucket <name>` | Override `R2_BUCKET` |
| `--r2-public-base-url <url>` | Override `R2_PUBLIC_BASE_URL` |

**Examples:**

```bash
# Alias a dated image to latest.jpg
fresco remote copy 2026-04-02-120000.jpg latest.jpg
```

---

### Composable workflows

The commands compose via shell substitution:

```bash
# Generate and preview (macOS)
open $(fresco generate)

# Generate and preview (Linux)
xdg-open $(fresco generate)

# Generate and upload (keeps original filename)
fresco upload $(fresco generate)

# Generate and upload as a specific filename
fresco upload $(fresco generate) latest.jpg

# Generate, upload dated, then alias to latest
IMAGE=$(fresco generate)
fresco upload "$IMAGE"
fresco remote copy "$(basename "$IMAGE")" latest.jpg
```

**Event-driven usage:** The commands can be called from any workflow trigger. For example, to generate a release image:

```yaml
on:
  release:
    types: [published]

steps:
  - run: fresco upload $(fresco generate --append "Release v${{ github.event.release.tag_name }}")
```

---

## Global flags

These flags work on all commands:

| Flag | Description |
|---|---|
| `--help` | Show help |
| `--version` | Show Fresco version |

---

## Environment variables

All configuration is via environment variables, managed by [apple/swift-configuration](https://github.com/apple/swift-configuration).

### Generate

| Variable | Description |
|---|---|
| `FRESCO_PROMPT` | The image generation prompt |
| `FRESCO_SLUG` | Project slug (used in filenames and R2 paths) |
| `GEMINI_API_KEY` | Google Gemini API key |

### Upload and remote copy

| Variable | Description |
|---|---|
| `FRESCO_SLUG` | Project slug (used in R2 paths) |
| `R2_ACCOUNT_ID` | Cloudflare account ID |
| `R2_ACCESS_KEY_ID` | R2 access key ID |
| `R2_SECRET_ACCESS_KEY` | R2 secret access key |
| `R2_BUCKET` | R2 bucket name |
| `R2_PUBLIC_BASE_URL` | R2 public URL |

Locally, store these in `.env` (gitignored). In CI, use GitHub Actions secrets.

---

## GitHub Actions workflow

See the [`Examples/`](../Examples/) directory for ready-to-use workflows and step snippets. See [`Examples/SETUP.md`](../Examples/SETUP.md) for setup instructions.
