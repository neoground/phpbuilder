#!/usr/bin/env bash
#
# PHP 8 building on Debian 11/12
#
# Provides a local PHP installation with useful PEAR + PECL extensions.
#
# Please adjust this to your environment before running!
#
# See usage instructions at the end of this file or simply run this file without parameters
#
# Version 1.7 - July 2024
#
SCRIPT_VERSION="1.7"

# Absolute path to the source directory. We'll build PHP in a sub-directory.
SRCDIR="/usr/local/src"

# Absolute path to PEAR installation
PEARDIR="/usr/local/pear"

# Absolute path to bin dir, where the executables will be installed to
BINDIR="/usr/local/bin"

# Absolute path to config main dir
CONFDIR="/etc/php"

# Get the directory of the current script
SCRIPT_DIR=$(dirname "$0")

# Check for interactive mode
INTERACTIVE=1

# Check for non-interactive flag
if [ "$3" = "-y" ]; then
  INTERACTIVE=0
fi

# Define colors and formatting
BLUE='\033[1;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
BOLD='\033[1m'
RESET='\033[0m'

# Function to display a header
display_header() {
  local title="$1"
  echo -e "\n${BLUE}::${RESET} ${BOLD}${title}${RESET}\n"
}

# Function to display a subheader
display_subheader() {
  local subheader="$1"
  echo -e "\n${GREEN}::${RESET} ${BOLD}${subheader}${RESET}\n"
}

# Function to display an error message
display_error() {
  local message="$1"
  echo -e "\n❌ Error: ${RED}${message}${RESET}\n"
}

# Function to display a success message
display_success() {
  local message="$1"
  echo -e "\n✅ ${GREEN}${message}${RESET}\n"
}

# Function to display an info message
display_info() {
  local message="$1"
  echo -e "\nℹ  ${BLUE}${message}${RESET}\n"
}

# Color output
GREEN='\e[0;32m'

NC='\e[0m' # No Color

# Header
echo -e ""
echo -e "${GREEN}  ___ _  _ ___   ___      _ _    _"
echo -e " | _ \ || | _ \ | _ )_  _(_) |__| |___ _ _ "
echo -e " |  _/ __ |  _/ | _ \ || | | / _\` / -_) '_|"
echo -e " |_| |_||_|_|   |___/\_,_|_|_\__,_\___|_|  ${NC}"
echo -e " ------------------------------------- ${BLUE}v${SCRIPT_VERSION}${NC}"
echo -e ""

# Get the OS information
os_name=$(lsb_release -is)
os_version=$(lsb_release -rs)

# Check if OS is Debian 11 or Debian 12
if [ "$os_name" = "Debian" ]; then
    if [ "$os_version" = "11" ] || [ "$os_version" = "12" ]; then
        display_info "Detected ${os_name} ${os_version}"
    else
        display_error "OS not supported, aborting."
        exit 1
    fi
else
    display_error "OS not supported, aborting."
    exit 1
fi

# PHP version detection
export PHPVER="$2"

if [ -z "$PHPVER" ] && [ -n "$1" ]
then
  display_error "No PHP version detected. Please set it as the second parameter."
  exit 1
fi

if [[ ! -z "$PHPVER" ]]
then
display_info "Setting PHP version: $PHPVER"
fi
echo -e ""

