# ==========================================
# WiloDev Dock - Script de Configuración para Windows
# ------------------------------------------
# Autor: WiloDev (@wilodev)
# Versión: 1.0.0
# Última actualización: 2023-07-05
#
# Este script configura la infraestructura base para el entorno WiloDev Dock en Windows:
# - Traefik como proxy inverso con SSL
# - MySQL como servidor de base de datos relacional
# - MongoDB como servidor de base de datos NoSQL
# - MailHog para pruebas de correo electrónico
# ==========================================

# Variables globales
$SCRIPT_VERSION = "1.0.1"
$LOG_FILE = "setup.log"
$MIN_DOCKER_VERSION = "20.10.0"
$MIN_COMPOSE_VERSION = "2.0.0"
$REQUIRED_SPACE_MB = 5120  # 5GB

# Función para mostrar logs con colores
function Log {
    param (
        [string]$Level,
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    
    # Formatear mensaje para consola con colores
    switch ($Level) {
        "ERROR" { 
            Write-Host "[$timestamp] ERROR: $Message" -ForegroundColor Red 
        }
        "WARNING" { 
            Write-Host "[$timestamp] WARNING: $Message" -ForegroundColor Yellow 
        }
        "SUCCESS" { 
            Write-Host "[$timestamp] SUCCESS: $Message" -ForegroundColor Green 
        }
        "INFO" { 
            Write-Host "[$timestamp] INFO: $Message" -ForegroundColor Cyan 
        }
        "DEBUG" { 
            if ($env:DEBUG -eq "true") {
                Write-Host "[$timestamp] DEBUG: $Message" -ForegroundColor Gray
            }
        }
    }
    
    # Guardar todos los mensajes en el archivo de log
    "[$timestamp] $Level: $Message" | Out-File -FilePath $LOG_FILE -Append
}

# Función para medir el tiempo de ejecución
function Measure-ExecutionTime {
    param (
        [string]$Description,
        [scriptblock]$ScriptBlock
    )
    
    $startTime = Get-Date
    & $ScriptBlock
    $endTime = Get-Date
    $duration = ($endTime - $startTime).TotalSeconds
    
    Log "INFO" "⏱️ $Description completado en $duration segundos"
}

# Verificar que estamos ejecutando como administrador
function Check-AdminPrivileges {
    Log "INFO" "Verificando privilegios de administrador..."
    
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Log "ERROR" "Este script debe ejecutarse como administrador"
        Log "ERROR" "Por favor, abre PowerShell como administrador e intenta nuevamente"
        exit 1
    }
    
    Log "SUCCESS" "Ejecutando con privilegios de administrador"
}

# Verificar estructura de archivos y directorios
function Check-FileStructure {
    Log "INFO" "Verificando estructura de archivos..."
    
    $requiredDirs = @(
        "mongo\config",
        "mysql\config",
        "traefik\config",
        "traefik\config\certs"
    )
    
    $requiredFiles = @(
        "docker-compose.example.yml",
        "traefik\config\traefik.example.yml",
        "traefik\config\dynamic.example.yml",
        "traefik\config\middleware.example.yml",
        "mysql\config\my.example.cnf",
        "mongo\config\mongod.example.conf",
        ".env.example"
    )
    
    $missing = $false
    
    # Verificar directorios
    foreach ($dir in $requiredDirs) {
        if (-not (Test-Path $dir -PathType Container)) {
            Log "ERROR" "Directorio requerido no encontrado: $dir"
            $missing = $true
        } else {
            Log "DEBUG" "Directorio encontrado: $dir"
        }
    }
    
    # Verificar archivos
    foreach ($file in $requiredFiles) {
        if (-not (Test-Path $file -PathType Leaf)) {
            Log "ERROR" "Archivo requerido no encontrado: $file"
            $missing = $true
        } else {
            Log "DEBUG" "Archivo encontrado: $file"
        }
    }
    
    if ($missing) {
        Log "ERROR" "Estructura de archivos incompleta"
        exit 1
    }
    
    Log "SUCCESS" "Estructura de archivos verificada correctamente"
}

# Verificar permisos de archivos
function Check-FilePermissions {
    Log "INFO" "Verificando permisos de archivos..."
    
    $dirsToCheck = @(
        "traefik\config\certs",
        "mysql\config",
        "mongo\config"
    )
    
    foreach ($dir in $dirsToCheck) {
        try {
            # Intentar crear un archivo temporal para verificar permisos de escritura
            $testFile = Join-Path -Path $dir -ChildPath "test_permissions.tmp"
            "test" | Out-File -FilePath $testFile -ErrorAction Stop
            Remove-Item -Path $testFile -ErrorAction Stop
            Log "DEBUG" "Permisos de escritura correctos en: $dir"
        } catch {
            Log "ERROR" "No hay permisos de escritura en: $dir"
            Log "INFO" "Usuario actual: $env:USERNAME"
            Log "INFO" "Para resolver este problema, ejecuta el script como administrador"
            return $false
        }
    }
    
    Log "SUCCESS" "Permisos de archivos verificados correctamente"
    return $true
}

