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
script/run-certbot.sh [optional arguments to certbot]
```

# Debugging

Get a shell inside the running container:

```bash
script/exec.sh
```

Run a single command inside the running container:

```bash
script/exec.sh your-command
```

# Known Issues

If you're using certbot and you make a change to anything in `/etc/apache2/sites-available/` in the Docker image, you'll need to remove certbot before your changes will take effect:

```bash
script/remove-certbot.sh
```

Then you can re-run certbot (including setup) if desired:

```bash
script/set-up-certbot.sh
script/run-certbot.sh [optional arguments to certbot]
```

Alternatively, you can manually apply the changes to the Apache configuration in `.ssl/apache-sites-available/` and then restart the server.

# Stop the production server

```bash
docker stack rm prod
```

# Renew expired certbot certificate

```bash
script/run-certbot.sh renew
```
