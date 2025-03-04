#!/bin/bash

# =================================================================
# WiloDev Dock - Script de Creación de Proyectos
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

# Activar modo estricto de shell para detectar errores temprano
set -euo pipefail

# =================================================================
# Constantes y colores para la salida en consola
# =================================================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Tipos de proyectos soportados (convertidos a minúsculas para comparación)
declare -a FRAMEWORKS=(
  "laravel"
  "symfony"
  "infinity"
)

# =================================================================
# Funciones de utilidad
# =================================================================

# --- Función: log ---
# Muestra mensajes de log con formato y colores
# Argumentos:
#   $1: Nivel de log (ERROR, WARNING, SUCCESS, INFO)
#   $2: Mensaje a mostrar
log() {
  local level=$1
  local message=$2
  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  case $level in
    "ERROR")   echo -e "${RED}[${timestamp}] ERROR: ${message}${NC}" ;;
    "WARNING") echo -e "${YELLOW}[${timestamp}] WARNING: ${message}${NC}" ;;
    "SUCCESS") echo -e "${GREEN}[${timestamp}] SUCCESS: ${message}${NC}" ;;
    "INFO")    echo -e "${BLUE}[${timestamp}] INFO: ${message}${NC}" ;;
  esac
}

# --- Función: check_dependencies ---
# Verifica que las dependencias necesarias estén instaladas y funcionando
# Sin argumentos
check_dependencies() {
  log "INFO" "Verificando dependencias..."
  
  # Verificar que Docker esté instalado y funcionando
  if ! command -v docker &> /dev/null; then
    log "ERROR" "Docker no está instalado. Por favor, instala Docker primero."
    exit 1
  fi
  
  # Verificar que Docker Compose esté instalado
  if ! command -v docker-compose &> /dev/null; then
    log "ERROR" "Docker Compose no está instalado. Por favor, instala Docker Compose primero."
    exit 1
  fi
  
  # Verificar que exista el archivo .env
  if [ ! -f ".env" ]; then
    log "ERROR" "Archivo .env no encontrado. Ejecuta './setup.sh' primero."
    exit 1
  fi
  
  # Cargar variables de entorno desde .env
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
  
  # Verificar que el contenedor de Traefik esté funcionando
  if ! docker ps | grep -q "${TRAEFIK_CONTAINER_NAME:-wilodev-traefik}"; then
    log "ERROR" "El contenedor de Traefik no está en ejecución. Ejecuta './setup.sh' primero."
    exit 1
  fi
  
  log "SUCCESS" "Todas las dependencias están correctamente instaladas."
}

# --- Función: validate_project_type ---
# Valida que el tipo de proyecto seleccionado sea soportado
# Argumentos:
#   $1: Tipo de proyecto seleccionado
validate_project_type() {
  local project_type=$1
  local valid=false
  
  log "INFO" "Validando tipo de proyecto: ${project_type}"
  
  # Convertir a minúsculas para facilitar la comparación
  project_type=$(echo "$project_type" | tr '[:upper:]' '[:lower:]')
  
  for framework in "${FRAMEWORKS[@]}"; do
    if [ "$project_type" == "$framework" ]; then
      valid=true
      break
    fi
  done
  
  if [ "$valid" != true ]; then
    log "ERROR" "Tipo de proyecto no válido: ${project_type}"
    log "ERROR" "Tipos de proyectos soportados: ${FRAMEWORKS[*]}"
    exit 1
  fi
  
  log "SUCCESS" "Tipo de proyecto válido: ${project_type}"
  
  # Devolver el tipo en minúsculas
  echo "$project_type"
}

# --- Función: validate_project_name ---
# Valida que el nombre del proyecto sea válido y no exista ya
# Argumentos:
#   $1: Nombre del proyecto
validate_project_name() {
  local project_name=$1
  
  log "INFO" "Validando nombre de proyecto: ${project_name}"
  
  # Verificar que el nombre solo contenga caracteres válidos
  if ! [[ $project_name =~ ^[a-zA-Z0-9_-]+$ ]]; then
    log "ERROR" "El nombre del proyecto contiene caracteres no válidos."
    log "ERROR" "Por favor, usa solo letras, números, guiones y guiones bajos."
    exit 1
  fi
  
  # Verificar que el directorio del proyecto no exista ya
  if [ -d "projects/${project_name}" ]; then
    log "ERROR" "El proyecto '${project_name}' ya existe en el directorio 'projects/'."
    log "ERROR" "Por favor, elige otro nombre o elimina el proyecto existente."
    exit 1
  fi
  
  log "SUCCESS" "Nombre de proyecto válido: ${project_name}"
}

