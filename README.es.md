# WiloDev Dock

<p align="center">
  <img src="docs/images/wilodev-dock-logo.webp" alt="Wilodev Dock Logo" width="700"/>
</p>

## Un Entorno de Desarrollo Completo en Contenedores

[![Licencia: MIT](https://img.shields.io/badge/Licencia-MIT-blue.svg)](LICENSE)
[![Versión](https://img.shields.io/badge/Versión-1.0.0-brightgreen.svg)](https://github.com/wilodev/wilodev-dock)
[![Docker](https://img.shields.io/badge/Docker-20.10+-099cec.svg)](https://www.docker.com/)

[English](README.md) | [Español](README.es.md)

## Descripción General

WiloDev Dock proporciona un entorno de desarrollo completo en contenedores que está listo para usar en minutos. Combina herramientas potentes como Traefik, MySQL, MongoDB y más para crear una configuración amigable para desarrolladores con capacidades robustas de monitoreo.

<p align="center">
  <img src="docs/images/architecture-overview.webp" alt="Architecture Overview" width="700"/>
</p>

### Características Principales

- **Configuración Cero**: Funciona de inmediato con valores predeterminados sensatos
- **Seguro por Defecto**: HTTPS con certificados autogenerados para desarrollo local
- **Monitoreo de Rendimiento**: Integración con Prometheus, Grafana y Loki
- **Bases de Datos Listas**: Servicios de MySQL y MongoDB preconfigurados
- **Pruebas de Correo**: MailHog para capturar y visualizar correos electrónicos salientes

<p align="center">
  <img src="docs/images/setup-flow.webp" alt="Setup Flow" width="700"/>
</p>

## 🚀 Inicio Rápido

### Para usuarios de Linux/Mac

```bash
# Clonar el repositorio
git clone https://github.com/wilodev/wilodev-dock.git
cd wilodev-dock

# Copiar el archivo de variables de entorno
cp .env.example .env

# Copiar el script de configuración apropiado para tu sistema
cp setup.linux-mac.example.sh setup.sh
chmod +x setup.sh

# Ejecutar el script de configuración
./setup.sh

# Tras la configuración, puedes acceder a:
# - Dashboard Traefik: https://traefik.wilodev.localhost (o el dominio configurado)
# - MailHog: https://mail.wilodev.localhost
# - Prometheus: https://prometheus.wilodev.localhost
# - Grafana: https://grafana.wilodev.localhost (usuario: admin, contraseña: admin123)
```

### Para usuarios de Windows

```powershell
# Clonar el repositorio
git clone https://github.com/wilodev/wilodev-dock.git
cd wilodev-dock

# Copiar el archivo de variables de entorno
Copy-Item .env.example .env

# Copiar el script de configuración para Windows
Copy-Item setup.windows.example.ps1 setup.ps1

# Ejecutar el script de configuración (como Administrador)
# Abrir PowerShell como Administrador y navegar al directorio del proyecto
.\setup.ps1
```

## Servicios Incluidos

| Servicio | Propósito | URL Predeterminada |
|----------|-----------|-------------------|
| **Traefik** | Proxy Inverso y SSL | https://{TRAEFIK_DOMAIN} |
| **MySQL** | Base de Datos Relacional | localhost:{MYSQL_PORT} |
| **MongoDB** | Base de Datos NoSQL | localhost:{MONGO_PORT} |
| **MailHog** | Pruebas de Correo | https://{MAILHOG_DOMAIN} |
| **Prometheus** | Recolección de Métricas | <https://prometheus.{DOMAIN_BASE}> |
| **Grafana** | Visualización de Métricas | <https://grafana.{DOMAIN_BASE}> |
| **Loki** | Agregación de Logs | (Interno) |

Nota: Las URLs reales dependerán de los valores en tu archivo `.env`. Los valores predeterminados son nombres de dominio como `traefik.wilodev.localhost` que apuntan a tu máquina local.

## Documentación

- [Guía de Inicio](docs/es/getting-started.md): Aprende a configurar y usar WiloDev Dock
- [Creación de Nuevos Proyectos](docs/es/creating-projects.md): Instrucciones para añadir nuevos proyectos al entorno
- [Referencia de Configuración](docs/es/configuration.md): Explicación detallada de todas las opciones de configuración
- [Solución de Problemas](docs/es/troubleshooting.md): Soluciones a problemas comunes

## Requisitos

- Docker Engine 20.10+
- Docker Compose 2.0+
- 5GB de espacio en disco (mínimo)
- 4GB de RAM (recomendado)

## 🛠️ Entornos de Desarrollo Soportados

WiloDev Dock proporciona entornos preconfigurados para los siguientes frameworks:

### Laravel

- PHP-FPM con versiones configurables
- Nginx optimizado para Laravel
- Redis para caché y colas
- Worker de colas integrado
- Configuración HTTPS automática con Traefik

### Symfony

- PHP-FPM con extensiones específicas para Symfony
- Nginx optimizado para el sistema de rutas de Symfony
- Redis para caché y sesiones
- Servicio Messenger para procesamiento asíncrono
- Webpack Encore para compilación de assets

Para crear un nuevo proyecto:

```bash
./create-project.sh
```

## Arquitectura y Flujo

WiloDev Dock utiliza una arquitectura en capas para máxima flexibilidad:

1. **Capa Traefik**: Maneja todo el tráfico HTTP/HTTPS entrante, terminación SSL y enrutamiento
2. **Capa de Servicio**: Contiene tus contenedores de aplicación (PHP, Node.js, etc.)
3. **Capa de Datos**: Proporciona servicios de bases de datos (MySQL, MongoDB)
4. **Capa de Utilidad**: Servicios adicionales como MailHog para pruebas
5. **Capa de Observabilidad**: Monitoreo con Prometheus, Grafana y Loki

El proceso de configuración sigue esta secuencia:

1. Validación del entorno
2. Creación y configuración de directorios
3. Generación de certificados SSL
4. Creación de red Docker
5. Inicialización de servicios
6. Verificación y comprobación de salud

### Gestión de SSL/HTTPS

Todo el tráfico externo es gestionado por Traefik a través de HTTPS (puerto 443):

1. **Certificados Autogenerados**: El script `setup.sh` utiliza `mkcert` para generar certificados SSL localmente confiables.
2. **Terminación SSL en Traefik**: Traefik maneja toda la encriptación/desencriptación SSL.
3. **Comunicación Interna**: Internamente, los servicios se comunican a través de HTTP (puerto 80) dentro de la red Docker.
4. **Preservación del Esquema HTTPS**: Los headers `X-Forwarded-*` aseguran que los frameworks web detecten correctamente las peticiones HTTPS.

## Casos de Uso Comunes

- **Desarrollo de Aplicaciones Web**: Perfecto para PHP/Laravel, Node.js y otros frameworks web
- **Desarrollo de APIs**: Prueba tus APIs con HTTPS automático y nombres de dominio adecuados
- **Microservicios**: Simula un entorno similar a producción localmente
- **Desarrollo de Bases de Datos**: Múltiples motores de bases de datos listos para usar

## Configuración del Entorno

WiloDev Dock utiliza variables de entorno para la configuración. Copia el archivo de ejemplo para comenzar:

```bash
cp .env.example .env
```

Las opciones clave de configuración incluyen:

- `DOMAIN_BASE`: Dominio base para todos los servicios (predeterminado: wilodev.localhost)
- `NETWORK_NAME`: Nombre de la red Docker (predeterminado: wilodev_network)
- `TRAEFIK_DOMAIN`: Dominio para el panel de Traefik
- `MYSQL_PORT`, `MONGO_PORT`: Puertos de bases de datos a exponer
- `TRAEFIK_DASHBOARD_USER`, `TRAEFIK_DASHBOARD_PASSWORD`: Credenciales del panel

Consulta el archivo `.env.example` para todas las opciones disponibles.

## Estructura de Directorios

```bash
wilodev-dock/
├── setup.linux-mac.example.sh      # Script de configuración para Linux/Mac
├── setup.windows.example.ps1       # Script de configuración para Windows
├── create-project.example.sh       # Script de creación para Linux/Mac
├── create-project.example.ps1      # Script de creación para Windows
├── docker-compose.yml              # Definiciones principales de servicios
├── .env.example                    # Ejemplo de archivo de configuración
├── traefik/                        # Configuración de Traefik
│   ├── config/                     # Archivos de configuración
│   │   ├── certs/                  # Certificados SSL
│   │   ├── dynamic.yml             # Configuración dinámica
│   │   ├── middleware.yml          # Definiciones de middleware
│   │   └── traefik.yml             # Configuración estática
├── mysql/                          # Configuración de MySQL
│   └── config/                     # Archivos de configuración
├── mongo/                          # Configuración de MongoDB
│   └── config/                     # Archivos de configuración
├── projects/                       # Directorio para tus proyectos
└── docs/                           # Documentación
```

## Contribuciones

¡Las contribuciones son bienvenidas! Por favor, lee nuestra [Guía de Contribución](CONTRIBUTING.es.md) para detalles sobre cómo enviar pull requests, reportar problemas y sugerir mejoras.

## Problemas y Soporte

¿Encontraste un error o tienes una solicitud de función? Por favor [abre un issue](https://github.com/wilodev/wilodev-dock/issues/new) en GitHub.

Para preguntas generales y discusiones, utiliza [GitHub Discussions](https://github.com/wilodev/wilodev-dock/discussions).

## Licencia

Este proyecto está licenciado bajo la Licencia MIT con un requisito de atribución - consulta el archivo [LICENSE](LICENSE) para más detalles.

## Agradecimientos

- [Traefik](https://traefik.io/) - Proxy inverso moderno
- [Docker](https://www.docker.com/) - Plataforma de contenedores
- [Grafana](https://grafana.com/) - Plataforma de visualización de métricas
- [MkCert](https://github.com/FiloSottile/mkcert) - Autoridad certificadora local
- [MySQL](https://www.mysql.com/) - Base de datos relacional
- [MongoDB](https://www.mongodb.com/) - Base de datos NoSQL
- [MailHog](https://github.com/mailhog/MailHog) - Herramienta de pruebas de correo electrónico

## Autor

- **WiloDev** - [GitHub](https://github.com/wilodev)
