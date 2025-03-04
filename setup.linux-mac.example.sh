#!/bin/bash

# ==========================================
# WiloDev Dock - Script de Configuración
# ------------------------------------------
# Autor: WiloDev (@wilodev)
# Versión: 1.0.0
# Última actualización: 2025-03-02
#
# Este script configura la infraestructura base para el entorno WiloDev Dock:
# - Traefik como proxy inverso con SSL
# - MySQL como servidor de base de datos relacional
# - MongoDB como servidor de base de datos NoSQL
# - MailHog para pruebas de correo electrónico
#
# El script NO configura proyectos específicos de Laravel o Symfony.
# Esa configuración se maneja con create-project.sh después de ejecutar este script.
# ==========================================

# Activar opciones estrictas de shell
set -euo pipefail

# --- Definición de colores para logs ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_VERSION="1.0.1"
LOG_FILE="setup.log"
MIN_DOCKER_VERSION="20.10.0"
MIN_COMPOSE_VERSION="2.0.0"
REQUIRED_SPACE_MB=5120  # 5GB

# --- Manejo de errores ---
trap 'handle_error $? $LINENO' ERR
trap cleanup_on_exit EXIT

# --- Función: handle_error ---
# Maneja errores que ocurran durante la ejecución del script
# Parámetros:
#   $1: Código de salida del comando que falló
#   $2: Número de línea donde ocurrió el error
handle_error() {
    local exit_code=$1
    local line_number=$2
    log "ERROR" "Script falló en la línea $line_number con código de salida $exit_code"
    
    # Intentar obtener información de depuración adicional
    if command -v caller >/dev/null 2>&1; then
        local caller_info
        caller_info=$(caller)
        log "ERROR" "Información adicional: ${caller_info}"
    fi
    
    log "INFO" "Consulte ${LOG_FILE} para más detalles"
    cleanup_on_exit
    exit $exit_code
}

# --- Función: log ---
# Muestra mensajes de log con nivel y timestamp
# Parámetros:
#   $1: Nivel de log (ERROR, WARNING, SUCCESS, INFO)
#   $2: Mensaje a mostrar
log() {
    local level=$1
    local message=$2
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Formatear mensaje para consola
    case $level in
        "ERROR")   echo -e "${RED}[${timestamp}] ERROR: ${message}${NC}" ;;
        "WARNING") echo -e "${YELLOW}[${timestamp}] WARNING: ${message}${NC}" ;;
        "SUCCESS") echo -e "${GREEN}[${timestamp}] SUCCESS: ${message}${NC}" ;;
        "INFO")    echo -e "${BLUE}[${timestamp}] INFO: ${message}${NC}" ;;
        "DEBUG")   if [[ "${DEBUG:-false}" == "true" ]]; then
                     echo -e "${CYAN}[${timestamp}] DEBUG: ${message}${NC}"
                   fi
                   ;;
    esac
    
    # Guardar todos los mensajes en el archivo de log (sin color)
    echo "[${timestamp}] ${level}: ${message}" >> "${LOG_FILE}"
}

# --- Función: measure_execution_time ---
# Mide el tiempo de ejecución de una función o comando
# Parámetros:
#   $1: Descripción de la operación
#   $@: Función o comando a ejecutar
measure_execution_time() {
    local description=$1
    shift
    local start_time end_time duration
    start_time=$(date +%s)
    "$@"
    end_time=$(date +%s)
    duration=$((end_time - start_time))
    log "INFO" "⏱️ ${description} completado en ${duration} segundos"
}

# --- Función: check_root ---
# Verifica que el script NO se esté ejecutando como root/sudo
# Esto es importante porque los archivos creados como root pueden causar
# problemas de permisos más adelante
check_root() {
    log "INFO" "Verificando permisos de ejecución..."
    
    if [ "$EUID" -eq 0 ]; then
        log "ERROR" "Este script no debe ejecutarse como root o con sudo"
        log "ERROR" "Por favor, ejecuta el script como usuario normal"
        exit 1
    fi
    
    log "SUCCESS" "Permisos de ejecución correctos"
}