# Verificar espacio en disco
function Check-DiskSpace {
    Log "INFO" "Verificando espacio en disco..."
    
    $drive = (Get-Location).Drive.Name + ":"
    $availableSpace = (Get-PSDrive -Name (Get-Location).Drive.Name).Free / 1MB
    
    Log "DEBUG" "Espacio disponible: ${availableSpace}MB - Requerido: ${REQUIRED_SPACE_MB}MB"
    
    if ($availableSpace -lt $REQUIRED_SPACE_MB) {
        Log "ERROR" "Espacio insuficiente en disco. Se requieren al menos ${REQUIRED_SPACE_MB}MB (${REQUIRED_SPACE_MB/1024}GB)"
        Log "ERROR" "Espacio disponible: ${availableSpace}MB ($([math]::Round($availableSpace/1024, 2))GB)"
        return $false
    }
    
    Log "SUCCESS" "Espacio en disco suficiente: $([math]::Round($availableSpace, 2))MB disponible"
    return $true
}

# Comparar versiones semánticas
function Compare-Versions {
    param (
        [string]$Current,
        [string]$Required
    )
    
    $currentParts = $Current.Split('.')
    $requiredParts = $Required.Split('.')
    
    # Rellenar con ceros si es necesario
    for ($i = 0; $i -lt 3; $i++) {
        if ($i -ge $currentParts.Count) { $currentParts += "0" }
        if ($i -ge $requiredParts.Count) { $requiredParts += "0" }
    }
    
    # Comparar versión mayor
    if ([int]$currentParts[0] -gt [int]$requiredParts[0]) { return $true }
    if ([int]$currentParts[0] -lt [int]$requiredParts[0]) { return $false }
    
    # Comparar versión menor
    if ([int]$currentParts[1] -gt [int]$requiredParts[1]) { return $true }
    if ([int]$currentParts[1] -lt [int]$requiredParts[1]) { return $false }
    
    # Comparar versión de parche
    if ([int]$currentParts[2] -ge [int]$requiredParts[2]) { return $true }
    return $false
}

# Verificar versión de Docker
function Check-DockerVersion {
    Log "INFO" "Verificando versión de Docker..."
    
    try {
        # Verificar que Docker está instalado
        if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
            Log "ERROR" "Docker no está instalado o no está en el PATH"
            return $false
        }
        
        # Obtener versión de Docker
        $dockerVersion = (docker version --format '{{.Server.Version}}' 2>$null)
        if (-not $dockerVersion) {
            $dockerVersion = (docker version | Select-String -Pattern 'Version:' | Select-Object -First 1).ToString().Split(':')[1].Trim()
        }
        
        Log "DEBUG" "Versión de Docker detectada: $dockerVersion"
        
        # Comparar versiones
        if (-not (Compare-Versions -Current $dockerVersion -Required $MIN_DOCKER_VERSION)) {
            Log "ERROR" "La versión de Docker ($dockerVersion) es inferior a la mínima requerida ($MIN_DOCKER_VERSION)"
            return $false
        }
        
        Log "SUCCESS" "Versión de Docker ($dockerVersion) cumple con los requisitos"
        
        # Verificar si Docker Compose está integrado (V2) o instalado separadamente
        $composeVersion = ""
        try {
            $composeVersion = (docker compose version --short 2>$null).Trim()
        } catch {
            try {
                $composeVersion = (docker-compose version --short 2>$null).Trim()
            } catch {
                Log "ERROR" "No se pudo detectar Docker Compose"
                return $false
            }
        }
        
        # Eliminar 'v' inicial si existe
        $composeVersion = $composeVersion -replace '^v', ''
        Log "DEBUG" "Versión de Docker Compose detectada: $composeVersion"
        
        # Comparar versiones
        if (-not (Compare-Versions -Current $composeVersion -Required $MIN_COMPOSE_VERSION)) {
            Log "ERROR" "La versión de Docker Compose ($composeVersion) es inferior a la mínima requerida ($MIN_COMPOSE_VERSION)"
            return $false
        }
        
        Log "SUCCESS" "Versión de Docker Compose ($composeVersion) cumple con los requisitos"
        return $true
    } catch {
        Log "ERROR" "Error al verificar la versión de Docker: $_"
        return $false
    }
}

