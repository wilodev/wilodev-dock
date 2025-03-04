# =================================================================
# WiloDev Dock - Script de Creación de Proyectos para Windows
# =================================================================
# Autor: WiloDev (@wilodev)
# Versión: 1.0.0
#
# Este script facilita la creación de nuevos proyectos dentro del
# entorno WiloDev Dock utilizando archivos de configuración existentes.
# Soporta los siguientes frameworks:
# - Laravel
# - Symfony 
# - Infinity (requiere licencia comercial)
#
# Cada proyecto se configura de forma independiente con su propio
# archivo docker-compose.yml, conectándose a la red de WiloDev Dock
# para acceder a los servicios compartidos.
# =================================================================

# =================================================================
# Constantes para la salida en consola
# =================================================================
$RED = [ConsoleColor]::Red
$GREEN = [ConsoleColor]::Green
$YELLOW = [ConsoleColor]::Yellow
$BLUE = [ConsoleColor]::Cyan
$NC = [ConsoleColor]::White

# Tipos de proyectos soportados
$FRAMEWORKS = @(
  "laravel"
  "symfony"
  "infinity"
)

# =================================================================
# Funciones de utilidad
# =================================================================

# --- Función: Log ---
# Muestra mensajes de log con formato y colores
# Argumentos:
#   $Level: Nivel de log (ERROR, WARNING, SUCCESS, INFO)
#   $Message: Mensaje a mostrar
function Log {
  param (
    [string]$Level,
    [string]$Message
  )
  
  $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
  
  switch ($Level) {
    "ERROR"   { Write-Host "[$timestamp] ERROR: $Message" -ForegroundColor $RED }
    "WARNING" { Write-Host "[$timestamp] WARNING: $Message" -ForegroundColor $YELLOW }
    "SUCCESS" { Write-Host "[$timestamp] SUCCESS: $Message" -ForegroundColor $GREEN }
    "INFO"    { Write-Host "[$timestamp] INFO: $Message" -ForegroundColor $BLUE }
  }
}

# --- Función: Check-Dependencies ---
# Verifica que las dependencias necesarias estén instaladas y funcionando
function Check-Dependencies {
  Log "INFO" "Verificando dependencias..."
  
  # Verificar que Docker esté instalado y funcionando
  if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Log "ERROR" "Docker no está instalado. Por favor, instala Docker primero."
    exit 1
  }
  
  # Verificar que Docker Compose esté instalado
  if (-not ((Get-Command docker -ErrorAction SilentlyContinue) -and (docker compose version 2>$null))) {
    if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
      Log "ERROR" "Docker Compose no está instalado. Por favor, instala Docker Compose primero."
      exit 1
    }
  }
  
  # Verificar que exista el archivo .env
  if (-not (Test-Path ".env" -PathType Leaf)) {
    Log "ERROR" "Archivo .env no encontrado. Ejecuta '.\setup.ps1' primero."
    exit 1
  }
  
  # Cargar variables de entorno desde .env
  Get-Content ".env" | ForEach-Object {
    if ($_ -match "^([^#=]+)=(.*)$") {
      $name = $matches[1].Trim()
      $value = $matches[2].Trim()
      # Eliminar comillas si existen
      $value = $value -replace "^[`"']|[`"']$", ""
      [Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
  }
  
  # Verificar que el contenedor de Traefik esté funcionando
  if (-not (docker ps --format "{{.Names}}" | Select-String -Pattern "^$env:TRAEFIK_CONTAINER_NAME$" -Quiet)) {
    Log "ERROR" "El contenedor de Traefik no está en ejecución. Ejecuta '.\setup.ps1' primero."
    exit 1
  }
  
  Log "SUCCESS" "Todas las dependencias están correctamente instaladas."
}

# --- Función: Validate-ProjectType ---
# Valida que el tipo de proyecto seleccionado sea soportado
# Argumentos:
#   $projectType: Tipo de proyecto seleccionado
function Validate-ProjectType {
  param (
    [string]$projectType
  )
  
  Log "INFO" "Validando tipo de proyecto: $projectType"
  
  # Convertir a minúsculas para facilitar la comparación
  $projectType = $projectType.ToLower()
  
  $valid = $false
  foreach ($framework in $FRAMEWORKS) {
    if ($projectType -eq $framework) {
      $valid = $true
      break
    }
  }
  
  if (-not $valid) {
    Log "ERROR" "Tipo de proyecto no válido: $projectType"
    Log "ERROR" "Tipos de proyectos soportados: $($FRAMEWORKS -join ', ')"
    exit 1
  }
  
  Log "SUCCESS" "Tipo de proyecto válido: $projectType"
  
  # Devolver el tipo en minúsculas
  return $projectType
}

