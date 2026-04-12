FROM php:8.5-apache

# Dipendenze di sistema
RUN apt-get update && apt-get install -y unzip git libzip-dev libpng-dev libjpeg-dev libfreetype6-dev && rm -rf /var/lib/apt/lists/*

# Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Estensioni PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && docker-php-ext-install mysqli pdo pdo_mysql zip gd && docker-php-ext-enable mysqli
RUN pecl install pcov && docker-php-ext-enable pcov
RUN pecl install xdebug && docker-php-ext-enable xdebug
RUN a2enmod rewrite

# COPIA FORZATA DELLA CONFIGURAZIONE
COPY vhost.conf /etc/apache2/sites-available/000-default.conf
COPY xdebug.ini /usr/local/etc/php/conf.d/xdebug.ini

# Script di avvio per impostare i permessi
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Sisma CLI
ENV PATH="/var/www/html/SismaFramework/Console:${PATH}"

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]