if [ "$1" == "init" ]
then
  display_header "Creating environment for PHP v$PHPVER"
  # Install dependencies only if they're missing and apt is available
  if command -v apt > /dev/null; then
    display_subheader "Checking dependencies and installing missing packages"
    apt install build-essential autoconf libtool bison re2c zlib1g-dev libgd-tools libssl-dev \
            libxml2-dev libssl-dev libsqlite3-dev libcurl4-openssl-dev libonig-dev \
            libxslt1-dev libzip-dev libsystemd-dev libc-client2007e-dev libbz2-dev libgd-dev \
            libkrb5-dev libmagickwand-dev libsodium-dev libavif-dev libargon2-1 wget
  else
    display_info "apt is not available on your system. Please make sure all required packages are installed!"
  fi
  echo -e ""

  if [[ -f /etc/ImageMagick-6/policy.xml ]]; then
    if [ $INTERACTIVE = 1 ]; then
      read -p "Do you want to update imagemagick policy.xml to allow PDF file handling? (Y/n): " USER_INPUT
      if [ -z "$USER_INPUT" ]; then
        sed -i 's+rights="none" pattern="PDF"+rights="read|write" pattern="PDF"+g' /etc/ImageMagick-6/policy.xml
        sed -i 's+name="disk" value="1GiB"+name="disk" value="2GiB"+g' /etc/ImageMagick-6/policy.xml
        echo -e "Updated ImageMagick configuration to allow PDF files handling."
      fi
    else
      # In non-interactive mode just do it
      sed -i 's+rights="none" pattern="PDF"+rights="read|write" pattern="PDF"+g' /etc/ImageMagick-6/policy.xml
      sed -i 's+name="disk" value="1GiB"+name="disk" value="2GiB"+g' /etc/ImageMagick-6/policy.xml
      echo -e "Updated ImageMagick configuration to allow PDF files handling."
    fi
  else
    echo -e "The file /etc/ImageMagick-6/policy.xml does not exist. Skipping config updates."
  fi
  echo -e ""

  # Clean environment, download + unpack php source
  cd $SRCDIR || exit 1
  rm -Rf php-"$PHPVER" php-"$PHPVER".tar.gz
  wget https://www.php.net/distributions/php-"$PHPVER".tar.gz
  tar -xvzf php-"$PHPVER".tar.gz
  cd php-"$PHPVER" || exit 1
  ./buildconf

  display_success "Init completed, you can now compile!"
  exit 0
fi

if [ "$1" == "compile" ]
then
  display_header "Compiling for PHP v$PHPVER"
  cd $SRCDIR/php-"$PHPVER" || exit 1
  # Config, Compile, Test
  ./configure \
    --enable-fpm \
    --with-fpm-systemd \
    --with-openssl \
    --with-zlib \
    --with-curl \
    --enable-bcmath \
    --enable-exif \
    --enable-gd \
    --with-freetype \
    --enable-gd \
    --with-avif \
    --with-webp \
    --with-jpeg \
    --with-freetype \
    --enable-intl \
    --enable-mbstring \
    --with-mysqli \
    --with-pdo-mysql \
    --enable-sockets \
    --enable-soap \
    --with-xsl \
    --with-bz2 \
    --with-zip \
    --with-zlib \
    --enable-calendar \
    --with-imap \
    --with-imap-ssl \
    --with-gettext \
    --enable-shmop \
    --with-kerberos \
    --enable-opcache \
    --enable-pcntl \
    --with-sodium \
    --with-password-argon2 \
    --with-readline \
    --sysconfdir="$CONFDIR" \
    --with-config-file-path="$CONFDIR"

  # Compile with 50% CPU usage so system keeps usable
  THREADS=$(($(nproc)/2))
  display_header "Starting compiler with $THREADS threads..."
  make -j $THREADS
  display_header "Compilation completed, running tests"
  make test
  display_success "Compilation and tests completed!"

  exit 0
fi

