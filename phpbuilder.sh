#!/usr/bin/env bash
#
# PHP building on Debian 11/12 with nginx + php-fpm
#
# Please adjust this to your environment before running!
#
# See usage instructions at the end of this file or simply run this file without parameters
#
# Version 1.4 - January 2024
#

# Absolute path to the source directory. We'll build PHP in a sub-directory.
SRCDIR="/usr/local/src"

# Absolute path to PEAR installation
PEARDIR="/usr/local/pear"

# Absolute path to bin dir, where the executables will be installed to
BINDIR="/usr/local/bin"

# Absolute path to config main dir. The config will be in a sub-directory of the version (e.g. 8.3)
CONFDIR="/etc/php"

# Get the directory of the current script
SCRIPT_DIR=$(dirname "$0")

# Check for interactive mode
INTERACTIVE=1

# Check for non-interactive flag
if [ "$3" = "-y" ]; then
  INTERACTIVE=0
fi

# Color output
COL_GREEN='\e[0;32m'
COL_LB='\e[1;34m'
NC='\e[0m' # No Color

# Header
echo -e ""
echo -e "${COL_GREEN}  ___ _  _ ___   ___      _ _    _"
echo -e " | _ \ || | _ \ | _ )_  _(_) |__| |___ _ _ "
echo -e " |  _/ __ |  _/ | _ \ || | | / _\` / -_) '_|"
echo -e " |_| |_||_|_|   |___/\_,_|_|_\__,_\___|_|  ${NC}"
echo -e " ------------------------------------------"
echo -e "${COL_LB} v1.4${NC}"
echo -e " ------------------------------------------"
echo -e " by Sven Reifschneider    ${COL_LB}::${NC} Neoground GmbH"
echo -e ""

export PHPVER="$2"
echo -e "${COL_GREEN}:: Setting PHP version: $PHPVER ${NC}"

if [ -z "$PHPVER" ] && [ -n "$1" ]
then
  echo -e "No PHP version detected. Please set it as the second parameter."

  exit 1
fi

# Extract the major version
PHPMAJVER=$(echo "$PHPVER" | awk -F. '{print $1 "." $2}')

echo -e "${COL_GREEN}:: Setting PHP version: $PHPVER ($PHPMAJVER config) ${NC}"

if [ "$1" == "init" ]
then
  echo -e "${COL_GREEN}:: Creating environment for PHP v$PHPVER ${NC}"
  # Install dependencies only if they're missing and apt is available
  if command -v apt > /dev/null; then
    echo -e "${COL_GREEN}:: apt is available: checking dependencies and installing missing packages ${NC}"
    apt install build-essential autoconf libtool bison re2c zlib1g-dev libgd-tools libssl-dev \
            libxml2-dev libssl-dev libsqlite3-dev libcurl4-openssl-dev libonig-dev \
            libxslt1-dev libzip-dev libsystemd-dev libc-client2007e-dev libbz2-dev libgd-dev \
            libkrb5-dev libmagickwand-dev libsodium-dev libavif-dev
  else
    echo -e "${COL_GREEN}:: apt is not available on your system. Please make sure all required packages are installed! ${NC}"
  fi
  echo -e ""

  if [[ -f /etc/ImageMagick-6/policy.xml ]]; then
    sed -i 's+rights="none" pattern="PDF"+rights="read|write" pattern="PDF"+g' /etc/ImageMagick-6/policy.xml
    sed -i 's+name="disk" value="1GiB"+name="disk" value="2GiB"+g' /etc/ImageMagick-6/policy.xml
    echo -e "Updated ImageMagick configuration to allow PDF files handling."
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

  echo -e ""
  echo -e "${COL_GREEN}✅ Init completed, you can now compile!${NC}"
  exit 0
fi