# Verificar prerrequisitos
function Check-Prerequisites {
    Log "INFO" "Verificando herramientas requeridas..."
    
    $missingTools = @()
    
    # Verificar Docker
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        $missingTools += "Docker (https://docs.docker.com/desktop/windows/install/)"
    } else {
        Log "DEBUG" "Docker encontrado"
    }
    
    # Verificar curl
    if (-not (Get-Command curl -ErrorAction SilentlyContinue)) {
        $missingTools += "curl (Instalar con: winget install curl)"
    } else {
        Log "DEBUG" "curl encontrado"
    }
    
    # Verificar Docker Compose (podría estar integrado con Docker)
    if (-not ((Get-Command docker -ErrorAction SilentlyContinue) -and (docker compose version 2>$null))) {
        if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
            $missingTools += "Docker Compose (incluido con Docker Desktop para Windows)"
        }
    } else {
        Log "DEBUG" "Docker Compose encontrado"
    }
    
    if ($missingTools.Count -gt 0) {
        Log "ERROR" "Las siguientes herramientas no están instaladas:"
        foreach ($tool in $missingTools) {
            Log "ERROR" "  - $tool"
        }
        Log "ERROR" "Por favor, instala las herramientas faltantes y vuelve a ejecutar el script"
        return $false
    }
    
    # Verificar versiones de Docker y Docker Compose
    if (-not (Check-DockerVersion)) {
        return $false
    }
    
    Log "SUCCESS" "Todas las herramientas requeridas están instaladas"
    return $true
}

# Configurar archivo .env
function Setup-EnvFile {
    Log "INFO" "Configurando archivo de variables de entorno..."
    
    if (-not (Test-Path ".env" -PathType Leaf)) {
        if (Test-Path ".env.example" -PathType Leaf) {
            Copy-Item ".env.example" ".env"
            Log "SUCCESS" "Archivo .env creado a partir del ejemplo"
            
            # Comprobar si hay variables personalizables
            Log "INFO" "Las siguientes variables pueden requerir personalización:"
            $domainBase = (Get-Content ".env.example" | Select-String "DOMAIN_BASE=").ToString().Split('=')[1]
            Log "INFO" "  - DOMAIN_BASE (actualmente: $domainBase)"
            Log "INFO" "  - TRAEFIK_DASHBOARD_USER/PASSWORD"
            Log "INFO" "  - MYSQL_ROOT_PASSWORD"
            Log "INFO" "Puedes modificar estas variables en el archivo .env según tus necesidades"
        } else {
            Log "ERROR" "No se encontró el archivo .env.example"
            exit 1
        }
    } else {
        Log "INFO" "El archivo .env ya existe, se conservará la configuración actual"
    }
    
    # Cargar variables de entorno
    Log "INFO" "Cargando variables de entorno desde .env..."
    Get-Content ".env" | ForEach-Object {
        if ($_ -match "^([^#=]+)=(.*)$") {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            # Eliminar comillas si existen
 $value = $value -replace "^[`"']|[`"']$", ""
            [Environment]::SetEnvironmentVariable($name, $value, "Process")
        }
    }

    # Generar hash de contraseña para Traefik Dashboard
    Log "INFO" "Generando hash de contraseña para Traefik Dashboard..."
    if ($env:TRAEFIK_DASHBOARD_USER -and $env:TRAEFIK_DASHBOARD_PASSWORD) {
        # En Windows, usaremos htpasswd.exe si está disponible, o generaremos mediante .NET
        $traefik_auth = ""
        
        if (Get-Command htpasswd -ErrorAction SilentlyContinue) {
            $traefik_auth = htpasswd -nb $env:TRAEFIK_DASHBOARD_USER $env:TRAEFIK_DASHBOARD_PASSWORD
        } else {
            # Método alternativo usando .NET
            Log "WARNING" "htpasswd no encontrado, usando método alternativo para generar credenciales"
            
            # Crear hash MD5 con sal (similar a htpasswd con formato apr1)
            Add-Type -AssemblyName System.Web
            $salt = -join ((65..90) + (97..122) | Get-Random -Count 8 | ForEach-Object { [char]$_ })
            $hash = [System.Web.Security.FormsAuthentication]::HashPasswordForStoringInConfigFile($env:TRAEFIK_DASHBOARD_PASSWORD + $salt, "MD5")
            $traefik_auth = "$($env:TRAEFIK_DASHBOARD_USER):$($hash)"
        }
        
        # Actualizar el archivo .env con el nuevo hash
        $envContent = Get-Content ".env"
        $envContent = $envContent -replace "^TRAEFIK_DASHBOARD_AUTH=.*$", "TRAEFIK_DASHBOARD_AUTH=$traefik_auth"
        $envContent | Set-Content ".env"
        
        Log "SUCCESS" "Hash de contraseña generado y actualizado en .env"
    } else {
        Log "WARNING" "No se pudieron generar credenciales: usuario o contraseña no definidos en .env"
    }
}

