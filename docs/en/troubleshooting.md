# Troubleshooting Guide for WiloDev Dock

## Introduction

This comprehensive troubleshooting guide helps you diagnose and resolve common issues with WiloDev Dock. Whether you're a junior developer new to containerized environments or an experienced senior engineer, you'll find detailed solutions for a wide range of problems.

## Table of Contents

- [Troubleshooting Guide for WiloDev Dock](#troubleshooting-guide-for-wilodev-dock)
  - [Introduction](#introduction)
  - [Table of Contents](#table-of-contents)
  - [Methodology](#methodology)
  - [Installation Issues](#installation-issues)
    - [Setup Script Fails](#setup-script-fails)
    - [Container Creation Fails](#container-creation-fails)
    - [Network and Connectivity Problems](#network-and-connectivity-problems)
      - [Services Can't Communicate](#services-cant-communicate)
      - [Domain Resolution Issues](#domain-resolution-issues)
  - [SSL Certificate Issues](#ssl-certificate-issues)
    - [Certificate Errors in Browser](#certificate-errors-in-browser)
  - [Service-Specific Problems](#service-specific-problems)
    - [Traefik Issues](#traefik-issues)
    - [MySQL Issues](#mysql-issues)
    - [MongoDB Issues](#mongodb-issues)
    - [MailHog Issues](#mailhog-issues)
    - [Monitoring Stack Issues](#monitoring-stack-issues)
  - [Project-Related Issues](#project-related-issues)
    - [Project Creation Fails](#project-creation-fails)
    - [Project Container Issues](#project-container-issues)
    - [Database Connection Issues](#database-connection-issues)
  - [Performance Optimization](#performance-optimization)
    - [Slow Container Performance](#slow-container-performance)
    - [Network Latency Issues](#network-latency-issues)
    - [Diagnostic Tools](#diagnostic-tools)
      - [Essential Docker Commands](#essential-docker-commands)
      - [Database Diagnostic Commands](#database-diagnostic-commands)
      - [Web Server Diagnostics](#web-server-diagnostics)
    - [Recovery and Backup](#recovery-and-backup)
      - [Creating Backups](#creating-backups)
      - [Restoring Backups](#restoring-backups)
      - [Emergency Reset](#emergency-reset)
    - [Additional Tips](#additional-tips)
      - [Regular System Checks](#regular-system-checks)
      - [Update Optimization](#update-optimization)
      - [Troubleshooting for Teams](#troubleshooting-for-teams)
  - [Recommended Additional Tools](#recommended-additional-tools)
  - [Conclusion](#conclusion)

## Methodology

When troubleshooting issues with WiloDev Dock, follow this structured approach:

1. **Identify the problem**: Determine exactly what's not working as expected
2. **Check logs**: Container logs are your first source of information
3. **Verify configuration**: Ensure your settings are correct
4. **Isolate the issue**: Determine if the problem is in the infrastructure or your application
5. **Apply solution**: Follow the specific steps for your issue
6. **Verify resolution**: Confirm the issue is resolved
7. **Document lessons learned**: Make notes to avoid similar issues in the future

## Installation Issues

### Setup Script Fails

**Symptoms:**

- The `setup.sh` script exits with an error
- Some containers fail to start

**Solutions:**

1. **Permission Issues**

    ```bash
        # Make sure script is executable
        chmod +x setup.sh

        # Ensure you're not running as root
        # Run as regular user, not with sudo
        ./setup.sh
    ```

2. **Docker Not Running**

    ```bash
        # Check Docker status
        systemctl status docker

        # Start Docker if needed
        sudo systemctl start docker
    ```

3. **Port Conflicts**

    ```bash
        # Check if ports 80/443 are already in use
        sudo lsof -i :80
        sudo lsof -i :443

        # Change ports in .env file if needed
        # TRAEFIK_HTTP_PORT=8080
        # TRAEFIK_HTTPS_PORT=8443
    ```

4. **Disk Space Issues**

    ```bash
        # Check available disk space
        df -h

        # Clean up Docker resources if needed
        docker system prune -a
    ```

### Container Creation Fails

**Symptoms:**

- One or more containers fail to start
- `docker-compose ps` shows containers in unhealthy state

**Solutions:**

1. **Inspect Error Messages**

    ```bash
        # View detailed container logs
        docker-compose logs [service_name]

        # Check container creation errors
        docker-compose ps -a
    ```

2. **Verify Environment Variables**

    ```bash
        # Make sure all required variables are set in .env
        grep -v '^#' .env | grep -v '^$'

        # Recreate containers with updated variables
        docker-compose down
        docker-compose up -d
    ```

3. **Rebuild Containers**

    ```bash
        # Force a clean rebuild
        docker-compose build --no-cache
        docker-compose up -d
    ```

### Network and Connectivity Problems

#### Services Can't Communicate

**Symptoms:**

- Applications can't connect to databases
- Inter-service communication fails
- Services can't resolve each other's names

**Solutions:**

1. **Verify Network Configuration**

    ```bash
        # List Docker networks
        docker network ls
        # Inspect network
        docker network inspect ${NETWORK_NAME}
        # Verify all services are on the same network
        docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' [container_id]
    ```

2. **Test Connectivity Within Network**

    ```bash
        # Access a running container
        docker exec -it ${TRAEFIK_CONTAINER_NAME} sh

        # Ping other services by container name
        ping mysql
        ping mongodb

        # Test specific ports
        nc -zv mysql 3306
    ```

3. **Recreate Network**

    ```bash
        docker-compose down
        docker network rm ${NETWORK_NAME}
        docker-compose up -d
    ```

#### Domain Resolution Issues

**Symptoms:**

- Cannot access services via domain names
- Browser shows "This site can't be reached"
- DNS resolution errors in logs

**Solutions:**

1. **Verify Local Domain Configuration**

    ```bash
        # Check `/etc/hosts` file

        cat /etc/hosts

        # Add required domains if needed

        sudo sh -c "echo '127.0.0.1 traefik.wilodev.localhost mail.wilodev.localhost' >> /etc/hosts"
    ```

2. **Flush DNS Cache**

    ```bash
        
        # macOS

        sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder

        # Linux (Ubuntu/Debian)

        sudo systemd-resolve --flush-caches

        # Windows (in Command Prompt as Administrator)

        ipconfig /flushdns --
    ```

3. **Test Domain Resolution**

    ```bash
        # Test DNS resolution

        nslookup traefik.wilodev.localhost

        # Try accessing with IP directly

        curl -H "Host: traefik.wilodev.localhost" <https://127.0.0.1>
    ```

## SSL Certificate Issues

### Certificate Errors in Browser

**Symptoms:**

- Browser shows "Your connection is not private" or "Invalid certificate"
- SSL errors in console or logs

**Solutions:**

1. **Verify Certificate Installation**

    ```bash
     
        # Check if certificate files exist

        ls -la traefik/config/certs/

        # Verify certificate matches domain

        openssl x509 -in traefik/config/certs/cert.pem -text -noout | grep DNS
    ```

2. **Reinstall mkcert Root CA**

    ```bash
        # Install mkcert root CA

        mkcert -install

        # Regenerate certificates

        cd traefik/config/certs
        mkcert -cert-file cert.pem -key-file key.pem "*.${DOMAIN_BASE}" "${DOMAIN_BASE}"
    ```

3. **Restart Traefik**

    ```bash
        docker-compose restart traefik
    ```

4. **Check Certificate Paths**

    ```bash
        # Verify SSL paths in .env

        cat .env | grep SSL_

        # Check Traefik certificate configuration

        docker-compose exec traefik cat /etc/traefik/dynamic.yml | grep certFile
    ```

## Service-Specific Problems

### Traefik Issues

**Symptoms:**

- Traefik dashboard not accessible
- Routing to services fails
- 404 errors for configured services

**Solutions:**

1. **Check Traefik Status**

    ```bash
        # View Traefik logs

        docker-compose logs traefik

        # Check Traefik configuration

        docker-compose exec traefik cat /etc/traefik/traefik.yml
    ```

2. **Verify Dashboard Access**

    ```bash
        # Test direct access

        curl -u ${TRAEFIK_DASHBOARD_USER}:${TRAEFIK_DASHBOARD_PASSWORD} https://${TRAEFIK_DOMAIN}

        # Check dashboard middleware configuration

        docker-compose exec traefik cat /etc/traefik/middleware.yml | grep -A10 ${AUTH_MIDDLEWARE_NAME}
    ```

3. **Debug Routing Issues**

    ```bash
        # Enable debug mode in traefik.yml

        # api

        # dashboard: true

        # debug: true

        # Restart Traefik and check logs

        docker-compose restart traefik
        docker-compose logs -f traefik
    ```

4. **Reset Traefik Configuration**

    ```bash
        # Backup current config
        cp -r traefik/config traefik/config.bak

        # Restore example configs
        cp traefik/config/traefik.example.yml traefik/config/traefik.yml
        cp traefik/config/dynamic.example.yml traefik/config/dynamic.yml
        cp traefik/config/middleware.example.yml traefik/config/middleware.yml

        # Restart Traefik
        docker-compose restart traefik
    ```

### MySQL Issues

**Symptoms:**

- MySQL container fails to start
- Connection timeouts or access denied errors
- Database consistency issues

**Solutions:**

1. **Check MySQL Status**

    ```bash
        # View MySQL logs

        docker-compose logs mysql

        # Check MySQL processes

        docker-compose exec mysql mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} processlist
    ```

2. **Fix Connection Issues**

    ```bash
        # Test MySQL connection

        docker-compose exec mysql mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} -e "SELECT 1;"

        # Verify user permissions

        docker-compose exec mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW GRANTS FOR '${MYSQL_USER}'@'%';"
    ```

3. **Repair Database**

    ```bash
        # Check and repair database

        docker-compose exec mysql mysqlcheck -u root -p${MYSQL_ROOT_PASSWORD} --auto-repair --check ${MYSQL_DATABASE}
    ```

4. **Reset MySQL Data (caution: data loss)**

    ```bash
        # Stop MySQL

        docker-compose stop mysql

        # Remove MySQL volume

        docker volume rm ${MYSQL_CONTAINER_NAME}-data

        # Restart MySQL (will recreate the database)

        docker-compose up -d mysql
    ```

### MongoDB Issues

**Symptoms:**

- MongoDB container fails to start
- Authentication issues
- Database access problems

**Solutions:**

1. **Check MongoDB Status**

    ```bash
        # View MongoDB logs

        docker-compose logs mongodb

        # Check MongoDB status

        docker-compose exec mongodb mongosh --eval "db.serverStatus()"
    ```

2. **Fix Authentication Issues**

    ```bash
        # Verify authentication setup

        docker-compose exec mongodb mongosh --eval "db.getUsers()"

        # Reset user password if needed

        docker-compose exec mongodb mongosh admin --eval "db.changeUserPassword('${MONGO_INITDB_ROOT_USERNAME}', '${MONGO_INITDB_ROOT_PASSWORD}')"
    ```

3. **Repair Database**

    ```bash
        # Repair MongoDB database

        docker-compose exec mongodb mongosh --eval "db.repairDatabase()"
    ```

4. **Reset MongoDB Data (caution: data loss)**

    ```bash
        # Stop MongoDB

        docker-compose stop mongodb

        # Remove MongoDB volume

        docker volume rm ${MONGO_CONTAINER_NAME}-data

        # Restart MongoDB (will recreate the database)

        docker-compose up -d mongodb
    ```

### MailHog Issues

**Symptoms:**

- MailHog UI not accessible
- Emails not captured
- SMTP connection issues

**Solutions:**

1. **Check MailHog Status**

    ```bash
        # View MailHog logs

        docker-compose logs mailhog

        # Test SMTP connection

        telnet ${MAILHOG_CONTAINER_NAME} 1025
    ```

2. **Verify MailHog Configuration**

    ```bash
        # Check MailHog labels in docker-compose.yml

        grep -A20 "mailhog:" docker-compose.yml

        # Test HTTP interface

        curl -I http://${MAILHOG_CONTAINER_NAME}:8025
    ```

3. **Reset MailHog**

    ```bash
        # Restart MailHog container

        docker-compose restart mailhog

        # If needed, recreate container

        docker-compose rm -f mailhog
        docker-compose up -d mailhog
    ```

4. **Test Email Sending**

    ```bash
        # Send a test email

        docker-compose exec app sh -c "echo 'Subject: Test Email\n\nThis is a test.' | sendmail <test@example.com>"

        # Or from a project container

        docker-compose -f projects/your-project/docker-compose.yml exec app php -r "mail('<test@example.com>', 'Test Email', 'This is a test');"
    ```

### Monitoring Stack Issues

**Symptoms:**

- Prometheus, Grafana, or Loki not working
- Missing metrics or logs
- Dashboard access problems

**Solutions:**

1. **Check Monitoring Services Status**

    ```bash
        # View service logs

        docker-compose logs prometheus
        docker-compose logs grafana
        docker-compose logs loki

        # Verify services are running

        docker-compose ps prometheus grafana loki promtail
    ```

2. **Fix Prometheus Issues**

    ```bash
        # Check Prometheus configuration

        docker-compose exec prometheus cat /etc/prometheus/prometheus.yml

        # Test Prometheus targets

        curl <http://prometheus:9090/api/v1/targets>

        # Restart Prometheus

        docker-compose restart prometheus
    ```

3. **Fix Grafana Issues**

    ```bash
        # Reset Grafana admin password

        docker-compose exec grafana grafana-cli admin reset-admin-password ${GRAFANA_ADMIN_PASSWORD}

        # Check data sources

        curl -u ${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD} <http://grafana:3000/api/datasources>

        # Restart Grafana

        docker-compose restart grafana
    ```

4. **Fix Loki Issues**

    ```bash
        # Verify Loki configuration
        docker-compose exec loki cat /etc/loki/config.yml

        # Check Loki status
        curl -s http://loki:3100/ready

        # Restart logging stack
        docker-compose restart loki promtail
    ```

## Project-Related Issues

### Project Creation Fails

**Symptoms:**

- `create-project.sh` script fails to create project
- Project directory structure incomplete or missing files
- Docker Compose for project fails to start

**Solutions:**

1. **Check Project Creation Logs**

    ```bash
        # Run with verbose output

        ./create-project.sh --verbose laravel myproject myapp

        # Check filesystem permissions

        ls -la projects/
    ```

2. **Verify Infrastructure Services**

    ```bash
        # Ensure base services are running

        docker-compose ps

        # Check databases are accessible

        docker-compose exec mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW DATABASES;"
    ```

3. **Manual Project Creation**

    ```bash
        # Create project directory

        mkdir -p projects/myproject
        cd projects/myproject

        # Initialize project manually (Laravel example)

        docker run --rm -v $(pwd):/app composer create-project laravel/laravel .

        # Copy example Docker files

        cp -r ../../examples/laravel/* .
    ```

### Project Container Issues

**Symptoms:**

- Project containers fail to start
- Web server not responding
- Application errors

**Solutions:**

1. **Check Project Container Logs**

    ```bash
        # View container logs

        cd projects/myproject
        docker-compose logs

        # Check container status

        docker-compose ps
    ```

2. **Verify Project Network Configuration**

    ```bash
        # Ensure containers are on the correct network

        docker network inspect ${NETWORK_NAME}

        # Check .env.docker file for correct connection strings

        cat .env.docker
    ```

3. **Rebuild Project Containers**

    ```bash
        # Force rebuild

        docker-compose build --no-cache
        docker-compose up -d
    ```

4. **Fix Web Server Issues**

    ```bash
        # Check Nginx/Apache configuration

        docker-compose exec webserver cat /etc/nginx/conf.d/default.conf

        # Test web server directly

        curl -I <http://localhost:$(docker-compose> port webserver 80 | cut -d: -f2)
    ```

### Database Connection Issues

**Symptoms:**

- Application cannot connect to database
- "Connection refused" or "Access denied" errors

**Solutions:**

1. **Verify Database Credentials**

    ```bash
        # Check .env file settings

        grep DB_ .env

        # Test connection from app container

        docker-compose exec app sh -c "mysql -h ${MYSQL_HOST} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} -e 'SHOW DATABASES;'"
    ```

2. **Check Database Network Access**

    ```bash
        # Verify database hostname

        docker-compose exec app ping mysql

        # Test database port

        docker-compose exec app nc -zv mysql 3306
    ```

3. **Update Connection Settings**

    ```bash
        # For Laravel, update .env

        docker-compose exec app sed -i 's/DB_HOST=.*/DB_HOST=mysql/' .env

        # Clear config cache (Laravel)

        docker-compose exec app php artisan config:clear
    ```

## Performance Optimization

### Slow Container Performance

**Symptoms:**

- Slow application response times
- High resource usage
- Container health checks failing

**Solutions:**

1. **Monitor Container Resources**

    ```bash
        # Check resource usage

        docker stats

        # Identify high CPU/memory containers

        docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
    ```

2. **Optimize Database Queries**

    ```bash
        # Enable slow query log (MySQL)

        docker-compose exec mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SET GLOBAL slow_query_log = 'ON'; SET GLOBAL long_query_time = 1;"

        # Check slow queries

        docker-compose exec mysql tail -f /var/log/mysql/mysql-slow.log
    ```

3. **Adjust Container Resources**

    ```yaml
        # Update docker-compose.yml to add resource limits
        # services:
        #   mysql:
        #     mem_limit: 1g
        #     cpus: 1
    ```

4. **Optimize PHP Configuration**

    ```bash
        # Increase PHP memory limit

        docker-compose exec app sed -i 's/memory_limit = .*/memory_limit = 256M/' /usr/local/etc/php/php.ini

        # Enable OPcache for production

        docker-compose exec app sed -i 's/;opcache.enable=.*/opcache.enable=1/' /usr/local/etc/php/php.ini
    ```

### Network Latency Issues

**Symptoms:**

- Slow inter-service communication
- Timeouts between containers

**Solutions:**

1. **Measure Network Performance**

    ```bash
        # Install network tools

        docker-compose exec app apt-get update && apt-get install -y iputils-ping iperf3

        # Test network performance

        docker-compose exec app ping -c 10 mysql
    ```

2. **Optimize Traefik Configuration**

    ```yaml
        # Update middleware.yml to add buffering

        # buffer

        # maxRequestBodyBytes: 10485760  # 10MB

        # memRequestBodyBytes: 2097152   # 2MB
    ```

### Diagnostic Tools

#### Essential Docker Commands

```bash
# View container logs

docker-compose logs [service]

# View real-time logs

docker-compose logs -f [service]

# Check container health

docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Enter container shell

docker-compose exec [service] bash  # or sh for Alpine containers

# View container configuration

docker inspect [container_id]

# Check network connections

docker network inspect ${NETWORK_NAME}
```

#### Database Diagnostic Commands

```bash
# MySQL health check

docker-compose exec mysql mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} status

# MySQL process list

docker-compose exec mysql mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} processlist

# MongoDB status

docker-compose exec mongodb mongosh --eval "db.serverStatus()"

# MongoDB database stats

docker-compose exec mongodb mongosh --eval "db.stats()"

```

#### Web Server Diagnostics

```bash
# Test Nginx configuration

docker-compose exec webserver nginx -t

# View access logs

docker-compose exec webserver tail -f /var/log/nginx/access.log

# View error logs

docker-compose exec webserver tail -f /var/log/nginx/error.log
```

### Recovery and Backup

#### Creating Backups

```bash
# Backup MySQL database

docker-compose exec -T mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE} > backup-$(date +%F).sql

# Backup MongoDB database

docker-compose exec -T mongodb mongodump --username ${MONGO_INITDB_ROOT_USERNAME} --password ${MONGO_INITDB_ROOT_PASSWORD} --db ${MONGO_INITDB_DATABASE} --archive > mongodb-backup-$(date +%F).archive

# Backup Docker volumes

docker run --rm -v ${MYSQL_CONTAINER_NAME}-data:/source -v $(pwd)/backups:/backup alpine tar -czf /backup/mysql-data-$(date +%F).tar.gz -C /source .
```

#### Restoring Backups

```bash
# Restore MySQL database

cat backup.sql | docker-compose exec -T mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE}

# Restore MongoDB database

cat mongodb-backup.archive | docker-compose exec -T mongodb mongorestore --username ${MONGO_INITDB_ROOT_USERNAME} --password ${MONGO_INITDB_ROOT_PASSWORD} --archive

# Restore Docker volume (caution: stop service first)

docker-compose stop mysql
docker run --rm -v ${MYSQL_CONTAINER_NAME}-data:/target -v $(pwd)/backups:/backup alpine sh -c "rm -rf /target/* && tar -xzf /backup/mysql-data.tar.gz -C /target"
docker-compose start mysql
```

#### Emergency Reset

If you need a complete reset of your WiloDev Dock environment:

```bash
# Stop all containers

docker-compose down

# Remove all volumes (CAUTION: DATA LOSS)

docker volume rm $(docker volume ls -q | grep wilodev)

# Clean Docker system

docker system prune -a

# Re-run setup

./setup.sh
```

### Additional Tips

#### Regular System Checks

To avoid issues, perform regular checks of the system:

```bash
# Health check script

# !/bin/bash

echo "Verificando servicios principales..."
docker-compose ps | grep "Up"
echo "Verificando uso de disco..."
df -h
echo "Verificando uso de memoria de contenedores..."
docker stats --no-stream
```

#### Update Optimization

When updating WiloDev Dock or its components:

- Always perform a full backup before
- Update one service at a time
- Check compatibility between versions
- Always check the logs after each update
- Maintain a separate test environment to validate important updates

#### Troubleshooting for Teams

For teams sharing the same environment:

- Establish a problem reporting process
- Document all configuration changes
- Maintain a record of resolved issues
- Implement regular configuration reviews
- Normalize configuration across the team

## Recommended Additional Tools

- Portainer: For visual container management
- ctop: For real-time monitoring of container resources
- Lazydocker: TUI interface to manage Docker
- Docker Compose UI: Web interface to manage Compose services

## Conclusion

This troubleshooting guide provides a systematic approach to diagnosing and resolving most problems you may encounter with WiloDev Dock. Remember that problem solving is both an art and a science - experience and methodical analysis are key to solving problems efficiently.

For persistent or complex issues, feel free to open an issue in the GitHub repository or contribute solutions you've discovered to enrich the documentation for the entire community.
