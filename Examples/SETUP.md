# Fresco Setup Guide

## Configuration

Fresco resolves each config value in this order:

1. **Flags** (if provided)
2. **Environment variables** already set in the shell or CI
3. **`.env` file** in the current directory

See `fresco.template.env` for the full list of variables.

### Local development

Copy `fresco.template.env` to `.env` and fill in your values. Fresco picks it up automatically.

### CI (GitHub Actions)

Add your values as repository secrets under Settings > Secrets and variables > Actions. The example workflows pass them as environment variables.

## .gitignore

Add `.env` to your `.gitignore` to keep secrets out of version control:

```
.env
```

## Workflows

Copy one of the example workflows into `.github/workflows/`:

- `fresco-cron.yml` — generate on a schedule
- `fresco-dispatch.yml` — generate on demand from the GitHub UI
- `fresco-release.yml` — generate when a release is published

## README and gallery updates

Fresco generates an image, uploads it, and prints the URL. What you do with that URL is up to you.

The step snippets show one approach using an HTML comment as a marker. For example, add this to your README where you want the image:

```markdown
<!-- Fresco image -->
![Fresco](https://your-initial-image-url)
```

The marker can be whatever you want — just keep it in sync with the `sed` pattern in your workflow.

- `steps-update-readme.yml` — replaces the image line after the marker
- `steps-update-gallery.yml` — appends a row to a markdown table

See `fresco.template.gallery.md` for a starter gallery file.
