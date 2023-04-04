# PHPBuilder

PHPBuilder is a powerful, modern, and easy-to-use script designed to build specific 
PHP versions from source and install them on your system. Initially developed 
for Debian 11, PHPBuilder is compatible with most Debian and Ubuntu-based systems.

In today's fast-paced digital world, staying up-to-date with the latest PHP 
versions is crucial for optimal performance and capabilities. 
While package repositories like `sury` offer solutions, they often lack the 
flexibility and control that developers and sysadmins demand, 
especially when it comes to security and data privacy.

That's why we at [Neoground GmbH](https://neoground.com) created PHPBuilder — an 
open-source project that empowers developers and sysadmins with a simple, 
up-to-date, and fully customizable PHP installation for their servers.

## Features

- Fetch and build PHP8+ from source, including unit tests
- Provide a modern environment with comprehensive PHP extension support 
- Install built PHP, including PEAR and PECL 
- Install custom PEAR and PECL extensions (e.g., `redis`, `imagick`)
- Make handy adjustments, like updating the imagick config for native PDF read/write support 
- Organize config files under `/etc/php` in version-specific subdirectories (e.g., PHP 8.1: `/etc/php/8.1/php.ini`)
- Enable PHP-FPM support via systemd
- Install the latest version of Composer 
- Easily install all required dev dependencies

## Usage

Simply execute the main script and enter the desired PHP version. 
The script will guide you through each step.

```sh
./phpbuilder.sh [PHP version]
```

Alternatively, you can run the command without parameters to view 
the available options and arguments, allowing you to build your 
PHP environment step by step.

```sh
./phpbuilder.sh
```

## Why PHPBuilder?

Born from our company's passion for innovation, PHPBuilder has evolved into an 
open-source project that benefits the entire development and sysadmin community. 
PHPBuilder enables you to harness the full potential of PHP while maintaining 
complete control over your environment.

This is also very handy for local development environments.

Unleash the power of PHPBuilder, and experience the difference today!

## Contributing

We welcome contributions! If you have any ideas, bug reports, or enhancements,
feel free to open an issue or submit a pull request on GitHub. 
Let's make PHPBuilder even better, together!
