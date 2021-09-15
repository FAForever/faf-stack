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

    scripts/init-db.sh
    scripts/init-rabbitmq.sh
    scripts/init-hydra.sh
    scripts/create-hydra-test-clients.sh

This will launch some core services and generate users, database schemas and OAuth clients.

### Update database schema

    docker-compose run --rm faf-db-migrations migrate

# Service specific configurations

## Postal

### Create initial user

Once Postal is running, create a user by executing the following command:
```
docker exec -it faf-postal /opt/postal/bin/postal make-user
```

### Set up a mail server for Mautic

1. Access Postal's web interface and log in with the user created above
1. Click `Create the first organization` and follow the instructions
1. Create a new mail server
    1. Click `Build your first mail server` and enter the following
    1. Name: FAF Mautic
    1. Short name: faf-mautic
    1. Mode: Choose what's appropriate
1. Set up the email domain
    1. Go to `Domain` and select `Add your first domain`
    1. Enter the domain name and continue
    1. Follow the instructions to set up the DNS correctly
    1. Click `Check my records are correct` and make sure everything is green
1. Set up an SMTP user for faf-mautic
    1. Go to `Credentials` and select `Add your first credential`
    1. Type: `SMTP`, Name: `FAF Mautic User`, Key: `faf-mautic`, Hold: `Process all messages`
    1. Click `Create credential`
1. Check the credentials for Mautic
    1. Go to `Overview` and select `Read about sending e-mail`
    1. Note `Username` and `Password`

## Mautic

Make sure you set up Postal first.

### Initial Setup

1. Access Mautic's web interface and follow the instructions until `Email Configuration` 
1. Enter the email configuration
    1. Email handling: `Send immediately`, Mailer transport: `Other SMTP Server`. Enter Server: `faf-postal`, Port: `25`, Encryption: `None`, Authentication mode: `Plain`
    1. Enter `Username` and `Password` as seen in Postal (check the Postal setup instructions above) 
1. Log in with the admin username and password (as created before)
1. Find and open the the `Settings` menu (top right corner)
    1. Configure API access
        1. Go to `Configuration`, then `API Settings`
        1. Set API enabled: `Yes`. If mautic/mautic#5743 is still unresolved, set Enable HTTP basic auth: `Yes`
        1. Click `Apply`
        1. If mautic/mautic#5743 is resolved, in the Settings menu, go to `API Credentials` and set up credentials for `faf-java-api`
        1. If mautic/mautic#5743 is still unresolved, go to `Users` in the settings menu and add a user for `faf-java-api`. Preferably, create a role with proper permissions first.
        1. Delete Mautic's cache, otherwise the API won't work. Delete `data/faf-mautic/html/app/cache`
    1. Configure E-Mail
        1. Go to `Configuration`, then `Email Settings`
        1. Click `Test connection` and expect `Success!`
        1. Click `Send test email` and expect to receive an email in the inbox of your user's email account
        1. Preferably, configure an inbox and configure Bounces, Unsubscribe Requests and Contact Replies
        1. Under `Message Settings`, set Disable trackable urls: `Yes`
        1. Under `Unsubscribe Settings`, set all `Show ...` options to `Yes`
        1. Click `Apply`
    1. Configure Custom Fields
        1. Go to `Custom Fields`
        1. Uncheck all except (Alias): country, preferred_locale
        1. Click `New` and enter Label: `FAF User ID`, Alias: `faf_user_id`, Object: `Contact`, Group: `Core`, Data Type: `Text`, Required: `Yes`, Available for segments: `No`, Is Unique Identifier: `Yes`. Click `Save & Close`
        1. Click `New` and enter Label: `FAF Username`, Alias: `faf_username`, Object: `Contact`, Group: `Core`, Data Type: `Text`, Required: `Yes`, Available for segments: `No`, Is Unique Identifier: `Yes`. Click `Save & Close`
        1. Open the field `Email` and set Required: `Yes`
        
## Grafana

### Initial Setup

1. Log into Grafana using `admin/admin`
1. Add a Prometheus datasource named `Prometheus` at `http://faf-prometheus:9090`
1. Go to global organization settings and change the name from `Main org.` to `Forged Alliance Forever`. This is 
required to enable anonymous access, too.
 
