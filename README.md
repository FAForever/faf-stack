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

Some containers need to persist files in volumes, or read files of other containers. All volumes are created inside 
the `data` directory, which is listed in `.gitignore`. It goes without saying that none of these files should ever be
committed.
