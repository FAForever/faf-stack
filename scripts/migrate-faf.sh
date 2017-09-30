#!/bin/bash
#set -x
#
# This script sets up a complete FAF server and migrates all relevant data over from the old server.
# Each file and directory is copied to its proper place in the new directory structure.
#
# This includes:
#   * SSH settings
#   * Users & groups
#   * Docker & Docker-Compose
#   * Git
#   * rsync
#   * FAF-Stack
#   * Directories
#   * Permissions
#   * Security settings
#
# Every action is idempotent, which means that the script can be executed repeatedly.
#
# The script is interactive and has your back, so you can just run it like so:
#
#   curl -fsSL https://raw.githubusercontent.com/FAForever/faf-stack/develop/scripts/migrate-faf.sh | bash
#

SOURCE_HOST="faforever.com"
SOURCE_HOST_USER="sheeo"
FAF_USER="faforever"
FAF_GROUP="faforever"
FAF_USER_ADDITIONAL_GROUPS=""
FAF_LOGIN_SHELL="/bin/bash"
PERMIT_ROOT_LOGIN="no"
ALLOW_PASSWORD_AUTHENTICATION="no"
DEFAULT_UMASK="007"
FAF_BASE_DIR="/opt/faf"
FAF_STACK_URL="https://github.com/FAForever/faf-stack.git"
DOCKER_COMPOSE_VERSION="1.16.1"

