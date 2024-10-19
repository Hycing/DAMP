FROM php:8.1-apache

RUN apt-get update && apt-get install -y gnupg2 curl

#Rep Microsoft
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add -

#rep de Microsoft for Debian Bullseye 
RUN echo "deb [arch=amd64] https://packages.microsoft.com/debian/11/prod bullseye main" > /etc/apt/sources.list.d/mssql-release.list

RUN apt-get update && ACCEPT_EULA=Y apt-get install -y \
  msodbcsql17 \
  unixodbc-dev \
  imagemagick \
  libfreetype6-dev \
  libjpeg62-turbo-dev \
  libmagickwand-dev --no-install-recommends \
  libpng-dev \
  && rm -rf /var/lib/apt/lists/*

RUN a2enmod ssl

RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout /etc/ssl/private/apache-selfsigned.key \
  -out /etc/ssl/certs/apache-selfsigned.crt \
  -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=localhost"

RUN echo "\
<VirtualHost *:443>\n\
    ServerAdmin webmaster@localhost\n\
    DocumentRoot /var/www/html\n\
    SSLEngine on\n\
    SSLCertificateFile /etc/ssl/certs/apache-selfsigned.crt\n\
    SSLCertificateKeyFile /etc/ssl/private/apache-selfsigned.key\n\
    <Directory /var/www/html>\n\
        Options Indexes FollowSymLinks MultiViews\n\
        AllowOverride All\n\
        Require all granted\n\
    </Directory>\n\
    ErrorLog \${APACHE_LOG_DIR}/error.log\n\
    CustomLog \${APACHE_LOG_DIR}/access.log combined\n\
</VirtualHost>" > /etc/apache2/sites-available/default-ssl.conf

RUN a2ensite default-ssl && a2enmod rewrite

RUN a2enmod rewrite \
  && docker-php-ext-install exif \
  && docker-php-ext-configure gd --with-freetype --with-jpeg && docker-php-ext-install -j$(nproc) gd \
  && pecl install imagick && docker-php-ext-enable imagick \
  && docker-php-ext-install mysqli \
  && docker-php-ext-install pdo pdo_mysql \
  && pecl install sqlsrv pdo_sqlsrv && docker-php-ext-enable sqlsrv pdo_sqlsrv \
  && docker-php-ext-configure pdo_odbc --with-pdo-odbc=unixODBC,/usr \
  && docker-php-ext-install pdo_odbc
