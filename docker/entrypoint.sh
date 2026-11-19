#!/bin/bash
set -e

# Copy environment file if .env is missing
if [ ! -f "/var/www/html/.env" ]; then
    if [ -f "/var/www/html/.env.docker" ]; then
        echo "Copying .env.docker to .env..."
        cp /var/www/html/.env.docker /var/www/html/.env
    elif [ -f "/var/www/html/.env.docker.example" ]; then
        echo "Copying .env.docker.example to .env..."
        cp /var/www/html/.env.docker.example /var/www/html/.env
    elif [ -f "/var/www/html/.env.example" ]; then
        echo "Copying .env.example to .env..."
        cp /var/www/html/.env.example /var/www/html/.env
    fi
fi

# Ensure storage and cache directories exist with appropriate permissions
mkdir -p \
    /var/www/html/storage/app/public \
    /var/www/html/storage/framework/cache/data \
    /var/www/html/storage/framework/sessions \
    /var/www/html/storage/framework/views \
    /var/www/html/storage/logs \
    /var/www/html/bootstrap/cache

chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# If vendor directory or autoloader is missing, install dependencies
if [ ! -f "/var/www/html/vendor/autoload.php" ]; then
    echo "Composer dependencies not found. Installing dependencies..."
    composer install --no-interaction --prefer-dist --optimize-autoloader
fi

# Generate application key if missing
if grep -q "APP_KEY=$" /var/www/html/.env 2>/dev/null || grep -q "APP_KEY=\"\"" /var/www/html/.env 2>/dev/null || [ -z "$APP_KEY" ] && ! grep -q "APP_KEY=base64:" /var/www/html/.env 2>/dev/null; then
    echo "Generating application encryption key..."
    php artisan key:generate --force --no-interaction || true
fi

# Wait for MySQL database if configured
DB_CONN="${DB_CONNECTION:-mysql}"
if [ "$DB_CONN" = "mysql" ] || [ "$DB_CONN" = "mariadb" ]; then
    DB_TARGET_HOST="${DB_HOST:-db}"
    DB_TARGET_PORT="${DB_PORT:-3306}"
    DB_TARGET_USER="${DB_USERNAME:-drivesphere}"
    DB_TARGET_PASS="${DB_PASSWORD:-secret123}"

    echo "Waiting for database at $DB_TARGET_HOST:$DB_TARGET_PORT..."
    max_tries=30
    counter=0
    until php -r "
        \$host = '$DB_TARGET_HOST';
        \$port = '$DB_TARGET_PORT';
        \$user = '$DB_TARGET_USER';
        \$pass = '$DB_TARGET_PASS';
        try {
            \$pdo = new PDO(\"mysql:host=\$host;port=\$port\", \$user, \$pass, [
                PDO::ATTR_TIMEOUT => 2,
                PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION
            ]);
            exit(0);
        } catch (\Throwable \$e) {
            exit(1);
        }
    " 2>/dev/null; do
        counter=$((counter + 1))
        if [ $counter -ge $max_tries ]; then
            echo "Database connection timed out after $max_tries attempts. Proceeding with command..."
            break
        fi
        sleep 2
    done

    if [ $counter -lt $max_tries ]; then
        echo "Database connection established successfully!"
    fi
fi

exec "$@"