# --- Función: Validate-ProjectName ---
# Valida que el nombre del proyecto sea válido y no exista ya
# Argumentos:
#   $projectName: Nombre del proyecto
function Validate-ProjectName {
  param (
    [string]$projectName
  )
  
  Log "INFO" "Validando nombre de proyecto: $projectName"
  
  # Verificar que el nombre solo contenga caracteres válidos
  if ($projectName -notmatch "^[a-zA-Z0-9_-]+$") {
    Log "ERROR" "El nombre del proyecto contiene caracteres no válidos."
    Log "ERROR" "Por favor, usa solo letras, números, guiones y guiones bajos."
    exit 1
  }
  
  # Verificar que el directorio del proyecto no exista ya
  if (Test-Path "projects\$projectName" -PathType Container) {
    Log "ERROR" "El proyecto '$projectName' ya existe en el directorio 'projects\'."
    Log "ERROR" "Por favor, elige otro nombre o elimina el proyecto existente."
    exit 1
  }
  
  Log "SUCCESS" "Nombre de proyecto válido: $projectName"
}

# --- Función: Validate-Subdomain ---
# Valida que el subdominio sea válido y no esté en uso
# Argumentos:
#   $subdomain: Subdominio
function Validate-Subdomain {
  param (
    [string]$subdomain
  )
  
  Log "INFO" "Validando subdominio: $subdomain"
  
  # Verificar que el subdominio solo contenga caracteres válidos
  if ($subdomain -notmatch "^[a-zA-Z0-9-]+$") {
    Log "ERROR" "El subdominio contiene caracteres no válidos."
    Log "ERROR" "Por favor, usa solo letras, números y guiones."
    exit 1
  }
  
  # Verificar subdominios en uso revisando en todos los docker-compose en la carpeta projects
  $usedSubdomains = @()
  Get-ChildItem -Path "projects" -Directory | ForEach-Object {
    $composeFile = Join-Path -Path "projects" -ChildPath (Join-Path -Path $_.Name -ChildPath "docker-compose.yml")
    if (Test-Path $composeFile -PathType Leaf) {
      Get-Content $composeFile | ForEach-Object {
        if ($_ -match "$env:DOMAIN_BASE") {
          $usedSubdomains += $_
        }
      }
    }
  }
  
  # Verificar si el subdominio está en uso
  foreach ($used in $usedSubdomains) {
    if ($used -match "${subdomain}\.${env:DOMAIN_BASE}") {
      Log "ERROR" "El subdominio '$subdomain.$env:DOMAIN_BASE' ya está en uso."
      Log "ERROR" "Por favor, elige otro subdominio."
      exit 1
    }
  }
  
  Log "SUCCESS" "Subdominio válido: $subdomain"
}

# --- Función: Replace-EnvVars ---
# Reemplaza las variables de entorno en un archivo
# Argumentos:
#   $inputFile: Archivo de entrada
#   $outputFile: Archivo de salida
#   $replacements: Array de pares variable=valor para reemplazo
function Replace-EnvVars {
  param (
    [string]$inputFile,
    [string]$outputFile,
    [string[]]$replacements
  )
  
  # Verificar que el archivo de entrada existe
  if (-not (Test-Path $inputFile -PathType Leaf)) {
    Log "ERROR" "Archivo de entrada no encontrado: $inputFile"
    exit 1
  }
  
  # Copiar archivo de entrada a salida
  Copy-Item $inputFile $outputFile
  
  # Realizar reemplazos por cada par variable=valor
  foreach ($replacement in $replacements) {
    $var = $replacement.Split('=')[0]
    $value = $replacement.Substring($replacement.IndexOf('=')+1)
    
    # Reemplazar la variable con su valor en el archivo
    (Get-Content $outputFile) | ForEach-Object { $_ -replace "\`${$var}", "$value" } | Set-Content $outputFile
  }
}

