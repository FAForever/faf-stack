# How to setup NodeBB for FAF

## 1. Setup MongoDB
Configure a password in `config/faf-mongodb/faf-mongodb.env`. Then starting from `faf-stack` folder run
`scripts/init-mongodb.sh`. This will setup MongoDB and create a user with the configured password.

MongoDB keeps running after the initialization.


## 2. Install NodeBB

### 2.1. Why installation?
On first run NodeBB will build itself with some JavaScript tools. We mounted the resulting files into the folder
`/data/faf-nodebb` so you only need to do it once (and also to not loose the plugins that we will install later on).


### 2.2. Configuration
In `config/faf-nodebb/config.json` update the password in the `mongo` section as in step 1. The rest should work
out-of-the-box.

### 2.3. Install
Start the installation from `faf-stack` via `scripts/install-nodebb.sh`.
Write down the credentials of the admin user. You will need it later to configure NodeBB.

### 2.4. Startup
Now you can start NodeBB via `docker-compose up -d faf-nodebb`.


## 3. Setup SSO

### 3.1. Configure the plugin
In `config/faf-nodebb/config.json` update all attributes in the `oauth` section. Don't forget that `id` and `secret`
have to match an OAuth client in the FAF db (table `oauth_clients`).

The oauth routes might seem confusing. This is due to the nature of docker. User calls come from the outside (localhost
or your DNS) while token fetching and user fetching is done from faf-nodebb docker container to faf-java-api docker
container via the internal docker network (thus: `http://faf-java-api:8010`).

### 3.2. Configure the faf-db
The nodebb oauth login requires a row in the `oauth_clients` table. Take the `id` and `secret` from the config.json.
The client_type needs to be `confidential`, the scope `public_profile`, the callback url
`${NODEBB_URL}/auth/${NODEBB_OAUTH_ID}/callback`.

### 3.3. Install the plugin

#### 3.3.1. On test / production
After the OAuth login NodeBB needs to fetch the user relevant information from a dedicated website like `/me`. As this
is different for each provider we published our own plugin on npm.

Find the plugin `nodebb-plugin-sso-oauth-faforever`, install it, then activate it from the Inactive tab and finally
restart NodeBB.

#### 3.3.2. For development
Copy the folder into `/data/faf-nodebb/node_modules/nodebb-plugin-sso-oauth-faforever`. `cd` into the plugin directory
and run `sudo npm i` (you can skip sudo if you setup file ownership). Restart NodeBB.

### 3.3.3. Configure NodeBB
**Attention: Only perform this changes if you created an admin account via OAuth! Otherwise you can't login as admin
anymore.**

In the ACP under `Settings->User` configure:
 -  Disable username changes
 -  Disable email changes
 -  Disable pass changes
 -  Disable Allow account deletion
 -  Registration Type = No registration

 In the ACP under `Manage->Privileges` configure:
 - Disable Local Login for all groups

If you configured it correctly, on Login you should be redirected to the faf-java-api login page instantly.


## 4. Setup write-api plugin
The SSO plugin allows FAF users to login with their current username. But what happens if the FAF user changes his
username? To cover that case we need to setup the `nodebb-plugin-write-api`. This enables our API to also change the
username in the NodeBB account.

Go the admin panel of NodeBB and find the plugin `nodebb-plugin-write-api`. Install it, then activate it. Then go back
to the main dashboard and `rebuild & restart` (restart alone is not sufficient). Now you have a new menu entry in under
the plugins button called `Write API`. In the master token section create a new token.

Configure the faf-java-api with this token.

---------

If you want to test it manually, you can use postman. The master token is your value for the Authorization header.
Use it like `Authorization: Bearer <master-token>`.

In this sample call we impersonate the admin user (id 1) to change the name to admin2.

PUT: `http://localhost:8016/api/v2/users/1`
```
{
   	"_uid": "1",
   	"username": "admin2"
}
```