# Validar variables de entorno
function Validate-EnvVariables {
    Log "INFO" "Validando variables de entorno críticas..."
    
    $requiredVars = @(
        "NETWORK_NAME",
        "DOMAIN_BASE",
        "TRAEFIK_CONTAINER_NAME",
        "MYSQL_CONTAINER_NAME",
        "MONGO_CONTAINER_NAME",
        "MYSQL_ROOT_PASSWORD",
        "TRAEFIK_DOMAIN"
    )
    
    $middlewareVars = @(
        "AUTH_MIDDLEWARE_NAME",
        "COMPRESS_MIDDLEWARE_NAME",
        "SECURITY_HEADERS_MIDDLEWARE_NAME",
        "RATE_LIMIT_MIDDLEWARE_NAME",
        "HTTPS_REDIRECT_MIDDLEWARE_NAME",
        "CORS_MIDDLEWARE_NAME"
    )
    
    $missingVars = @()
    $warningVars = @()
    
    # Verificar variables críticas
    foreach ($var in $requiredVars) {
        $value = [Environment]::GetEnvironmentVariable($var)
        if ([string]::IsNullOrEmpty($value)) {
            $missingVars += $var
        }
    }
    
    # Verificar variables de middleware (advertencias)
    foreach ($var in $middlewareVars) {
        $value = [Environment]::GetEnvironmentVariable($var)
        if ([string]::IsNullOrEmpty($value)) {
            $warningVars += $var
        }
    }
    
    # Mostrar advertencias para variables no críticas
    if ($warningVars.Count -gt 0) {
        Log "WARNING" "Las siguientes variables opcionales no están definidas en el archivo .env:"
        foreach ($var in $warningVars) {
            Log "WARNING" "  - $var (recomendado para configuración completa de middlewares)"
        }
    }
    
    # Detener si faltan variables críticas
    if ($missingVars.Count -gt 0) {
        Log "ERROR" "Faltan las siguientes variables críticas en el archivo .env:"
        foreach ($var in $missingVars) {
            Log "ERROR" "  - $var"
        }
        Log "ERROR" "Por favor, completa la configuración en el archivo .env"
        exit 1
    }
    
    Log "SUCCESS" "Todas las variables críticas están definidas"
}

# Copiar archivo si no existe
function Copy-IfNotExists {
    param (
        [string]$SourceFile,
        [string]$DestFile,
        [string]$Description
    )
    
    if (-not (Test-Path $DestFile -PathType Leaf)) {
        if (Test-Path $SourceFile -PathType Leaf) {
            Copy-Item $SourceFile $DestFile
            Log "SUCCESS" "$Description: Archivo creado desde $SourceFile"
        } else {
            Log "ERROR" "Archivo de origen $SourceFile no encontrado"
            return $false
        }
    } else {
        Log "INFO" "$Description: El archivo $DestFile ya existe, se mantendrá la configuración actual"
    }
    
    return $true
}

# Crear directorios necesarios
function Create-Directories {
    Log "INFO" "Creando estructura de directorios..."
    
    $directories = @(
        "traefik\config\certs",
        "traefik\logs",
        "mysql\config",
        "mysql\logs",
        "mongo\config",
        "mongo\logs",
        "prometheus",
        "grafana\provisioning\datasources",
        "grafana\provisioning\dashboards",
        "loki",
        "promtail",
        "projects"
    )
    
    foreach ($dir in $directories) {
        if (-not (Test-Path $dir -PathType Container)) {
            New-Item -Path $dir -ItemType Directory -Force | Out-Null
            Log "SUCCESS" "Directorio $dir creado"
        } else {
            Log "INFO" "Directorio $dir ya existe"
        }
    }
}

# Copiar archivos de configuración
function Copy-ConfigFiles {
    Log "INFO" "Copiando archivos de configuración..."
    
    # Archivos principales de infraestructura
    Copy-IfNotExists "docker-compose.example.yml" "docker-compose.yml" "Docker Compose principal"
    
    # Traefik
    Copy-IfNotExists "traefik\config\traefik.example.yml" "traefik\config\traefik.yml" "Configuración de Traefik"
    Copy-IfNotExists "traefik\config\dynamic.example.yml" "traefik\config\dynamic.yml" "Configuración dinámica de Traefik"
    Copy-IfNotExists "traefik\config\middleware.example.yml" "traefik\config\middleware.yml" "Configuración de middleware de Traefik"
    
    # MySQL y MongoDB
    Copy-IfNotExists "mysql\config\my.example.cnf" "mysql\config\my.cnf" "Configuración de MySQL"
    Copy-IfNotExists "mongo\config\mongod.example.conf" "mongo\config\mongod.conf" "Configuración de MongoDB"
    
    # Script de creación de proyectos
    Copy-IfNotExists "create-project.example.sh" "create-project.ps1" "Script de creación de proyectos"
}

