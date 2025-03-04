# Creación de Proyectos con WiloDev Dock

## Introducción

Esta guía explica cómo crear nuevos proyectos de desarrollo utilizando el entorno WiloDev Dock. Ya sea que estés construyendo una aplicación Laravel o Symfony, el script `create-project.sh` simplifica la inicialización del proyecto configurando automáticamente contenedores, servidores web y conexiones a bases de datos.

## Requisitos Previos

Antes de crear tu primer proyecto, asegúrate de que:

1. Has completado la [Guía de Inicio](./getting-started.md)
2. La infraestructura de WiloDev Dock está funcionando (`docker-compose ps` muestra Traefik, MySQL, MongoDB, etc.)
3. Has generado certificados SSL durante la configuración (requeridos para HTTPS)
4. Tienes conocimientos básicos del framework que planeas utilizar (Laravel o Symfony)

## Uso Básico

El script de creación de proyectos proporciona una forma interactiva de configurar nuevos proyectos:

Para crear un nuevo proyecto:

### Linux/Mac

```bash
./create-project.sh
```

### Windows

```powershell
.\create-project.ps1
```

```bash
./create-project.sh <framework> <nombre-proyecto> <subdominio>
```

## Parámetros

- **framework**: Tipo de proyecto a crear  (`laravel` or `symfony`)
- **project-name**: ombre para tu proyecto (solo caracteres alfanuméricos, guiones y guiones bajos)
- **subdomain**: Subdominio donde será accesible tu proyecto  (ej., `miapp` resulta en `miapp.wilodev.localhost`)

```bash
Example:
./create-project.sh laravel mi-blog blog
```

Esto crea un proyecto Laravel llamado "mi-blog" accesible en`https://blog.wilodev.localhost`

## Guía Paso a Paso

Vamos a crear un proyecto desde el principio hasta el final:

1. Navegando hasta el directorio de WiloDev Dock

   > Primero, asegúrate de estar en el directorio de WiloDev Dock:

   ```bash
      cd wilodev-dock
   ```

2. Ejecutar el script de creación

   Vamos a crear una aplicación Laravel:

   ```bash
      ./create-project.sh laravel app-tareas tareas
   ```

   El script:

   - Validará tus entradas
   - Creará los directorios necesarios
   - Descargará Laravel/Symfony a través de Composer
   - Configurará Nginx y PHP
   - Creará archivos Docker Compose
   - Configurará el acceso a la base de datos

3. Entendiendo la salida

   Durante la ejecución, verás una salida detallada como:

   ```bash
      [2023-07-15 14:30:25] INFO: 🐳 WiloDev Dock - Creador de Proyectos
      [2023-07-15 14:30:25] INFO: ========================================
      [2023-07-15 14:30:25] INFO: Verificando dependencias...
      [2023-07-15 14:30:26] SUCCESS: Todas las dependencias están correctamente instaladas.
      [2023-07-15 14:30:26] INFO: Validando tipo de proyecto: laravel
      [2023-07-15 14:30:26] SUCCESS: Tipo de proyecto válido: laravel
      [2023-07-15 14:30:26] INFO: Validando nombre del proyecto: app-tareas
      [2023-07-15 14:30:26] SUCCESS: Nombre de proyecto válido: app-tareas
      [2023-07-15 14:30:26] INFO: Validando subdominio: tareas
      [2023-07-15 14:30:26] SUCCESS: Subdominio válido: tareas
      [2023-07-15 14:30:26] INFO: Creando proyecto Laravel: app-tareas
      ...
   ```

   Espera a que el script complete su ejecución. Esto puede tomar algunos minutos.

4. Iniciando tu nuevo proyecto

   Una vez que el script ha completado su ejecución, navega hasta el directorio de tu proyecto y comienza los contenedores:

   ```bash
      cd projects/todo-app
      docker-compose up -d
   ```

5. Accediendo a tu aplicación

   Tu aplicación ahora está disponible en:

   ```bash
      [https://tareas.wilodev.localhost](https://tareas.wilodev.localhost)
   ```

¡Visita esta URL en tu navegador para ver tu nueva aplicación Laravel!

### Tipos de Proyectos en Detalle

#### Proyectos Laravel

Cuando creas un proyecto Laravel, obtienes:

- Contenedor PHP-FPM con una versión de PHP configurable
- Nginx configurado con optimizaciones específicas de Laravel
- Base de datos MySQL configurada automáticamente
- Redis para la caché y las colas (opcional)
- Variables de entorno de Laravel pre-configuradas
- Worker de colas para procesamiento en segundo plano (opcional)