# --- Función: Create-LaravelProject ---
# Crea un nuevo proyecto Laravel
# Argumentos:
#   $projectName: Nombre del proyecto
#   $subdomain: Subdominio
function Create-LaravelProject {
  param (
    [string]$projectName,
    [string]$subdomain
  )
  
  $projectDir = "projects\$projectName"
  
  Log "INFO" "Creando proyecto Laravel: $projectName"
  
  # Crear directorio del proyecto
  New-Item -Path $projectDir -ItemType Directory -Force | Out-Null
  
  # Crear proyecto Laravel usando Docker
  Log "INFO" "Instalando Laravel usando Composer..."
  docker run --rm -v "${PWD}/$($projectDir.Replace('\','/')):/app" -w /app composer create-project --prefer-dist laravel/laravel .
  
  # Crear directorios adicionales necesarios
  New-Item -Path "$projectDir\docker\nginx" -ItemType Directory -Force | Out-Null
  New-Item -Path "$projectDir\docker\supervisor" -ItemType Directory -Force | Out-Null
  
  # Configurar .env.docker para el proyecto
  Log "INFO" "Configurando variables de entorno para Docker..."
  $replacements = @(
    "APP_NAME=$projectName",
    "APP_DOMAIN=${subdomain}.${env:DOMAIN_BASE}",
    "PROJECT_PATH=$projectDir",
    "PHP_VERSION=$env:PHP_VERSION",
    "NODE_VERSION=$env:NODE_VERSION",
    "NETWORK_NAME=$env:NETWORK_NAME",
    "MYSQL_CONTAINER_NAME=$env:MYSQL_CONTAINER_NAME",
    "MYSQL_DATABASE=$projectName",
    "MYSQL_USER=$env:MYSQL_USER",
    "MYSQL_PASSWORD=$env:MYSQL_PASSWORD",
    "MONGO_CONTAINER_NAME=$env:MONGO_CONTAINER_NAME",
    "MONGO_INITDB_DATABASE=$env:MONGO_INITDB_DATABASE",
    "MONGO_INITDB_ROOT_USERNAME=$env:MONGO_INITDB_ROOT_USERNAME",
    "MONGO_INITDB_ROOT_PASSWORD=$env:MONGO_INITDB_ROOT_PASSWORD"
  )
  Replace-EnvVars "laravel\.env.example.docker" "$projectDir\.env.docker" $replacements
  
  # Copiar Dockerfile para el proyecto
  Log "INFO" "Configurando Dockerfile para el proyecto..."
  Replace-EnvVars "laravel\Dockerfile.example" "$projectDir\Dockerfile" @(
    "PHP_VERSION=$env:PHP_VERSION",
    "NODE_VERSION=$env:NODE_VERSION"
  )
  
  # Copiar configuración de Nginx
  Log "INFO" "Configurando Nginx para el proyecto..."
  Replace-EnvVars "laravel\nginx.example.conf" "$projectDir\docker\nginx\default.conf" @(
    "APP_DOMAIN=${subdomain}.${env:DOMAIN_BASE}"
  )
  
  # Copiar configuración de PHP
  Log "INFO" "Configurando PHP para el proyecto..."
  Copy-Item "laravel\php.example.ini" "$projectDir\docker\php.ini"
  
  # Copiar configuración de Supervisor
  Log "INFO" "Configurando Supervisor para el proyecto..."
  Copy-Item "laravel\supervisor.example.conf" "$projectDir\docker\supervisor\laravel.conf"
  
  # Crear docker-compose.yml para el proyecto
  Log "INFO" "Creando configuración de Docker Compose para el proyecto..."
  Replace-EnvVars "laravel\docker-compose.example.yml" "$projectDir\docker-compose.yml" @(
    "APP_NAME=$projectName",
    "APP_DOMAIN=${subdomain}.${env:DOMAIN_BASE}",
    "PHP_VERSION=$env:PHP_VERSION",
    "NODE_VERSION=$env:NODE_VERSION",
    "NETWORK_NAME=$env:NETWORK_NAME"
  )
  
  # Crear base de datos para el proyecto
  Log "INFO" "Creando base de datos para el proyecto..."
  $sqlCommand = @"
CREATE DATABASE IF NOT EXISTS ${projectName};
GRANT ALL PRIVILEGES ON ${projectName}.* TO '${env:MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
"@
  $sqlCommand | docker exec -i $env:MYSQL_CONTAINER_NAME mysql -u root -p"$env:MYSQL_ROOT_PASSWORD"

Log "SUCCESS" "Proyecto Laravel '$projectName' creado correctamente."
  Log "SUCCESS" "Accede al proyecto en: https://${subdomain}.${env:DOMAIN_BASE}"
  Log "INFO" "Para iniciar el proyecto, navega a projects\$projectName y ejecuta: docker-compose up -d"
}

