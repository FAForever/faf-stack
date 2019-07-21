#!/bin/bash
#set -x
#
# This script aims to set up a complete FAF server.
#
# This includes:
#   * SSH settings
#   * Users & groups
#   * Docker & Docker-Compose
#   * Git
#   * FAF-Stack
#   * Directories
#   * Permissions
#   * Security settings
#
# Every action is idempotent, which means that the script can be executed repeatedly.
#

FAF_USER="faforever"
FAF_GROUP="faforever"
FAF_USER_ADDITIONAL_GROUPS=""
FAF_LOGIN_SHELL="/bin/bash"
PERMIT_ROOT_LOGIN="no"
ALLOW_PASSWORD_AUTHENTICATION="no"
DEFAULT_UMASK="007"
FAF_BASE_DIR="/opt/faf"
FAF_STACK_URL="https://github.com/FAForever/faf-stack.git"
DOCKER_COMPOSE_VERSION="1.24.0"


function check_is_root {
  if [[ $EUID > 0 ]]; then
    echo "This script needs to be run as root"
    exit 1
  fi
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
  curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose \
     || { echo "Failed to install Docker-Compose"; exit 1; }
  chmod +x /usr/local/bin/docker-compose \
     || { echo "Failed to make docker-compose executable"; exit 1; }
  chgrp docker /usr/local/bin/docker-compose \
     || { echo "Failed to change group of docker-compose"; exit 1; }
  hash -r
}

function install_faf_stack {
  if [ -d "${FAF_BASE_DIR}/.git" ]; then
    echo "Not cloning faf-stack as it is already cloned (at ${FAF_BASE_DIR})"
    return
  fi

  echo "Cloning faf-stack"
  mkdir -p "${FAF_BASE_DIR}"
  sudo chown "${FAF_USER}:${FAF_GROUP}" "${FAF_BASE_DIR}"
  sudo -u "${FAF_USER}" git clone "${FAF_STACK_URL}" "${FAF_BASE_DIR}"  || { echo "Failed to clone ${FAF_STACK_URL} to ${FAF_BASE_DIR}"; exit 1; }
  pushd "${FAF_BASE_DIR}"
  sudo -u "${FAF_USER}" cp .env.template .env
  sudo -u "${FAF_USER}" cp -r config.template/ config
  popd
}

function install_cron_jobs {
  # FIXME make sure the script is actually at this path
  #(crontab -l 2>/dev/null; echo "0 0 * * 1 bash ${FAF_BASE_DIR}/scripts/reporting.sh") | crontab -
  :
}

function install_tmux_init_file {
  echo "Creating tmux init file"
  cat > /etc/init.d/faforever-tmux.sh <<EOF
#!/bin/bash
### BEGIN INIT INFO
# Provides:          faforever-tmux
# Required-Start:    \$local_fs \$network
# Required-Stop:     \$local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: faforever-tmux
# Description:       A tmux terminal session for the faforever user
### END INIT INFO

if [ "\$1" != "start" ]; then
  exit 0;
fi
pushd /opt/faf
su -c "tmux -S /tmp/tmux-faforever new-session -d" faforever
chgrp faforever /tmp/tmux-faforever
popd
EOF
  chmod +x /etc/init.d/faforever-tmux.sh
  update-rc.d faforever-tmux.sh defaults

  /etc/init.d/faforever-tmux.sh start
}

function add_user_to_docker_group {
  usermod -a -G docker "${FAF_USER}"
}

check_is_root
configure_umask
configure_permit_root_login
create_groups
create_users
update_apt_index
install_apt_https
install_curl
install_git
install_docker_ce
install_docker_compose
install_rsync
install_faf_stack
install_cron_jobs
install_tmux_init_file
add_user_to_docker_group

/etc/init.d/faforever-tmux.sh start
