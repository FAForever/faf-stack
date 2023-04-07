# FAF Stack

This repository aims to provide a ready-to-go Docker Compose setup for managing the complete FAF stack (or parts of it) with simple commands.

The FAF production and test server use this repository and therefore guarantee close-to-production readyness.

## Structure

The FAF stack consist of multiple components:

* Service definitions in .yml files
* Global and application level configuration
* Application data

This repository contains only templates of the configuration and no data. "Real" configuration and data are excluded by `.gitignore`. In fact, all files and directories are excluded if not explicitly un-ignored within `.gitignore`. The data directory will be automatically created.

### Service definitions

FAF is a very complex infrastructure. In order to make it easier for new developers to get into it, we split the services across multiple docker-compose files:

* `docker-compose.yml` contains all **core** services of FAF. If you want to start developing for FAF you can concentrate on this particular file.
* `faf-extra.yml` contains services for the FAF community which are not required for the core infrastructure to run.
* `monitoring.yml` contains dedicated monitoring applications which provide insights on the load and behavior of the FAF applications

### Configuration

On root level there needs to be an `.env` file which contains some global setup.

Each service has its own directory within `config`. They usually contain an environment file and/or other configuration files needed for the service to operate properly. Environment files are loaded by Docker Compose and additional files/directories may be mounted as volumes (both as specified in their respective `.yml` file).

The `config` directory does not exist and has to be copied from `config.templates`. After that, it has to be kept in sync with updates to `config.templates` manually (like when a parameter has been added, renamed or removed).
If you don't need / want to change the application config, you could also create a **symlink** from `config.template` to `config`. This way you will always have the latest default config. 

### Data

Some services need to persist files in volumes, or read files of other services. All volumes are created inside 
the `data` directory.

**Attention Windows users**: Docker for Windows has some troubles mounting volumes to your hard disk. You need to configure access to the drive and even then some services might refuse to work. For a better experience we recommend using a virtual machine running Linux or at least running docker in the Windows Subsystem for Linux (WSL).

## Naming

To keep things intuitive and avoid conflicts, all services, network aliases, user names, folder names and environment files follow a
consistent naming.

## Usage

### Prerequisites

* [Docker](https://github.com/docker/docker/releases) 20.10.7-ce or newer
* [Docker Compose](https://github.com/docker/compose/releases) v1.28.6 or newer

(It might work with older versions but is not tested on these.)

### Copy configuration template files

    cp -R config.template config
    cp .env.template .env


### Recreate security keys (for production systems)

In folder `config/faf-java-api/pki` replace `private.key` and `public.key` with new keys generated with `ssh-keygen -m pem`. The secret key needs to be in rsa format and the public key in ssh-rsa format (see config.template for examples).

Hint: Some linux distros generate 3072 bit RSA keys by default (e.g. Arch). 3072 bit is not supported. Please use 2048 bit or 4096 bit key length.  


### Initialize core services

    scripts/init-all.sh

This will launch some core services and generate system users, database schemas and OAuth clients.

### Load test data

After initialization you will have a blank database - no logins, no maps, etc. In all likelihood you'd like to load some data to use this environment. You could look at the [test data](https://github.com/FAForever/db/blob/develop/test-data.sql), the [sanitized db dump](https://github.com/FAForever/faf-db-dump/tree/2294e41bae36acaed4a52c8a7d090ddd76001a25) or [API server integration test data](https://github.com/FAForever/faf-java-api/tree/develop/src/inttest/resources/sql). Each of these has pros and cons and commonly becomes stale (as schema evolves etc), and you may need to fiddle with data to match new schemas; database repository history may help.

To load the data, you'd run a command along the lines of -

    docker exec -i  faf-db mysql -D faf -uroot -pbanana < $DB_REPO/test-data.sql

### Update database schema

If new migrations were added since you've initialized your environment, you can run them with -

    docker-compose run --rm faf-db-migrations migrate

# Service specific configurations

## Grafana

### Initial Setup

1. Log into Grafana using `admin/admin`
1. Add a Prometheus datasource named `Prometheus` at `http://faf-prometheus:9090`
1. Go to global organization settings and change the name from `Main org.` to `Forged Alliance Forever`. This is 
required to enable anonymous access, too.
 