**Estructura del Proyecto Laravel:**

```bash
projects/nombre-de-tu-proyecto/
├── .env                    # Variables de entorno de Laravel
├── .env.docker            # Variables de entorno específicas de Docker
├── Dockerfile             # Configuración del contenedor PHP
├── app/                   # Código de la aplicación Laravel
├── docker/
│   ├── nginx/             # Configuración de Nginx
│   ├── supervisor/        # Configuración del worker de colas
│   └── php.ini            # Configuración de PHP
├── docker-compose.yml     # Definición de servicios Docker
└── ...                    # Otros archivos y directorios de Laravel
```

#### Proyectos Symfony

Cuando creas un proyecto Symfony, obtienes:

- Contenedor PHP-FPM con extensiones optimizadas para Symfony
- Nginx configurado con reglas de enrutamiento específicas de Symfony
- Base de datos MySQL configurada automáticamente
- Redis para la caché y las sesiones (opcional)
- Variables de entorno de Symfony pre-configuradas
- Servicio Messenger para procesamiento asincrónico (opcional)

**Symfony Project Structure:**

```bash
projects/nombre-de-tu-proyecto/
├── .env                    # Variables de entorno de Symfony
├── .env.docker            # Variables de entorno específicas de Docker
├── Dockerfile             # Configuración del contenedor PHP
├── bin/                   # Consola y binarios de Symfony
├── config/                # Configuración de Symfony
├── docker/
│   ├── nginx/             # Configuración de Nginx
│   └── php.ini            # Configuración de PHP
├── docker-compose.yml     # Definición de servicios Docker
├── public/                # Archivos accesibles vía web
├── src/                   # Código de la aplicación Symfony
└── ...                    # Otros archivos y directorios de Symfony
```

### Personalizando Tu Proyecto

#### Modificando la Configuración de Docker

Puedes personalizar la configuración de Docker editando el archivo `docker-compose.yml` en el directorio de tu proyecto:

```bash
cd projects/nombre-de-tu-proyecto
nano docker-compose.yml
```

Personalizaciones comunes incluyen:

- Cambiando la versión de PHP
- Agregando Node.js para activos frontend
- Configurando límites de memoria
- Agregando servicios adicionales

Después de hacer cambios, aplícalos con:

```bash
docker-compose down
docker-compose up -d
```

#### Personalizando la Configuración de Nginx

Para modificar cómo Nginx maneja tus solicitudes web:

```bash
cd projects/nombre-de-tu-proyecto
nano docker/nginx/default.conf
```

**Personalizaciones comunes de Nginx para Laravel:**

- Ajustando los tiempos de espera de las solicitudes
- Redirigiendo URLs específicas
- Habilitando o deshabilitando la caché
- Configurando páginas de error personalizadas

Después de los cambios, reinicia el contenedor web:

```bash
docker-compose restart webserver
```

#### Personalizando la Configuración de PHP

Para ajustar la configuración de PHP:

```bash
cd projects/your-project-name
nano docker/php.ini
```

**Personalizaciones comunes de PHP:**

- Límites de memoria
- Tamaños de carga de archivos
- Tiempos de ejecución
- Configuración de OPCache

Reinicia PHP después de los cambios:

```bash
docker-compose restart app
```

### Trabajando con Bases de Datos

#### Conectando a MySQL

Tu proyecto está automáticamente configurado para conectarse a MySQL. Detalles de la base de datos:

- **Host**: mysql (dentro de Docker) o localhost (desde la máquina host)
- **Port**: 3306 (puerto por defecto de MySQL)
- **Database**: El mismo nombre que tu proyecto
- **Username**: De tu archivo `.env` (valor de `MYSQL_USER`)
- **Password**: De tu archivo `.env` (valor de `MYSQL_PASSWORD`)

Desde la máquina host, puedes conectarte usando herramientas como MySQL Workbench, DBeaver, o la línea de comandos:

```bash
mysql -h localhost -P 3306 -u your_user -p your_project_name
```

#### Conectando a MongoDB

Si tu proyecto utiliza MongoDB:

- **Host**: mongodb (dentro de Docker) o localhost (desde la máquina host)
- **Port**: 27017 (puerto por defecto de MongoDB)
- **Database**: De tu archivo `.env` (valor de `MONGO_INITDB_DATABASE`)
- **Username**: De tu archivo `.env` (valor de `MONGO_INITDB_ROOT_USERNAME`)
- **Password**: De tu archivo `.env` (valor de `MONGO_INITDB_ROOT_PASSWORD`)

Conecta usando MongoDB Compass o la línea de comandos:

```bash
mongosh mongodb://username:password@localhost:27017/your_database
```

### Entendiendo cómo funciona HTTPS

Todos los proyectos creados con el script están automáticamente configurados con HTTPS a través de Traefik:

1. **Acceso Externo**: Los usuarios se conectan a <https://yoursubdomain.wilodev.localhost>
   - Traefik: Maneja el término SSL/TLS utilizando certificados locales
   - Comunicación Interna: Traefik reenvía las solicitudes a tu contenedor Nginx a través de HTTP
2. **Aplicación**: Tu framework detecta correctamente HTTPS a través de encabezados especiales

No es necesario configurar SSL adicionalmente en el nivel del proyecto.

### Solución de Problemas

#### Problemas Comunes

##### Fallo en la creación del proyecto

Si el script de creación del proyecto falla:

1. Asegúrate de que Docker esté en funcionamiento
2. Comprueba el espacio en disco (se recomienda al menos 1GB libre por proyecto)
3. Verifica que los contenedores MySQL y MongoDB estén en funcionamiento
4. Comprueba los permisos en el directorio de proyectos

#### No se puede acceder al proyecto en el navegador

Si no puedes acceder a tu proyecto en la URL esperada:

1. Verifica que los contenedores del proyecto estén en funcionamiento (`docker-compose ps`)
2. Comprueba los errores en los registros de Nginx (`docker-compose logs webserver`)
3. Asegúrate de que Traefik esté en funcionamiento (`docker ps | grep traefik`)
4. Intenta borrar la caché de tu navegador o usar modo incógnito
5. Comprueba el archivo `/etc/hosts` o la configuración DNS para una resolución de dominio correcta

#### Problemas con la base de datos

Si tu aplicación no puede conectarse a la base de datos:

1. Verifica que el contenedor de la base de datos esté en funcionamiento (`docker-compose ps`)
2. Comprueba las credenciales de la base de datos en los archivos `.env`
3. Asegúrate de que la base de datos exista (`docker exec -it wilodev-mysql mysql -u root -p`)
4. Comprueba la conectividad de red entre contenedores

### Ejemplos

#### Creando una API Básica de Laravel

```bash
# Crear el proyecto
./create-project.sh laravel proyecto-api api

# Iniciar los contenedores
cd projects/proyecto-api
docker-compose up -d

# Instalar Laravel Sanctum para autenticación API
docker-compose exec app composer require laravel/sanctum
docker-compose exec app php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
docker-compose exec app php artisan migrate

# Tu API está disponible en https://api.wilodev.localhost
```

#### Creando un Sitio Web con Symfony

```bash
## Crear el proyecto
./create-project.sh symfony sitio-web web

# Iniciar los contenedores
cd projects/sitio-web
docker-compose up -d

# Instalar paquetes de Symfony
docker-compose exec app composer require symfony/orm-pack
docker-compose exec app composer require --dev symfony/maker-bundle
docker-compose exec app php bin/console doctrine:database:create

# Tu sitio web está disponible en https://web.wilodev.localhost
```

### Preguntas Frecuentes

**¿Puedo crear varios proyectos?**

¡Sí! Puedes crear tantos proyectos como necesites. Cada uno tendrá su propio directorio, contenedores y subdominio.

**¿Cómo accedo a la línea de comandos del contenedor?**

Usa el comando `docker-compose exec`:

```bash
cd projects/nombre-de-tu-proyecto
docker-compose exec app bash
```

Esto te dará un shell bash dentro del contenedor PHP.

#### ¿Cómo ejecuto comandos de Artisan o Symfony console?

**Para Laravel:**

```bash
cd projects/tu-proyecto-laravel
docker-compose exec app php artisan migrate
```

**Para Symfony:**

```bash
cd projects/tu-proyecto-symfony
docker-compose exec app php bin/console cache:clear
```

#### ¿Cómo instalo paquetes adicionales?

Usa Composer dentro de tu contenedor:

```bash
cd projects/nombre-de-tu-proyecto
docker-compose exec app composer require nombre-del-paquete
```

#### ¿Puedo cambiar la versión de PHP después de la creación?

¡Sí! Edita el Dockerfile en el directorio de tu proyecto, luego reconstruye:

```bash
cd projects/nombre-de-tu-proyecto
# Edita Dockerfile para cambiar PHP_VERSION
docker-compose build --no-cache
docker-compose up -d
```

#### ¿Cómo ejecuto npm o yarn?

Los contenedores tienen Node.js y npm/yarn instalados:

```bash
cd projects/nombre-de-tu-proyecto
docker-compose exec app npm install
docker-compose exec app npm run dev
```
