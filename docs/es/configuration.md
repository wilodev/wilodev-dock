# Referencia de Configuración de WiloDev Dock

## Descripción General

Este documento proporciona una guía completa para configurar WiloDev Dock, explicando todas las configuraciones disponibles, variables de entorno y opciones de personalización. Ya sea que necesites ajustar la configuración de bases de datos, modificar el comportamiento del proxy o personalizar soluciones de monitoreo, encontrarás instrucciones detalladas aquí.

## Tabla de Contenidos

- [Variables de Entorno](#variables-de-entorno)
- [Configuración de Traefik](#configuración-de-traefik)
- [Configuración de Bases de Datos](#configuración-de-bases-de-datos)
- [Configuración SSL/HTTPS](#configuración-sslhttps)
- [Configuración de Middleware](#configuración-de-middleware)
- [Configuración de Monitoreo](#configuración-de-monitoreo)
- [Configuración de Red Personalizada](#configuración-de-red-personalizada)
- [Personalización Avanzada](#personalización-avanzada)

## Variables de Entorno

El archivo `.env` es el archivo de configuración central para WiloDev Dock. Aquí hay un desglose de todas las variables disponibles:

### Configuración Base (.env)

```bash
# Dominio base para todos los servicios (ej., 'miapp.localhost')
DOMAIN_BASE=wilodev.localhost

# Nombre de la red Docker
NETWORK_NAME=wilodev_network
```

### Nombres de Contenedores (.env)

```bash
# Nombres para todos los contenedores de servicios - cámbialos si necesitas múltiples instalaciones
TRAEFIK_CONTAINER_NAME=wilodev-traefik
MYSQL_CONTAINER_NAME=wilodev-mysql
MONGO_CONTAINER_NAME=wilodev-mongo
MAILHOG_CONTAINER_NAME=wilodev-mailhog
PROMETHEUS_CONTAINER_NAME=wilodev-prometheus
GRAFANA_CONTAINER_NAME=wilodev-grafana
LOKI_CONTAINER_NAME=wilodev-loki
PROMTAIL_CONTAINER_NAME=wilodev-promtail
```

### Subdominios de Servicios (.env)

```bash
# Subdominios para varios servicios
TRAEFIK_SUBDOMAIN=traefik
MAILHOG_SUBDOMAIN=mail
```

### Versiones de Servicios (.env)

```bash
# Versiones de software - actualiza según sea necesario, pero ten en cuenta posibles problemas de compatibilidad
PHP_VERSION=8.3
MYSQL_VERSION=8.0
MONGO_VERSION=7.0
NODE_VERSION=20
TRAEFIK_VERSION=v3.3.4
PROMETHEUS_VERSION=v2.45.0
GRAFANA_VERSION=10.1.0
LOKI_VERSION=2.9.0
PROMTAIL_VERSION=2.9.0
```

### Puertos de Servicios (.env)

```bash
# Puertos para acceso externo - cámbialos si tienes conflictos de puertos
TRAEFIK_HTTP_PORT=80
TRAEFIK_HTTPS_PORT=443
MYSQL_PORT=3306
MONGO_PORT=27017
MAILHOG_SMTP_PORT=1025
MAILHOG_HTTP_PORT=8025
```

### Configuración de MySQL (.env)

```bash
# Credenciales de MySQL y nombre de base de datos
MYSQL_ROOT_PASSWORD=rootpassword
MYSQL_DATABASE=app
MYSQL_USER=appuser
MYSQL_PASSWORD=apppassword
```

### Configuración de MongoDB (.env)

```bash
# Credenciales de MongoDB y nombre de base de datos
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD=rootpassword
MONGO_INITDB_DATABASE=app
```

### Configuración de Traefik (.env)

```bash
# Credenciales del panel de Traefik
TRAEFIK_DASHBOARD_USER=admin
TRAEFIK_DASHBOARD_PASSWORD=admin123
TRAEFIK_DASHBOARD_AUTH=admin:$apr1$xyz...123  # Generado por setup.sh

# Rutas de certificados SSL
SSL_CERT_PATH=./traefik/config/certs/cert.pem
SSL_KEY_PATH=./traefik/config/certs/key.pem

# Configuración del panel
TRAEFIK_DASHBOARD_ENABLED=true
TRAEFIK_API_INSECURE=false
TRAEFIK_LOG_LEVEL=INFO
TRAEFIK_ACCESS_LOG_ENABLED=true
TRAEFIK_DASHBOARD_ROUTER_NAME=traefik-dashboard

# SSL
TRAEFIK_ACME_EMAIL=admin@example.com
TRAEFIK_SSL_RESOLVER=mkcert
```

### Configuración de Middleware (.env)

```bash
# Nombres de middleware - cámbialos solo si necesitas evitar conflictos de nombres
AUTH_MIDDLEWARE_NAME=auth-basic
COMPRESS_MIDDLEWARE_NAME=compress
SECURITY_HEADERS_MIDDLEWARE_NAME=secure-headers
RATE_LIMIT_MIDDLEWARE_NAME=rate-limit
HTTPS_REDIRECT_MIDDLEWARE_NAME=https-redirect
CORS_MIDDLEWARE_NAME=cors
PATH_REWRITE_MIDDLEWARE_NAME=path-rewrite
TIMEOUT_MIDDLEWARE_NAME=timeout

# Configuración de seguridad
AUTH_REALM=Secured Area
HSTS_SECONDS=31536000
HSTS_INCLUDE_SUBDOMAINS=true
HSTS_PRELOAD=true
FRAME_OPTIONS_VALUE=SAMEORIGIN
XSS_FILTER=true
REFERRER_POLICY=strict-origin-when-cross-origin
FEATURE_POLICY=camera 'none'; microphone 'none'; geolocation 'none'
PERMISSIONS_POLICY=camera=(), microphone=(), geolocation=()

# Configuración HTTPS
HTTPS_REDIRECT_PERMANENT=true
HTTPS_PORT=443

# Configuración de límite de tasa
RATE_LIMIT_AVERAGE=100
RATE_LIMIT_PERIOD=1s
RATE_LIMIT_BURST=50

# Configuración CORS
CORS_ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS
CORS_ALLOWED_HEADERS=Content-Type,Authorization,X-Requested-With
CORS_MAX_AGE=600
CORS_ALLOW_CREDENTIALS=true
ADDITIONAL_ALLOWED_ORIGINS=https://app.example.com

# Reescritura de ruta
STRIP_PREFIX_PATH=/api

# Configuración del servicio de autenticación
AUTH_SERVICE_HOST=auth-service
AUTH_SERVICE_PORT=8080
```

### Configuración de Red Personalizada (.env)

```bash
# IPs confiables (separadas por coma) para acceso de administrador
TRAEFIK_TRUSTED_IPS=127.0.0.1/32,10.0.0.0/8
```

### Configuración de Monitoreo (.env)

```bash
# Habilitar/deshabilitar servicios de monitoreo
PROMETHEUS_ENABLED=true
GRAFANA_ENABLED=true
LOKI_ENABLED=true

# Credenciales de administrador de Grafana
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin123
```

## Configuración de Traefik

Traefik es el proxy inverso principal utilizado en WiloDev Dock, que maneja todo el tráfico HTTP/HTTPS, enrutamiento y terminación SSL.

### Archivo de Configuración Principal

El archivo de configuración principal de Traefik se encuentra en `traefik/config/traefik.yml`. Los ajustes clave incluyen:

- `api`: Controla el panel de Traefik
- `entryPoints`: Define puntos de entrada HTTP y HTTPS
- `providers`: Configura cómo Traefik descubre servicios
- `certificatesResolvers`: Configura el manejo de certificados SSL
- `log`: Controla el comportamiento de registro

Ejemplo de personalizaciones:

```yaml
# Habilitar modo de depuración para solución de problemas
api:
  dashboard: true
  debug: true

# Cambiar el puerto HTTP
entryPoints:
  web:
    address: ":8080"
    
# Ajustar nivel de log para mayor verbosidad
log:
  level: DEBUG
```

### Configuración Dinámica

El archivo de configuración dinámica en `traefik/config/dynamic.yml` contiene configuraciones que se pueden actualizar sin reiniciar Traefik:

- `tls`: Configuración TLS/SSL y certificados
- `http.routers`: Reglas de enrutamiento específicas
- `http.services`: Definiciones de servicios backend

Ejemplo de personalizaciones:

```yaml
# Agregar un nuevo servicio
http:
  services:
    mi-api-personalizada:
      loadBalancer:
        servers:
          - url: "http://mi-contenedor-api:8080"
```

### Configuración de Middleware Traefik

El archivo de configuración de middleware en `traefik/config/middleware.yml` define todos los componentes de middleware:

- Autenticación
- Compresión
- Cabeceras de seguridad
- Límite de tasa
- CORS
- Reescritura de ruta

Ejemplo de personalizaciones:

```yaml
# Agregar un middleware personalizado
http:
  middlewares:
    mi-middleware-personalizado:
      headers:
        customResponseHeaders:
          X-Cabecera-Personalizada: "Valor Personalizado"
```

## Configuración de Bases de Datos

### Configuración de MySQL

La configuración de MySQL se puede personalizar de dos maneras:

1. **Variables de Entorno**: Establece valores en `.env` para configuración básica
2. **Archivo de Configuración Personalizado**: Edita `mysql/config/my.cnf` para configuraciones avanzadas

Optimizaciones comunes de MySQL:

```ini
[mysqld]
# Aumentar tamaño del pool de buffer para mejor rendimiento
innodb_buffer_pool_size = 256M

# Mejorar rendimiento de escritura
innodb_flush_log_at_trx_commit = 2

# Configuración de caché de consultas
query_cache_size = 32M
query_cache_limit = 2M
```

### Configuración de MongoDB

La configuración de MongoDB se puede personalizar en:

1. **Variables de Entorno**: Establece valores en `.env` para configuración básica
2. **Archivo de Configuración Personalizado**: Edita `mongo/config/mongod.conf` para configuraciones avanzadas

Optimizaciones comunes de MongoDB:

```yaml
storage:
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1
systemLog:
  verbosity: 0
```

## Configuración SSL/HTTPS

WiloDev Dock utiliza certificados SSL localmente confiables generados con `mkcert`. La configuración ocurre automáticamente durante la configuración inicial.

### Rutas de Certificados SSL

```bash
SSL_CERT_PATH=./traefik/config/certs/cert.pem
SSL_KEY_PATH=./traefik/config/certs/key.pem
```

### Regeneración de Certificados

Si necesitas regenerar certificados o agregar dominios adicionales:

```bash
cd traefik/config/certs
mkcert -cert-file cert.pem -key-file key.pem "*.wilodev.localhost" "wilodev.localhost" "dominio-adicional.localhost"
```

### Configuración TLS Avanzada

La configuración TLS avanzada se puede personalizar en `traefik/config/dynamic.yml`:

```yaml
tls:
  options:
    default:
      minVersion: "ТLS1.3"
      sniStrict: true
      cipherSuites:
        - "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
        - "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
```

## Configuración de Middleware

Los middlewares de Traefik se pueden personalizar en `traefik/config/middleware.yml`. Algunos middlewares clave incluyen:

### Cabeceras de Seguridad

```yaml
secureHeaders:
  headers:
    forceSTSHeader: true
    stsSeconds: 31536000
    stsIncludeSubdomains: true
    contentSecurityPolicy: "default-src 'self'"
```

### Límite de Tasa

```yaml
rateLimit:
  rateLimit:
    average: 100
    period: 1s
    burst: 50
```

### CORS

```yaml
cors:
headers:
  accessControlAllowMethods:
    - "GET"
    - "POST"
    - "PUT"
    - "DELETE"
    - "OPTIONS"
  accessControlAllowOriginList:
    - "https://*.example.com"
  accessControlMaxAge: 600
  accessControlAllowCredentials: true
```

### Configuración de Monitoreo

WiloDev Dock incluye un stack completo de monitoreo con Prometheus, Grafana y Loki.

### Configuración de Prometheus

El archivo de configuración de Prometheus está en `prometheus/prometheus.yml`. Los ajustes clave incluyen:

- `scrape_interval`: Con qué frecuencia recopilar métricas
- `scrape_configs`:  Qué objetivos monitorear

Ejemplo de personalización:

```yaml
global:
  scrape_interval: 30s  # Recopilar métricas cada 30 segundos

scrape_configs:
  - job_name: 'mi-app-personalizada'
    static_configs:
      - targets: ['mi-app:9090']

```

### Configuración de Grafana

Grafana se configura a través de variables de entorno y archivos de aprovisionamiento en `grafana/provisioning/`:

- `datasources`: Configura fuentes de datos como Prometheus y Loki
- `dashboards`: Configura dashboards preconfigurados

Puedes añadir dashboards personalizados colocando archivos JSON en `grafana/provisioning/dashboards/`.

### Configuración de Loki

Loki se configura en `loki/config.yml`. Puedes ajustar:

- `retention_period`: Cuánto tiempo mantener los logs
- `chunk_size`: Ajuste de rendimiento para almacenamiento de logs

### Configuración de Red Personalizada

La red Docker se define en el archivo `docker-compose.yml`:

```yaml
networks:
${NETWORK_NAME}:
  name: ${NETWORK_NAME}
  driver: bridge
```

Para personalizar la configuración de red:

1. Edita el archivo `.env` para cambiar `NETWORK_NAME`
2. Añade configuración de subred si es necesario:

```yaml
networks:
${NETWORK_NAME}:
  name: ${NETWORK_NAME}
  driver: bridge
  ipam:
    config:
      - subnet: 172.28.0.0/16
```

### Personalización Avanzada

#### Añadir Servicios Personalizados

Para añadir un servicio personalizado a WiloDev Dock:

1. Añade el servicio a `docker-compose.yml`:

   ```yaml
    mi-servicio-personalizado:
      container_name: mi-servicio-personalizado
      image: mi-imagen-personalizada:latest
      restart: unless-stopped
      networks:
        - ${NETWORK_NAME}
      volumes:
        - ./mis-datos-personalizados:/var/data
      labels:
        - "traefik.enable=true"
        - "traefik.http.routers.mi-servicio.rule=Host(`mi-servicio.${DOMAIN_BASE}`)"
        - "traefik.http.routers.mi-servicio.entrypoints=websecure"
        - "traefik.http.routers.mi-servicio.tls=true"
        - "traefik.http.services.mi-servicio.loadbalancer.server.port=8080"
   ```

2. Actualiza `.env` con cualquier variable de entorno requerida
3. Inicia el servicio: `docker-compose up -d mi-servicio-personalizado`

#### Personalización de Logging de Docker

Puedes personalizar el logging de Docker para todos los servicios añadiendo:

```yaml
logging:
  driver: "json-file"
  options:
    max-size: "10m"
    max-file: "3"
```

#### Optimización de Almacenamiento Persistente

Para mejor rendimiento o gestión de datos:

```yaml
volumes:
mysql_data:
  name: ${MYSQL_CONTAINER_NAME}-data
  driver: local
  driver_opts:
    type: none
    o: bind
    device: /ruta/a/almacenamiento/personalizado
```

## Solución de Problemas de Configuración

### Problemas Comunes de Configuración

#### Problemas con Certificados SSL

Si encuentras errores de certificados SSL:

1. Asegúrate de que mkcert está instalado correctamente:

   ```bash
   mkcert -install
   ```

2. Regenerate certificates:

   ```bash
   cd traefik/config/certs
   mkcert -cert-file cert.pem -key-file key.pem "*.${DOMAIN_BASE}" "${DOMAIN_BASE}"
   ```

3. Verifica que las rutas de certificados en  `.env` coincidan con los archivos reales
4. Reinicia Traefik:

   ```bash
   docker-compose restart traefik
   ```

#### Problemas de Conectividad de Red

Si los servicios no pueden comunicarse:

1. Verifica que todos los servicios estén en la misma red:

   ```bash
   docker network inspect ${NETWORK_NAME}
   ```

2. Comprueba si hay configuraciones de red superpuestas
3. Intenta recrear la red:

   ```bash
   docker-compose down
   docker network rm ${NETWORK_NAME}
   docker-compose up -d
   ```

#### Problemas de Conexión a Bases de Datos

Si los proyectos no pueden conectarse a las bases de datos:

1. Verifica las credenciales de la base de datos en `.env`
2. Comprueba si los contenedores de bases de datos están funcionando:
  
   ```bash
   docker-compose ps mysql mongodb
   ```

3. Prueba la conexión directamente:

   ```bash
   docker exec -it ${MYSQL_CONTAINER_NAME} mysql -u ${MYSQL_USER} -p${MYSQL_PASSWORD}
   ```

#### Problemas de Rendimiento

Si experimentas lentitud en el entorno:

1. Monitorea el uso de recursos:

    ```bash
    docker stats
    ```

2. Ajusta los límites de memoria en `docker-compose.yml`:
  
    ```yaml
      services:
        mysql:
          mem_limit: 512m
    ```

3. Optimiza la configuración de bases de datos como se describió anteriormente
4. Considera deshabilitar servicios que no necesites:

    ```bash
    docker-compose stop prometheus grafana loki promtail
    ```

#### Problemas con el Panel de Traefik

Si no puedes acceder al panel de Traefik:

1. Verifica que Traefik esté funcionando:

    ```bash
    docker-compose ps traefik
    ```

2. Comprueba las credenciales en `.env`:
  
    ```yaml
      services:
        mysql:
          mem_limit: 512m
    ```

3. Verifica que el middleware de autenticación esté configurado correctamente
4. Comprueba los logs de Traefik:

    ```bash
    docker-compose logs traefik
    ```

### Recursos Adicionales

- [Documentación oficial de traefik](https://doc.traefik.io/traefik/)
- [Documentación de Docker Compose](https://docs.docker.com/compose/)
- [Documentación de MySQL](https://docs.mysql.com/)
- [Documentación de MongoDB](https://docs.mongodb.com/)
- [Documentación de Prometheus](https://prometheus.io/docs/introduction/overview/)
- [Documentación de Grafana](https://grafana.com/docs/grafana/latest/)
- [Documentación de Loki](https://grafana.com/docs/loki/latest/)

### Conclusión

Esta guía de configuración te proporciona una referencia completa para personalizar y optimizar tu entorno WiloDev Dock. Desde ajustes básicos hasta configuraciones avanzadas, ahora tienes las herramientas necesarias para adaptar el entorno a tus necesidades específicas de desarrollo.

Recuerda que la mayoría de los cambios de configuración requieren reiniciar los servicios afectados o, en algunos casos, reiniciar todo el entorno para aplicar correctamente todas las configuraciones.
