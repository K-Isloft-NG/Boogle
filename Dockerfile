FROM php:8.3-apache

# Extension PDO PostgreSQL (Neon)
RUN apt-get update \
    && apt-get install -y --no-install-recommends libpq-dev \
    && docker-php-ext-install pdo_pgsql \
    && rm -rf /var/lib/apt/lists/*

# Configuration PHP de production (display_errors désactivé, expose_php off)
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Seul le dossier public/ est exposé par Apache : src/, sql/, templates/ restent inaccessibles
ENV APACHE_DOCUMENT_ROOT=/var/www/html/public
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
        /etc/apache2/sites-available/*.conf \
        /etc/apache2/apache2.conf \
        /etc/apache2/conf-available/*.conf \
    && a2enmod headers \
    && printf 'ServerTokens Prod\nServerSignature Off\n' > /etc/apache2/conf-available/security-hardening.conf \
    && a2enconf security-hardening

COPY . /var/www/html
RUN chown -R www-data:www-data /var/www/html/logs

EXPOSE 80
