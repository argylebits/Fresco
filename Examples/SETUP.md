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
- `fresco-pre-release.yml` — generate when a pre-release is published
- `fresco-release-pr.yml` — generate when a PR is labeled "release"
- `fresco-tag.yml` — generate when a version tag is pushed

## Optional step snippets

Add these steps after the generate step in any workflow above.

- `steps-update-readme.yml` — replaces the image line after a marker in your README
- `steps-update-gallery.yml` — appends a row to a markdown table
- `steps-latest-jpg.yml` — copies the image to a stable `latest.jpg` URL on R2 and purges the GitHub camo cache

## README image marker

The readme snippet uses an HTML comment as a marker. For example:

```markdown
<!-- Fresco image -->
![Fresco](https://your-r2-domain.dev/your-slug/latest.jpg)
```

The marker can be whatever you want — just keep it in sync with the `sed` pattern in your workflow.

## Gallery

To maintain a gallery of generated images:

1. Copy `fresco.template.gallery.md` to `gallery.md` in your repo
2. Add the steps from `steps-update-gallery.yml` to your workflow
