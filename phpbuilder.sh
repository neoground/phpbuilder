#!/usr/bin/env bash
#
# PHP 8 building on Debian 11
#
# Please adjust this to your environment before running!
#
# See usage instructions at the end of this file or simply run this file without parameters
#
# Version 1.3 - January 2023
#

COL_GREEN='\e[0;32m'
COL_LB='\e[1;34m'
NC='\e[0m' # No Color

# Header
echo -e " "
echo -e "${COL_GREEN}  ___ _  _ ___   ___      _ _    _"
echo -e " | _ \ || | _ \ | _ )_  _(_) |__| |___ _ _ "
echo -e " |  _/ __ |  _/ | _ \ || | | / _\` / -_) '_|"
echo -e " |_| |_||_|_|   |___/\_,_|_|_\__,_\___|_|  ${NC}"
echo -e " ------------------------------------------"
echo -e "${COL_LB} v1.3                          for Upgrades${NC}"
echo -e " ------------------------------------------"
echo -e " by Sven Reifschneider    ${COL_LB}::${NC} Neoground GmbH"
echo -e " "

export PHPVER="$2"

# TODO PHP version can also be first parameter for build assistant
# TODO Add build assistant

if [ -z "$PHPVER" ] && [ -n "$1" ]
then
  echo -e "No PHP version detected. Please set it as second parameter."

  exit 1
fi

# Extract the major version
PHPMAJVER=$(echo "$PHPVER" | awk -F. '{print $1 "." $2}')

echo -e "${COL_GREEN}:: Setting PHP version: $PHPVER ($PHPMAJVER config) ${NC}"


# Install dependencies
if [ "$1" == "depinstall" ]
then
  apt install build-essential autoconf libtool bison re2c zlib1g-dev libgd-tools libssl-dev \
            libxml2-dev libssl-dev libsqlite3-dev libcurl4-openssl-dev libonig-dev \
            libxslt1-dev libzip-dev libsystemd-dev libc-client2007e-dev libbz2-dev libgd-dev \
            libkrb5-dev libmagickwand-dev libsodium-dev libavif-dev

  # Update imagick config so we can read / write PDFs
  # TODO Ask user if this is wanted and check file existence
  # Ask the user for confirmation
  read -p "Do you want to enable PDF support for Imagick? (y/n): " ANSWER

  # Check if the answer is y, Y, j, or J
  case $ANSWER in
      [yYjJ]* )
          sed -i 's+rights="none" pattern="PDF"+rights="read|write" pattern="PDF"+g' /etc/ImageMagick-6/policy.xml
          sed -i 's+name="disk" value="1GiB"+name="disk" value="4GiB"+g' /etc/ImageMagick-6/policy.xml
          echo "Updated Imagick config /etc/ImageMagick-6/policy.xml"
          ;;
      * )
          ;;
  esac

  exit 0
fi

# Download
if [ "$1" == "init" ]
then
  # Clean environment, download + unpack php source
  cd /usr/local/src || exit 1
  rm -Rf php-"$PHPVER" php-"$PHPVER".tar.gz
  wget https://www.php.net/distributions/php-"$PHPVER".tar.gz
  tar -xvzf php-"$PHPVER".tar.gz
  cd php-"$PHPVER" || exit 1
  ./buildconf

  echo -e "${COL_GREEN}✅ Init completed!${NC}"
  exit 0
fi

# Compile
if [ "$1" == "compile" ]
then
  echo -e "${COL_GREEN}:: Compiling for PHP v$PHPVER ${NC}"
  cd /usr/local/src/php-"$PHPVER" || exit 1
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
    --sysconfdir=/etc/php/"$PHPMAJVER" \
    --with-config-file-path=/etc/php/"$PHPMAJVER"

  # Compile with 50% CPU usage so system keeps usable
  THREADS=$(($(nproc)/2))
  echo -e " "
  echo -e "${COL_GREEN}:: Starting compiler with $THREADS threads...${NC}"
  make -j $THREADS
  echo -e " "
  echo -e "${COL_GREEN}:: Compilation completed, running tests${NC}"
  make test
  echo -e " "
  echo -e "${COL_GREEN}✅ Compilation and tests completed!${NC}"
  exit 0
fi

