# Creating Projects with WiloDev Dock

## Introduction

This guide explains how to create new development projects using the WiloDev Dock environment. Whether you're building a Laravel or Symfony application, the `create-project.sh` script simplifies project initialization by automatically setting up containers, configuring web servers, and connecting to databases.

## Prerequisites

Before creating your first project, ensure:

1. You've completed the [Getting Started](./getting-started.md) guide
2. The WiloDev Dock infrastructure is running (`docker-compose ps` shows Traefik, MySQL, MongoDB, etc.)
3. You've generated SSL certificates during setup (required for HTTPS)
4. You have a basic understanding of the framework you plan to use (Laravel or Symfony)

## Basic Usage

The project creation script provides an interactive way to set up new projects:

### Linux/Mac

```bash
./create-project.sh laravel my-project my-project
```

### Windows

```powershell
.\create-project.ps1 laravel my-project my-project
```

Both commands support the following project types:

- `laravel` - For Laravel projects
- `symfony` - For Symfony projects
- `infinity` - For Infinity Framework projects (requires commercial license)

## Parameters

- **framework**: Type of project to create (`laravel` or `symfony`)
- **project-name**: Name for your project (alphanumeric characters, hyphens, and underscores only)
- **subdomain**: Subdomain where your project will be accessible (e.g., `myapp` results in `myapp.wilodev.localhost`)

```bash
Example:
./create-project.sh laravel my-blog blog
```

This creates a Laravel project named "my-blog" accessible at `https://blog.wilodev.localhost`

## Step-by-Step Guide

Let's walk through creating a project from start to finish:

1. Navigating to WiloDev Dock directory

   First, make sure you're in the WiloDev Dock directory:

   ```bash
      cd wilodev-dock
   ```

2. Running the creation script

   Let's create a Laravel application:

   ```bash
      ./create-project.sh laravel todo-app todo
   ```

   The script will:

   - Validate your inputs
   - Create necessary directories
   - Download Laravel/Symfony via Composer
   - Configure Nginx and PHP
   - Create Docker Compose files
   - Set up database access

3. Understanding the output

   During execution, you'll see detailed output like:

   ```bash
      [2023-07-15 14:30:25] INFO: 🐳 WiloDev Dock - Project Creator
      [2023-07-15 14:30:25] INFO: ========================================
      [2023-07-15 14:30:25] INFO: Verifying dependencies...
      [2023-07-15 14:30:26] SUCCESS: All dependencies are correctly installed.
      [2023-07-15 14:30:26] INFO: Validating project type: laravel
      [2023-07-15 14:30:26] SUCCESS: Valid project type: laravel
      [2023-07-15 14:30:26] INFO: Validating project name: todo-app
      [2023-07-15 14:30:26] SUCCESS: Valid project name: todo-app
      [2023-07-15 14:30:26] INFO: Validating subdomain: todo
      [2023-07-15 14:30:26] SUCCESS: Valid subdomain: todo
      [2023-07-15 14:30:26] INFO: Creating Laravel project: todo-app
      ...
   ```

   Wait for the script to complete. This might take a few minutes.

4. Starting your new project

   Once the script completes, navigate to your project directory and start the containers:

   ```bash
      cd projects/todo-app
      docker-compose up -d
   ```

5. Accessing your application

   Your application is now available at:

   ```bash
      <https://todo.wilodev.localhost>
   ```

Visit this URL in your browser to see your new Laravel application!

### Project Types in Detail

#### Laravel Projects

When creating a Laravel project, you get:

- PHP-FPM container with configurable PHP version
- Nginx configured with Laravel-specific optimizations
- MySQL database automatically configured
- Redis for caching and queues (optional)
- Laravel environment variables pre-configured
- Queue worker for background processing (optional)

**Laravel Project Structure:**

```bash
projects/your-project-name/
├── .env                    # Laravel environment variables
├── .env.docker            # Docker-specific environment variables
├── Dockerfile             # PHP container configuration
├── app/                   # Laravel application code
├── docker/
│   ├── nginx/             # Nginx configuration
│   ├── supervisor/        # Queue worker configuration
│   └── php.ini            # PHP configuration
├── docker-compose.yml     # Docker services definition
└── ...                    # Other Laravel files and directories
```

#### Symfony Projects

When creating a Symfony project, you get:

- PHP-FPM container with extensions optimized for Symfony
- Nginx configured with Symfony-specific routing rules
- MySQL database automatically configured
- Redis for caching and sessions (optional)
- Symfony environment variables pre-configured
- Messenger service for asynchronous processing (optional)

**Symfony Project Structure:**

```bash
projects/your-project-name/
├── .env                    # Symfony environment variables
├── .env.docker            # Docker-specific environment variables
├── Dockerfile             # PHP container configuration
├── bin/                   # Symfony console and binaries
├── config/                # Symfony configuration
├── docker/
│   ├── nginx/             # Nginx configuration
│   └── php.ini            # PHP configuration
├── docker-compose.yml     # Docker services definition
├── public/                # Web accessible files
├── src/                   # Symfony application code
└── ...                    # Other Symfony files and directories
```

### Customizing Your Project

#### Modifying Docker Configuration

You can customize your Docker setup by editing docker-compose.yml in your project directory:

```bash
cd projects/your-project-name
nano docker-compose.yml
```

Common customizations include:

- Changing PHP version
- Adding Node.js for frontend assets
- Configuring memory limits
- Adding additional services

After making changes, apply them with:

```bash
docker-compose down
docker-compose up -d
```

#### Customizing Nginx Configuration

To modify how Nginx handles your web requests:

```bash
cd projects/your-project-name
nano docker/nginx/default.conf
```

**Common Nginx customizations:**

- Adjusting request timeouts
- Redirecting specific URLs
- Enabling or disabling caching
- Setting custom error pages

After changes, restart the web container:

```bash
docker-compose restart webserver
```

#### Customizing PHP Configuration

To adjust PHP settings:

```bash
cd projects/your-project-name
nano docker/php.ini
```

**Common PHP customizations:**

- Memory limits
- File upload sizes
- Execution timeouts
- OPCache settings

Restart PHP after changes:

```bash
docker-compose restart app
```

### Working with Databases

#### Connecting to MySQL

Your project is automatically configured to connect to MySQL. Database details:

- **Host**: mysql (inside Docker) or localhost (from host machine)
- **Port**: 3306
- **Database**: The same as your project name
- **Username**: From your `.env` file (`MYSQL_USER` value)
- **Password**: From your `.env` file (`MYSQL_PASSWORD` value)

From your host machine, you can connect using tools like MySQL Workbench, DBeaver, or command line:

```bash
mysql -h localhost -P 3306 -u your_user -p your_project_name
```

#### Connecting to MongoDB

If your project uses MongoDB:

- **Host**: mongodb (inside Docker) or localhost (from host machine)
- **Port**: 27017
- **Database**: From your `.env` file (`MONGO_INITDB_DATABASE` value)
- **Username**: From your `.env` file (`MONGO_INITDB_ROOT_USERNAME` value)
- **Password**: From your `.env` file (`MONGO_INITDB_ROOT_PASSWORD` value)

Connect using MongoDB Compass or command line:

```bash
mongosh mongodb://username:password@localhost:27017/your_database
```

### Understanding How HTTPS Works

All projects created with the script are automatically configured with HTTPS through Traefik:

1. **External Access**: Users connect to <https://yoursubdomain.wilodev.localhost>
   - Traefik: Handles the SSL/TLS termination using local certificates
   - Internal Communication: Traefik forwards requests to your project's Nginx container via HTTP
2. Application: Your framework detects HTTPS correctly through special headers

No additional SSL configuration is required at the project level.

### Troubleshooting

#### Common Issues

##### Project Creation Fails

If the project creation script fails:

1. Ensure Docker is running
2. Check disk space (at least 1GB free recommended per project)
3. Verify MySQL and MongoDB containers are running
4. Check permissions on the projects directory

#### Cannot Access Project in Browser

If you can't access your project at the expected URL:

1. Verify the project containers are running (`docker-compose ps`)
2. Check for errors in Nginx logs (`docker-compose logs webserver`)
3. Ensure Traefik is running (`docker ps | grep traefik`)
4. Try clearing your browser cache or using incognito mode
5. Check `/etc/hosts` file or DNS settings for proper domain resolution

#### Database Connection Issues

If your application can't connect to the database:

1. Verify database container is running (`docker-compose ps`)
2. Check database credentials in the `.env` files
3. Ensure the database exists (`docker exec -it wilodev-mysql mysql -u root -p`)
4. Check network connectivity between containers

### Examples

#### Creating a Basic Laravel API

```bash
# Create the project

./create-project.sh laravel api-project api

# Start the containers

cd projects/api-project
docker-compose up -d

# Install Laravel Sanctum for API authentication

docker-compose exec app composer require laravel/sanctum
docker-compose exec app php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
docker-compose exec app php artisan migrate

# Your API is available at <https://api.wilodev.localhost>
```

#### Creating a Symfony Website

```bash
# Create the project

./create-project.sh symfony website website

# Start the containers

cd projects/website
docker-compose up -d

# Install Symfony packages

docker-compose exec app composer require symfony/orm-pack
docker-compose exec app composer require --dev symfony/maker-bundle
docker-compose exec app php bin/console doctrine:database:create

# Your website is available at <https://website.wilodev.localhost>
```

### Frequently Asked Questions

**Can I create multiple projects?**

Yes! You can create as many projects as you need. Each will have its own directory, containers, and subdomain.

**How do I access the container's command line?**

Use the `docker-compose exec` command:

```bash
cd projects/your-project-name
docker-compose exec app bash
```

This gives you a bash shell inside your PHP container.

#### How do I run Artisan or Symfony console commands?

**For Laravel:**

```bash
cd projects/your-laravel-project
docker-compose exec app php artisan migrate
```

**For Symfony:**

```bash
cd projects/your-symfony-project
docker-compose exec app php bin/console cache:clear
```

#### How do I install additional packages?

Use Composer inside your container:

```bash
cd projects/your-project-name
docker-compose exec app composer require package-name
```

#### Can I change the PHP version after creation?

Yes! Edit the Dockerfile in your project directory, then rebuild:

```bash
cd projects/your-project-name
# Edit Dockerfile to change PHP_VERSION
docker-compose build --no-cache
docker-compose up -d
```

#### How do I run npm or yarn?

The containers have Node.js and npm/yarn installed:

```bash
cd projects/your-project-name
docker-compose exec app npm install
docker-compose exec app npm run dev
```