# Configurar mkcert para Windows
function Setup-Mkcert {
    Log "INFO" "Configurando mkcert para certificados SSL..."

    # Verificar si mkcert está instalado
    if (-not (Get-Command mkcert -ErrorAction SilentlyContinue)) {
        Log "WARNING" "mkcert no está instalado, procediendo a instalarlo..."
        
        # Crear directorio temporal
        $tempDir = Join-Path $env:TEMP "mkcert_install"
        New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
        
        # Descargar mkcert de GitHub
        $mkcertUrl = "https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-windows-amd64.exe"
        $mkcertPath = Join-Path $tempDir "mkcert.exe"
        
        Log "INFO" "Descargando mkcert desde GitHub..."
        try {
            Invoke-WebRequest -Uri $mkcertUrl -OutFile $mkcertPath
        }
        catch {
            Log "ERROR" "Error al descargar mkcert: $_"
            exit 1
        }
        
        # Crear directorio en Program Files
        $programDir = "C:\Program Files\mkcert"
        if (-not (Test-Path $programDir -PathType Container)) {
            New-Item -Path $programDir -ItemType Directory -Force | Out-Null
        }
        
        # Copiar el ejecutable
        Copy-Item $mkcertPath (Join-Path $programDir "mkcert.exe")
        
        # Agregar a PATH
        $currentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
        if ($currentPath -notlike "*$programDir*") {
            [Environment]::SetEnvironmentVariable("PATH", "$currentPath;$programDir", "Machine")
            # Actualizar PATH en la sesión actual
            $env:PATH = "$env:PATH;$programDir"
        }
        
        Log "SUCCESS" "mkcert instalado correctamente en $programDir"
        
        # Limpiar directorio temporal
        Remove-Item -Path $tempDir -Recurse -Force
    } else {
        Log "INFO" "mkcert ya está instalado en el sistema"
    }
    
    # Ejecutar mkcert -install para configurar la CA local
    Log "INFO" "Instalando autoridad certificadora local..."
    try {
        $output = & mkcert -install 2>&1
        Log "DEBUG" "Salida de mkcert -install: $output"
        Log "SUCCESS" "Autoridad certificadora local configurada correctamente"
    } catch {
        Log "ERROR" "Error al instalar la autoridad certificadora local: $_"
        exit 1
    }
}