# Install
if [ "$1" == "install" ]
then
  echo -e "${COL_GREEN}:: Installing PHP v$PHPVER ${NC}"
  mkdir -p /etc/php/$PHPMAJVER
  mkdir -p /etc/php/php-fpm.d
  cd /usr/local/src/php-"$PHPVER" || exit 1
  make install

  # Copy config files (if not existing yet)
  echo "Updating php + php-fpm config"
  cp -n ./php.ini-development /etc/php/$PHPMAJVER/php.ini-development
  cp -n ./php.ini-production /etc/php/$PHPMAJVER/php.ini-production
  cp -n ./php.ini-production /etc/php/$PHPMAJVER/php.ini
  cp -n ./sapi/fpm/php-fpm.conf /etc/php/$PHPMAJVER/php-fpm.conf

  echo "Updating systemd service"
  cp -n ./sapi/fpm/php-fpm.service /etc/systemd/system/php-fpm.service
  systemctl daemon-reload
  echo "You may need to run: systemctl enable --now php-fpm"

  # TODO check if config is okay and make adjustments to environment if not

  echo -e " "
  echo -e "${COL_GREEN}✅ Installation completed!${NC}"

  exit 0
fi

# Extensions
if [ "$1" == "ext" ]
then
  echo -e "${COL_GREEN}:: Installing PEAR + PECL extensions for PHP v$PHPVER ${NC}"

  # Installing PEAR + PECL extensions
  echo -e " "
  echo -e "${COL_GREEN}:: Installing PEAR${NC}"
  cd /usr/local/src || exit 1
  rm -Rf /usr/local/src/go-pear.phar
  wget https://pear.php.net/go-pear.phar

  echo -e " "
  echo -e "${COL_LB}Please set the following values:${NC}"
  echo -e "1: /usr/local/pear"
  echo -e " "

  /usr/local/bin/php go-pear.phar
  /usr/local/pear/bin/pecl config-set php_ini /etc/php/$PHPMAJVER/php.ini

  echo -e " "
  echo -e "${COL_GREEN}:: Installing PECL extensions${NC}"

  # Todo make extensions selectable
  /usr/local/pear/bin/pecl uninstall redis
  /usr/local/pear/bin/pecl install redis
  /usr/local/pear/bin/pecl uninstall mailparse
  /usr/local/pear/bin/pecl install mailparse
  /usr/local/pear/bin/pecl uninstall imagick
  /usr/local/pear/bin/pecl install imagick

  echo -e " "
  echo -e "${COL_GREEN}✅ Installation completed!${NC}"

  exit 0
fi

# Composer
if [ "$1" == "composer" ]
then
  # Install composer
  echo -e "${COL_GREEN}:: Installing composer${NC}"
  wget -O /usr/local/bin/composer https://getcomposer.org/composer-stable.phar
  chmod +x /usr/local/bin/composer

  echo -e " "
  echo -e "${COL_GREEN}✅ Installation completed!${NC}"

  exit 0
fi

if [ "$1" == "restart" ]
then
  echo -e "${COL_GREEN}:: Restarting services${NC}"

  echo -e "Restarting php-fpm"
  systemctl restart php-fpm.service
  # TODO Detect nginx / apache2
  echo -e "Restarting nginx"
  systemctl restart nginx.service

  echo -e " "
  echo -e "${COL_GREEN}✅ Services restarted!${NC}"

  exit 0
fi

# Default case: show help / info

echo -e " "
echo -e "This script helps you build and upgrade PHP versions"
echo -e "for a Debian 11 environment."
echo -e " "
echo -e "Always provide the desired PHP version as the second"
echo -e "parameter, as shown in the usage examples below."
echo -e " "
echo -e "Extensions and composer updates are optional for minor"
echo -e "version updates. Usually, they can remain as is,"
echo -e "so you may finish after the install step."
echo -e " "
echo -e "${COL_LB}Usage in order:${NC}"
echo -e " "
echo -e "$0 ${COL_GREEN}depinstall 8.2.4${NC} -> Install dependencies for PHP 8.2.4"
echo -e "$0 ${COL_GREEN}init 8.2.4${NC}       -> Initialize system for PHP 8.2.4"
echo -e "$0 ${COL_GREEN}compile 8.2.4${NC}    -> Configure, make, and test PHP 8.2.4"
echo -e "$0 ${COL_GREEN}install 8.2.4${NC}    -> Install PHP 8.2.4"
echo -e "$0 ${COL_GREEN}ext${NC}              -> Install PEAR and PECL extensions"
echo -e "$0 ${COL_GREEN}composer${NC}         -> Install the latest composer"
echo -e "$0 ${COL_GREEN}restart${NC}          -> Restart services (php-fpm + web server)"
echo -e " "

exit 0