# --- Función: validate_subdomain ---
# Valida que el subdominio sea válido y no esté en uso
# Argumentos:
#   $1: Subdominio
validate_subdomain() {
  local subdomain=$1
  
  log "INFO" "Validando subdominio: ${subdomain}"
  
  # Verificar que el subdominio solo contenga caracteres válidos
  if ! [[ $subdomain =~ ^[a-zA-Z0-9-]+$ ]]; then
    log "ERROR" "El subdominio contiene caracteres no válidos."
    log "ERROR" "Por favor, usa solo letras, números y guiones."
    exit 1
  fi
  
  # Verificar subdominios en uso revisando en todos los docker-compose en la carpeta projects
  local used_subdomains=()
  for compose_file in projects/*/docker-compose.yml; do
    if [ -f "$compose_file" ]; then
      # Buscar reglas de host en el archivo docker-compose.yml
      while read -r line; do
        if [[ $line == *"${DOMAIN_BASE}"* ]]; then
          used_subdomains+=("$line")
        fi
      done < "$compose_file"
    fi
  done
  
  # Verificar si el subdominio está en uso
  for used in "${used_subdomains[@]}"; do
    if [[ $used == *"${subdomain}.${DOMAIN_BASE}"* ]]; then
      log "ERROR" "El subdominio '${subdomain}.${DOMAIN_BASE}' ya está en uso."
      log "ERROR" "Por favor, elige otro subdominio."
      exit 1
    fi
  done
  
  log "SUCCESS" "Subdominio válido: ${subdomain}"
}

# --- Función: replace_env_vars ---
# Reemplaza las variables de entorno en un archivo
# Argumentos:
#   $1: Archivo de entrada
#   $2: Archivo de salida
#   $3...: Pares variable=valor para reemplazo
replace_env_vars() {
  local input_file=$1
  local output_file=$2
  shift 2
  
  # Verificar que el archivo de entrada existe
  if [ ! -f "$input_file" ]; then
    log "ERROR" "Archivo de entrada no encontrado: $input_file"
    exit 1
  fi
  
  # Copiar archivo de entrada a salida
  cp "$input_file" "$output_file"
  
  # Realizar reemplazos por cada par variable=valor
  for var_value in "$@"; do
    local var="${var_value%%=*}"
    local value="${var_value#*=}"
    
    # Reemplazar la variable con su valor en el archivo
    sed -i "s|\${${var}}|${value}|g" "$output_file"
  done
}

# --- Función: create_laravel_project ---
# Crea un nuevo proyecto Laravel
# Argumentos:
#   $1: Nombre del proyecto
#   $2: Subdominio
create_laravel_project() {
  local project_name=$1
  local subdomain=$2
  local project_dir="projects/${project_name}"
  
  log "INFO" "Creando proyecto Laravel: ${project_name}"
  
  # Crear directorio del proyecto
  mkdir -p "$project_dir"
  
  # Crear proyecto Laravel usando Docker
  log "INFO" "Instalando Laravel usando Composer..."
  docker run --rm -v "$(pwd)/${project_dir}:/app" -w /app composer create-project --prefer-dist laravel/laravel .
  
  # Crear directorios adicionales necesarios
  mkdir -p "${project_dir}/docker/nginx"
  mkdir -p "${project_dir}/docker/supervisor"
  
  # Configurar .env.docker para el proyecto
  log "INFO" "Configurando variables de entorno para Docker..."
  replace_env_vars "laravel/.env.example.docker" "${project_dir}/.env.docker" \
    "APP_NAME=${project_name}" \
    "APP_DOMAIN=${subdomain}.${DOMAIN_BASE}" \
    "PROJECT_PATH=${project_dir}" \
    "PHP_VERSION=${PHP_VERSION}" \
    "NODE_VERSION=${NODE_VERSION}" \
    "NETWORK_NAME=${NETWORK_NAME}" \
    "MYSQL_CONTAINER_NAME=${MYSQL_CONTAINER_NAME}" \
    "MYSQL_DATABASE=${project_name}" \
    "MYSQL_USER=${MYSQL_USER}" \
    "MYSQL_PASSWORD=${MYSQL_PASSWORD}" \
    "MONGO_CONTAINER_NAME=${MONGO_CONTAINER_NAME}" \
    "MONGO_INITDB_DATABASE=${MONGO_INITDB_DATABASE}" \
    "MONGO_INITDB_ROOT_USERNAME=${MONGO_INITDB_ROOT_USERNAME}" \
    "MONGO_INITDB_ROOT_PASSWORD=${MONGO_INITDB_ROOT_PASSWORD}"
  
  # Copiar Dockerfile para el proyecto
  log "INFO" "Configurando Dockerfile para el proyecto..."
  replace_env_vars "laravel/Dockerfile.example" "${project_dir}/Dockerfile" \
    "PHP_VERSION=${PHP_VERSION}" \
    "NODE_VERSION=${NODE_VERSION}"
  
  # Copiar configuración de Nginx
  log "INFO" "Configurando Nginx para el proyecto..."
  replace_env_vars "laravel/nginx.example.conf" "${project_dir}/docker/nginx/default.conf" \
    "APP_DOMAIN=${subdomain}.${DOMAIN_BASE}"
  
  # Copiar configuración de PHP
  log "INFO" "Configurando PHP para el proyecto..."
  cp "laravel/php.example.ini" "${project_dir}/docker/php.ini"
  
  # Copiar configuración de Supervisor
  log "INFO" "Configurando Supervisor para el proyecto..."
  cp "laravel/supervisor.example.conf" "${project_dir}/docker/supervisor/laravel.conf"
  
  # Crear docker-compose.yml para el proyecto
  log "INFO" "Creando configuración de Docker Compose para el proyecto..."
  replace_env_vars "laravel/docker-compose.example.yml" "${project_dir}/docker-compose.yml" \
    "APP_NAME=${project_name}" \
    "APP_DOMAIN=${subdomain}.${DOMAIN_BASE}" \
    "PHP_VERSION=${PHP_VERSION}" \
    "NODE_VERSION=${NODE_VERSION}" \
    "NETWORK_NAME=${NETWORK_NAME}"
  
  # Crear base de datos para el proyecto
  log "INFO" "Creando base de datos para el proyecto..."
  docker exec -i ${MYSQL_CONTAINER_NAME} mysql -u root -p${MYSQL_ROOT_PASSWORD} << EOL
CREATE DATABASE IF NOT EXISTS ${project_name};
GRANT ALL PRIVILEGES ON ${project_name}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOL

  log "SUCCESS" "Proyecto Laravel '${project_name}' creado correctamente."
  log "SUCCESS" "Accede al proyecto en: https://${subdomain}.${DOMAIN_BASE}"
  log "INFO" "Para iniciar el proyecto, navega a projects/${project_name} y ejecuta: docker-compose up -d"
}

# --- Función: create_symfony_project ---
# Crea un nuevo proyecto Symfony
# Argumentos:
#   $1: Nombre del proyecto
#   $2: Subdominio
create_symfony_project() {
  local project_name=$1
  local subdomain=$2
  local project_dir="projects/${project_name}"
  
  log "INFO" "Creando proyecto Symfony: ${project_name}"
  
  # Crear directorio del proyecto
  mkdir -p "$project_dir"
  
  # Crear proyecto Symfony usando Docker
  log "INFO" "Instalando Symfony usando Composer..."
  docker run --rm -v "$(pwd)/${project_dir}:/app" -w /app composer create-project symfony/skeleton .
  
  # Crear directorios adicionales necesarios
  mkdir -p "${project_dir}/docker/nginx"
  
# Configurar .env.docker para el proyecto
  log "INFO" "Configurando variables de entorno para Docker..."
  replace_env_vars "symfony/.env.example.docker" "${project_dir}/.env.docker" \
    "APP_NAME=${project_name}" \
    "APP_DOMAIN=${subdomain}.${DOMAIN_BASE}" \
    "PROJECT_PATH=${project_dir}" \
    "PHP_VERSION=${PHP_VERSION}" \
    "NODE_VERSION=${NODE_VERSION}" \
    "NETWORK_NAME=${NETWORK_NAME}" \
    "MYSQL_CONTAINER_NAME=${MYSQL_CONTAINER_NAME}" \
    "MYSQL_DATABASE=${project_name}" \
    "MYSQL_USER=${MYSQL_USER}" \
    "MYSQL_PASSWORD=${MYSQL_PASSWORD}" \
    "MONGO_CONTAINER_NAME=${MONGO_CONTAINER_NAME}" \
    "MONGO_INITDB_DATABASE=${MONGO_INITDB_DATABASE}" \
    "MONGO_INITDB_ROOT_USERNAME=${MONGO_INITDB_ROOT_USERNAME}" \
    "MONGO_INITDB_ROOT_PASSWORD=${MONGO_INITDB_ROOT_PASSWORD}"
  
  # Copiar Dockerfile para el proyecto
  log "INFO" "Configurando Dockerfile para el proyecto..."
  replace_env_vars "symfony/Dockerfile.example" "${project_dir}/Dockerfile" \
    "PHP_VERSION=${PHP_VERSION}" \
    "NODE_VERSION=${NODE_VERSION}"
  
  # Copiar configuración de Nginx
  log "INFO" "Configurando Nginx para el proyecto..."
  replace_env_vars "symfony/nginx.example.conf" "${project_dir}/docker/nginx/default.conf" \
    "APP_DOMAIN=${subdomain}.${DOMAIN_BASE}"
  
  # Copiar configuración de PHP
  log "INFO" "Configurando PHP para el proyecto..."
  cp "symfony/php.example.ini" "${project_dir}/docker/php.ini"
  
  # Crear docker-compose.yml para el proyecto
  log "INFO" "Creando configuración de Docker Compose para el proyecto..."
  replace_env_vars "symfony/docker-compose.example.yml" "${project_dir}/docker-compose.yml" \
    "APP_NAME=${project_name}" \
    "APP_DOMAIN=${subdomain}.${DOMAIN_BASE}" \
    "PHP_VERSION=${PHP_VERSION}" \
    "NODE_VERSION=${NODE_VERSION}" \
    "NETWORK_NAME=${NETWORK_NAME}"
  
  # Crear base de datos para el proyecto
  log "INFO" "Creando base de datos para el proyecto..."
  docker exec -i ${MYSQL_CONTAINER_NAME} mysql -u root -p${MYSQL_ROOT_PASSWORD} << EOL
CREATE DATABASE IF NOT EXISTS ${project_name};
GRANT ALL PRIVILEGES ON ${project_name}.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOL

  log "SUCCESS" "Proyecto Symfony '${project_name}' creado correctamente."
  log "SUCCESS" "Accede al proyecto en: https://${subdomain}.${DOMAIN_BASE}"
  log "INFO" "Para iniciar el proyecto, navega a projects/${project_name} y ejecuta: docker-compose up -d"
}

# --- Función: create_infinity_project ---
# Crea un nuevo proyecto Infinity
# Argumentos:
#   $1: Nombre del proyecto
#   $2: Subdominio
create_infinity_project() {
  local project_name=$1
  local subdomain=$2
  
  log "INFO" "Sobre Infinity Framework..."
  log "INFO" "Infinity es un framework comercial de WiloDev."
  log "WARNING" "Este es un framework que requiere licencia comercial."
  log "INFO" "Para obtener información sobre licencias y descargar el framework:"
  log "INFO" "   Visita: https://infinyti.tech"
  log "INFO" "   Contacto: info@infinyti.tech"
  log "INFO" " "
  log "INFO" "Una vez que hayas adquirido la licencia, podrás configurar tu proyecto Infinity."
  log "INFO" "Tu subdominio reservado será: ${subdomain}.${DOMAIN_BASE}"
}

# --- Función: display_help ---
# Muestra el mensaje de ayuda del script
# Sin argumentos
display_help() {
  cat << EOL
=================================================================
WiloDev Dock - Script de Creación de Proyectos
=================================================================

DESCRIPCIÓN:
  Este script facilita la creación de nuevos proyectos dentro del
  entorno WiloDev Dock utilizando archivos de configuración existentes.

USO:
  ./create-project.sh <tipo> <nombre> <subdominio>

ARGUMENTOS:
  tipo        Tipo de proyecto (laravel, symfony, infinity)
  nombre      Nombre del proyecto (solo letras, números, guiones y guiones bajos)
  subdominio  Subdominio para acceder al proyecto (solo letras, números y guiones)

EJEMPLOS:
  ./create-project.sh laravel mi-proyecto mi-proyecto
  ./create-project.sh symfony api api
  ./create-project.sh infinity admin admin

=================================================================
EOL
}

# =================================================================
# Función principal
# =================================================================

# --- Función: main ---
# Función principal que ejecuta el script
# Argumentos:
#   $@: Todos los argumentos pasados al script
main() {
  log "INFO" "========================================"
  log "INFO" "🐳 WiloDev Dock - Creador de Proyectos"
  log "INFO" "========================================"
  
  # Verificar que se proporcionen los argumentos correctos
  if [ $# -lt 3 ]; then
    log "ERROR" "Se requieren 3 argumentos: tipo de proyecto, nombre del proyecto y subdominio."
    display_help
    exit 1
  fi
  
  # Obtener argumentos
  local project_type=$1
  local project_name=$2
  local subdomain=$3
  
  # Verificar dependencias
  check_dependencies
  
  # Validar tipo de proyecto
  project_type=$(validate_project_type "$project_type")
  
  # Validar nombre del proyecto
  validate_project_name "$project_name"
  
  # Validar subdominio
  validate_subdomain "$subdomain"
  
  # Crear el proyecto según el tipo
  case "$project_type" in
    "laravel")
      create_laravel_project "$project_name" "$subdomain"
      ;;
    "symfony")
      create_symfony_project "$project_name" "$subdomain"
      ;;
    "infinity")
      create_infinity_project "$project_name" "$subdomain"
      ;;
  esac
  
  log "INFO" "========================================"
  log "SUCCESS" "✅ Proceso completado"
  log "INFO" "========================================"
}

# Ejecutar la función principal con todos los argumentos
main "$@"