# --- Función: Create-SymfonyProject ---
# Crea un nuevo proyecto Symfony
# Argumentos:
#   $projectName: Nombre del proyecto
#   $subdomain: Subdominio
function Create-SymfonyProject {
  param (
    [string]$projectName,
    [string]$subdomain
  )
  
  $projectDir = "projects\$projectName"
  
  Log "INFO" "Creando proyecto Symfony: $projectName"
  
  # Crear directorio del proyecto
  New-Item -Path $projectDir -ItemType Directory -Force | Out-Null
  
  # Crear proyecto Symfony usando Docker
  Log "INFO" "Instalando Symfony usando Composer..."
  docker run --rm -v "${PWD}/$($projectDir.Replace('\','/')):/app" -w /app composer create-project symfony/website-skeleton .
  
  # Crear directorios adicionales necesarios
  New-Item -Path "$projectDir\docker\nginx" -ItemType Directory -Force | Out-Null
  New-Item -Path "$projectDir\docker\supervisor" -ItemType Directory -Force | Out-Null
  
  # Configurar .env.docker para el proyecto
  Log "INFO" "Configurando variables de entorno para Docker..."
  $replacements = @(
    "APP_NAME=$projectName",
    "APP_DOMAIN=${subdomain}.${env:DOMAIN_BASE}",
    "PROJECT_PATH=$projectDir",
    "PHP_VERSION=$env:PHP_VERSION",
    "NODE_VERSION=$env:NODE_VERSION",
    "NETWORK_NAME=$env:NETWORK_NAME",
    "MYSQL_CONTAINER_NAME=$env:MYSQL_CONTAINER_NAME",
    "MYSQL_DATABASE=$projectName",
    "MYSQL_USER=$env:MYSQL_USER",
    "MYSQL_PASSWORD=$env:MYSQL_PASSWORD",
    "MONGO_CONTAINER_NAME=$env:MONGO_CONTAINER_NAME",
    "MONGO_INITDB_DATABASE=$env:MONGO_INITDB_DATABASE",
    "MONGO_INITDB_ROOT_USERNAME=$env:MONGO_INITDB_ROOT_USERNAME",
    "MONGO_INITDB_ROOT_PASSWORD=$env:MONGO_INITDB_ROOT_PASSWORD"
  )
  Replace-EnvVars "symfony\.env.example.docker" "$projectDir\.env.docker" $replacements
  
  # Copiar Dockerfile para el proyecto
  Log "INFO" "Configurando Dockerfile para el proyecto..."
  Replace-EnvVars "symfony\Dockerfile.example" "$projectDir\Dockerfile" @(
    "PHP_VERSION=$env:PHP_VERSION",
    "NODE_VERSION=$env:NODE_VERSION"
  )
  
  # Copiar configuración de Nginx
  Log "INFO" "Configurando Nginx para el proyecto..."
  Replace-EnvVars "symfony\nginx.example.conf" "$projectDir\docker\nginx\default.conf" @(
    "APP_DOMAIN=${subdomain}.${env:DOMAIN_BASE}"
  )
  
  # Copiar configuración de PHP
  Log "INFO" "Configurando PHP para el proyecto..."
  Copy-Item "symfony\php.example.ini" "$projectDir\docker\php.ini"
  
  # Copiar configuración de Supervisor
  Log "INFO" "Configurando Supervisor para el proyecto..."
  Copy-Item "symfony\supervisor.example.conf" "$projectDir\docker\supervisor\symfony.conf"
  
  # Crear docker-compose.yml para el proyecto
  Log "INFO" "Creando configuración de Docker Compose para el proyecto..."
  Replace-EnvVars "symfony\docker-compose.example.yml" "$projectDir\docker-compose.yml" @(
    "APP_NAME=$projectName",
    "APP_DOMAIN=${subdomain}.${env:DOMAIN_BASE}",
    "PHP_VERSION=$env:PHP_VERSION",
    "NODE_VERSION=$env:NODE_VERSION",
    "NETWORK_NAME=$env:NETWORK_NAME"
  )
  
  # Crear base de datos para el proyecto
  Log "INFO" "Creando base de datos para el proyecto..."
  $sqlCommand = @"
CREATE DATABASE IF NOT EXISTS ${projectName};
GRANT ALL PRIVILEGES ON ${projectName}.* TO '${env:MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
"@
  $sqlCommand | docker exec -i $env:MYSQL_CONTAINER_NAME mysql -u root -p"$env:MYSQL_ROOT_PASSWORD"

  Log "SUCCESS" "Proyecto Symfony '$projectName' creado correctamente."
  Log "SUCCESS" "Accede al proyecto en: https://${subdomain}.${env:DOMAIN_BASE}"
  Log "INFO" "Para iniciar el proyecto, navega a projects\$projectName y ejecuta: docker-compose up -d"
}