# Generar certificados SSL
function Generate-SSLCertificates {
    Log "INFO" "Generando certificados SSL..."
    
    $certDir = "traefik\config\certs"
    $certFile = Join-Path $certDir "cert.pem"
    $keyFile = Join-Path $certDir "key.pem"
    
    # Verificar si ya existen certificados
    if ((Test-Path $certFile) -and (Test-Path $keyFile)) {
        Log "INFO" "Los certificados SSL ya existen en $certDir"
        
        # Verificar validez de los certificados existentes
        try {
            $certInfo = & openssl x509 -enddate -noout -in $certFile 2>&1
            $certExpiry = $certInfo -replace "notAfter=", ""
            Log "INFO" "Certificado actual expira: $certExpiry"
        } catch {
            Log "WARNING" "No se pudo verificar la fecha de expiración del certificado actual"
        }
        
        # Preguntar si desea regenerar los certificados
        $regenerate = Read-Host "¿Deseas regenerar los certificados SSL? (s/n)"
        if ($regenerate -match "^[Ss]$") {
            Log "INFO" "Regenerando certificados SSL..."
            Remove-Item $certFile -Force -ErrorAction SilentlyContinue
            Remove-Item $keyFile -Force -ErrorAction SilentlyContinue
        } else {
            Log "INFO" "Manteniendo certificados SSL existentes"
            return
        }
    }
    
    # Lista de dominios a incluir en el certificado
    $domains = @(
        "*.$env:DOMAIN_BASE",
        "$env:DOMAIN_BASE",
        "$env:TRAEFIK_DOMAIN",
        "$env:MAILHOG_DOMAIN",
        "prometheus.$env:DOMAIN_BASE",
        "grafana.$env:DOMAIN_BASE"
    )
    
    # Construir comando mkcert con todos los dominios
    $mkcertCmd = "mkcert -cert-file `"$certFile`" -key-file `"$keyFile`""
    foreach ($domain in $domains) {
        $mkcertCmd += " `"$domain`""
    }
    
    # Generar certificados
    Log "INFO" "Generando nuevos certificados SSL para $($domains.Count) dominios..."
    Log "DEBUG" "Comando: $mkcertCmd"
    
    try {
        Invoke-Expression $mkcertCmd | Out-String | ForEach-Object { Log "DEBUG" $_ }
        
        # Verificar que los certificados se hayan generado correctamente
        if ((Test-Path $certFile) -and (Test-Path $keyFile)) {
            # Mostrar información del certificado
            Log "INFO" "Información del certificado generado:"
            $certInfo = & openssl x509 -in $certFile -noout -subject -issuer -dates 2>&1
            $certInfo | ForEach-Object { Log "INFO" "  $_" }
            
            Log "SUCCESS" "Certificados SSL generados correctamente en $certDir"
        } else {
            Log "ERROR" "No se pudieron generar los certificados SSL"
            exit 1
        }
    } catch {
        Log "ERROR" "Error al generar certificados SSL: $_"
        exit 1
    }
}

# Crear red Docker
function Create-DockerNetwork {
    Log "INFO" "Verificando red Docker $env:NETWORK_NAME..."
    
    # Comprobar si la red ya existe
    $networkExists = (docker network ls --format "{{.Name}}" | Select-String -Pattern "^$env:NETWORK_NAME$" -Quiet)
    
    if ($networkExists) {
        Log "INFO" "La red Docker $env:NETWORK_NAME ya existe"
    } else {
        # Crear la red
        try {
            docker network create $env:NETWORK_NAME | Out-Null
            Log "SUCCESS" "Red Docker $env:NETWORK_NAME creada correctamente"
        } catch {
            Log "ERROR" "Error al crear la red Docker $env:NETWORK_NAME: $_"
            exit 1
        }
    }
}

# Iniciar servicios
function Start-Services {
    Log "INFO" "Iniciando servicios de infraestructura..."
    
    # Verificar si docker-compose.yml existe
    if (-not (Test-Path "docker-compose.yml" -PathType Leaf)) {
        Log "ERROR" "No se encontró el archivo docker-compose.yml"
        exit 1
    }
    
    # Verificar sintaxis del archivo docker-compose.yml
    Log "INFO" "Verificando sintaxis de docker-compose.yml..."
    try {
        docker-compose config | Out-Null
    } catch {
        Log "ERROR" "Error en la sintaxis del archivo docker-compose.yml: $_"
        exit 1
    }
    
    # Detener servicios existentes si están en ejecución
    Log "INFO" "Deteniendo servicios existentes si están en ejecución..."
    try {
        docker-compose down --remove-orphans
    } catch {
Log "WARNING" "Error al detener servicios existentes: $_"
        # Continuamos de todos modos
    }
    
    # Iniciar servicios
    Log "INFO" "Iniciando servicios..."
    try {
        docker-compose up -d
        Log "SUCCESS" "Servicios de infraestructura iniciados correctamente"
    } catch {
        Log "ERROR" "Error al iniciar los servicios con docker-compose: $_"
        exit 1
    }
}

# Verificar servicios en ejecución
function Verify-RunningServices {
    Log "INFO" "Verificando estado de los servicios principales..."
    
    # Tiempo de espera para que los servicios se inicien completamente
    $waitTime = 15
    Log "INFO" "Esperando $waitTime segundos para que los servicios se inicien completamente..."
    Start-Sleep -Seconds $waitTime
    
    # Servicios esenciales que deben estar en ejecución
    $requiredServices = @(
        $env:TRAEFIK_CONTAINER_NAME,
        $env:MYSQL_CONTAINER_NAME,
        $env:MONGO_CONTAINER_NAME,
        $env:MAILHOG_CONTAINER_NAME
    )
    
    if ($env:PROMETHEUS_ENABLED -eq "true") {
        $requiredServices += $env:PROMETHEUS_CONTAINER_NAME
    }
    
    if ($env:GRAFANA_ENABLED -eq "true") {
        $requiredServices += $env:GRAFANA_CONTAINER_NAME
    }
    
    if ($env:LOKI_ENABLED -eq "true") {
        $requiredServices += $env:LOKI_CONTAINER_NAME
        $requiredServices += $env:PROMTAIL_CONTAINER_NAME
    }

    $failedServices = @()
    
    foreach ($service in $requiredServices) {
        $serviceRunning = docker ps --format "{{.Names}}" | Select-String -Pattern "^$service$" -Quiet
        
        if (-not $serviceRunning) {
            $failedServices += $service
            Log "ERROR" "Servicio $service no está en ejecución"
            
            # Mostrar los logs del servicio fallido
            Log "INFO" "Logs de $service:"
            docker logs $service 2>&1 | Select-Object -Last 20 | ForEach-Object { Log "INFO" $_ }
        } else {
            Log "SUCCESS" "Servicio $service está en ejecución"
            
            # Verificar estado de healthcheck si está configurado
            try {
                $healthStatus = docker inspect $service --format "{{.State.Health.Status}}" 2>$null
                
                if ($healthStatus -eq "healthy") {
                    Log "SUCCESS" "Healthcheck de $service: healthy"
                } elseif ($healthStatus -eq "starting") {
                    Log "WARNING" "Healthcheck de $service: starting (aún inicializando)"
                } elseif ($healthStatus -eq "unhealthy") {
                    Log "ERROR" "Healthcheck de $service: unhealthy"
                    $failedServices += "$service (unhealthy)"
                }
            } catch {
                # El servicio podría no tener healthcheck configurado
                Log "DEBUG" "No se pudo obtener estado de healthcheck para $service"
            }
        }
    }
    
    if ($failedServices.Count -gt 0) {
        Log "ERROR" "Los siguientes servicios presentan problemas: $($failedServices -join ', ')"
        Log "ERROR" "Revisa los logs con 'docker logs <nombre-contenedor>' para más detalles"
        exit 1
    }
    
    Log "SUCCESS" "Todos los servicios principales están en ejecución"
}

# Mostrar mensaje de éxito
function Display-SuccessMessage {
    Log "INFO" ""
    Log "INFO" "=============================================="
    Log "INFO" "      🚀 WILODEV DOCK - RESUMEN DE CONFIGURACIÓN      "
    Log "INFO" "=============================================="
    Log "INFO" ""
    
    # Información general
    Log "INFO" "🔹 General:"
    Log "INFO" "   • Red: $env:NETWORK_NAME"
    Log "INFO" "   • Dominio base: $env:DOMAIN_BASE"
    Log "INFO" ""
    
    # Traefik
    Log "INFO" "🔹 Traefik:"
    Log "INFO" "   • Dashboard: https://$env:TRAEFIK_DOMAIN"
    Log "INFO" "   • Usuario: $env:TRAEFIK_DASHBOARD_USER"
    Log "INFO" "   • Puerto HTTP: $env:TRAEFIK_HTTP_PORT"
    Log "INFO" "   • Puerto HTTPS: $env:TRAEFIK_HTTPS_PORT"
    Log "INFO" ""
    
    # MySQL
    Log "INFO" "🔹 MySQL:"
    Log "INFO" "   • Host: localhost (para aplicaciones externas) o $env:MYSQL_CONTAINER_NAME (para contenedores)"
    Log "INFO" "   • Puerto: $env:MYSQL_PORT"
    Log "INFO" "   • Base de datos: $env:MYSQL_DATABASE"
    Log "INFO" "   • Usuario: $env:MYSQL_USER"
    Log "INFO" ""
    
    # MongoDB
    Log "INFO" "🔹 MongoDB:"
    Log "INFO" "   • Host: localhost (para aplicaciones externas) o $env:MONGO_CONTAINER_NAME (para contenedores)"
    Log "INFO" "   • Puerto: $env:MONGO_PORT"
    Log "INFO" "   • Base de datos: $env:MONGO_INITDB_DATABASE"
    Log "INFO" "   • Usuario: $env:MONGO_INITDB_ROOT_USERNAME"
    Log "INFO" ""
    
    # MailHog
    Log "INFO" "🔹 MailHog:"
    Log "INFO" "   • Interfaz web: https://$env:MAILHOG_DOMAIN"
    Log "INFO" "   • Puerto SMTP: $env:MAILHOG_SMTP_PORT"
    Log "INFO" "   • Host SMTP: localhost (para aplicaciones externas) o $env:MAILHOG_CONTAINER_NAME (para contenedores)"
    Log "INFO" ""
    
    # Observabilidad
    Log "INFO" "🔹 Observabilidad:"
    Log "INFO" "   • Prometheus: https://prometheus.$env:DOMAIN_BASE"
    Log "INFO" "   • Grafana: https://grafana.$env:DOMAIN_BASE"
    Log "INFO" "   • Usuario Grafana: admin"
    Log "INFO" "   • Contraseña Grafana: admin123"
    Log "INFO" ""
    
    # Instrucciones adicionales
    Log "INFO" "🔹 Instrucciones para crear un nuevo proyecto:"
    Log "INFO" "   • Ejecuta: .\create-project.ps1"
    Log "INFO" ""
    Log "INFO" "🔹 Para detener todos los servicios:"
    Log "INFO" "   • Ejecuta: docker-compose down"
    Log "INFO" ""
    Log "INFO" "🔹 Para reiniciar todos los servicios:"
    Log "INFO" "   • Ejecuta: docker-compose restart"
    Log "INFO" ""
    
    Log "SUCCESS" "✅ Configuración completada con éxito. ¡Disfruta de tu entorno de desarrollo WiloDev Dock!"
    Log "INFO" ""

    # Instrucciones específicas para Windows
    Log "INFO" "🔹 Notas específicas para Windows:"
    Log "INFO" "   • Para acceder a los dominios locales, asegúrate de que estén en tu archivo hosts"
    Log "INFO" "   • Puedes editar C:\Windows\System32\drivers\etc\hosts como administrador"
    Log "INFO" "   • Agrega: 127.0.0.1 $env:TRAEFIK_DOMAIN"
    Log "INFO" "   • Agrega: 127.0.0.1 $env:MAILHOG_DOMAIN"
    Log "INFO" "   • Agrega: 127.0.0.1 prometheus.$env:DOMAIN_BASE"
    Log "INFO" "   • Agrega: 127.0.0.1 grafana.$env:DOMAIN_BASE"
    Log "INFO" ""
}

# Verificar y actualizar archivo hosts (específico para Windows)
function Update-HostsFile {
    Log "INFO" "Verificando archivo hosts para dominios locales..."
    
    $hostsFile = "C:\Windows\System32\drivers\etc\hosts"
    $domainsToAdd = @(
        "127.0.0.1 $env:TRAEFIK_DOMAIN",
        "127.0.0.1 $env:MAILHOG_DOMAIN",
        "127.0.0.1 prometheus.$env:DOMAIN_BASE",
        "127.0.0.1 grafana.$env:DOMAIN_BASE"
    )
    
    $currentHosts = Get-Content $hostsFile -ErrorAction SilentlyContinue
    $needsUpdating = $false
    
    foreach ($domainEntry in $domainsToAdd) {
        if ($currentHosts -notcontains $domainEntry) {
            $needsUpdating = $true
        }
    }
    
    if ($needsUpdating) {
        Log "INFO" "Se necesita actualizar el archivo hosts con los dominios locales"
        Log "INFO" "Se requieren privilegios de administrador para actualizar el archivo hosts"
        
        $response = Read-Host "¿Deseas actualizar automáticamente el archivo hosts? (s/n)"
        
        if ($response -match "^[Ss]$") {
            try {
                # Crear copia de seguridad
                Copy-Item $hostsFile "$hostsFile.bak" -Force
                
                # Agregar entradas
                foreach ($domainEntry in $domainsToAdd) {
                    if ($currentHosts -notcontains $domainEntry) {
                        Add-Content -Path $hostsFile -Value "`n$domainEntry" -Force
                        Log "SUCCESS" "Agregado: $domainEntry al archivo hosts"
                    }
                }
                
                Log "SUCCESS" "Archivo hosts actualizado correctamente"
            } catch {
                Log "ERROR" "Error al actualizar el archivo hosts: $_"
                Log "INFO" "Deberás actualizarlo manualmente como administrador"
            }
        } else {
            Log "INFO" "Por favor, actualiza manualmente el archivo hosts"
            Log "INFO" "Agrega las siguientes líneas a $hostsFile:"
            foreach ($domainEntry in $domainsToAdd) {
                Log "INFO" "  $domainEntry"
            }
        }
    } else {
        Log "SUCCESS" "El archivo hosts ya contiene todas las entradas necesarias"
    }
}

