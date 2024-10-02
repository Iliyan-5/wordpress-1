#!/bin/bash

set -ex

echo 'export DB_ENDPOINT=${DB_ENDPOINT}' >> /tmp/vars
echo 'export DB_NAME=${DB_NAME}' >> /tmp/vars
echo 'export DB_USER=${DB_USER}' >> /tmp/vars
echo 'export DB_PASSWORD=${DB_PASSWORD}' >> /tmp/vars
echo 'export WP_URL=${WP_URL}' >> /tmp/vars
echo 'export WP_TITLE=${WP_TITLE}' >> /tmp/vars
echo 'export WP_ADMIN_USER=${WP_ADMIN_USER}' >> /tmp/vars
echo 'export WP_ADMIN_PASSWORD=${WP_ADMIN_PASSWORD}' >> /tmp/vars
echo 'export WP_ADMIN_EMAIL=${WP_ADMIN_EMAIL}' >> /tmp/vars

source /tmp/vars


# Update the package index
yum update -y

# Install Apache and PHP
yum install -y httpd php php-mysqlnd php-pdo php-gd php-mbstring php-xml php-pear php-bcmath

# Start Apache and enable it 
systemctl start httpd
systemctl enable httpd

#Install Wordpress CLI
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar

#Add WP-CLI to PATH
mv wp-cli.phar /usr/local/bin/wp

# Download WordPress
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz -C /var/www/html --strip-components=1
rm latest.tar.gz

# Set the correct permissions
chown -R root:root /var/www/html
chmod -R 775 /var/www/html

cd /var/www/html

# Configure and Install WP
wp config create --dbname=$DB_NAME --dbuser=$DB_USER --dbpass=$DB_PASSWORD --dbhost=$DB_ENDPOINT --path=/var/www/html --allow-root
wp core install --url=$WP_URL --title="$WP_TITLE" --admin_user=$WP_ADMIN_USER --admin_password="password1" --admin_email=$WP_ADMIN_EMAIL --path=/var/www/html --allow-root

chown -R apache:apache /var/www/html
chmod -R 755 /var/www/html


# Create .htaccess file to redirect to wp-login.php
cat <<EOT > /var/www/html/.htaccess
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteCond %%{REQUEST_URI} ^/\$
RewriteRule ^(.*)\$ /wp-login.php [L]
</IfModule>
EOT

# Ensure AllowOverride is enabled in Apache config
sed -i 's/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf

# Restart Apache
systemctl restart httpd