# --- Función: check_file_structure ---
# Verifica la estructura de archivos y directorios requeridos
# Solo verifica la infraestructura base, no proyectos específicos
check_file_structure() {
    log "INFO" "Verificando estructura de archivos..."
    
    local required_dirs=(
        "mongo/config"
        "mysql/config"
        "traefik/config"
        "traefik/config/certs"
    )
    
    local required_files=(
        "docker-compose.example.yml"
        "traefik/config/traefik.example.yml"
        "traefik/config/dynamic.example.yml"
        "traefik/config/middleware.example.yml"
        "mysql/config/my.example.cnf"
        "mongo/config/mongod.example.conf"
        ".env.example"
    )
    
    local missing=false
    
    # Verificar directorios
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            log "ERROR" "Directorio requerido no encontrado: $dir"
            missing=true
        else
            log "DEBUG" "Directorio encontrado: $dir"
        fi
    done
    
    # Verificar archivos
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            log "ERROR" "Archivo requerido no encontrado: $file"
            missing=true
        else
            log "DEBUG" "Archivo encontrado: $file"
        fi
    done
    
    if [ "$missing" = true ]; then
        log "ERROR" "Estructura de archivos incompleta"
        exit 1
    fi
    
    log "SUCCESS" "Estructura de archivos verificada correctamente"
}

# --- Función: cleanup_on_exit ---
# Limpia los archivos generados en caso de error durante la ejecución
# Esto evita que queden archivos corruptos o incompletos
# Limpia los archivos generados en caso de error durante la ejecución
cleanup_on_exit() {
    # Solo limpiamos si hay un error y no estamos en modo debug
    if [[ $? -ne 0 && "${DEBUG:-false}" != "true" ]]; then
        log "WARNING" "Limpiando archivos generados debido a error..."
        
        # Lista de archivos a limpiar si falló la configuración
        local files_to_clean=(
            "docker-compose.yml.tmp"
        )
        
        for file in "${files_to_clean[@]}"; do
            if [ -f "$file" ]; then
                rm "$file"
                log "INFO" "Eliminado: $file"
            fi
        done
        
        log "INFO" "Limpieza completada"
    else
        log "DEBUG" "No se requiere limpieza - salida normal o modo debug activo"
    fi
}

# --- Función: check_file_permissions ---
# Verifica los permisos de los directorios críticos
# Esto asegura que podamos escribir en ellos durante la configuración
check_file_permissions() {
    log "INFO" "Verificando permisos de archivos..."
    
    local dirs_to_check=(
        "traefik/config/certs"
        "mysql/config"
        "mongo/config"
    )
    
    for dir in "${dirs_to_check[@]}"; do
        if [ ! -w "$dir" ]; then
            log "ERROR" "No hay permisos de escritura en: $dir"
            
            # Intentar diagnosticar el problema
            ls -la "$dir"
            log "INFO" "Usuario actual: $(whoami)"
            log "INFO" "Grupo actual: $(id -gn)"
            
            # Sugerir solución
            log "INFO" "Para resolver: chmod -R u+w $dir"
            
            return 1
        else
            log "DEBUG" "Permisos de escritura correctos en: $dir"
        fi
    done
    
    log "SUCCESS" "Permisos de archivos verificados correctamente"
}
# --- Función: check_disk_space ---
# Verifica que haya suficiente espacio en disco para la instalación
# La infraestructura base requiere aproximadamente 5GB
check_disk_space() {
    log "INFO" "Verificando espacio en disco..."
    
    local available_space
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        available_space=$(df -m . | awk 'NR==2 {print $4}')
    else
        # Linux
        available_space=$(df -m . | awk 'NR==2 {print $4}')
    fi
    
    log "DEBUG" "Espacio disponible: ${available_space}MB - Requerido: ${REQUIRED_SPACE_MB}MB"
    
    if [ "$available_space" -lt "$REQUIRED_SPACE_MB" ]; then
        log "ERROR" "Espacio insuficiente en disco. Se requieren al menos ${REQUIRED_SPACE_MB}MB (${REQUIRED_SPACE_MB/1024}GB)"
        log "ERROR" "Espacio disponible: ${available_space}MB (${available_space/1024}GB)"
        return 1
    fi
    
    log "SUCCESS" "Espacio en disco suficiente: ${available_space}MB disponible"
}

