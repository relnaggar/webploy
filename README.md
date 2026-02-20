# deploy

# Quick Start

## Step 1

```bash
script/aws-install-docker.sh # only need to run once
```

## Step 2

```bash
script/up.sh DOCKER_IMAGE_IDENTIFIER
```
Replace `DOCKER_IMAGE_IDENTIFIER` with the identifier of the image you want to deploy in the format `dockerhub_username/image_name:image_tag`. For example, `johndoe/myapp:latest`.

On subsequent runs, you can optionally omit the `DOCKER_IMAGE_IDENTIFIER` argument.

## Step 3 (optional)

You can now run certbot to get a certificate from Let's Encrypt:

```bash
script/set-up-certbot.sh
script/run-certbot.sh "-w /var/www/public -d yourdomain.com"
```

## Step 4 (optional)

Enable continuous SQLite replication to Cloudflare R2 via [Litestream](https://litestream.io):

```bash
script/set-up-litestream.sh
```

You will be prompted for your Cloudflare account ID, R2 bucket name, R2 access key, R2 secret key, and the path to your SQLite database inside the container (e.g. `/var/db/database.sqlite`).

This starts a Litestream sidecar that streams WAL changes to R2 within seconds of each write. WAL history is retained for 72 hours, with a full snapshot every 6 hours.

### Restoring from backup

```bash
script/db-restore.sh app.sqlite                               # restore to latest
script/db-restore.sh app.sqlite --timestamp 2026-01-15T10:30:00Z  # restore to point in time
```

The app will be taken offline briefly during a restore.

### Checking replication health

```bash
script/litestream-status.sh
```

Shows the service replica count and the last 50 log lines. Run this to verify replication is active or to diagnose errors.

# Debugging

Get a shell inside the running container:
```bash
script/exec.sh -u USER
```

Run a single command inside the running container:
```bash
script/exec.sh -u USER COMMAND
```

Default `USER` is `root`.

# Stop the production server

```bash
docker stack rm prod
```

# Renew expired certbot certificate

```bash
script/run-certbot.sh renew
```