# Función principal
function Main {
    # Inicializar archivo de log
    "" | Out-File -FilePath $LOG_FILE -Force
    
    Log "INFO" "========================================"
    Log "INFO" "🐳 WiloDev Dock - Iniciando configuración (v$SCRIPT_VERSION)"
    Log "INFO" "========================================"
    
    # Fase 1: Verificaciones
    Measure-ExecutionTime -Description "Verificación de privilegios de administrador" -ScriptBlock { Check-AdminPrivileges }
    Measure-ExecutionTime -Description "Verificación de estructura" -ScriptBlock { Check-FileStructure }
    Measure-ExecutionTime -Description "Verificación de permisos de archivos" -ScriptBlock { Check-FilePermissions }
    Measure-ExecutionTime -Description "Verificación de espacio en disco" -ScriptBlock { Check-DiskSpace }
    Measure-ExecutionTime -Description "Verificación de requisitos" -ScriptBlock { Check-Prerequisites }
    
    # Fase 2: Preparación
    Measure-ExecutionTime -Description "Creación de directorios" -ScriptBlock { Create-Directories }
    Measure-ExecutionTime -Description "Configuración de variables de entorno" -ScriptBlock { Setup-EnvFile }
    Measure-ExecutionTime -Description "Validación de variables" -ScriptBlock { Validate-EnvVariables }
    Measure-ExecutionTime -Description "Copia de archivos de configuración" -ScriptBlock { Copy-ConfigFiles }
    
    # Fase 3: Configuración SSL
    Measure-ExecutionTime -Description "Configuración de mkcert" -ScriptBlock { Setup-Mkcert }
    Measure-ExecutionTime -Description "Generación de certificados SSL" -ScriptBlock { Generate-SSLCertificates }
    
    # Fase 4: Despliegue
    Measure-ExecutionTime -Description "Creación de red Docker" -ScriptBlock { Create-DockerNetwork }
    Measure-ExecutionTime -Description "Inicio de servicios" -ScriptBlock { Start-Services }
    Measure-ExecutionTime -Description "Verificación de servicios" -ScriptBlock { Verify-RunningServices }
    
    # Fase 5: Configuración específica de Windows
    Measure-ExecutionTime -Description "Actualización de archivo hosts" -ScriptBlock { Update-HostsFile }
    
    # Fase 6: Finalización
    Display-SuccessMessage
    
    Log "INFO" "========================================"
    Log "SUCCESS" "✅ Configuración completada con éxito"
    Log "INFO" "========================================"
    Log "INFO" "Para más detalles, consulta el archivo de log: $LOG_FILE"
}

# Verificar si se está ejecutando en modo debug
if ($args -contains "--debug") {
    $env:DEBUG = "true"
    Log "INFO" "Modo debug activado"
}

# Ejecutar la función principal
Main