# --- Función: Create-InfinityProject ---
# Crea un nuevo proyecto Infinity
# Argumentos:
#   $projectName: Nombre del proyecto
#   $subdomain: Subdominio
function Create-InfinityProject {
  param (
    [string]$projectName,
    [string]$subdomain
  )
  
  $projectDir = "projects\$projectName"
  
  Log "INFO" "Creando proyecto Infinity: $projectName"
  
  # Verificar licencia comercial
  $license = Read-Host "Este framework requiere licencia comercial. ¿Tienes una licencia válida? (s/n)"
  if ($license -ne "s") {
    Log "ERROR" "Se requiere una licencia válida para crear proyectos Infinity."
    exit 1
  }
  
  $licenseKey = Read-Host "Introduce tu clave de licencia"
  
  # Crear directorio del proyecto
  New-Item -Path $projectDir -ItemType Directory -Force | Out-Null
  
  # Clonar repositorio de Infinity (simulado - ajusta según el caso real)
  Log "INFO" "Clonando repositorio Infinity..."
  # docker run --rm -v "${PWD}/$($projectDir.Replace('\','/')):/app" -w /app alpine/git clone https://github.com/tu-org/infinity-framework.git .
  
  # En lugar de clonar, simplemente creamos una estructura básica de archivos para demostración
  "# Infinity Project: $projectName" | Out-File -FilePath "$projectDir\README.md"
  New-Item -Path "$projectDir\src" -ItemType Directory -Force | Out-Null
  New-Item -Path "$projectDir\config" -ItemType Directory -Force | Out-Null
  New-Item -Path "$projectDir\public" -ItemType Directory -Force | Out-Null
  "<?php echo 'Infinity Framework';" | Out-File -FilePath "$projectDir\public\index.php"
  
  # Crear directorios adicionales necesarios
  New-Item -Path "$projectDir\docker\nginx" -ItemType Directory -Force | Out-Null
  
  # Configurar .env.docker para el proyecto
  Log "INFO" "Configurando variables de entorno para Docker..."
  $replacements = @(
    "APP_NAME=$projectName",
    "APP_DOMAIN=${subdomain}.${env:DOMAIN_BASE}",
    "PROJECT_PATH=$projectDir",
    "PHP_VERSION=$env:PHP_VERSION",
    "NODE_VERSION=$env:NODE_VERSION",
    "NETWORK_NAME=$env:NETWORK_NAME",
    "MYSQL_CONTAINER_NAME=$env:MYSQL_CONTAINER_NAME",
    "MYSQL_DATABASE=$projectName",
    "MYSQL_USER=$env:MYSQL_USER",
    "MYSQL_PASSWORD=$env:MYSQL_PASSWORD",
    "INFINITY_LICENSE=$licenseKey"
  )
  Replace-EnvVars "infinity\.env.example.docker" "$projectDir\.env.docker" $replacements
  
  # Copiar Dockerfile para el proyecto
  Log "INFO" "Configurando Dockerfile para el proyecto..."
  Replace-EnvVars "infinity\Dockerfile.example" "$projectDir\Dockerfile" @(
    "PHP_VERSION=$env:PHP_VERSION",
    "NODE_VERSION=$env:NODE_VERSION"
  )
  
  # Copiar configuración de Nginx
  Log "INFO" "Configurando Nginx para el proyecto..."
  Replace-EnvVars "infinity\nginx.example.conf" "$projectDir\docker\nginx\default.conf" @(
    "APP_DOMAIN=${subdomain}.${env:DOMAIN_BASE}"
  )
  
  # Crear docker-compose.yml para el proyecto
  Log "INFO" "Creando configuración de Docker Compose para el proyecto..."
  Replace-EnvVars "infinity\docker-compose.example.yml" "$projectDir\docker-compose.yml" @(
    "APP_NAME=$projectName",
    "APP_DOMAIN=${subdomain}.${env:DOMAIN_BASE}",
    "PHP_VERSION=$env:PHP_VERSION",
    "NODE_VERSION=$env:NODE_VERSION",
    "NETWORK_NAME=$env:NETWORK_NAME"
  )
  
  # Crear base de datos para el proyecto
  Log "INFO" "Creando base de datos para el proyecto..."
  $sqlCommand = @"
CREATE DATABASE IF NOT EXISTS ${projectName};
GRANT ALL PRIVILEGES ON ${projectName}.* TO '${env:MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
"@
  $sqlCommand | docker exec -i $env:MYSQL_CONTAINER_NAME mysql -u root -p"$env:MYSQL_ROOT_PASSWORD"

  Log "SUCCESS" "Proyecto Infinity '$projectName' creado correctamente."
  Log "SUCCESS" "Accede al proyecto en: https://${subdomain}.${env:DOMAIN_BASE}"
  Log "INFO" "Para iniciar el proyecto, navega a projects\$projectName y ejecuta: docker-compose up -d"
}