declare -A PATH_MAPPINGS
#              /opt/stable/api                       ignored, part of faf-stack
#              /opt/stable/api_secrets.env           ignored, part of faf-stack
#              /opt/stable/app                       ignored, not used anymore
PATH_MAPPINGS['/opt/stable/certs/']="${FAF_BASE_DIR}/data/faf-nginx/certs"
#              /opt/stable/~certs                    ignored, not used anymore
#              /opt/stable/checklist.md              ignored, obsolete
#              /opt/stable/clans                     ignored, part of faf-stack
PATH_MAPPINGS['/opt/stable/content/achievements/']="${FAF_BASE_DIR}/data/content/achievements"
#              /opt/stable/content/CustomGame*log    ignored, trash
PATH_MAPPINGS['/opt/stable/content/faf/avatars/']="${FAF_BASE_DIR}/data/content/avatars"
#              /opt/stable/content/faf/bans-*.txt    ignored, trash
#              /opt/stable/content/faf/FAF*0.10*     ignored, very old client releases
PATH_MAPPINGS['/opt/stable/content/faf/images/']="${FAF_BASE_DIR}/data/content/images"
PATH_MAPPINGS['/opt/stable/content/faf/include/']="${FAF_BASE_DIR}/data/content/include"
PATH_MAPPINGS['/opt/stable/content/faf/leaderboards/']="${FAF_BASE_DIR}/data/content/leaderboards"
PATH_MAPPINGS['/opt/stable/content/faf/tutorials/']="${FAF_BASE_DIR}/data/content/tutorials"
PATH_MAPPINGS['/opt/stable/content/faf/updaterNew/']="${FAF_BASE_DIR}/data/content/legacy-featured-mod-files"
#              /opt/stable/content/faf/vault/*.png   ignored, not used anymore
#              /opt/stable/content/faf/vault/images  ignored, old map previews
PATH_MAPPINGS['/opt/stable/content/faf/vault/map_previews/small/']="${FAF_BASE_DIR}/data/content/maps/previews/small"
PATH_MAPPINGS['/opt/stable/content/faf/vault/map_previews/large/']="${FAF_BASE_DIR}/data/content/maps/previews/large"
PATH_MAPPINGS['/opt/stable/content/faf/vault/maps/']="${FAF_BASE_DIR}/data/content/maps"
PATH_MAPPINGS['/opt/stable/content/faf/vault/maps.php']="${FAF_BASE_DIR}/data/content/vault"
PATH_MAPPINGS['/opt/stable/content/faf/vault/map_vault/']="${FAF_BASE_DIR}/data/content/vault/map_vault"
PATH_MAPPINGS['/opt/stable/content/faf/vault/mods/']="${FAF_BASE_DIR}/data/content/mods"
PATH_MAPPINGS['/opt/stable/content/faf/vault/mods_thumbs/']="${FAF_BASE_DIR}/data/content/mods/thumbs"
PATH_MAPPINGS['/opt/stable/content/faf/vault/replays_simple.php']="${FAF_BASE_DIR}/data/content/vault"
PATH_MAPPINGS['/opt/stable/content/faf/vault/replay_vault/0/']="${FAF_BASE_DIR}/data/content/replays"
PATH_MAPPINGS['/opt/stable/content/faf/vault/replay_vault/css/']="${FAF_BASE_DIR}/data/content/vault/replay_vault/css"
PATH_MAPPINGS['/opt/stable/content/faf/vault/replay_vault/replay.php']="${FAF_BASE_DIR}/data/content/vault"
#              /opt/stable/content/faf/xdelta'       ignored, generated as needed by the legacy updater
#              /opt/stable/content/fafclans*gzip     ignored, trash
#              /opt/stable/content/FAForever-0.10.*  ignored, very old client releases
PATH_MAPPINGS['/opt/stable/content/fafskin.zip']="${FAF_BASE_DIR}/data/content"
PATH_MAPPINGS['/opt/stable/content/favicon.ico']="${FAF_BASE_DIR}/data/content"
PATH_MAPPINGS['/opt/stable/content/Forged*.msi']="${FAF_BASE_DIR}/data/content/clients/python"
#              /opt/stable/content/Game*log          ignored, trash
PATH_MAPPINGS['/opt/stable/content/images/']="${FAF_BASE_DIR}/data/content/images"
PATH_MAPPINGS['/opt/stable/content/jre/']="${FAF_BASE_DIR}/data/content/jre"
PATH_MAPPINGS['/opt/stable/content/patchnotes/']="${FAF_BASE_DIR}/data/content/patchnotes"
#              /opt/stable/content/reports.tar.xz    ignored, trash
PATH_MAPPINGS['/opt/stable/content/server*.csr']="${FAF_BASE_DIR}/data/content"
PATH_MAPPINGS['/opt/stable/content/wheel/']="${FAF_BASE_DIR}/data/content/wheel"
PATH_MAPPINGS['/opt/stable/db/']="${FAF_BASE_DIR}/data/faf-db"
#              /opt/stable/db.bak                    ignored, obsolete
PATH_MAPPINGS['/opt/stable/db_dumps/']="${FAF_BASE_DIR}/backups/faf-db"
#              /opt/stable/db_repo                   ignored, part of faf-stack
#              /opt/stable/db_secrets.env            ignored, part of faf-stack
#              /opt/stable/discord-irc.json          ignored, part of faf-stack
#              /opt/stable/discord-irc.json.new      ignored, obsolete
#              /opt/stable/docker-compose.yml        ignored, part of faf-stack
#              /opt/stable/faf-clans.env             ignored, part of faf-stack
#              /opt/stable/faf_java_api.env          ignored, part of faf-stack
#              /opt/stable/faforever.com.key         ignored, not used anymore
#              /opt/stable/faf_server_privkey.pkcs1  ignored, not used anymore
#              /opt/stable/faf_server_pubkey.pem     ignored, not used anymore
#              /opt/stable/faftools                  ignored, scripts go into scripts/
#              /opt/stable/featured_mods             ignored, to be configured in faf-java-api
PATH_MAPPINGS['/opt/stable/forums/']="${FAF_BASE_DIR}/data/faf-phpbb3"
#              /opt/stable/.git                      ignored, part of faf-stack
#              /opt/stable/irc                       ignored, part of faf-stack
#              /opt/stable/Jeremy                    To be included in faf-stack (or, replaced by decent mod tools)
#              /opt/stable/jeremy_secrets.env        To be included in faf-stack (or, replaced by decent mod tools)
#              /opt/stable/latest.tar.gz             ignored, obsolete (contains Wordpress)
#              /opt/stable/legacy-replay-server      ignored, part of faf-stack
#              /opt/stable/legacy-secondaryServer    ignored, part of faf-stack
#              /opt/stable/legacy-updater            ignored, part of faf-stack
PATH_MAPPINGS['/opt/stable/mediawiki/']="${FAF_BASE_DIR}/data/faf-mediawiki"
#              /opt/stable/mumble_secrets.env        ignored, part of faf-stack
#              /opt/stable/murmur                    ignored, part of faf-stack
#              /opt/stable/nginx-php-sites           ignored, will be fixed in faf-website Dockerfile
#              /opt/stable/outkey.py                 ignored, not used anymore
#              /opt/stable/pear                      ignored, will be fixed in faf-website
#              /opt/stable/QAI                       To be included in faf-stack
#              /opt/stable/README.md                 ignored, obsolete
#              /opt/stable/repositories              ignored, created by faf-java-api in data/faf-java-api
#              /opt/stable/scratch                   ignored, obsolete
#              /opt/stable/server                    ignored, part of faf-stack
#              /opt/stable/scripts                   ignored, obsolete (contains an SQL dump)
#              /opt/stable/server-scripts            ignored, see https://github.com/duk3luk3/faf-server-scripts.git
#              /opt/stable/server_secrets.env        ignored, part of faf-stack
#              /opt/stable/slack_secrets.env         To be included in faf-stack
#              /opt/stable/softove                   ignored, part of faf-stack
#              /opt/stable/update-loggly-certificate.sh ignored, obsolete
PATH_MAPPINGS['/opt/stable/vhost.d/ ']="${FAF_BASE_DIR}/data/faf-nginx/vhost.d"
#              /opt/stable/website                   ignored, part of faf-stack
#              /opt/stable/wordpress                 ignored, part of faf-stacl
#              /opt/stable/wordpress.bak             ignored, obsolete


