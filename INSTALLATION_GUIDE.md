# CAR RENTAL ERP — INSTALLATION & SETUP GUIDE

## 1. Quick Setup with Docker (Recommended 🐳)

### Prerequisites
- Docker Desktop v24+ & Docker Compose v2.20+

```bash
# 1. Configure environment from Docker template
cp .env.docker.example .env

# 2. Build images and start all containers (App, Nginx, MySQL 8.0, Queue Worker, Scheduler)
docker compose up -d --build

# 3. Run database migrations with comprehensive dummy seeds
docker compose exec app php artisan migrate:fresh --seed

# 4. View container status
docker compose ps
```

Visit: `http://localhost:8000`

---

## 2. Local Native Setup (Without Docker)

### Prerequisites
- **PHP:** 8.2+ (PHP 8.4 recommended) with extensions: `pdo_mysql`, `mbstring`, `curl`, `openssl`, `gd`, `zip`, `bcmath`.
- **Database:** MariaDB 10.4+ or MySQL 8.0+.
- **Node.js:** v20+ with npm.
- **Composer:** v2+.

```bash
# 1. Clone or navigate to directory
cd /path/to/WebotApp-DriveSphere-ERP

# 2. Configure environment
cp .env.example .env
php artisan key:generate

# 3. Install PHP & Node dependencies
composer install
npm install

# 4. Compile frontend assets
npm run build

# 5. Create database and run migrations
mysql -u root -e "CREATE DATABASE IF NOT EXISTS carrental_erp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
php artisan migrate --seed

# 6. Start the local server
php artisan serve
```

Visit: `http://localhost:8000`

---

## 3. Demo Login Credentials

| Role | Email | Password |
|---|---|---|
| **Super Admin** | `admin@drivesphere.com` | `password123` |
| **Fleet Manager** | `fleet@drivesphere.com` | `password123` |
| **Counter Staff** | `staff@drivesphere.com` | `password123` |
| **Chauffeur** | `driver@drivesphere.com` | `password123` |
| **Customer** | `customer@drivesphere.com` | `password123` |

*(Note: The login screen also features 1-click instant login buttons for all roles).*

