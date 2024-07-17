# PHPBuilder

![Header Banner](https://neoground.com/data/projects/phpbuilder/assets/banner.jpg)

---

![GitHub release (latest SemVer)](https://img.shields.io/github/v/release/neoground/phpbuilder?sort=semver)
![GitHub license](https://img.shields.io/github/license/neoground/phpbuilder)
![GitHub issues](https://img.shields.io/github/issues/neoground/phpbuilder)
![GitHub stars](https://img.shields.io/github/stars/neoground/phpbuilder?style=social)

## 🤗 About

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

## 🤩 Features

- Fetch and build PHP8+ from source, including unit tests
- Provide a modern environment with comprehensive PHP extension support 
- Install built PHP, including PEAR and PECL 
- Install custom PEAR and PECL extensions (currently `redis`, `imagick` and `mailparse`)
- Make handy adjustments, like updating the imagick config for native PDF read/write support 
- Organize config files centralized under `/etc/php` (e.g.: `/etc/php/php.ini`)
- Enable PHP-FPM support via systemd
- Install the latest version of Composer 
- Easily install all required dev dependencies

## 🛠 Installation

Experience the efficiency of PHPBuilder with our straightforward installation process.
Whether you're looking to deploy the latest release or experiment with the most recent code, 
our installation guide makes it easy for you to get started. 
Follow these steps to install PHPBuilder on your system and elevate your PHP development environment.

### Installing the Latest Release

For those who prefer the stability and reliability of an official release, 
installing the latest version of PHPBuilder is a simple process. Follow these 
steps to get up and running with the most recent stable release:

1. **Download the Latest Release**:  
   Use `wget` to download the latest release package from our GitHub repository:

   ```sh
   wget https://github.com/neoground/phpbuilder/releases/download/v1.5/phpbuilder-v1.6.zip
   ```

2. **Unpack the Archive**:  
   Once the download is complete, unzip the archive to extract the PHPBuilder script:

   ```sh
   unzip phpbuilder-v1.6.zip
   ```

3. **Set Execution Permissions**:  
   Change the permission of the script to make it executable:

   ```sh
   chmod +x phpbuilder.sh
   ```

4. **Run the Installation**:  
   Execute the PHPBuilder script in auto-mode with the desired PHP version (e.g., PHP 8.3.9):

   ```sh
   ./phpbuilder.sh auto 8.3.9
   ```

   The script will guide you through the installation process, ensuring a smooth and efficient setup.
   You can also simply call the script without parameters to get an overview of all available commands.

### Installing from the Latest Code

For developers and sysadmins who like to stay on the cutting edge, installing PHPBuilder
from the latest code offers access to the most recent features and updates. 
Here’s how to install PHPBuilder using the latest code from our GitHub repository:

1. **Clone the Repository**:  
   Use `git` to clone the PHPBuilder repository to your local system:

   ```sh
   git clone https://github.com/neoground/phpbuilder.git
   ```

2. **Navigate to the Directory**:  
   Change to the directory containing the cloned PHPBuilder script:

   ```sh
   cd phpbuilder
   ```

3. **Set Execution Permissions**:  
   Update the script's permissions to make it executable:

   ```sh
   chmod +x phpbuilder.sh
   ```

4. **Run the Installation**:  
   Start the PHPBuilder installation in auto-mode with your desired PHP version:

   ```sh
   ./phpbuilder.sh auto 8.3.9
   ```

   Follow the prompts provided by the script to complete the installation.

## 👩‍💻 Usage

Simply execute the main script in auto-mode and enter the desired PHP version. 
The script will guide you through each step.

You can also call the script without any parameters to display the help message.

```sh
./phpbuilder.sh auto [PHP version]
```

Alternatively, you can run the command without parameters to view 
the available options and arguments, allowing you to build your 
PHP environment step by step.

```sh
./phpbuilder.sh
```

## 🤔 Why PHPBuilder?

Born from our company's passion for innovation, PHPBuilder has evolved into an 
open-source project that benefits the entire development and sysadmin community. 
PHPBuilder enables you to harness the full potential of PHP while maintaining 
complete control over your environment.

This is also very handy for local development environments.

Unleash the power of PHPBuilder, and experience the difference today!

## 🤝 Contributing

We welcome contributions! If you have any ideas, bug reports, or enhancements,
feel free to open an issue or submit a pull request on GitHub. 
Let's make PHPBuilder even better, together!