if [ "$1" == "install" ]
then
  display_header "Installing PHP v$PHPVER"
  cd $SRCDIR/php-"$PHPVER" || exit 1
  make install

  # Copy config files (if not existing yet)
  echo "Updating php + php-fpm config"
  cp -u ./php.ini-development $CONFDIR/php.ini-development
  cp -u ./php.ini-production $CONFDIR/php.ini-production

  display_success "Installation completed!"

  # Main config file (php.ini)
  if [ ! -f $CONFDIR/php.ini ]; then
    display_header "Missing config file: $CONFDIR/php.ini"

    # In interactive mode ask the user for confirmation.
    if [ $INTERACTIVE = 1 ]; then
      read -p "Do you want to create php.ini at $CONFDIR/php.ini? (Y/n): " USER_INPUT
      if [ -z "$USER_INPUT" ]; then
        USER_INPUT="y"
      fi
      if [ "${USER_INPUT,,}" = "y" ]; then
        cp ./php.ini-production $CONFDIR/php.ini
        echo -e "php.ini created at $CONFDIR/php.ini"
      else
        echo -e "Skipping creating php.ini"
      fi
    else
        # In non-interactive mode copy file without asking for confirmation.
        cp "$SCRIPT_DIR/php.ini" $CONFDIR/php.ini
        echo -e "php.ini created at $CONFDIR/php.ini"
    fi
  fi

  # Config file for php-fpm
  if [ ! -f $CONFDIR/php-fpm.conf ]; then
    display_header "Missing config file: $CONFDIR/php-fpm.conf"

    # In interactive mode ask the user for confirmation.
    if [ $INTERACTIVE = 1 ]; then
      read -p "Do you want to create php-fpm.conf at $CONFDIR/php-fpm.conf? (Y/n): " USER_INPUT
      if [ -z "$USER_INPUT" ]; then
        USER_INPUT="y"
      fi
      if [ "${USER_INPUT,,}" = "y" ]; then
        cp "$SCRIPT_DIR/php-fpm.conf" $CONFDIR/php-fpm.conf
        # Update config values
        sed -i "s/#CONFPATH/$CONFDIR/g" "/etc/systemd/system/php-fpm.service"
        echo -e "php-fpm.conf created at $CONFDIR/php-fpm.conf"
      else
        echo -e "Skipping creating php-fpm.conf"
      fi
    else
        # In non-interactive mode copy file without asking for confirmation.
        cp "$SCRIPT_DIR/php-fpm.conf" $CONFDIR/php-fpm.conf
        # Update config values
        sed -i "s/#CONFPATH/$CONFDIR/g" "/etc/systemd/system/php-fpm.service"
        echo -e "php-fpm.conf created at $CONFDIR/php-fpm.conf"
    fi
  fi

  # Systemd service + config for php-fpm
  if [ ! -f /etc/systemd/system/php-fpm.service ]; then
    display_header "Missing php-fpm systemd service file: /etc/systemd/system/php-fpm.service"

    # In interactive mode ask the user for confirmation.
    if [ $INTERACTIVE = 1 ]; then
      read -p "Do you want to add the systemd service for php-fpm? (Y/n): " USER_INPUT
      if [ -z "$USER_INPUT" ]; then
        USER_INPUT="y"
      fi
      if [ "${USER_INPUT,,}" = "y" ]; then
        cp "$SCRIPT_DIR/php-fpm.service" /etc/systemd/system/php-fpm.service
        systemctl enable php-fpm.service
        echo -e "Systemd service added and enabled"
      else
        echo -e "Skipping systemd service"
      fi
    else
        # In non-interactive mode copy file without asking for confirmation.
        cp "$SCRIPT_DIR/php-fpm.service" /etc/systemd/system/php-fpm.service
        systemctl enable php-fpm.service
        echo -e "Systemd service added and enabled"
    fi
  fi

  exit 0
fi

if [ "$1" == "ext" ]
then
  display_header "Installing PEAR + PECL extensions"

  # Installing PEAR + PECL extensions
  display_subheader "Installing PEAR"
  cd $SRCDIR || exit 1
  rm -Rf $SRCDIR/go-pear.phar
  wget https://pear.php.net/go-pear.phar

  display_info "Please set the following values:"
  echo -e "1: $PEARDIR"
  echo -e ""

  $BINDIR/php go-pear.phar
  ln -s $PEARDIR/bin/pear $BINDIR/pear
  ln -s $PEARDIR/bin/peardev $BINDIR/peardev
  ln -s $PEARDIR/bin/pecl $BINDIR/pecl
  $PEARDIR/bin/pecl config-set php_ini $CONFDIR/php.ini

  display_subheader "Installing PECL extensions"

  $PEARDIR/bin/pecl uninstall redis
  $PEARDIR/bin/pecl install redis
  $PEARDIR/bin/pecl uninstall mailparse
  $PEARDIR/bin/pecl install mailparse
  $PEARDIR/bin/pecl uninstall imagick
  $PEARDIR/bin/pecl install imagick
  $PEARDIR/bin/pear install pear/PHP_Archive

  display_success "Installation completed!"

  exit 0
