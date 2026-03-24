# Fresco — Deployment Guide

This guide covers self-hosting the Fresco server (Phase 2) on a VPS. If you're using the CLI in standalone mode (Phase 1), you don't need this guide — just follow the [CLI Reference](CLI.md).

---

## What you're deploying

A Hummingbird Swift service that:
- Manages feed configurations in PostgreSQL
- Runs a persistent scheduler (one background Task per feed)
- Calls Gemini and uploads to R2 on schedule
- Exposes an API for the CLI to call in server mode

---

## Requirements

- Ubuntu 22.04 VPS (Hetzner, DigitalOcean, etc.)
- Docker + Docker Compose
- Nginx
- An existing PostgreSQL instance (or add one to the Compose stack)
- Cloudflare R2 bucket
- Gemini API key
- Domain pointed at your VPS

---

## Setup

### 1. Clone the repo

```bash
git clone https://github.com/argylebits/Fresco /opt/fresco
cd /opt/fresco
```

### 2. Configure environment

```bash
cp fresco.template.env .env
nano .env
```

Required values:

```bash
ADMIN_API_KEY=$(openssl rand -hex 32)
GEMINI_API_KEY=your-gemini-api-key
DATABASE_URL=postgres://user:password@localhost:5432/fresco
R2_ACCOUNT_ID=your-cloudflare-account-id
R2_ACCESS_KEY_ID=your-r2-access-key-id
R2_SECRET_ACCESS_KEY=your-r2-secret-access-key
R2_BUCKET=fresco-images
R2_PUBLIC_BASE_URL=https://pub-xxxx.r2.dev
```

```bash
chmod 600 .env
```

### 3. Start the server

```bash
docker compose up -d --build
curl http://localhost:8080/health
```

### 4. Configure Nginx

```bash
cp nginx.conf /etc/nginx/sites-available/fresco
# edit server_name to your domain
ln -s /etc/nginx/sites-available/fresco /etc/nginx/sites-enabled/
certbot --nginx -d fresco.yourdomain.com
systemctl reload nginx
```

### 5. Point the CLI at your server

```bash
# On your development machine
fresco init --server https://fresco.yourdomain.com
```

---

## Registering a feed via CLI

```bash
fresco init --server https://fresco.yourdomain.com
```

This registers the feed with your server and configures the CLI to use server mode for this project. The GitHub Actions workflow is updated to call your server instead of Gemini directly — meaning the Actions runner needs no Gemini or R2 credentials, only your server URL and feed API key.

---

## Server API

The full OpenAPI spec is at `docs/openapi.yaml`. Key endpoints:

| Method | Path | Auth | Description |
|---|---|---|---|
| GET | `/health` | None | Health check |
| POST | `/feeds` | Admin key | Create a feed |
| GET | `/feeds` | Admin key | List all feeds |
| GET | `/feeds/:slug/status` | Feed key | Last generation status |
| POST | `/feeds/:slug/trigger` | Feed key | Manual generation trigger |
| GET | `/feeds/:slug/history` | Feed key | Generation history |

---

## Updates

```bash
cd /opt/fresco
git pull
docker compose build
docker compose up -d
```

---

## Logs

```bash
docker compose logs -f fresco-server
```