declare -A SYMLINKS
SYMLINKS["${FAF_BASE_DIR}/data/content/faf/avatars"]='../avatars'
SYMLINKS["${FAF_BASE_DIR}/data/content/faf/images"]='../images'
SYMLINKS["${FAF_BASE_DIR}/data/content/faf/include"]='../include'
SYMLINKS["${FAF_BASE_DIR}/data/content/faf/leaderboards"]='../leaderboards'
SYMLINKS["${FAF_BASE_DIR}/data/content/faf/tutorials"]='../tutorials'
SYMLINKS["${FAF_BASE_DIR}/data/content/faf/updaterNew"]='../legacy-featured-mod-files'
SYMLINKS["${FAF_BASE_DIR}/data/content/faf/vault/map_previews/small"]='../../../maps/previews/small'
SYMLINKS["${FAF_BASE_DIR}/data/content/faf/vault/map_previews/large"]='../../../maps/previews/large'
SYMLINKS["${FAF_BASE_DIR}/data/content/faf/vault/mod_thumbs/small"]='../../../mods/thumbs'
SYMLINKS["${FAF_BASE_DIR}/data/content/faf/vault/replay_vault/replay.php"]='../../../vault/replay.php'
SYMLINKS["${FAF_BASE_DIR}/data/content/faf/vault/replays_simple.php"]='../../vault/replays_simple.php'

function check_is_root {
  if [[ $EUID > 0 ]]; then
    echo "This script needs to be run as root"
    exit 1
  fi
}

function generate_ssh_key_pair {
  fafUserHome=$(eval echo "~${FAF_USER}")

  if [ -f "${fafUserHome}/.ssh/id_rsa" ]; then
    echo "Not generating SSH key as it already exists"
  else
    sudo -u "${FAF_USER}" ssh-keygen -f "${fafUserHome}/.ssh/id_rsa" -N '' || { echo "Failed to generate SSH keys"; exit 1; }
  fi

  echo
  echo "Add the following public key to the authorized_keys file of '${SOURCE_HOST_USER}@${SOURCE_HOST}"
  echo
  cat "${fafUserHome}/.ssh/id_rsa.pub"
  echo
  read -p "Press enter once you're ready"
  while ! sudo -u "${FAF_USER}" ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "${SOURCE_HOST_USER}@${SOURCE_HOST}" echo ping; do
    read -p "That did not seem to work, try again and press enter"
  done
}

function confirm_source_user_permissions {
  echo
  echo "Please make sure that the user '${SOURCE_HOST_USER}@${SOURCE_HOST}' has full read permission"
  echo "for the following files and directories:"
  echo
  for fromDirectory in "${!PATH_MAPPINGS[@]}"; do
    echo "${fromDirectory}"
  done
  echo
  answer=
  while [ "${answer}" != "continue" ]; do
     read -p "Once you're done, enter 'continue' to continue: " answer
  done
}

function configure_permit_root_login {
  sed -i "s/^ *#* *PermitRootLogin.*$/PermitRootLogin ${PERMIT_ROOT_LOGIN}/g" /etc/ssh/sshd_config
}

function configure_allow_password_authentication {
  sed -i "s/^ *#* *PasswordAuthentication.*$/PasswordAuthentication ${ALLOW_PASSWORD_AUTHENTICATION}/g" /etc/ssh/sshd_config
}

function create_groups {
  if grep -q "${FAF_GROUP}" /etc/group; then
    echo "Not creating group ${FAF_GROUP} as it already exists"
    return
  fi

  echo "Creating group ${FAF_GROUP}"
  groupadd "${FAF_GROUP}" || { echo "Failed to add group ${FAF_GROUP}"; exit 1; }
}

function create_users {
  if id "${FAF_USER}" > /dev/null 2>&1; then
    echo "Not creating user ${FAF_USER} as it already exists"
    return
  fi

  echo "Creating user ${FAF_USER}"
  useradd -g "${FAF_GROUP}" -d "/home/${FAF_USER}" -m -l -s "${FAF_LOGIN_SHELL}" -G "${FAF_USER_ADDITIONAL_GROUPS}" "${FAF_USER}" \
    || { echo "Failed add user ${FAF_USER}"; exit 1; }
}

function configure_umask {
  echo "Setting default umask to ${DEFAULT_UMASK}"
  if grep umask /etc/profile; then
    sed -i "s/^ *#* *umask.*$/umask ${DEFAULT_UMASK}/g" /etc/profile
  else
    echo "umask ${DEFAULT_UMASK}" >> /etc/profile
  fi
  . /etc/profile
}