if [ "$1" == "compile" ]
then
  echo -e "${COL_GREEN}:: Compiling for PHP v$PHPVER ${NC}"
  cd $SRCDIR/php-"$PHPVER" || exit 1
  # Config, Compile, Test
  ./configure \
    --enable-fpm \
    --with-fpm-systemd \
    --with-openssl \
    --with-zlib \
    --with-curl \
    --enable-exif \
    --enable-gd \
    --with-freetype \
    --with-external-gd \
    --with-avif \
    --enable-intl \
    --enable-mbstring \
    --with-mysqli \
    --with-pdo-mysql \
    --enable-sockets \
    --enable-soap \
    --with-xsl \
    --with-bz2 \
    --with-zip \
    --enable-calendar \
    --with-imap \
    --with-imap-ssl \
    --with-gettext \
    --enable-shmop \
    --with-kerberos \
    --enable-opcache \
    --enable-pcntl \
    --with-sodium \
    --sysconfdir="$CONFDIR/$PHPMAJVER" \
    --with-config-file-path="$CONFDIR/$PHPMAJVER"

  # Compile with 50% CPU usage so system keeps usable
  THREADS=$(($(nproc)/2))
  echo -e ""
  echo -e "${COL_GREEN}:: Starting compiler with $THREADS threads...${NC}"
  make -j $THREADS
  echo -e ""
  echo -e "${COL_GREEN}:: Compilation completed, running tests${NC}"
  make test
  echo -e ""
  echo -e "${COL_GREEN}✅ Compilation and tests completed!${NC}"

  exit 0
fi

if [ "$1" == "install" ]
then
  echo -e "${COL_GREEN}:: Installing PHP v$PHPVER ${NC}"
  cd $SRCDIR/src/php-"$PHPVER" || exit 1
  make install

  # Copy config files (if not existing yet)
  echo "Updating php + php-fpm config"
  cp -n ./php.ini-development /etc/php/$PHPMAJVER/php.ini-development
  cp -n ./php.ini-production /etc/php/$PHPMAJVER/php.ini-production
  cp -n ./php.ini-production /etc/php/$PHPMAJVER/php.ini
  cp -n ./sapi/fpm/php-fpm.conf /etc/php/$PHPMAJVER/php-fpm.conf

  if [ ! -f "/etc/systemd/system/php${PHPMAJVER}-fpm.service" ]; then
    cp -n "$SCRIPT_DIR/php-fpm.service" "/etc/systemd/system/php${PHPMAJVER}-fpm.service"
    # Update config values
    sed -i "s/#MAJVER/$PHPMAJVER/g" "/etc/systemd/system/php${PHPMAJVER}-fpm.service"
    sed -i "s/#CONFPATH/$CONFDIR\/$PHPMAJVER/g" "/etc/systemd/system/php${PHPMAJVER}-fpm.service"
  fi
  systemctl enable "php${PHPMAJVER}-fpm.service"

  echo -e ""
  echo -e "${COL_GREEN}✅ Installation completed!${NC}"

  # Main config file (php.ini)
  if [ ! -f /etc/php/php.ini ]; then
    echo -e "${COL_GREEN}:: Missing config file: /etc/php/php.ini ${NC}"

    # In interactive mode ask the user for confirmation.
    if [ $INTERACTIVE = 1 ]; then
      read -p "Do you want to create php.ini at /etc/php/php.ini? (Y/n): " USER_INPUT
      if [ -z "$USER_INPUT" ]; then
        USER_INPUT="y"
      fi
      if [ "${USER_INPUT,,}" = "y" ]; then
        cp "$SCRIPT_DIR/php.ini" /etc/php/php.ini
        echo -e "php.ini created at /etc/php/php.ini"
      else
        echo -e "Skipping creating php.ini"
      fi
    else
        # In non-interactive mode copy file without asking for confirmation.
        cp "$SCRIPT_DIR/php.ini" /etc/php/php.ini
        echo -e "php.ini created at /etc/php/php.ini"
    fi
  fi

  # Config file for php-fpm
  if [ ! -f /etc/php/php-fpm.conf ]; then
    echo -e "${COL_GREEN}:: Missing config file: /etc/php/php-fpm.conf ${NC}"

    # In interactive mode ask the user for confirmation.
    if [ $INTERACTIVE = 1 ]; then
      read -p "Do you want to create php-fpm.conf at /etc/php/php-fpm.conf? (Y/n): " USER_INPUT
      if [ -z "$USER_INPUT" ]; then
        USER_INPUT="y"
      fi
      if [ "${USER_INPUT,,}" = "y" ]; then
        cp "$SCRIPT_DIR/php-fpm.conf" /etc/php/php-fpm.conf
        echo -e "php-fpm.conf created at /etc/php/php-fpm.conf"
      else
        echo -e "Skipping creating php-fpm.conf"
      fi
    else
        # In non-interactive mode copy file without asking for confirmation.
        cp "$SCRIPT_DIR/php-fpm.conf" /etc/php/php-fpm.conf
        echo -e "php-fpm.conf created at /etc/php/php-fpm.conf"
    fi
  fi

  # Systemd service + config for php-fpm
  if [ ! -f /etc/systemd/system/php-fpm.service ]; then
    echo -e "${COL_GREEN}:: Missing php-fpm systemd service file: /etc/systemd/system/php-fpm.service ${NC}"

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
  echo -e "${COL_GREEN}:: Installing PEAR + PECL extensions${NC}"

  # Installing PEAR + PECL extensions
  echo -e ""
  echo -e "${COL_GREEN}:: Installing PEAR${NC}"
  cd $SRCDIR/src || exit 1
  rm -Rf $SRCDIR/src/go-pear.phar
  wget https://pear.php.net/go-pear.phar

  echo -e ""
  echo -e "${COL_LB}Please set the following values:${NC}"
  echo -e "1: $PEARDIR"
  echo -e ""

  $BINDIR/php go-pear.phar
  ln -s $PEARDIR/bin/pear $BINDIR/pear
  ln -s $PEARDIR/bin/peardev $BINDIR/peardev
  ln -s $PEARDIR/bin/pecl $BINDIR/pecl
  $PEARDIR/bin/pecl config-set php_ini /etc/php/php.ini

  echo -e ""
  echo -e "${COL_GREEN}:: Installing PECL extensions${NC}"

  $PEARDIR/bin/pecl uninstall redis
  $PEARDIR/bin/pecl install redis
  $PEARDIR/bin/pecl uninstall mailparse
  $PEARDIR/bin/pecl install mailparse
  $PEARDIR/bin/pecl uninstall imagick
  $PEARDIR/bin/pecl install imagick

  echo -e ""
  echo -e "${COL_GREEN}✅ Installation completed!${NC}"

  exit 0
