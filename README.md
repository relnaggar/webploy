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
