# Retro Rage Arcade — Web CI & Future Idea AI VPS Deployment Guide

This document describes the automated Web build pipeline in `devil1527/rage_bait` and the future manual infrastructure setup required to serve `https://play.ideaai.in` on the existing Idea AI Apache VPS.

## 1. Branch & CI Architecture

- **Single source-code branch:** `migration/android-api36-godot47`
  - Android APK CI (`.github/workflows/android-dev-manual.yml`) and Web HTML5 CI (`.github/workflows/web-export.yml`) both build from this same source branch.
  - Adding or updating `.github/workflows/web-export.yml` or this file (`web/DEPLOYMENT.md`) does **not** trigger Android APK or AAB workflows.
- **Generated deployment branch:** `web-deploy`
  - Maintained strictly as a single-commit orphan snapshot containing **only** the validated `build/web/` output plus `deploy-metadata.json`.
  - Contains no Godot source code, scenes, Android plugins, keystores, or `ad_config.json`.
  - Never merged back into `migration/android-api36-godot47`, `main`, or `release/play`.
  - Failed tests, export errors, or validation failures exit before publishing, preserving the last known-good `web-deploy` snapshot.

## 2. Enabling Automatic `web-deploy` Publishing

By default, `.github/workflows/web-export.yml` runs all tests, exports `"Web"`, and validates outputs without modifying branches. To allow CI to create/update `web-deploy`:

1. **Continuous auto-publish from `migration/android-api36-godot47`:**
   - GitHub Repository Settings → **Secrets and variables** → **Actions** → **Variables** → add `ENABLE_WEB_DEPLOY_BRANCH` = `true`.
2. **One-off manual publish:**
   - GitHub **Actions** → **Web HTML5 Build & Export** → **Run workflow** on `migration/android-api36-godot47` with `publish_web_deploy = true`.

---

## 3. Future Idea AI VPS Hosting Setup (`https://play.ideaai.in`)

> **Important Isolation Rules:**
> - Root site `ideaai.in` (`/var/www/ideaai/`) must remain completely untouched.
> - Privacy policy (`https://devil1527.github.io/rage_bait/privacy-policy.html`) and AdMob `app-ads.txt` (`https://devil1527.github.io/app-ads.txt`) remain hosted separately and untouched.
> - Do not run VPS commands, Apache edits, or DNS changes from `rage_bait` unless explicitly executed during deployment setup.

### 3.1 Dedicated VPS Directory & Restricted SSH User
- Target document root on the Ubuntu VPS: `/var/www/play.ideaai.in/`
- Create a dedicated deployment identity (separate from `deploy-ideaai`) with write ownership restricted strictly to `/var/www/play.ideaai.in/` (and a temporary staging folder such as `/home/deploy-play/upload`), with zero write permissions to `/var/www/ideaai/` or system Apache configs.
- Pull or sync **only** from `devil1527/rage_bait` branch `web-deploy` (e.g., shallow `git fetch origin web-deploy` + `rsync --delete` of the built Web files to `/var/www/play.ideaai.in/`).

### 3.2 Isolated Apache VirtualHost Configuration (`play.ideaai.in`)
- Create a dedicated site config (e.g., `/etc/apache2/sites-available/play.ideaai.in.conf`), separate from `ideaai.in`:
  - `ServerName play.ideaai.in`
  - `DocumentRoot /var/www/play.ideaai.in`
  - MIME types (ensure `.wasm`, `.js`, and `.pck` serve cleanly):
    - `AddType application/wasm .wasm`
    - `AddType application/javascript .js .mjs`
    - `AddType application/octet-stream .pck`
  - Enable compression (`mod_deflate` / `mod_brotli`) for `text/html`, `application/javascript`, `application/wasm`, and `application/octet-stream`.
  - Cache policy:
    - Keep `index.html` and `deploy-metadata.json` non-cached (`Cache-Control: no-cache, must-revalidate`) so browser refreshes always load matching `.pck`/`.wasm` hashes.
    - Keep `.wasm`, `.pck`, `.js` cache-friendly (or short-TTL until content hashing/query versioning is needed).
  - **Cross-Origin Isolation (COOP/COEP) is NOT required:** `[preset.2]` uses single-threaded Web export (`variant/thread_support=false`).

### 3.3 Cloudflare DNS & TLS
- Add a single DNS record in Cloudflare for the subdomain only:
  - Type: `A` (pointing to the Idea AI VPS IPv4, matching the VPS Apache vhost) or `CNAME`.
  - Name: `play` (`play.ideaai.in`).
  - Keep Cloudflare SSL/TLS in `Full (strict)` (with valid Apache Origin / Let's Encrypt certificate for `play.ideaai.in`).
  - Do not modify root `ideaai.in` records, SPF/TXT records, or `/var/www/ideaai/`.
