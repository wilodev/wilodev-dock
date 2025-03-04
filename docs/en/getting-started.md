# Getting Started with WiloDev Dock

## Introduction

WiloDev Dock is a comprehensive containerized development environment designed to streamline your web development workflow. This guide will walk you through setting up and using the environment for the first time.

## System Requirements

Before getting started, ensure your system meets the following requirements:

- Docker Engine 20.10 or higher
- Docker Compose 2.0 or higher
- At least 5GB of free disk space
- Minimum 4GB RAM (8GB recommended for optimal performance)
- Modern web browser (Chrome, Firefox, Edge, or Safari)
- Terminal access

## Optional Requirements

The following tools aren't strictly required but can enhance your experience:

- **Git** for version control
- **mkcert** for local SSL certificates (automatically installed by the setup script if missing)
- **htpasswd** utility (part of apache2-utils/httpd-tools packages)

## Installation

### Step 1: Clone the Repository

Start by cloning the WiloDev Dock repository to your local machine:

```bash
git clone https://github.com/wilodev/wilodev-dock.git
cd wilodev-dock
```

### Step 2: Create Environment Configuration

Copy the example environment file and customize it to your needs:

```bash
cp .env.example .env
```

Open the `.env` file in your preferred text editor and adjust the following key settings:

- **DOMAIN_BASE**: The base domain for all services (default: wilodev.localhost)
- **NETWORK_NAME**: Docker network name (default: wilodev_network)
- **TRAEFIK_DASHBOARD_USER** and **TRAEFIK_DASHBOARD_PASSWORD**: Credentials for the Traefik dashboard
- **Database connection details (MYSQL_ROOT_PASSWORD, MONGO_INITDB_ROOT_USERNAME, etc.)**: Ensure these match your database configurations.

### Step 3: Run the Setup Script

Execute the setup script to configure your environment:

#### Linux/Mac-script

```bash
cp setup.linux-mac.example.sh setup.sh
chmod +x setup.sh
./setup.sh
```

#### Windows-script

```powershell
Copy-Item setup.windows.example.ps1 setup.ps1
.\setup.ps1
```

This script will:

- Check your system for required software
- Create necessary directories
- Set up SSL certificates for local development
- Create Docker networks and volumes
- Start all the infrastructure services
- Verify that everything is running correctly

The process usually takes 2-5 minutes, depending on your internet connection and system performance.

## First Steps After Installation

Once the installation completes successfully, you'll have access to the following services:

### Accessing the Traefik Dashboard

The Traefik dashboard provides an overview of your services and routing configuration:

- **URL**: <https://traefik.wilodev.localhos> (or your configured TRAEFIK_DOMAIN)
- **Credentials**: The username and password you set in the .env file

### Exploring Available Services

WiloDev Dock comes with several pre-configured services:

| Service | Purpose | Default URL |
|---------|---------|-------------|
| **Traefik** | Reverse Proxy & SSL | https://{TRAEFIK_DOMAIN} |
| **MySQL** | Relational Database | localhost:{MYSQL_PORT} |
| **MongoDB** | NoSQL Database | localhost:{MONGO_PORT}|
| **MailHog** | Email Testing | https://{MAILHOG_DOMAIN} |
| **Prometheus** | Metrics Collection |    <https://prometheus.{DOMAIN_BASE}> |
| **Grafana** | Metrics Visualization | <https://grafana.{DOMAIN_BASE}> |
| **Loki** | Log Aggregation | (Internal) |

### Connecting to Databases

You can connect to the databases using your preferred database client:

#### MySQL

- **Host**: localhost
- **Port**: 3306 (or as configured in .env)
- **Username**: As defined in MYSQL_USER
- **Password**: As defined in MYSQL_PASSWORD
- **Database**: As defined in MYSQL_DATABASE

#### MongoDB

- **Host**: localhost
- **Port**: 27017 (or as configured in .env)
- **Username**: As defined in MONGO_INITDB_ROOT_USERNAME
- **Password**: As defined in MONGO_INITDB_ROOT_PASSWORD
- **Database**: As defined in MONGO_INITDB_DATABASE

### Testing Email Functionality

MailHog captures all outgoing emails from your applications. To test it:

1. Configure your application to use SMTP with:

   - **Host**: mailhog (or localhost)
   - **Port**: 1025 (or as configured in .env)
   - **No authentication required**

2. Access the MailHog web interface at <https://mail.wilodev.localhost> to view captured emails

### Creating Your First Project

WiloDev Dock supports different types of projects, primarily focused on Laravel and Symfony frameworks.

#### Using the Project Creation Script

To create a new project:

##### Linux/Mac

```bash
./create-project.sh
```

##### Windows

```powershell
.\create-project.ps1
```

This interactive script will:

- Ask for the project type (Laravel or Symfony)
- Prompt for project name and domain
- Set up appropriate Docker containers
- Configure Nginx and PHP
- Initialize the project with the selected framework
- Configure database connections

#### Manual Project Configuration

If you prefer to manually configure a project:

1. Create a directory in the `projects/` folder
2. Copy the appropriate template files from:
   - `laravel/` directory for Laravel projects
   - `symfony/` directory for Symfony projects
3. Adjust the Docker Compose and configuration files as needed
4. Start your project containers

### Understanding the Architecture

WiloDev Dock uses a layered architecture:

- Traefik Layer: Handles all HTTP/HTTPS traffic, routes requests, and manages SSL
- Service Layer: Contains your application containers (PHP, Node.js, etc.)
- Data Layer: Provides database services (MySQL, MongoDB)
- Utility Layer: Additional services like MailHog for testing
- Observability Layer: Monitoring with Prometheus, Grafana, and Loki

### SSL/HTTPS Configuration

All external traffic is managed by Traefik through HTTPS (port 443):

- Self-generated certificates created by mkcert provide locally-trusted SSL
- Traefik handles SSL termination
- Internal services communicate via HTTP on the Docker network
- Framework-specific configurations ensure your applications correctly detect HTTPS

### Basic Commands

#### Starting and Stopping Services

To start all services:

```bash
docker compose up -d
```

To stop all services:

```bash
docker compose down
```

To restart a specific service:

```bash
docker compose restart <service_name>
```

#### Viewing Logs

To view logs from all services:

```bash
docker-compose logs
```

For a specific service:

```bash
docker-compose logs [service-name]
```

To follow logs in real-time:

```bash
docker-compose logs -f [service-name]
```

### Next Steps

Now that you have WiloDev Dock up and running, you can:

- [Create a new project](./creating-projects.md) for your development work
- Explore the [configuration reference](./configuration.md) for advanced settings
- Check the [troubleshooting guide](./troubleshooting.md) if you encounter issues
- Learn about [performance tuning](./performance.md) for optimal development experience
