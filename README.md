# FAF Stack

This repository aims to provide a complete and ready-to-go Docker Compose file to set up a complete FAF Stack, or
parts of it, with a single command.

## Structure

There are two directories: `config` (already there) and `data` (created upon first start).

### Configuration

Each service has its own directory within `conf`. They usually contain an environment file and/or other configuration
files needed for the service to operate properly. Environment files are loaded by Docker Compose and additional
files/directories may be mounted as volumes (both as specified in `docker-compose.yml`).

For production or personal use, we recommend to create a new branch in which configuration files can be committed
safely. Once the stack gets updated, changes can be merged into this branch as needed. However, **do never push
production or your personal configuration files**.

### Data

Some services need to persist files in volumes, or read files of other services. All volumes are created inside 
the `data` directory, which is listed in `.gitignore`. It goes without saying that none of these files should ever be
committed.

## Naming

To keep things easy and avoid conflicts, all services, network aliases, folder names and environment files have
consistent names.

## Usage

### Prerequisites

* [Docker](https://github.com/docker/docker/releases) v1.13.0 or newer
* [Docker Compose](https://github.com/docker/compose/releases) v1.10.0 or newer

### Start all at once

```
docker-compose up -d
```

### Start a single service

If you start a single service, services it depends on will be started automatically. For instance:

```
docker-compose up -d faf-server
```

This also starts `faf-db`.

### Start from local repository

To start a service from your local repository, find its `image` or `build` in the `docker-compose.yml` and change it to:

```
build: <path>
```

Where `<path>` is for instance `../faf-server`.
