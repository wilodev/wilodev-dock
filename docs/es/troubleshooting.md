# Guía de Solución de Problemas para WiloDev Dock

## Introducción

Esta completa guía de solución de problemas te ayuda a diagnosticar y resolver problemas comunes con WiloDev Dock. Ya seas un desarrollador junior nuevo en entornos containerizados o un ingeniero senior con experiencia, encontrarás soluciones detalladas para una amplia gama de problemas.

## Tabla de Contenidos

- [Guía de Solución de Problemas para WiloDev Dock](#guía-de-solución-de-problemas-para-wilodev-dock)
  - [Introducción](#introducción)
  - [Tabla de Contenidos](#tabla-de-contenidos)
  - [Metodología](#metodología)
  - [Problemas de Instalación](#problemas-de-instalación)
    - [El Script de Configuración Falla](#el-script-de-configuración-falla)
    - [Falla en la Creación de Contenedores](#falla-en-la-creación-de-contenedores)
    - [Problemas de Network y Conexión](#problemas-de-network-y-conexión)
      - [Problemas de Comunicación entre Servicios](#problemas-de-comunicación-entre-servicios)
      - [Problemas de Resolución de Dominio](#problemas-de-resolución-de-dominio)
  - [Problemas con Certificados SSL](#problemas-con-certificados-ssl)
    - [Errores de Certificados en el Navegador](#errores-de-certificados-en-el-navegador)
  - [Problemas Específicos de Servicios](#problemas-específicos-de-servicios)
    - [Problemas con Traefik](#problemas-con-traefik)
    - [Problemas con MySQL](#problemas-con-mysql)
    - [Problemas con MongoDB](#problemas-con-mongodb)
    - [Problemas con MailHog](#problemas-con-mailhog)
      - [Problemas con Stack de Monitoreo](#problemas-con-stack-de-monitoreo)
  - [Problemas Relacionados con Proyectos](#problemas-relacionados-con-proyectos)
    - [Falla en la Creación de Proyectos](#falla-en-la-creación-de-proyectos)
    - [Problemas con Contenedores de Proyectos](#problemas-con-contenedores-de-proyectos)
    - [Problemas de Conexión a la Base de Datos](#problemas-de-conexión-a-la-base-de-datos)
  - [Optimización de Rendimiento](#optimización-de-rendimiento)
    - [Rendimiento Lento de Contenedores](#rendimiento-lento-de-contenedores)
    - [Problemas de Latencia de Red](#problemas-de-latencia-de-red)
    - [Herramientas de Diagnóstico](#herramientas-de-diagnóstico)
      - [Comandos Esenciales de Docker](#comandos-esenciales-de-docker)
      - [Comandos de Diagnóstico de Base de Datos](#comandos-de-diagnóstico-de-base-de-datos)
      - [Diagnósticos del Servidor Web](#diagnósticos-del-servidor-web)
    - [Recuperación y Respaldo](#recuperación-y-respaldo)
      - [Creación de Respaldos](#creación-de-respaldos)
      - [Restauración de Respaldos](#restauración-de-respaldos)
      - [Restablecimiento de Emergencia](#restablecimiento-de-emergencia)
    - [Consejos Adicionales](#consejos-adicionales)
      - [Verificación Proactiva del Sistema](#verificación-proactiva-del-sistema)
      - [Optimización de Actualizaciones](#optimización-de-actualizaciones)
      - [Solución de Problemas para Equipos](#solución-de-problemas-para-equipos)
  - [Herramientas Recomendadas Adicionales](#herramientas-recomendadas-adicionales)
  - [Conclusión](#conclusión)

## Metodología

Cuando solucionas problemas con WiloDev Dock, sigue este enfoque estructurado:

1. **Identificar el problema**: Determina exactamente qué no funciona como se esperaba
2. **Revisar los registros**: Los registros de los contenedores son tu primera fuente de información
3. **Verificar la configuración**: Asegúrate de que tus ajustes sean correctos
4. **Aislar el problema**: Determina si el problema está en la infraestructura o en tu aplicación
5. **Aplicar la solución**: Sigue los pasos específicos para tu problema
6. **Verificar la resolución**: Confirma que el problema ha sido resuelto
7. **Documenta las lecciones aprendidas**: Haz notas para evitar problemas similares en el futuro

## Problemas de Instalación

### El Script de Configuración Falla

**Síntomas:**

- El script `setup.sh` sale con un error
- Algunos contenedores no pueden iniciar

**Soluciones:**

1. **Problemas de Permisos**

    ```bash
        # Asegúrate de que el script sea ejecutable
        chmod +x setup.sh

        # Asegúrate de no ejecutarlo como root
        # Ejecuta como usuario normal, no con sudo
        ./setup.sh
    ```

2. **Docker No Está Ejecutándose*

    ```bash
        # Verifica el estado de Docker
        systemctl status docker

        # Inicia Docker si es necesario
        sudo systemctl start docker
    ```

3. **Conflictos de Puertos**

    ```bash
        # Verifica si los puertos 80/443 ya están en uso
        sudo lsof -i :80
        sudo lsof -i :443

        # Cambia los puertos en el archivo .env si es necesario
        # TRAEFIK_HTTP_PORT=8080
        # TRAEFIK_HTTPS_PORT=8443
    ```

4. **Problemas de Espacio en Disco**

    ```bash
        # Verifica el espacio disponible en disco
        df -h

        # Limpia los recursos de Docker si es necesario
        docker system prune -a
    ```

### Falla en la Creación de Contenedores

**Síntomas:**

- Uno o más contenedores no pueden iniciar
- `docker-compose ps` muestra contenedores en estado no saludable

**Soluciones:**

1. **Inspeccionar Mensajes de Error**

    ```bash
        # Ver los registros detallados del contenedor
        docker-compose logs [nombre_servicio]

        # Comprobar errores de creación de contenedores
        docker-compose ps -a
    ```

2. **Verifica Variables de Entorno**

    ```bash
        # Asegúrate de que todas las variables requeridas estén configuradas en .env
        grep -v '^#' .env | grep -v '^$'

        # Recrea contenedores con variables actualizadas
        docker-compose down
        docker-compose up -d
    ```

3. **Reconstruye Contenedores**

    ```bash
        # Fuerza una reconstrucción limpia
        docker-compose build --no-cache
        docker-compose up -d
    ```

### Problemas de Network y Conexión

#### Problemas de Comunicación entre Servicios

**Síntomas:**

- Aplicaciones no pueden conectarse a las bases de datos
- La comunicación entre servicios falla
- Los servicios no pueden resolver los nombres de los demás

**Soluciones:**

1. **Verifica la Configuración de Red**

    ```bash
        # Lista las redes de Docker
        docker network ls
        # Inspecciona la red
        docker network inspect ${NETWORK_NAME}
        # Verifica que todos los servicios estén en la misma red
        docker inspect -f '{{range $k, $v := .NetworkSettings.Networks}}{{$k}}{{end}}' [container_id]
    ```

2. **Prueba la Conexión Dentro de la Red**

    ```bash
        # Accede a un contenedor en ejecución
        docker exec -it ${TRAEFIK_CONTAINER_NAME} sh

        # Prueba la conexión a otros servicios por nombre de contenedor
        ping mysql
        ping mongodb

        # Prueba puertos específicos
        nc -zv mysql 3306
    ```

3. **Recrea la Red**

    ```bash
        docker-compose down
        docker network rm ${NETWORK_NAME}
        docker-compose up -d
    ```

#### Problemas de Resolución de Dominio

**Síntomas:**

- No se puede acceder a los servicios a través de los nombres de dominio
- El navegador muestra "Este sitio no está disponible" o "Certificado no válido"
- Errores de resolución de DNS en los registros

**Soluciones:**

1. **Verifica la Configuración Local de Dominio**

    ```bash
        # Verifica el archivo `/etc/hosts`

        cat /etc/hosts

        # Agrega los dominios requeridos si es necesario

        sudo sh -c "echo '127.0.0.1 traefik.wilodev.localhost mail.wilodev.localhost' >> /etc/hosts"
    ```

2. **Vaciar el Cache DNS**

    ```bash
        
        # macOS

        sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder

        # Linux (Ubuntu/Debian)

        sudo systemd-resolve --flush-caches

        # Windows (in Command Prompt como Administrador)

        ipconfig /flushdns --
    ```

3. **Prueba la Resolución de Dominios**

    ```bash
        # Prueba la resolución DNS

        nslookup traefik.wilodev.localhost

        # Intenta acceder directamente con IP

        curl -H "Host: traefik.wilodev.localhost" <https://127.0.0.1>
    ```

## Problemas con Certificados SSL

### Errores de Certificados en el Navegador

**Síntomas:**

- El navegador muestra "Your connection is not private" o "Invalid certificate"
- Errores de SSL en la consola o registros

**Soluciones:**

1. **Verifica la Instalación de Certificados**

    ```bash
        # Verifica si los archivos de certificado existen
        ls -la traefik/config/certs/

        # Verifica que el certificado coincida con el dominio
        openssl x509  -in traefik/config/certs/cert.pem -text -noout | grep DNS
    ```

2. **Reinstala la CA Raíz de mkcert**

    ```bash
        # Instala la CA raíz de mkcert
        mkcert -install

        # Regenera certificados
        cd traefik/config/certs
        mkcert -cert-file cert.pem -key-file key.pem "*.${DOMAIN_BASE}" "${DOMAIN_BASE}"
    ```

3. **Reinicia Traefik**

    ```bash
        docker-compose restart traefik
    ```

4. **Verifica las Rutas de los Certificados**

    ```bash
        # Verifica las rutas SSL en .env
        cat .env | grep SSL_

        # Verifica la configuración de certificados en Traefik
        docker-compose exec traefik cat /etc/traefik/dynamic.yml | grep certFile
    ```

## Problemas Específicos de Servicios

### Problemas con Traefik

**Síntomas:**

- El panel de control de Traefik no es accesible
- La ruta a los servicios falla
- Errores 404 para los servicios configurados

**Soluciones:**

1. **Verifica el Estado de Traefik**

    ```bash
        # View Traefik logs
        docker-compose logs traefik

        # Check Traefik configuration
        docker-compose exec traefik cat /etc/traefik/traefik.yml
    ```

2. **Verifica el Acceso al Panel**

    ```bash
        # Prueba acceso directo
        curl -u ${TRAEFIK_DASHBOARD_USER}:${TRAEFIK_DASHBOARD_PASSWORD} https://${TRAEFIK_DOMAIN}

        # Verifica la configuración del middleware del panel
        docker-compose exec traefik cat /etc/traefik/middleware.yml | grep -A10 ${AUTH_MIDDLEWARE_NAME}
    ```

3. **Depura Problemas de Enrutamiento**

    ```bash
        # Habilita el modo debug en traefik.yml
        # api:
        #   dashboard: true
        #   debug: true

        # Reinicia Traefik y verifica logs
        docker-compose restart traefik
        docker-compose logs -f traefik
        docker-compose logs -f traefik
    ```

4. **Restablece la Configuración de Traefik**

    ```bash
        # Respalda la configuración actual
        cp -r traefik/config traefik/config.bak

        # Restaura configuraciones de ejemplo
        cp traefik/config/traefik.example.yml traefik/config/traefik.yml
        cp traefik/config/dynamic.example.yml traefik/config/dynamic.yml
        cp traefik/config/middleware.example.yml traefik/config/middleware.yml

        # Reinicia Traefik
        docker-compose restart traefik
    ```

### Problemas con MySQL

**Síntomas:**

- El contenedor de MySQL no puede iniciar
- Tiempos de conexión o errores de acceso denegado
- Problemas de consistencia de la base de datos

**Soluciones:**

1. **Verifica el Estado de MySQL**

    ```bash
        # Ver logs de MySQL
        docker-compose logs mysql

        # Verifica procesos de MySQL
        docker-compose exec mysql mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} processlist
    ```

2. **Soluciona Problemas de Conexión**

    ```bash
        # Prueba la conexión a MySQL
        docker-compose exec mysql mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD} -e "SELECT 1;"

        # Verifica permisos de usuario
        docker-compose exec mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW GRANTS FOR '${MYSQL_USER}'@'%';"
    ```

3. **Repara la Base de Datos**

    ```bash
        # Verifica y repara la base de datos
        docker-compose exec mysql mysqlcheck -u root -p${MYSQL_ROOT_PASSWORD} --auto-repair --check ${MYSQL_DATABASE}
    ```

4. **Restablece los Datos de MySQL (precaución: pérdida de datos)**

    ```bash
        # Detiene MySQL
        docker-compose stop mysql

        # Elimina el volumen de MySQL
        docker volume rm ${MYSQL_CONTAINER_NAME}-data

        # Reinicia MySQL (recreará la base de datos)
        docker-compose up -d mysql
    ```

### Problemas con MongoDB

**Síntomas:**

- El contenedor de MongoDB no puede iniciar
- Problemas de autenticación
- Problemas de acceso a la base de datos

**Soluciones:**

1. **Verifica el Estado de MongoDB**

    ```bash
        # Ver logs de MongoDB
        docker-compose logs mongodb

        # Verifica el estado de MongoDB
        docker-compose exec mongodb mongosh --eval "db.serverStatus()"
    ```

2. **Soluciona Problemas de Autenticación**

    ```bash
        # Verifica la configuración de autenticación
        docker-compose exec mongodb mongosh --eval "db.getUsers()"

        # Restablece la contraseña de usuario si es necesario
        docker-compose exec mongodb mongosh admin --eval "db.changeUserPassword('${MONGO_INITDB_ROOT_USERNAME}', '${MONGO_INITDB_ROOT_PASSWORD}')"
    ```

3. **Repara la Base de Datos**

    ```bash
        #Repara la base de datos MongoDB
        docker-compose exec mongodb mongosh --eval "db.repairDatabase()"
    ```

4. **Restablece los Datos de MongoDB (precaución: pérdida de datos)**

    ```bash
        # Detiene MongoDB
        docker-compose stop mongodb

        # Elimina el volumen de MongoDB
        docker volume rm ${MONGO_CONTAINER_NAME}-data

        # Reinicia MongoDB (recreará la base de datos)
        docker-compose up -d mongodb
    ```

### Problemas con MailHog

**Síntomas:**

- La interfaz de usuario de MailHog no es accesible
- Los correos electrónicos no son capturados
- Problemas de conexión SMTP

**Soluciones:**

1. **Verifica el Estado de MailHog**

    ```bash
        # Ver logs de MailHog
        docker-compose logs mailhog

        # Prueba la conexión SMTP
        telnet mailhog 1025
    ```

2. **Verifica la Configuración de MailHog**

    ```bash
        # Verifica las etiquetas de MailHog en docker-compose.yml
        grep -A20 "mailhog:" docker-compose.yml
    
        # Prueba la interfaz HTTP
        curl -I http://${MAILHOG_CONTAINER_NAME}:8025
    ```

3. **Restablece MailHog**

    ```bash
        # Reinicia el contenedor de MailHog
        docker-compose restart mailhog

        # Si es necesario, recrea el contenedor
        docker-compose rm -f mailhog
        docker-compose up -d mailhog
    ```

4. **Prueba el Envío de Correo Electrónico**

    ```bash
        # Envía un correo de prueba
        docker-compose exec app sh -c "echo 'Subject: Correo de Prueba\n\nEste es una prueba.' | sendmail test@example.com"

        # O desde un contenedor de proyecto
        docker-compose -f projects/your-project/docker-compose.yml exec app php -r "mail('<test@example.com>', 'Test Email', 'This is a test');"
    ```

#### Problemas con Stack de Monitoreo

**Síntomas:**

- Prometheus, Grafana o Loki no funcionan
- Métricas o registros faltantes
- Problemas de acceso al panel

**Soluciones:**

1. **Verifica el Estado de los Servicios de Monitoreo**

    ```bash
        # Ver logs de los servicios
        docker-compose logs prometheus
        docker-compose logs grafana
        docker-compose logs loki

        # Verifica que los servicios estén ejecutándose
        docker-compose ps prometheus grafana loki promtail
    ```

2. **Soluciona Problemas de Prometheus**

    ```bash
        # Verifica la configuración de Prometheus
        docker-compose exec prometheus cat /etc/prometheus/prometheus.yml

        # Prueba los objetivos de Prometheus
        curl http://prometheus:9090/api/v1/targets

        # Reinicia Prometheus
        docker-compose restart prometheus
    ```

3. **Soluciona Problemas de Grafana**

    ```bash
        # Restablece la contraseña de administrador de Grafana
        docker-compose exec grafana grafana-cli admin reset-admin-password ${GRAFANA_ADMIN_PASSWORD}

        # Verifica las fuentes de datos
        curl -u ${GRAFANA_ADMIN_USER}:${GRAFANA_ADMIN_PASSWORD} http://grafana:3000/api/datasources

        # Reinicia Grafana
        docker-compose restart grafana
    ```

4. **Soluciona Problemas de Loki**

    ```bash
        # Verifica la configuración de Loki
        docker-compose exec loki cat /etc/loki/config.yml

        # Verifica el estado de Loki
        curl -s http://loki:3100/ready

        # Reinicia el stack de logging
        docker-compose restart loki promtail
    ```

## Problemas Relacionados con Proyectos

### Falla en la Creación de Proyectos

**Síntomas:**

- El script `create-project.sh` falla al crear el proyecto
- La estructura de directorios del proyecto está incompleta o faltan archivos
- El Docker Compose para el proyecto falla al iniciar

**Soluciones:**

1. **Verifica los Registros de Creación de Proyectos**

    ```bash
        # Ejecuta con salida detallada
        ./create-project.sh --verbose laravel miproyecto miapp

        # Verifica permisos del sistema de archivos
        ls -la projects/
    ```

2. **Verifica los Servicios de Infraestructura**

    ```bash
        # Ensure base services are running

        docker-compose ps

        # Check databases are accessible

        docker-compose exec mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SHOW DATABASES;"
    ```

3. **Creación Manual del Proyecto**

    ```bash
        ## Crea el directorio del proyecto
        mkdir -p projects/miproyecto
        cd projects/miproyecto

        # Inicializa el proyecto manualmente (ejemplo Laravel)
        docker run --rm -v $(pwd):/app composer create-project laravel/laravel .

        # Copia archivos Docker de ejemplo
        cp -r ../../examples/laravel/* .
    ```

### Problemas con Contenedores de Proyectos

**Síntomas:**

- Los contenedores del proyecto fallan al iniciar
- El servidor web no responde
- Errores en la aplicación

**Soluciones:**

1. **Verifica los Registros de Contenedores de Proyecto**

    ```bash
        # Ver logs de contenedores
        cd projects/miproyecto
        docker-compose logs

        # Verifica el estado del contenedor
        docker-compose ps
    ```

2. **Verifica la Configuración de Red del Proyecto**

    ```bash
        # Asegúrate de que los contenedores estén en la red correcta
        docker network inspect ${NETWORK_NAME}

        # Verifica el archivo .env.docker para conexiones correctas
        cat .env.docker
    ```

3. **Reconstruye los Contenedores del Proyecto**

    ```bash
        # Fuerza la reconstrucción
        docker-compose build --no-cache
        docker-compose up -d
    ```

4. **Soluciona Problemas del Servidor Web**

    ```bash
        # Verifica la configuración de Nginx/Apache
        docker-compose exec webserver cat /etc/nginx/conf.d/default.conf

        # Prueba el servidor web directamente
        curl -I http://localhost:$(docker-compose port webserver 80 | cut -d: -f2)
    ```

### Problemas de Conexión a la Base de Datos

**Síntomas:**

- La aplicación no puede conectarse a la base de datos
- Errores "Connection refused" o "Access denied" en los registros

**Soluciones:**

1. **Verifica las Credenciales de la Base de Datos**

    ```bash
        # Verifica las configuraciones en el archivo .env
        grep DB_ .env
        # Prueba la conexión desde el contenedor de la aplicación
        docker-compose exec app sh -c "mysql -h ${MYSQL_HOST} -u ${MYSQL_USER} -p${MYSQL_PASSWORD} -e 'SHOW DATABASES;'"
    ```

2. **Verifica el Acceso a la Red de la Base de Datos**

    ```bash
        # Verifica el nombre de host de la base de datos
        docker-compose exec app ping mysql

        # Prueba el puerto de la base de datos
        docker-compose exec app nc -zv mysql 3306
    ```

3. **Actualiza la Configuración de Conexión**

    ```bash
        # Para Laravel, actualiza .env
        docker-compose exec app sed -i 's/DB_HOST=.*/DB_HOST=mysql/' .env

        # Borra el cache de configuración (Laravel)
        docker-compose exec app php artisan config:clear
    ```

## Optimización de Rendimiento

### Rendimiento Lento de Contenedores

**Síntomas:**

- Respuestas lentas de la aplicación
- Alto uso de recursos (CPU, memoria)
- Fallas en las comprobaciones de estado de los contenedores

**Soluciones:**

1. **Monitorea los Recursos de Contenedores*

    ```bash
        # Comprueba el uso de recursos
        docker stats
        # Identifica contenedores con alto uso de CPU/memoria
        docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}"
    ```

2. **Optimiza las Consultas a la Base de Datos**

    ```bash
        # Habilita el registro de consultas lentas (MySQL)
        docker-compose exec mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} -e "SET GLOBAL slow_query_log = 'ON'; SET GLOBAL long_query_time = 1;"

        # Comprueba las consultas lentas
        docker-compose exec mysql tail -f /var/log/mysql/mysql-slow.log
    ```

3. **Ajusta los Recursos de Contenedores**

    ```yaml
        # Update docker-compose.yml to add resource limits
        # services:
        #   mysql:
        #     mem_limit: 1g
        #     cpus: 1
    ```

4. **Optimiza la Configuración de PHP**

    ```bash
        # Aumenta el límite de memoria de PHP
        docker-compose exec app sed -i 's/memory_limit = .*/memory_limit = 256M/' /usr/local/etc/php/php.ini
        # Habilita OPcache para producción
        docker-compose exec app sed -i 's/;opcache.enable=.*/opcache.enable=1/' /usr/local/etc/php/php.ini
    ```

### Problemas de Latencia de Red

**Síntomas:**

- Comunicación lenta entre servicios
- Tiempos de espera entre contenedores

**Soluciones:**

1. **Mide el Rendimiento de la Red**

    ```bash
        # Instala herramientas de red
        docker-compose exec app apt-get update && apt-get install -y iputils-ping iperf3
        # Prueba el rendimiento de la red
        docker-compose exec app ping -c 10 mysql
    ```

2. **Optimize Traefik Configuration**

    ```yaml
        # Actualiza middleware.yml para añadir buffer
        # buffer:
        #   maxRequestBodyBytes: 10485760  # 10MB
        #   memRequestBodyBytes: 2097152   # 2MB
    ```

### Herramientas de Diagnóstico

#### Comandos Esenciales de Docker

```bash
# Ver logs de contenedores
docker-compose logs [servicio]

# Ver logs en tiempo real
docker-compose logs -f [servicio]

# Verifica la salud del contenedor
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# Accede a la shell del contenedor
docker-compose exec [servicio] bash  # o sh para contenedores Alpine

# Ver la configuración del contenedor
docker inspect [id_contenedor]

# Verifica conexiones de red
docker network inspect ${NETWORK_NAME}
```

#### Comandos de Diagnóstico de Base de Datos

```bash
# Verificación de salud de MySQL
docker-compose exec mysql mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} status

# Lista de procesos MySQL
docker-compose exec mysql mysqladmin -u root -p${MYSQL_ROOT_PASSWORD} processlist

# Estado de MongoDB
docker-compose exec mongodb mongosh --eval "db.serverStatus()"

# Estadísticas de base de datos MongoDB
docker-compose exec mongodb mongosh --eval "db.stats()"

```

#### Diagnósticos del Servidor Web

```bash
# Prueba la configuración de Nginx
docker-compose exec webserver nginx -t

# Ver logs de acceso
docker-compose exec webserver tail -f /var/log/nginx/access.log

# Ver logs de error
docker-compose exec webserver tail -f /var/log/nginx/error.log
```

### Recuperación y Respaldo

#### Creación de Respaldos

```bash
# Respaldar base de datos MySQL
docker-compose exec -T mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE} > backup-$(date +%F).sql

# Respaldar base de datos MongoDB
docker-compose exec -T mongodb mongodump --username ${MONGO_INITDB_ROOT_USERNAME} --password ${MONGO_INITDB_ROOT_PASSWORD} --db ${MONGO_INITDB_DATABASE} --archive > mongodb-backup-$(date +%F).archive

# Respaldar volúmenes Docker
docker run --rm -v ${MYSQL_CONTAINER_NAME}-data:/source -v $(pwd)/backups:/backup alpine tar -czf /backup/mysql-data-$(date +%F).tar.gz -C /source .
```

#### Restauración de Respaldos

```bash
# Restaurar base de datos MySQL
cat backup.sql | docker-compose exec -T mysql mysql -u root -p${MYSQL_ROOT_PASSWORD} ${MYSQL_DATABASE}

# Restaurar base de datos MongoDB
cat mongodb-backup.archive | docker-compose exec -T mongodb mongorestore --username ${MONGO_INITDB_ROOT_USERNAME} --password ${MONGO_INITDB_ROOT_PASSWORD} --archive

# Restaurar volumen Docker (precaución: detén el servicio primero)
docker-compose stop mysql
docker run --rm -v ${MYSQL_CONTAINER_NAME}-data:/target -v $(pwd)/backups:/backup alpine sh -c "rm -rf /target/* && tar -xzf /backup/mysql-data.tar.gz -C /target"
docker-compose start mysql
```

#### Restablecimiento de Emergencia

Si necesitas un restablecimiento completo de tu entorno WiloDev Dock:

```bash
# Detener todos los contenedores
docker-compose down

# Eliminar todos los volúmenes (PRECAUCIÓN: PÉRDIDA DE DATOS)
docker volume rm $(docker volume ls -q | grep wilodev)

# Limpiar el sistema Docker
docker system prune -a

# Volver a ejecutar la configuración
./setup.sh
```

### Consejos Adicionales

#### Verificación Proactiva del Sistema

Para evitar problemas, realiza verificaciones regulares del sistema:

```bash
# Script de verificación de salud
#!/bin/bash
echo "Verificando servicios principales..."
docker-compose ps | grep "Up"
echo "Verificando uso de disco..."
df -h
echo "Verificando uso de memoria de contenedores..."
docker stats --no-stream
```

#### Optimización de Actualizaciones

Cuando actualices WiloDev Dock o sus componentes:

- Realiza siempre una copia de seguridad completa antes de cualquier actualización
- Actualiza un servicio a la vez
- Comprueba la compatibilidad entre versiones
- Siempre revisa los registros después de cada actualización
- Mantén un entorno de prueba separado para validar actualizaciones importantes

#### Solución de Problemas para Equipos

Para equipos que comparten el mismo entorno:

- Establece un proceso de informes de problemas
- Documenta todos los cambios de configuración
- Mantén un registro de problemas resueltos
- Implementa revisiones regulares de configuración
- Normaliza la configuración en el equipo

## Herramientas Recomendadas Adicionales

- Portainer: Para la gestión visual de contenedores
- ctop: Para la monitorización en tiempo real de recursos de contenedores
- Lazydocker: Interfaz TUI para gestionar Docker
- Docker Compose UI: Interfaz web para gestionar servicios de Compose

## Conclusión

Esta guía de solución de problemas proporciona un enfoque sistemático para diagnosticar y resolver la mayoría de los problemas que puedes encontrar con WiloDev Dock. Recuerda que la solución de problemas es tanto un arte como una ciencia - la experiencia y el análisis metódico son clave para resolverlos eficientemente.

Para problemas persistentes o complejos, no dudes en abrir un issue en el repositorio de GitHub o contribuir con soluciones que hayas descubierto para enriquecer la documentación para toda la comunidad.
