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
# Version 1.6 - July 2024
#
SCRIPT_VERSION="1.6"

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
echo -e " ------------------------------------- ${COL_LB}v${SCRIPT_VERSION}${NC}"
echo -e ""

# Get the OS information
os_name=$(lsb_release -is)
os_version=$(lsb_release -rs)

# Check if OS is Debian 11 or Debian 12
if [ "$os_name" = "Debian" ]; then
    if [ "$os_version" = "11" ] || [ "$os_version" = "12" ]; then
        echo -e "${COL_GREEN}ℹ Detected ${os_name} ${os_version}${NC}"
    else
        echo -e "❌ Error: OS not supported, aborting."
        exit 1
    fi
else
    echo -e "❌ Error: OS not supported, aborting."
    exit 1
fi

# PHP version detection
export PHPVER="$2"

if [ -z "$PHPVER" ] && [ -n "$1" ]
then
  echo -e "❌ No PHP version detected. Please set it as the second parameter."
  exit 1
fi

echo -e "${COL_GREEN}ℹ Setting PHP version: $PHPVER ${NC}"
echo -e ""

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
    --enable-bcmath \
    --enable-exif \
    --enable-gd \
    --enable-gd-native-ttf \
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
    --sysconfdir="$CONFDIR" \
    --with-config-file-path="$CONFDIR"

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
  cp -u ./php.ini-development $CONFDIR/php.ini-development
  cp -u ./php.ini-production $CONFDIR/php.ini-production

  echo -e ""
  echo -e "${COL_GREEN}✅ Installation completed!${NC}"

  # Main config file (php.ini)
  if [ ! -f $CONFDIR/php.ini ]; then
    echo -e ""
    echo -e "${COL_GREEN}:: Missing config file: $CONFDIR/php.ini ${NC}"

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
    echo -e ""
    echo -e "${COL_GREEN}:: Missing config file: $CONFDIR/php-fpm.conf ${NC}"

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
    echo -e ""
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
  $PEARDIR/bin/pecl config-set php_ini $CONFDIR/php.ini

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

  restart_service php-fpm.service
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
echo -e "This script helps you build and upgrade PHP versions for a Debian 11/12 environment."
echo -e " "
echo -e "Always provide the desired PHP version as the second parameter, as shown in the usage examples below."
echo -e " "
echo -e "Extensions and composer updates are optional for minor version updates. Usually, they can remain as is, so you may finish after the install step."
echo -e ""
echo -e "You can also set '-y' as the last parameter for the non-interactive mode (only works on manual usage commands)."
echo -e "E.g. ${COL_GREEN}$0 auto 8.3.9 -y${NC}"
echo -e ""
echo -e "${COL_LB}Automatic usage:${NC}"
echo -e ""
echo -e "$0 ${COL_GREEN}auto 8.3.9${NC}    -> Run all those commands in order for PHP 8.3.9"
echo -e ""
echo -e "${COL_LB}Manual usage in order:${NC}"
echo -e ""
echo -e "$0 ${COL_GREEN}init 8.3.9${NC}    -> Init system for PHP 8.3.9"
echo -e "$0 ${COL_GREEN}compile 8.3.9${NC} -> Configure + make + test"
echo -e "$0 ${COL_GREEN}install 8.3.9${NC} -> Make install + update config"
echo -e "$0 ${COL_GREEN}ext${NC}           -> Install PEAR + PECL extensions (redis, mailparse, imagick)"
echo -e "$0 ${COL_GREEN}composer${NC}      -> Install latest composer"
echo -e "$0 ${COL_GREEN}finish${NC}        -> Restart services"
echo -e ""

exit 0