# --- Función: Update-HostsFile ---
# Actualiza el archivo hosts para añadir el nuevo dominio
# Argumentos:
#   $subdomain: Subdominio a añadir
function Update-HostsFile {
  param (
    [string]$subdomain
  )
  
  Log "INFO" "Actualizando archivo hosts para el nuevo subdominio..."
  
  $hostsFile = "C:\Windows\System32\drivers\etc\hosts"
  $domainEntry = "127.0.0.1 ${subdomain}.${env:DOMAIN_BASE}"
  
  $currentHosts = Get-Content $hostsFile -ErrorAction SilentlyContinue
  
  # Verificar si el dominio ya está en el archivo hosts
  if ($currentHosts -contains $domainEntry) {
    Log "INFO" "El dominio ya existe en el archivo hosts."
    return
  }
  
  Log "INFO" "Se necesita añadir el dominio $domainEntry al archivo hosts."
  Log "INFO" "Se requieren privilegios de administrador para actualizar el archivo hosts."
  
  $response = Read-Host "¿Deseas actualizar automáticamente el archivo hosts? (s/n)"
  
  if ($response -match "^[Ss]$") {
    try {
      # Crear copia de seguridad
      Copy-Item $hostsFile "$hostsFile.bak" -Force
      
      # Añadir entrada
      Add-Content -Path $hostsFile -Value "`n$domainEntry" -Force
      
      Log "SUCCESS" "Archivo hosts actualizado correctamente."
    } catch {
      Log "ERROR" "Error al actualizar el archivo hosts: $_"
      Log "INFO" "Deberás actualizarlo manualmente como administrador. Añade esta línea: $domainEntry"
    }
  } else {
    Log "INFO" "Por favor, actualiza manualmente el archivo hosts."
    Log "INFO" "Añade la siguiente línea a $hostsFile: $domainEntry"
  }
}

