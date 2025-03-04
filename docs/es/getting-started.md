# Primeros Pasos con WiloDev Dock

## Introducción

WiloDev Dock es un entorno de desarrollo completo en contenedores diseñado para optimizar tu flujo de trabajo de desarrollo web. Esta guía te llevará paso a paso a través de la configuración y uso del entorno por primera vez.

## Requisitos del Sistema

Antes de comenzar, asegúrate de que tu sistema cumpla los siguientes requisitos:

- Docker Engine 20.10 o superior
- Docker Compose 2.0 o superior
- Al menos 5GB de espacio libre en disco
- Mínimo 4GB de RAM (se recomiendan 8GB para rendimiento óptimo)
- Navegador web moderno (Chrome, Firefox, Edge, o Safari)
- Acceso a terminal

## Requisitos Opcionales

Las siguientes herramientas no son estrictamente necesarias, pero pueden mejorar tu experiencia:

- **Git** para control de versiones
- **mkcert** para certificados SSL locales (instalado automáticamente por el script de configuración si falta)
- Utilidad **htpasswd** (parte de los paquetes apache2-utils/httpd-tools)

## Instalación

### Paso 1: Clonar el Repositorio

Comienza clonando el repositorio de WiloDev Dock en tu máquina local:

```bash
git clone https://github.com/wilodev/wilodev-dock.git
cd wilodev-dock
```

### Paso 2: Crear Configuración de Entorno

Copia el archivo de entorno de ejemplo y personalízalo según tus necesidades:

```bash
cp .env.example .env
```

Abre el archivo `.env` en tu editor de texto preferido y ajusta las siguientes configuraciones clave:

- **DOMAIN_BASE**: El dominio base para todos los servicios (predeterminado: wilodev.localhost)
- **NETWORK_NAME**:  Nombre de la red Docker (predeterminado: wilodev_network)
- **TRAEFIK_DASHBOARD_USER** and **TRAEFIK_DASHBOARD_PASSWORD**:Credenciales para el panel de Traefik
- Detalles de conexión a bases de datos **(MYSQL_ROOT_PASSWORD, MONGO_INITDB_ROOT_USERNAME, etc.)**

### Paso 3: Ejecutar el Script de Configuración

Ejecuta el script de configuración para configurar tu entorno:

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

Este script:

- Verificará tu sistema en busca del software necesario
- Creará los directorios necesarios
- Configurará certificados SSL para el desarrollo local
- Creará redes y volúmenes de Docker
- Iniciará todos los servicios de infraestructura
- Verificará que todo se esté ejecutando correctamente

El proceso generalmente toma entre 2 y 5 minutos, dependiendo de tu conexión a internet y el rendimiento del sistema.

## Primeros Pasos Después de la Instalación

Una vez que la instalación se complete con éxito, tendrás acceso a los siguientes servicios:

### Accediendo al Panel de Traefik

El panel de Traefik proporciona una visión general de tus servicios y configuración de enrutamiento:

- **URL**: <https://traefik.wilodev.localhos> (o tu TRAEFIK_DOMAIN configurado)
- **Credenciales**:  El nombre de usuario y contraseña que estableciste en el archivo `.env`

### Explorando los Servicios Disponibles

WiloDev Dock viene con varios servicios preconfigurados:

| Service | Purpose | Default URL |
|---------|---------|-------------|
| **Traefik** | Reverse Proxy & SSL | https://{TRAEFIK_DOMAIN} |
| **MySQL** | Relational Database | localhost:{MYSQL_PORT} |
| **MongoDB** | NoSQL Database | localhost:{MONGO_PORT}|
| **MailHog** | Email Testing | https://{MAILHOG_DOMAIN} |
| **Prometheus** | Metrics Collection |    <https://prometheus.{DOMAIN_BASE}> |
| **Grafana** | Metrics Visualization | <https://grafana.{DOMAIN_BASE}> |
| **Loki** | Log Aggregation | (Internal) |

### Conexión a Bases de Datos

Puedes conectarte a las bases de datos utilizando tu cliente de base de datos preferido:

#### MySQL

