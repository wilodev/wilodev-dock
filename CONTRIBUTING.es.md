# Contribuyendo a WiloDev Dock

¡Gracias por considerar contribuir a WiloDev Dock! Este documento describe el proceso para contribuir al proyecto y ayuda a garantizar una experiencia de colaboración fluida.

## Tabla de Contenidos

- [Contribuyendo a WiloDev Dock](#contribuyendo-a-wilodev-dock)
  - [Tabla de Contenidos](#tabla-de-contenidos)
  - [Código de Conducta](#código-de-conducta)
  - [Primeros Pasos](#primeros-pasos)
    - [Prerrequisitos](#prerrequisitos)
    - [Configuración de tu Entorno de Desarrollo](#configuración-de-tu-entorno-de-desarrollo)
  - [Flujo de Trabajo de Desarrollo](#flujo-de-trabajo-de-desarrollo)
  - [Proceso de Pull Request](#proceso-de-pull-request)
    - [Criterios de Revisión de PR](#criterios-de-revisión-de-pr)
  - [Estándares de Codificación](#estándares-de-codificación)
    - [Scripts de Shell](#scripts-de-shell)
    - [Configuración YAML](#configuración-yaml)
    - [Estructura de Directorios](#estructura-de-directorios)
  - [Pruebas](#pruebas)
  - [Documentación](#documentación)
  - [Comunidad](#comunidad)
  - [Reconocimiento](#reconocimiento)

## Código de Conducta

Este proyecto se adhiere a un Código de Conducta que establece las expectativas para la participación en nuestra comunidad. Al participar, se espera que cumplas con este código. Por favor, lee el archivo [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) para más detalles.

> **Nota para Imagen:** Para una ilustración del Código de Conducta, podrías usar el prompt: "Crea una ilustración simple y profesional que represente pautas comunitarias y código de conducta. Muestra desarrolladores diversos colaborando respetuosamente con símbolos de inclusión y trabajo en equipo. Usa un estilo limpio y moderno con acentos en azul y verde azulado."

## Primeros Pasos

### Prerrequisitos

Antes de comenzar a contribuir, asegúrate de tener:

- Docker Engine 20.10+
- Docker Compose 2.0+
- Git
- Una cuenta de GitHub
- Conocimiento básico de Docker, Bash y YAML

### Configuración de tu Entorno de Desarrollo

1. Haz un fork del repositorio en GitHub
2. Clona tu fork localmente:

   ```bash
   git clone https://github.com/TU-USUARIO/wilodev-dock.git
   cd wilodev-dock
   ```

3. Añade el repositorio upstream como remoto:

   ```bash
   git remote add upstream https://github.com/wilodev/wilodev-dock.git
   ```

4. Crea una rama para tu trabajo:

   ```bash
   git checkout -b feature/nombre-de-tu-caracteristica
   ```

## Flujo de Trabajo de Desarrollo

1. Mantén tu fork actualizado con el repositorio upstream:

   ```bash
   git fetch upstream
   git merge upstream/main
   ```

2. Realiza tus cambios en tu rama de características:
   - Sigue los [estándares de codificación](#estándares-de-codificación)
   - Mantén los commits enfocados y con mensajes claros
   - Haz referencia a números de issue en los mensajes de commit cuando sea aplicable

3. Prueba tus cambios a fondo (ver [Pruebas](#pruebas))

4. Documenta tus cambios (ver [Documentación](#documentación))

## Proceso de Pull Request

1. Actualiza tu fork con los últimos cambios upstream
2. Sube tus cambios a tu fork
3. Envía un pull request (PR) desde tu rama a la rama `main` del upstream
4. En la descripción de tu PR:
   - Describe claramente los cambios
   - Enlaza a cualquier issue relacionado
   - Incluye capturas de pantalla si es aplicable
   - Completa la plantilla del PR
5. Participa en el proceso de revisión de código:
   - Responde a los comentarios
   - Realiza los cambios solicitados
   - Discute alternativas cuando sea necesario

### Criterios de Revisión de PR

Los PRs se revisan basados en:

- Calidad del código y adherencia a los estándares
- Funcionalidad y fiabilidad
- Consideraciones de seguridad
- Completitud de la documentación
- Cobertura de pruebas

## Estándares de Codificación

### Scripts de Shell

- Usa `#!/bin/bash` para scripts de shell
- Incluye shebang apropiado y comentarios de encabezado
- Usa `set -euo pipefail` para una ejecución más segura
- Formatea las funciones como:

  ```bash
  nombre_funcion() {
      # Descripción de la función
      local variable1="valor"
      
      # Lógica aquí
  }
  ```

- Usa nombres de variables y funciones significativos
- Añade comentarios para lógica compleja

### Configuración YAML

- Usa indentación de 2 espacios
- Incluye comentarios descriptivos
- Agrupa configuraciones relacionadas
- Usa variables de entorno para valores configurables
- Mantén las líneas por debajo de 100 caracteres cuando sea posible

### Estructura de Directorios

Mantén la estructura de directorios establecida:

```bash
wilodev-dock/
├── docker-compose.yml
├── .env.example
├── setup.sh
├── traefik/
├── mysql/
├── mongo/
├── projects/
└── docs/
```

## Pruebas

Antes de enviar un PR, por favor prueba:

1. Instalación completa desde cero:

    ```bash
    ./setup.sh
    ```

2. Funcionalidad de servicios:
   - Acceso al dashboard de Traefik
   - Conectividad a MySQL y MongoDB
   - Recepción de correos en MailHog
   - Stack de monitoreo (si aplica)

3. Casos extremos:
   - Instalación en diferentes sistemas operativos
   - Varias configuraciones vía .env
   - Manejo de errores y recuperación

## Documentación

Documenta cualquier cambio que hagas:

1. Actualiza el README.md si cambias características visibles al usuario
2. Actualiza o crea documentación en el directorio docs/
3. Incluye comentarios de código claros
4. Actualiza ejemplos de configuración si es necesario

La documentación debe ser:

- Clara y concisa
- Accesible para usuarios de todos los niveles
- Disponible en inglés (las traducciones al español son bienvenidas)
- Correctamente formateada en Markdown

> **Nota para Imagen:** Para una ilustración de documentación, podrías usar el prompt: "Crea una ilustración limpia y minimalista que represente documentación técnica. Muestra documentos organizados, fragmentos de código y diagramas con un enfoque en la claridad y estructura. Usa un estilo profesional con acentos azules."

## Comunidad

Mantente conectado con la comunidad de WiloDev Dock:

- Síguenos en [GitHub](https://github.com/wilodev)
- Únete a nuestras discusiones en [GitHub Discussions](https://github.com/wilodev/wilodev-dock/discussions)
- Reporta errores en [GitHub Issues](https://github.com/wilodev/wilodev-dock/issues)

## Reconocimiento

Los contribuyentes son reconocidos en:

- El README del proyecto
- Notas de lanzamiento
- El archivo [CONTRIBUTORS.md](CONTRIBUTORS.md)

¡Gracias por contribuir a WiloDev Dock!