# --- Función: Main ---
# Función principal del script
function Main {
  # Mostrar encabezado
  Write-Host "`n=============================================" -ForegroundColor $BLUE
  Write-Host "   🚀 WILODEV DOCK - CREADOR DE PROYECTOS" -ForegroundColor $BLUE
  Write-Host "=============================================" -ForegroundColor $BLUE
  
  # Verificar dependencias
  Check-Dependencies
  
  # Verificar argumentos
  if ($args.Count -lt 2 -or $args.Count -gt 3) {
    Log "ERROR" "Uso incorrecto. Debes proporcionar al menos dos argumentos."
    Log "INFO" "Uso: .\create-project.ps1 <tipo-proyecto> <nombre-proyecto> [subdominio]"
    Log "INFO" "Tipos de proyecto disponibles: $($FRAMEWORKS -join ', ')"
    exit 1
  }
  
  # Extraer argumentos
  $projectType = Validate-ProjectType $args[0]
  $projectName = $args[1]
  
  # Validar nombre del proyecto
  Validate-ProjectName $projectName
  
  # Determinar subdominio (usar nombre del proyecto si no se especifica)
  $subdomain = if ($args.Count -eq 3) { $args[2] } else { $projectName }
  
  # Validar subdominio
  Validate-Subdomain $subdomain
  
  # Crear proyecto según el tipo seleccionado
  switch ($projectType) {
    "laravel" {
      Create-LaravelProject $projectName $subdomain
    }
    "symfony" {
      Create-SymfonyProject $projectName $subdomain
    }
    "infinity" {
      Create-InfinityProject $projectName $subdomain
    }
    default {
      Log "ERROR" "Tipo de proyecto no implementado: $projectType"
      exit 1
    }
  }
  
  # Actualizar archivo hosts
  Update-HostsFile $subdomain
  
  # Iniciar los servicios del proyecto
  Log "INFO" "Iniciando servicios del proyecto..."
  try {
    Set-Location -Path "projects\$projectName"
    docker-compose up -d
    Set-Location -Path "..\..\"
    
    Log "SUCCESS" "Servicios del proyecto iniciados correctamente."
  } catch {
    Log "ERROR" "Error al iniciar los servicios del proyecto: $_"
    Log "INFO" "Intenta iniciarlos manualmente navegando a projects\$projectName y ejecutando: docker-compose up -d"
  }
  
# Mensaje final
  Write-Host "`n=============================================" -ForegroundColor $GREEN
  Write-Host "   ✅ PROYECTO CREADO EXITOSAMENTE" -ForegroundColor $GREEN
  Write-Host "=============================================" -ForegroundColor $GREEN
  Write-Host "Proyecto: $projectName" -ForegroundColor $GREEN
  Write-Host "Tipo: $projectType" -ForegroundColor $GREEN
  Write-Host "URL: https://${subdomain}.${env:DOMAIN_BASE}" -ForegroundColor $GREEN
  Write-Host "`nPara gestionar tu proyecto:" -ForegroundColor $BLUE
  Write-Host "- Código fuente: projects\$projectName" -ForegroundColor $BLUE
  Write-Host "- Configuración: projects\$projectName\docker-compose.yml" -ForegroundColor $BLUE
  Write-Host "- Comandos: cd projects\$projectName && docker-compose [comando]" -ForegroundColor $BLUE
  Write-Host "`nComandos útiles:" -ForegroundColor $YELLOW
  Write-Host "- Iniciar: docker-compose up -d" -ForegroundColor $YELLOW
  Write-Host "- Detener: docker-compose down" -ForegroundColor $YELLOW
  Write-Host "- Ver logs: docker-compose logs -f" -ForegroundColor $YELLOW
  Write-Host "- Ejecutar comandos: docker-compose exec app [comando]" -ForegroundColor $YELLOW
  Write-Host "=============================================" -ForegroundColor $GREEN
}

# Ejecutar función principal con los argumentos pasados al script
if ($args.Count -gt 0) {
  Main $args
} else {
  # Mostrar encabezado
  Write-Host "`n=============================================" -ForegroundColor $BLUE
  Write-Host "   🚀 WILODEV DOCK - CREADOR DE PROYECTOS" -ForegroundColor $BLUE
  Write-Host "=============================================" -ForegroundColor $BLUE
  Write-Host "Uso: .\create-project.ps1 <tipo-proyecto> <nombre-proyecto> [subdominio]" -ForegroundColor $YELLOW
  Write-Host "Tipos de proyecto disponibles: $($FRAMEWORKS -join ', ')" -ForegroundColor $YELLOW
  Write-Host "`nEjemplos:" -ForegroundColor $BLUE
  Write-Host ".\create-project.ps1 laravel mi-proyecto" -ForegroundColor $BLUE
  Write-Host ".\create-project.ps1 symfony blog blog-symfony" -ForegroundColor $BLUE
  Write-Host "=============================================" -ForegroundColor $BLUE
}