fi

if [ "$1" == "composer" ]
then
  # Install composer
  echo -e "${COL_GREEN}:: Installing composer${NC}"
  wget -O $BINDIR/composer https://getcomposer.org/composer-stable.phar
  chmod +x $BINDIR/composer

  echo -e ""
  echo -e "${COL_GREEN}✅ Installation completed!${NC}"

  exit 0
fi

if [ "$1" == "finish" ]
then
  echo -e "${COL_GREEN}:: Restarting services${NC}"

  restart_service() {
    local service="$1"
    if systemctl --quiet is-enabled "$service"; then
        echo -e "Restarting $service"
        systemctl restart "$service"
    fi
  }

  restart_service "php${PHPMAJVER}-fpm.service"
  restart_service nginx.service
  restart_service apache2.service
  restart_service httpd.service
  restart_service lsws.service
  restart_service zoneminder.service

  echo -e ""
  echo -e "${COL_GREEN}✅ Services restarted!${NC}"

  exit 0
fi

if [ "$1" == "auto" ]
then
  echo -e "${COL_GREEN}:: Auto builder for PHP v$PHPVER ${NC}"

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

  echo -e ""
  echo -e "${COL_GREEN}✅ PHP v${PHPVER} installed successfully!${NC}"
  echo -e ""
  $BINDIR/php -v

  exit 0
fi

# Default case: show help / info

echo -e ""
echo -e "This script helps you build and upgrade PHP versions"
echo -e "for a Debian 11/12 environment."
echo -e " "
echo -e "Always provide the desired PHP version as the second"
echo -e "parameter, as shown in the usage examples below."
echo -e " "
echo -e "Extensions and composer updates are optional for minor"
echo -e "version updates. Usually, they can remain as is,"
echo -e "so you may finish after the install step."
echo -e ""
echo -e "You can also set '-y' as the last parameter"
echo -e "for the non-interactive mode."
echo -e "E.g. $0 auto 8.3.1 -y"
echo -e ""
echo -e "${COL_LB}Usage in order:${NC}"
echo -e ""
echo -e "$0 ${COL_GREEN}auto 8.3.1${NC}    -> Run all those commands in order for PHP 8.3.1"
echo -e "$0 ${COL_GREEN}init 8.3.1${NC}    -> Init system for PHP 8.3.1"
echo -e "$0 ${COL_GREEN}compile 8.3.1${NC} -> Configure + make + test"
echo -e "$0 ${COL_GREEN}install 8.3.1${NC} -> Make install + update config"
echo -e "$0 ${COL_GREEN}ext${NC}           -> Install PEAR + PECL extensions (redis, mailparse, imagick)"
echo -e "$0 ${COL_GREEN}composer${NC}      -> Install latest composer"
echo -e "$0 ${COL_GREEN}finish${NC}        -> Restart services"
echo -e ""

exit 0