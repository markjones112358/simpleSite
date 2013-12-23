#! /bin/bash
if [ ! -w "/etc/apache2/sites-available" ]
then
    echo "This script requires elevated priveledges - run with sudo"
    exit
fi
install=`pwd`
echo "The website will run from the current directory ($install)."
echo ""
echo "This website will use two subdomains. One for dynamic content (pages etc.)"
echo "and one for static content (images and javascript etc.)."
echo ""
echo "The url for dynamic content is usually www.domain.com"
echo "and static is usually static.domain.com"
echo ""
read -p "Enter the full url for this website's dynamic content: " url_content
if [ `echo "$url_content" | grep -c '\.'` -eq 0 ]
then
    echo "The url must include a top-level domain (e.g. .com)"
    exit
fi
read -p "Enter the full url for this website's static content: " url_static
if [ `echo "$url_static" | grep -c '\.'` -eq 0 ]
then
    echo "The url must include a top-level domain (e.g. .com)"
    exit
fi

echo "Main site will be installed as $url_content"
echo "With a static subdomain of $url_static"
echo ""
read -p "Enter a name for the website: " name
echo "The website will be called $name"
echo ""
echo "TIP: You may add any alias website names to /etc/apache2/sites-available/$name,"
echo "     after which you will need to restart apache (sudo service apache2 restart)."
echo ""
read -p "Enter your email address: " email
echo ""
echo "The website watches and displays the content of a given folder."
read -p "Enter the full path to the watch folder: " path
echo "The website will watch $path"
echo "TIP: Website settings are stored in $path/.siteSettings,"
echo "     modify this file to alter the website style"
echo ""
if [ -e "$path" ]
then
    if [ -d "$path" ]
    then
        echo "Directory found"
        if [ ! -e "$path/.siteSettings" ]
        then
            echo "Creating site configuration folder at location"
            mkdir $path/.siteSettings
            chgrp www-data $path/.siteSettings
            chown $USER $path/.siteSettings
            chmod 754 $path/.siteSettings
        fi

        if [ ! -e "$path/.siteSettings/settings.php" ]
        then
            echo "Copying site settings to sittings folder"
            cp settings.php $path/.siteSettings
        fi

        if [ ! -e "$path/.siteSettings/logo_large.png" ]
        then
            echo "Copying default logo (large) to sittings folder"
            cp static/logo_large.png $path/.siteSettings
        fi

        if [ ! -e "$path/.siteSettings/logo_small.png" ]
        then
            echo "Copying default logo (small) to sittings folder"
            cp static/logo_small.png $path/.siteSettings
        fi

    else
        echo "Path not a directory"
        exit
    fi
else
    echo "Path not found"
    exit
fi
echo "Linking /var/www/$name to $install..."
if [ -e "/var/www/$name" ]
then
    sudo rm "/var/www/$name"
fi
sudo ln -sf $install/ /var/www/$name
echo "Done!"
echo ""
echo "Creating apache configuration file (/etc/apache2/sites-available/$name)..."
sudo echo "<VirtualHost *:80>
    ServerAdmin $email
    ServerName $url_content
    DocumentRoot /var/www/$name/public_html/

    <Directory /var/www/$name/public_html>
        Options -Indexes +FollowSymLinks MultiViews
        AllowOverride None
        Order allow,deny
        allow from all
        DirectoryIndex /index.php
        FallbackResource /index.php
    </Directory>
</VirtualHost>

<VirtualHost *:80>
    ServerAdmin $email
    ServerName $url_static
    DocumentRoot /var/www/$name/static/

    <Directory /var/www/$name/static/>
        Options -Indexes +FollowSymLinks MultiViews
        AllowOverride None
        Order allow,deny
        allow from all
    </Directory>
</VirtualHost>" > /etc/apache2/sites-available/$name
echo "Done!"
echo ""
echo "Enabling new website configuration in Apache..."
sudo a2ensite $name
echo "Done!"
echo ""
echo "Setting www-data group write permissions on public_html folder..."
chgrp www-data . -R
chmod 754 . -R
chgrp www-data public_html -R
chmod 774 public_html -R
echo "Done!"
echo ""
echo "Restarting Apache with new configuration loaded..."
sudo service apache2 restart
echo "Done!"
echo ""
if [ `grep -c "$url_content" /etc/hosts` -eq 0 ]
then
    echo "Adding link in hosts file to allow local viewing of website (/etc/hosts)..."
    sudo echo "
127.0.0.1        $url_content
127.0.0.1        $url_static" >> /etc/hosts
    echo "Done!"
    echo ""
fi
echo "Fetching required PHP-HTMLifier library from github..."
sudo rm -r lib/PHP-HTMLifier
git clone https://github.com/markjones112358/PHP-HTMLifier lib/PHP-HTMLifier
echo "Done!"
echo ""
echo "Saving website configuration"
if [ -e config.php ]
then
    rm config.php
fi
echo "
<?php
// Website configuration - generated by setup.sh of simpleSite
// For site source see: https://github.com/markjones112358/simpleSite

define('PATH_WATCH', '$path');
define('URL_STATIC', '$url_static');
define('PAGE_CACHING', True);
include(PATH_WATCH . '/.siteSettings/settings.php');
?>
" > config.php
echo "Done!"
echo ""
if [ ! -e /usr/bin/convert ]
    then
    echo "Important! Could not find ImageMagick!"
    echo "Please install imagemagick using your package manager"
    echo "e.g. sudo apt-get install imagemagick"
fi
echo ""
echo "Installation complete. You can view the website at http://$url_content"