fi

if [ "$1" == "composer" ]
then
  # Install composer
  display_header "Installing composer"
  wget -O $BINDIR/composer https://getcomposer.org/composer-stable.phar
  chmod +x $BINDIR/composer

  display_success "Installation completed!"

  exit 0
fi

if [ "$1" == "finish" ]
then
  display_header "Restarting services"

  restart_service() {
    local service="$1"
    if systemctl --quiet is-enabled "$service"; then
        echo -e "Restarting $service"
        systemctl restart "$service"
    fi
  }

  restart_service php-fpm.service
  restart_service nginx.service
  restart_service apache2.service
  restart_service httpd.service
  restart_service lsws.service
  restart_service zoneminder.service

  display_success "Services restarted!"

  display_header "PHP Version"
  $BINDIR/php -v

  exit 0
fi

if [ "$1" == "clean" ]
then
  display_header "Clean up environment"

  rm -Rf $SRCDIR/php-"$PHPVER" $SRCDIR/php-"$PHPVER".tar.gz

  display_success "Cleaned up dev environment!"

  exit 0
fi

if [ "$1" == "auto" ]
then
  display_header "Auto builder for PHP v$PHPVER"

  function ask_execute() {
    local command=$1
    local question=$2

    if [ $INTERACTIVE = 1 ]; then
      echo -e ""
      read -p "$question (Y/n): " USER_INPUT
      if [ -z "$USER_INPUT" ]; then
        USER_INPUT="y"
      fi
      if [ "${USER_INPUT,,}" = "y" ]; then
        bash "$0" $command "$PHPVER"
      fi
    else
      # In non-interactive mode simply execute
      bash "$0" $command "$PHPVER"
    fi
  }

  ask_execute init "(1/6) Do you want to init the build system for PHP?"
  ask_execute compile "(2/6) Do you want to configure + make + test PHP?"
  ask_execute install "(3/6) Do you want to install PHP?"
  ask_execute ext "(4/6) Do you want to install the PEAR + PECL extensions?"
  ask_execute composer "(5/6) Do you want to install the latest composer?"
  ask_execute finish "(6/6) Do you want to finish the installation and restart services?"

  exit 0
fi

# Default case: show help / info

echo -e ""
echo -e "This script helps you build and upgrade PHP versions for a Debian 11/12 environment."
echo -e " "
echo -e "Always provide the desired PHP version as the second parameter, as shown in the usage examples below."
echo -e " "
echo -e "Extensions and composer updates are optional for minor version updates. Usually, they can remain as is, so you may finish after the install step."
echo -e ""
echo -e "You can also set '-y' as the last parameter for the non-interactive mode (only works on manual usage commands)."
echo -e "E.g. ${GREEN}$0 auto 8.3.11 -y${NC}"
echo -e ""
echo -e "${BLUE}Automatic usage:${NC}"
echo -e ""
echo -e "$0 ${GREEN}auto 8.3.11${NC}    -> Run all those commands in order for PHP 8.3.11"
echo -e ""
echo -e "${BLUE}Manual usage in order:${NC}"
echo -e ""
echo -e "$0 ${GREEN}init 8.3.11${NC}    -> Init system for PHP 8.3.11"
echo -e "$0 ${GREEN}compile 8.3.11${NC} -> Configure + make + test"
echo -e "$0 ${GREEN}install 8.3.11${NC} -> Make install + update config"
echo -e "$0 ${GREEN}ext${NC}           -> Install PEAR + PECL extensions (redis, mailparse, imagick)"
echo -e "$0 ${GREEN}composer${NC}      -> Install latest composer"
echo -e "$0 ${GREEN}finish${NC}        -> Restart services"
echo -e "$0 ${GREEN}clean${NC}         -> Clean up environment (remove source)"
echo -e ""

exit 0
