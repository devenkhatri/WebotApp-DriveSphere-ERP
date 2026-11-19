# ==============================================================================
# Stage 1: Build Frontend Assets (Vite + Tailwind CSS + Alpine.js + Chart.js)
# ==============================================================================
FROM node:20-alpine AS frontend
WORKDIR /app

# Copy dependency definitions and install
COPY package.json package-lock.json ./
RUN npm ci

# Copy configuration and asset source files
COPY vite.config.js tailwind.config.js postcss.config.js ./
COPY resources ./resources

# Build production assets into /app/public/build
RUN npm run build

# ==============================================================================
# Stage 2: Install Composer Dependencies
# ==============================================================================
FROM composer:2 AS vendor
WORKDIR /app

# Copy composer definitions
COPY composer.json composer.lock ./

# Install PHP dependencies without dev packages and scripts
RUN composer install \
    --no-dev \
    --no-interaction \
    --no-scripts \
    --prefer-dist \
    --optimize-autoloader \
    --ignore-platform-reqs

# ==============================================================================
# Stage 3: Final PHP-FPM Application Runtime
# ==============================================================================
FROM php:8.3-fpm-alpine AS app

# Install system dependencies
RUN apk add --no-cache \
    bash \
    curl \
    git \
    libpng \
    libjpeg-turbo \
    freetype \
    libzip \
    icu-libs \
    oniguruma

# Install official PHP extension installer helper
COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/

# Install and enable essential PHP extensions
RUN install-php-extensions \
    pdo_mysql \
    mbstring \
    bcmath \
    gd \
    zip \
    opcache \
    intl \
    exif \
    pcntl \
    redis

# Install Composer CLI into final image for container execution
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy custom PHP & OPcache configurations
COPY docker/php/php.ini /usr/local/etc/php/conf.d/99-custom.ini
COPY docker/php/opcache.ini /usr/local/etc/php/conf.d/99-opcache.ini

# Copy application source code
COPY . /var/www/html

# Copy pre-installed vendor and pre-compiled frontend assets
COPY --from=vendor /app/vendor /var/www/html/vendor
COPY --from=frontend /app/public/build /var/www/html/public/build

# Setup entrypoint script
COPY docker/entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Ensure storage & bootstrap directory permissions for www-data
RUN mkdir -p \
    /var/www/html/storage/app/public \
    /var/www/html/storage/framework/cache/data \
    /var/www/html/storage/framework/sessions \
    /var/www/html/storage/framework/views \
    /var/www/html/storage/logs \
    /var/www/html/bootstrap/cache \
    && chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache \
    && chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Expose PHP-FPM FastCGI port
EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["php-fpm"]