# --- Función: check_docker_version ---
# Verifica la versión de Docker y Docker Compose
check_docker_version() {
    log "INFO" "Verificando versión de Docker..."
    
    # Verificar versión de Docker
    local docker_version
    docker_version=$(docker version --format '{{.Server.Version}}' 2>/dev/null || echo "0.0.0")
    log "DEBUG" "Versión de Docker detectada: $docker_version"
    
    # Comparar versiones (simplificado)
    if ! meets_version_requirement "$docker_version" "$MIN_DOCKER_VERSION"; then
        log "ERROR" "La versión de Docker ($docker_version) es inferior a la mínima requerida ($MIN_DOCKER_VERSION)"
        return 1
    fi
    
    log "SUCCESS" "Versión de Docker ($docker_version) cumple con los requisitos"
    
    # Verificar versión de Docker Compose
    local compose_version
    
    # Intentar obtener versión de Docker Compose V2 (integrado con Docker)
    compose_version=$(docker compose version --short 2>/dev/null || echo "")
    
    # Si no funcionó, intentar con la versión standalone
    if [ -z "$compose_version" ]; then
        compose_version=$(docker-compose version --short 2>/dev/null || echo "0.0.0")
    fi
    
    compose_version=${compose_version#v}  # Eliminar 'v' inicial si existe
    log "DEBUG" "Versión de Docker Compose detectada: $compose_version"
    
    # Comparar versiones
    if ! meets_version_requirement "$compose_version" "$MIN_COMPOSE_VERSION"; then
        log "ERROR" "La versión de Docker Compose ($compose_version) es inferior a la mínima requerida ($MIN_COMPOSE_VERSION)"
        return 1
    fi
    
    log "SUCCESS" "Versión de Docker Compose ($compose_version) cumple con los requisitos"
}

# --- Función: meets_version_requirement ---
# Compara dos versiones semánticas
# Parámetros:
#   $1: Versión actual
#   $2: Versión mínima requerida
meets_version_requirement() {
    local current="$1"
    local required="$2"
    
    # Convertir a componentes
    local IFS=.
    read -ra current_parts <<< "$current"
    read -ra required_parts <<< "$required"
    
    # Rellenar con ceros si es necesario
    for i in {0..2}; do
        current_parts[i]=${current_parts[i]:-0}
        required_parts[i]=${required_parts[i]:-0}
    done
    
    # Comparar versión mayor
    if [ "${current_parts[0]}" -gt "${required_parts[0]}" ]; then
        return 0
    elif [ "${current_parts[0]}" -lt "${required_parts[0]}" ]; then
        return 1
    fi
    
    # Comparar versión menor
    if [ "${current_parts[1]}" -gt "${required_parts[1]}" ]; then
        return 0
    elif [ "${current_parts[1]}" -lt "${required_parts[1]}" ]; then
        return 1
    fi
    
    # Comparar versión de parche
    if [ "${current_parts[2]}" -ge "${required_parts[2]}" ]; then
        return 0
    else
        return 1
    fi
}

# --- Función: check_prerequisites ---
# Verifica que las herramientas necesarias estén instaladas
check_prerequisites() {
    log "INFO" "Verificando herramientas requeridas..."
    local missing_tools=()

    # Herramientas esenciales
    declare -A required_tools=(
        ["docker"]="Docker (https://docs.docker.com/get-docker/)"
        ["curl"]="curl (utilidad para transferencia de datos)"
        ["htpasswd"]="htpasswd (parte del paquete apache2-utils en Linux o httpd-tools en CentOS)"
    )
    
    # Verificar cada herramienta
    for tool in "${!required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool (${required_tools[$tool]})")
            log "DEBUG" "Herramienta no encontrada: $tool"
        else
            log "DEBUG" "Herramienta encontrada: $tool"
        fi
    done

    # Comprobar Docker Compose (podría estar integrado con Docker)
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        missing_tools+=("Docker Compose (https://docs.docker.com/compose/install/)")
        log "DEBUG" "Docker Compose no encontrado"
    else
        log "DEBUG" "Docker Compose encontrado"
    fi

    if [ ${#missing_tools[@]} -gt 0 ]; then
        log "ERROR" "Las siguientes herramientas no están instaladas:"
        for tool in "${missing_tools[@]}"; do
            log "ERROR" "  - $tool"
        done
        log "ERROR" "Por favor, instala las herramientas faltantes y vuelve a ejecutar el script"
        exit 1
    fi
    
    # Verificar versiones de Docker y Docker Compose
    check_docker_version
    
    log "SUCCESS" "Todas las herramientas requeridas están instaladas"
}

# --- Función: setup_env_file ---
# Crea el archivo .env a partir del example si no existe
# Este archivo contiene todas las variables de configuración para la infraestructura
setup_env_file() {
    log "INFO" "Configurando archivo de variables de entorno..."
    
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            cp ".env.example" ".env"
            log "SUCCESS" "Archivo .env creado a partir del ejemplo"
            
            # Comprobar si hay variables personalizables que requieren cambios
            log "INFO" "Las siguientes variables pueden requerir personalización:"
            log "INFO" "  - DOMAIN_BASE (actualmente: $(grep DOMAIN_BASE .env.example | cut -d '=' -f2))"
            log "INFO" "  - TRAEFIK_DASHBOARD_USER/PASSWORD"
            log "INFO" "  - MYSQL_ROOT_PASSWORD"
            log "INFO" "Puedes modificar estas variables en el archivo .env según tus necesidades"
        else
            log "ERROR" "No se encontró el archivo .env.example"
            exit 1
        fi
    else
        log "INFO" "El archivo .env ya existe, se conservará la configuración actual"
    fi
    
    # Cargar variables de entorno
    log "INFO" "Cargando variables de entorno desde .env..."
    set -a
    # shellcheck disable=SC1091
    source .env
    set +a

    # Generar hash de contraseña para Traefik Dashboard
    log "INFO" "Generando hash de contraseña para Traefik Dashboard..."
    if [[ -n "${TRAEFIK_DASHBOARD_USER:-}" && -n "${TRAEFIK_DASHBOARD_PASSWORD:-}" ]]; then
        # Usar OpenSSL como alternativa si htpasswd no está disponible
        if command -v htpasswd &> /dev/null; then
            TRAEFIK_DASHBOARD_AUTH=$(htpasswd -nb "${TRAEFIK_DASHBOARD_USER}" "${TRAEFIK_DASHBOARD_PASSWORD}")
        else
            log "WARNING" "htpasswd no encontrado, usando método alternativo para generar credenciales"
            PASS_HASH=$(openssl passwd -apr1 "${TRAEFIK_DASHBOARD_PASSWORD}")
            TRAEFIK_DASHBOARD_AUTH="${TRAEFIK_DASHBOARD_USER}:${PASS_HASH}"
        fi
        
        # Actualizar el archivo .env con el nuevo hash
        sed -i.bak "s|^TRAEFIK_DASHBOARD_AUTH=.*|TRAEFIK_DASHBOARD_AUTH=${TRAEFIK_DASHBOARD_AUTH}|" .env
        rm -f .env.bak
        
        log "SUCCESS" "Hash de contraseña generado y actualizado en .env"
    else
        log "WARNING" "No se pudieron generar credenciales: usuario o contraseña no definidos en .env"
    fi
}


# --- Función: validate_env_variables ---
# Valida que las variables críticas estén definidas en .env
# Sin estas variables, la infraestructura no puede funcionar correctamente
validate_env_variables() {
    log "INFO" "Validando variables de entorno críticas..."
    
    local required_vars=(
        "NETWORK_NAME"
        "DOMAIN_BASE"
        "TRAEFIK_CONTAINER_NAME"
        "MYSQL_CONTAINER_NAME"
        "MONGO_CONTAINER_NAME"
        "MYSQL_ROOT_PASSWORD"
        "TRAEFIK_DOMAIN"
    )
    
    local middleware_vars=(
        "AUTH_MIDDLEWARE_NAME"
        "COMPRESS_MIDDLEWARE_NAME"
        "SECURITY_HEADERS_MIDDLEWARE_NAME"
        "RATE_LIMIT_MIDDLEWARE_NAME"
        "HTTPS_REDIRECT_MIDDLEWARE_NAME"
        "CORS_MIDDLEWARE_NAME"
    )
    
    local missing_vars=()
    local warning_vars=()
    
    # Verificar variables críticas
    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            missing_vars+=("$var")
        fi
    done
    
    # Verificar variables de middleware (advertencias)
    for var in "${middleware_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            warning_vars+=("$var")
        fi
    done
    
    # Mostrar advertencias para variables no críticas
    if [ ${#warning_vars[@]} -gt 0 ]; then
        log "WARNING" "Las siguientes variables opcionales no están definidas en el archivo .env:"
        for var in "${warning_vars[@]}"; do
            log "WARNING" "  - $var (recomendado para configuración completa de middlewares)"
        done
    fi
    
    # Detener si faltan variables críticas
    if [ ${#missing_vars[@]} -gt 0 ]; then
        log "ERROR" "Faltan las siguientes variables críticas en el archivo .env:"
        for var in "${missing_vars[@]}"; do
            log "ERROR" "  - $var"
        done
        log "ERROR" "Por favor, completa la configuración en el archivo .env"
        exit 1
    fi
    
    log "SUCCESS" "Todas las variables críticas están definidas"
}

# --- Función: copy_if_not_exists ---
# Copia un archivo de ejemplo a su destino final solo si este no existe
# Esto respeta la configuración existente del usuario
# Parámetros:
#   $1: Archivo de origen (ejemplo)
#   $2: Archivo de destino
#   $3: Descripción del archivo
copy_if_not_exists() {
    local source_file=$1
    local dest_file=$2
    local description=$3
    
    if [ ! -f "$dest_file" ]; then
        if [ -f "$source_file" ]; then
            cp "$source_file" "$dest_file"
            log "SUCCESS" "$description: Archivo creado desde $source_file"
        else
            log "ERROR" "Archivo de origen $source_file no encontrado"
            return 1
        fi
    else
        log "INFO" "$description: El archivo $dest_file ya existe, se mantendrá la configuración actual"
    fi
    
    return 0
}

# --- Función: create_directories ---
# Crea los directorios necesarios para la infraestructura
# Estos directorios almacenarán configuraciones, certificados y datos persistentes
create_directories() {
    log "INFO" "Creando estructura de directorios..."
    
    local directories=(
        "traefik/config/certs"
        "traefik/logs"
        "mysql/config"
        "mysql/logs"
        "mongo/config"
        "mongo/logs"
        "prometheus"
        "grafana/provisioning/datasources"
        "grafana/provisioning/dashboards"
        "loki"
        "promtail"
        "projects"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log "SUCCESS" "Directorio $dir creado"
        else
            log "INFO" "Directorio $dir ya existe"
        fi
    done
}

# --- Función: copy_config_files ---
# Copia los archivos de configuración de ejemplo para todos los servicios
# Solo copia archivos que no existen, respetando configuraciones existentes
copy_config_files() {
    log "INFO" "Copiando archivos de configuración..."
    
    # Archivos principales de infraestructura
    copy_if_not_exists "docker-compose.example.yml" "docker-compose.yml" "Docker Compose principal"
    
    # Traefik
    copy_if_not_exists "traefik/config/traefik.example.yml" "traefik/config/traefik.yml" "Configuración de Traefik"
    copy_if_not_exists "traefik/config/dynamic.example.yml" "traefik/config/dynamic.yml" "Configuración dinámica de Traefik"
    copy_if_not_exists "traefik/config/middleware.example.yml" "traefik/config/middleware.yml" "Configuración de middleware de Traefik"
    
    # MySQL y MongoDB
    copy_if_not_exists "mysql/config/my.example.cnf" "mysql/config/my.cnf" "Configuración de MySQL"
    copy_if_not_exists "mongo/config/mongod.example.conf" "mongo/config/mongod.conf" "Configuración de MongoDB"
    
    # Script de creación de proyectos
    copy_if_not_exists "create-project.example.sh" "create-project.sh" "Script de creación de proyectos"
    chmod +x create-project.sh
}

# --- Función: setup_mkcert ---
# Configura e instala mkcert si es necesario para generar certificados SSL locales
# mkcert permite crear certificados que son reconocidos como válidos por navegadores
setup_mkcert() {
    log "INFO" "Configurando mkcert para certificados SSL..."

    # Verificar si mkcert está instalado
    if ! command -v mkcert &> /dev/null; then
        log "WARNING" "mkcert no está instalado, procediendo a instalarlo..."

        # Detectar sistema operativo
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command -v brew &> /dev/null; then
                brew install mkcert nss
                log "SUCCESS" "mkcert instalado via Homebrew"
            else
                log "ERROR" "Homebrew no está instalado. Por favor, instala Homebrew primero"
                log "ERROR" "Consulta https://brew.sh/ para instrucciones de instalación"
                exit 1
            fi
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            if command -v apt-get &> /dev/null; then
                # Debian/Ubuntu
                log "INFO" "Instalando dependencias para mkcert en Debian/Ubuntu..."
                sudo apt-get update
                sudo apt-get install -y libnss3-tools wget
                
                # Descargar e instalar mkcert
                log "INFO" "Descargando mkcert..."
                wget -q -O mkcert "https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-linux-amd64"
                chmod +x mkcert
                sudo mv mkcert /usr/local/bin/
                log "SUCCESS" "mkcert instalado correctamente en /usr/local/bin/"
            elif command -v dnf &> /dev/null; then
                # Fedora/RHEL/CentOS
                log "INFO" "Instalando dependencias para mkcert en Fedora/RHEL/CentOS..."
                sudo dnf install -y nss-tools wget
                
                # Descargar e instalar mkcert
                log "INFO" "Descargando mkcert..."
                wget -q -O mkcert "https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-linux-amd64"
                chmod +x mkcert
                sudo mv mkcert /usr/local/bin/
                log "SUCCESS" "mkcert instalado correctamente en /usr/local/bin/"
            else
                log "ERROR" "No se pudo detectar un gestor de paquetes compatible (apt-get o dnf)"
                log "ERROR" "Por favor, instala mkcert manualmente: https://github.com/FiloSottile/mkcert"
                exit 1
            fi
        else
            log "ERROR" "Sistema operativo no compatible para instalación automática de mkcert"
            log "ERROR" "Por favor, instala mkcert manualmente: https://github.com/FiloSottile/mkcert"
            exit 1
        fi
        
        log "SUCCESS" "mkcert instalado correctamente"
    else
        log "INFO" "mkcert ya está instalado en el sistema"
    fi
    
    # Ejecutar mkcert -install para configurar la CA local
    log "INFO" "Instalando autoridad certificadora local..."
    if ! mkcert -install; then
        log "ERROR" "Error al instalar la autoridad certificadora local"
        exit 1
    fi
    
    log "SUCCESS" "Autoridad certificadora local configurada correctamente"
}

# --- Función: generate_ssl_certificates ---
# Genera certificados SSL para los dominios configurados en el entorno
# Estos certificados serán usados por Traefik para proveer HTTPS
# Utiliza las variables definidas en el archivo .env
generate_ssl_certificates() {
    log "INFO" "Generando certificados SSL para ${DOMAIN_BASE}..."
    
    local cert_dir="traefik/config/certs"
    local cert_file="${cert_dir}/cert.pem"
    local key_file="${cert_dir}/key.pem"
    
    # Verificar si ya existen certificados
    if [ -f "$cert_file" ] && [ -f "$key_file" ]; then
        log "INFO" "Los certificados SSL ya existen en $cert_dir"
        
        # Verificar validez de los certificados existentes
        local cert_expiry
        cert_expiry=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
        log "INFO" "Certificado actual expira: $cert_expiry"
        
        # Preguntar si desea regenerar los certificados
        read -r -p "¿Deseas regenerar los certificados SSL? (s/n): " regenerate
        if [[ "$regenerate" =~ ^[Ss]$ ]]; then
            log "INFO" "Regenerando certificados SSL..."
            rm -f "$cert_file" "$key_file"
        else
            log "INFO" "Manteniendo certificados SSL existentes"
            return 0
        fi
    fi
    
    # Lista de dominios a incluir en el certificado
    local domains=(
        "*.${DOMAIN_BASE}"
        "${DOMAIN_BASE}"
        "${TRAEFIK_DOMAIN}"
        "${MAILHOG_DOMAIN}"
        "prometheus.${DOMAIN_BASE}"
        "grafana.${DOMAIN_BASE}"
    )
    
    # Construir comando mkcert con todos los dominios
    local mkcert_cmd="mkcert -cert-file \"$cert_file\" -key-file \"$key_file\""
    for domain in "${domains[@]}"; do
        mkcert_cmd+=" \"$domain\""
    done
    
    # Generar certificados
    log "INFO" "Generando nuevos certificados SSL para ${#domains[@]} dominios..."
    log "DEBUG" "Comando: $mkcert_cmd"
    if ! eval "$mkcert_cmd"; then
        log "ERROR" "Error al generar certificados SSL"
        exit 1
    fi
    
    # Verificar que los certificados se hayan generado correctamente
    if [ -f "$cert_file" ] && [ -f "$key_file" ]; then
        # Mostrar información del certificado
        log "INFO" "Información del certificado generado:"
        openssl x509 -in "$cert_file" -noout -subject -issuer -dates | while read -r line; do
            log "INFO" "  $line"
        done
        
        log "SUCCESS" "Certificados SSL generados correctamente en $cert_dir"
    else
        log "ERROR" "No se pudieron generar los certificados SSL"
        exit 1
    fi
}

# --- Función: create_docker_network ---
# Crea la red Docker definida en el .env si no existe
# Esta red será compartida por todos los servicios y proyectos
create_docker_network() {
    log "INFO" "Verificando red Docker ${NETWORK_NAME}..."
    
    # Comprobar si la red ya existe
    if docker network ls | grep -q "$NETWORK_NAME"; then
        log "INFO" "La red Docker $NETWORK_NAME ya existe"
    else
        # Crear la red
        if docker network create "$NETWORK_NAME"; then
            log "SUCCESS" "Red Docker $NETWORK_NAME creada correctamente"
        else
            log "ERROR" "Error al crear la red Docker $NETWORK_NAME"
            exit 1
        fi
    fi
}

# --- Función: handle_services ---
# Inicia los servicios de infraestructura base definidos en docker-compose.yml
# Incluye Traefik, MySQL, MongoDB y MailHog
handle_services() {
    log "INFO" "Iniciando servicios de infraestructura..."
    
    # Verificar si docker-compose.yml existe
    if [ ! -f "docker-compose.yml" ]; then
        log "ERROR" "No se encontró el archivo docker-compose.yml"
        exit 1
    fi
    
    # Verificar sintaxis del archivo docker-compose.yml
    log "INFO" "Verificando sintaxis de docker-compose.yml..."
    if ! docker-compose config > /dev/null; then
        log "ERROR" "Error en la sintaxis del archivo docker-compose.yml"
        exit 1
    fi
    
    # Detener servicios existentes si están en ejecución
    log "INFO" "Deteniendo servicios existentes si están en ejecución..."
    docker-compose down --remove-orphans || true
    
    # Iniciar servicios
    log "INFO" "Iniciando servicios..."
    if ! docker-compose up -d; then
        log "ERROR" "Error al iniciar los servicios con docker-compose"
        exit 1
    fi
    
    log "SUCCESS" "Servicios de infraestructura iniciados correctamente"
}

# --- Función: verify_running_services ---
# Verifica que los servicios principales estén funcionando correctamente
# Si algún servicio no está ejecutándose, puede indicar un problema de configuración
verify_running_services() {
    log "INFO" "Verificando estado de los servicios principales..."
    
    # Tiempo de espera para que los servicios se inicien completamente
    local wait_time=15
    log "INFO" "Esperando $wait_time segundos para que los servicios se inicien completamente..."
    sleep "$wait_time"
    
    # Servicios esenciales que deben estar en ejecución
    local required_services=(
        "$TRAEFIK_CONTAINER_NAME"
        "$MYSQL_CONTAINER_NAME"
        "$MONGO_CONTAINER_NAME"
        "$MAILHOG_CONTAINER_NAME"
    )
    
    if [ "${PROMETHEUS_ENABLED:-false}" = "true" ]; then
        required_services+=("$PROMETHEUS_CONTAINER_NAME")
    fi
    
    if [ "${GRAFANA_ENABLED:-false}" = "true" ]; then
        required_services+=("$GRAFANA_CONTAINER_NAME")
    fi
    
    if [ "${LOKI_ENABLED:-false}" = "true" ]; then
        required_services+=("$LOKI_CONTAINER_NAME")
        required_services+=("$PROMTAIL_CONTAINER_NAME")
    fi

    local failed_services=()
    
    for service in "${required_services[@]}"; do
        if ! docker ps --format '{{.Names}}' | grep -q "$service"; then
            failed_services+=("$service")
            log "ERROR" "Servicio $service no está en ejecución"
            
            # Mostrar los logs del servicio fallido
            log "INFO" "Logs de $service:"
            docker logs "$service" 2>&1 | tail -n 20
        else
            log "SUCCESS" "Servicio $service está en ejecución"
            
            # Verificar estado de healthcheck si está configurado
            if docker inspect "$service" --format '{{.State.Health.Status}}' 2>/dev/null | grep -q "healthy"; then
                log "SUCCESS" "Healthcheck de $service: healthy"
            elif docker inspect "$service" --format '{{.State.Health.Status}}' 2>/dev/null | grep -q "starting"; then
                log "WARNING" "Healthcheck de $service: starting (aún inicializando)"
            elif docker inspect "$service" --format '{{.State.Health.Status}}' 2>/dev/null | grep -q "unhealthy"; then
                log "ERROR" "Healthcheck de $service: unhealthy"
                failed_services+=("$service (unhealthy)")
            fi
        fi
    done
    
    if [ ${#failed_services[@]} -gt 0 ]; then
        log "ERROR" "Los siguientes servicios presentan problemas: ${failed_services[*]}"
        log "ERROR" "Revisa los logs con 'docker logs <nombre-contenedor>' para más detalles"
        exit 1
    fi
    
    log "SUCCESS" "Todos los servicios principales están en ejecución"
}

# --- Función: display_success_message ---
# Muestra un resumen de la configuración y las instrucciones para el usuario
# Proporciona información sobre cómo acceder a los diferentes servicios
display_success_message() {
    local BOLD='\033[1m'
    
    log "INFO" ""
    log "INFO" "${BOLD}==============================================${NC}"
    log "INFO" "${BOLD}      🚀 WILODEV DOCK - RESUMEN DE CONFIGURACIÓN      ${NC}"
    log "INFO" "${BOLD}==============================================${NC}"
    log "INFO" ""
    
    # Información general
    log "INFO" "${BOLD}🔹 General:${NC}"
    log "INFO" "   • Red: ${NETWORK_NAME}"
    log "INFO" "   • Dominio base: ${DOMAIN_BASE}"
    log "INFO" ""
    
    # Traefik
    log "INFO" "${BOLD}🔹 Traefik:${NC}"
    log "INFO" "   • Dashboard: https://${TRAEFIK_DOMAIN}"
    log "INFO" "   • Usuario: ${TRAEFIK_DASHBOARD_USER}"
    log "INFO" "   • Puerto HTTP: ${TRAEFIK_HTTP_PORT}"
    log "INFO" "   • Puerto HTTPS: ${TRAEFIK_HTTPS_PORT}"
    log "INFO" ""
    
    # MySQL
    log "INFO" "${BOLD}🔹 MySQL:${NC}"
    log "INFO" "   • Host: localhost (para aplicaciones externas) o ${MYSQL_CONTAINER_NAME} (para contenedores)"
    log "INFO" "   • Puerto: ${MYSQL_PORT}"
    log "INFO" "   • Base de datos: ${MYSQL_DATABASE}"
    log "INFO" "   • Usuario: ${MYSQL_USER}"
    log "INFO" ""
    
    # MongoDB
    log "INFO" "${BOLD}🔹 MongoDB:${NC}"
    log "INFO" "   • Host: localhost (para aplicaciones externas) o ${MONGO_CONTAINER_NAME} (para contenedores)"
    log "INFO" "   • Puerto: ${MONGO_PORT}"
    log "INFO" "   • Base de datos: ${MONGO_INITDB_DATABASE}"
    log "INFO" "   • Usuario: ${MONGO_INITDB_ROOT_USERNAME}"
    log "INFO" ""
    
    # MailHog
    log "INFO" "${BOLD}🔹 MailHog:${NC}"
    log "INFO" "   • Interfaz web: https://${MAILHOG_DOMAIN}"
    log "INFO" "   • Puerto SMTP: ${MAILHOG_SMTP_PORT}"
    log "INFO" "   • Host SMTP: localhost (para aplicaciones externas) o ${MAILHOG_CONTAINER_NAME} (para contenedores)"
    log "INFO" ""
    
    # Observabilidad
    log "INFO" "${BOLD}🔹 Observabilidad:${NC}"
    log "INFO" "   • Prometheus: https://prometheus.${DOMAIN_BASE}"
    log "INFO" "   • Grafana: https://grafana.${DOMAIN_BASE}"
    log "INFO" "   • Usuario Grafana: admin"
    log "INFO" "   • Contraseña Grafana: admin123"
    log "INFO" ""
    
    # Instrucciones adicionales
    log "INFO" "${BOLD}🔹 Instrucciones para crear un nuevo proyecto:${NC}"
    log "INFO" "   • Ejecuta: ./create-project.sh"
    log "INFO" ""
    log "INFO" "${BOLD}🔹 Para detener todos los servicios:${NC}"
    log "INFO" "   • Ejecuta: docker-compose down"
    log "INFO" ""
    log "INFO" "${BOLD}🔹 Para reiniciar todos los servicios:${NC}"
    log "INFO" "   • Ejecuta: docker-compose restart"
    log "INFO" ""
    
    log "SUCCESS" "✅ Configuración completada con éxito. ¡Disfruta de tu entorno de desarrollo WiloDev Dock!"
    log "INFO" ""
}

# --- Función principal ---
# Ejecuta todas las funciones en el orden correcto
# Mide el tiempo de ejecución de cada paso para informar al usuario
    main() {
    # Inicializar archivo de log
    > "${LOG_FILE}"
    
    log "INFO" "========================================"
    log "INFO" "🐳 WiloDev Dock - Iniciando configuración (v${SCRIPT_VERSION})"
    log "INFO" "========================================"
    
    # Fase 1: Verificaciones
    measure_execution_time "Verificación de permisos" check_root
    measure_execution_time "Verificación de estructura" check_file_structure
    measure_execution_time "Verificación de permisos de archivos" check_file_permissions
    measure_execution_time "Verificación de espacio en disco" check_disk_space
    measure_execution_time "Verificación de requisitos" check_prerequisites
    
    # Fase 2: Preparación
    measure_execution_time "Creación de directorios" create_directories
    measure_execution_time "Configuración de variables de entorno" setup_env_file
    measure_execution_time "Validación de variables" validate_env_variables
    measure_execution_time "Copia de archivos de configuración" copy_config_files
    
    # Fase 3: Configuración SSL
    measure_execution_time "Configuración de mkcert" setup_mkcert
    measure_execution_time "Generación de certificados SSL" generate_ssl_certificates
    
    # Fase 4: Despliegue
    measure_execution_time "Creación de red Docker" create_docker_network
    measure_execution_time "Inicio de servicios" handle_services
    measure_execution_time "Verificación de servicios" verify_running_services
    
    # Fase 5: Finalización
    display_success_message

    log "INFO" "========================================"
    log "SUCCESS" "✅ Configuración completada con éxito"
    log "INFO" "========================================"
    log "INFO" "Para más detalles, consulta el archivo de log: ${LOG_FILE}"
}

# Verificar si el script se está ejecutando en modo debug
if [[ "${1:-}" == "--debug" ]]; then
    DEBUG=true
    log "INFO" "Modo debug activado"
fi

# Ejecutar la función principal
main