- **Host**: localhost
- **Port**: 3306 (o como se configura en .env)
- **Username**: Como se define en MYSQL_USER
- **Password**: Como se define en MYSQL_PASSWORD
- **Database**: Como se define en MYSQL_DATABASE

#### MongoDB

- **Host**: localhost
- **Port**: 27017 (o según lo configurado en .env)
- **Username**: Como se define en MONGO_INITDB_ROOT_USERNAME
- **Password**: Como se define en MONGO_INITDB_ROOT_PASSWORD
- **Database**: Como se define en MONGO_INITDB_DATABASE

### Probando la Funcionalidad de Correo Electrónico

MailHog captura todos los correos electrónicos salientes de tus aplicaciones. Para probarlo:

1. Configura tu aplicación para usar SMTP con:

   - **Host**:mailhog (o localhost)
   - **Port**: 1025 (o según lo configurado en .env)
   - **No se requiere autenticación**

2. Accede a la interfaz web de MailHog en <https://mail.wilodev.localhost> para ver los correos capturados

### Creando Tu Primer Proyecto

WiloDev Dock admite diferentes tipos de proyectos, principalmente enfocados en frameworks Laravel y Symfony.

#### Usando el Script de Creación de Proyectos

Para crear un nuevo proyecto:

##### Linux/Mac

```bash
./create-project.sh
```

##### Windows

```powershell
.\create-project.ps1
```

Este script interactivo:

- Preguntará por el tipo de proyecto (Laravel o Symfony)
- Solicitará el nombre del proyecto y dominio
- Configurará contenedores Docker apropiados para el framework seleccionado
- Configurará Nginx y PHP
- Inicializará el proyecto con el framework seleccionado
- Configurará conexiones a bases de datos

#### Configuración Manual de Proyectos

Si prefieres configurar manualmente un proyecto:

1. Crea un directorio en la carpeta `projects/`
2. Copia los archivos de plantilla apropiados de:
   - Directorio laravel/ para proyectos Laravel
   - Directorio symfony/ para proyectos Symfony
3. Ajusta los archivos Docker Compose y de configuración según sea necesario
4. Inicia los contenedores de tu proyecto

### Entendiendo la Arquitectura

WiloDev Dock utiliza una arquitectura en capas:

- Capa Traefik: Maneja todo el tráfico HTTP/HTTPS, enruta solicitudes y gestiona SSL
- Capa de Servicio: Contiene tus contenedores de aplicación (PHP, Node.js, etc.)
- Capa de Datos: Proporciona servicios de bases de datos (MySQL, MongoDB)
- Capa de Utilidad: Servicios adicionales como MailHog para pruebas
- Capa de Observabilidad: Monitoreo con Prometheus, Grafana y Loki

### Configuración SSL/HTTPS

Todo el tráfico externo es gestionado por Traefik a través de HTTPS (puerto 443):

- Certificados autogenerados creados por `mkcert` proporcionan SSL confiable localmente
- Traefik maneja la terminación SSL
- Los servicios internos se comunican vía HTTP en la red Docker
- Las configuraciones específicas para cada framework aseguran que tus aplicaciones detecten correctamente HTTPS

### Comandos Básicos

#### Iniciar y Detener Servicios

Para iniciar todos los servicios:

```bash
docker compose up -d
```

Para detener todos los servicios:

```bash
docker compose down
```

Para reiniciar un servicio específico:

```bash
docker compose restart <service_name>
```

#### Ver los Registros

Para ver los registros de todos los servicios:

```bash
docker-compose logs
```

Para un servicio específico:

```bash
docker-compose logs [service-name]
```

Para seguir los registros en tiempo real:

```bash
docker-compose logs -f [service-name]
```

### Pasos Siguientes

Ahora que tienes WiloDev Dock en funcionamiento, puedes:

- [Crear un nuevo proyecto](./creating-projects.es.md) para tu trabajo de desarrollo
- Explora la [referencia de configuración](./configuration.es.md) para ajustes avanzados
- Consulta la [guía de solución de problemas](./troubleshooting.es.md) si encuentras problemas
- Aprende sobre [optimización de rendimiento](./performance.es.md) para una experiencia de desarrollo óptima