function update_apt_index {
  echo "Updating APT index"
  apt update || { echo "Failed to update APT index"; exit 1; }
}

function install_apt_https {
  echo "Installing packages to allow APT to use repositories over HTTPS"
  apt install apt-transport-https ca-certificates software-properties-common || { echo "Failed to install HTTPS repository support for APT"; exit 1; }
}

function install_curl {
  if command -v curl >/dev/null 2>&1; then
    echo "Not installing curl as it is already installed"
    return
  fi

  echo "Installing curl"
  yes | apt install curl || { echo "Failed to install curl"; exit 1; }
}

function install_git {
  if command -v git >/dev/null 2>&1; then
    echo "Not installing Git as it is already installed"
    return
  fi

  echo "Installing Git"
  yes | apt install git || { echo "Failed to install Git"; exit 1; }
}

function install_rsync {
  if command -v rsync >/dev/null 2>&1; then
    echo "Not installing rsync as it is already installed"
    return
  fi

  echo "Installing rsync"
  yes | apt install rsync || { echo "Failed to install rsync"; exit 1; }
}

function install_docker_ce {
  if command -v docker >/dev/null 2>&1; then
    echo "Not installing Docker as it is already installed"
    return
  fi

  echo "Installing Docker"
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  # TODO verify fingerprint
  add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  apt update
  yes | apt install docker-ce || { echo "Failed to install Docker CE"; exit 1; }
}

function install_docker_compose {
  if command -v docker-compose >/dev/null 2>&1; then
    echo "Not installing Docker Compose as it is already installed"
    return
  fi

  echo "Installing Docker-Compose"
  curl -L https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose \
     || { echo "Failed to install Docker-Compose"; exit 1; }
  chmod +x /usr/local/bin/docker-compose \
     || { echo "Failed to make docker-compose executable"; exit 1; }
  hash -r
}

function clone_faf_stack {
  if [ -d "${FAF_BASE_DIR}/.git" ]; then
    echo "Not cloning faf-stack as it is already cloned (at ${FAF_BASE_DIR})"
    return
  fi

  echo "Cloning faf-stack"
  mkdir -p "${FAF_BASE_DIR}"
  sudo chown "${FAF_USER}:${FAF_GROUP}" "${FAF_BASE_DIR}"
  sudo -u "${FAF_USER}" git clone "${FAF_STACK_URL}" "${FAF_BASE_DIR}"  || { echo "Failed to clone ${FAF_STACK_URL} to ${FAF_BASE_DIR}"; exit 1; }
}

function fetch_files {
  fromDirectory=$1
  toDirectory=$2
  rsyncCommand="rsync -avz -e \"ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null\" \"${SOURCE_HOST_USER}@${SOURCE_HOST}\":\"${fromDirectory}\" \"${toDirectory}\""

  sudo -u "${FAF_USER}" rsync -avz -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null" ${SOURCE_HOST_USER}@${SOURCE_HOST}:${fromDirectory} "${toDirectory}" || { echo "Failed to copy files from ${SOURCE_HOST}:${fromDirectory} to ${toDirectory}"; exit 1; }
}

function migrate_files {
  for fromDirectory in "${!PATH_MAPPINGS[@]}"; do
    targetDirectory="${PATH_MAPPINGS[${fromDirectory}]}"
    sudo -u "${FAF_USER}" mkdir -p "${targetDirectory}"
    fetch_files "${fromDirectory}" "${targetDirectory}"
    chmod -R u=rwX,g=rwX,o= "${targetDirectory}"
  done
}

function create_symlinks {
  echo "Creating symlinks"
  for symlink in "${!SYMLINKS[@]}"; do
    linkTarget="${SYMLINKS[${symlink}]}"
    sudo -u "${FAF_USER}" mkdir -p "$(dirname ${symlink})"
    echo "Linking ${symlink} to ${linkTarget}"
    ln -s "${linkTarget}" "${symlink}"
  done
}

function fix_replay_vault {
  sed -i "s,/faf/vault/replay_vault,/replays,g" "${FAF_BASE_DIR}/data/content/vault/replay.php"
  sed -i "s,replay_vault/replay\.php,replay.php,g" "${FAF_BASE_DIR}/data/content/vault/replays_simple.php"
}

function install_cron_jobs {
  # FIXME make sure the script is actually at this path
  #(crontab -l 2>/dev/null; echo "0 0 * * 1 bash ${FAF_BASE_DIR}/scripts/reporting.sh") | crontab -
  :
}

check_is_root
configure_umask
configure_permit_root_login
create_groups
create_users
generate_ssh_key_pair
confirm_source_user_permissions
update_apt_index
install_apt_https
install_curl
install_git
install_docker_ce
install_docker_compose
install_rsync
clone_faf_stack
migrate_files
create_symlinks
fix_replay_vault
install_cron_jobs
