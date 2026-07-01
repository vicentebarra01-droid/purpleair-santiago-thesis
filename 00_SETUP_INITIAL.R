# ================================================================================
# SCRIPT DE SETUP INICIAL - LIBRERÍAS Y PREPARACIÓN
# ================================================================================

cat("\n╔════════════════════════════════════════════════════════════════════════════╗\n")
cat("║        SETUP INICIAL - PROYECTO TESIS PURPLEAIR SANTIAGO                   ║\n")
cat("║     Zonificación Espacial de PM2.5 (Junio-Agosto 2024-2025)                ║\n")
cat("╚════════════════════════════════════════════════════════════════════════════╝\n\n")

# 1. LIMPIAR AMBIENTE
cat("[1/6] Limpiando ambiente de trabajo...\n")
rm(list = ls())
gc()

options(stringsAsFactors = FALSE)
options(scipen = 999)
Sys.setenv(TZ = "America/Santiago")

cat("✓ Ambiente limpiado\n\n")

# 2. CARGAR CONFIGURACIÓN
cat("[2/6] Cargando configuración...\n")
source("./CONFIGURACION.R")
cat("✓ Configuración cargada\n\n")

# 3. INSTALAR/CARGAR LIBRERÍAS
cat("[3/6] Validando librerías...\n")

required_packages <- c(
  "tidyverse", "httr", "jsonlite", "sf", "sp", "rgdal", "rgeos",
  "ggplot2", "mapview", "leaflet", "lubridate", "data.table", "zoo",
  "RColorBrewer", "viridis", "gridExtra", "scales"
)

install_if_missing <- function(pkg) {
  if (!require(pkg, character.only = TRUE)) {
    cat(sprintf("   Instalando: %s...\n", pkg))
    install.packages(pkg, dependencies = TRUE, quiet = TRUE)
    library(pkg, character.only = TRUE)
  } else {
    cat(sprintf("   ✓ %s\n", pkg))
  }
}

invisible(sapply(required_packages, install_if_missing))
cat("\n✓ Librerías cargadas\n\n")

# 4. CREAR DIRECTORIOS
cat("[4/6] Creando directorios...\n")

dirs_to_create <- c(
  "data", "data/raw", "output/raw", "output/processed",
  "output/maps", "output/spatial", "output/reports", "logs"
)

invisible(sapply(dirs_to_create, function(dir) {
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    cat(sprintf("   ✓ %s\n", dir))
  }
}))
cat("\n✓ Directorios creados\n\n")

# 5. CONFIGURAR LOGGING
cat("[5/6] Configurando logging...\n")

log_file <<- sprintf("logs/analysis_%s.log", format(Sys.time(), "%Y%m%d_%H%M%S"))

log_message <<- function(msg, level = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  log_entry <- sprintf("[%s] %s: %s", timestamp, level, msg)
  cat(sprintf("%s\n", log_entry))
  cat(sprintf("%s\n", log_entry), file = log_file, append = TRUE)
}

log_message("Iniciando análisis de zonificación espacial PM2.5")
log_message(sprintf("Área: Santiago [%.2f,%.2f] a [%.2f,%.2f]",
  BBOX_SANTIAGO$lon_min, BBOX_SANTIAGO$lat_min,
  BBOX_SANTIAGO$lon_max, BBOX_SANTIAGO$lat_max))
log_message(sprintf("Períodos: Junio-Agosto 2024 y 2025"))
log_message(sprintf("Clusters K-means: %d", K_CLUSTERS))

cat("✓ Logging configurado\n")
cat(sprintf("   Archivo: %s\n\n", log_file))

# 6. VALIDAR CONFIGURACIÓN
cat("[6/6] Validando configuración...\n\n")

tryCatch({
  validate_config()
}, error = function(e) {
  cat(sprintf("\n❌ Error: %s\n", e$message))
  log_message(sprintf("Error: %s", e$message), "ERROR")
  stop("Corregir configuración")
})

# 7. RESUMEN
cat("\n╔════════════════════════════════════════════════════════════════════════════╗\n")
cat("║                    ✅ SETUP COMPLETADO EXITOSAMENTE                          ║\n")
cat("╚════════════════════════════════════════════════════════════════════════════╝\n\n")

cat("INFORMACIÓN DEL PROYECTO:\n")
cat(sprintf("  API Key: %s\n",
  ifelse(PURPLEAIR_API_KEY == "YOUR_API_KEY_HERE",
    "⚠ NO CONFIGURADA", "✓ Configurada")))
cat(sprintf("  Clusters: %d\n", K_CLUSTERS))
cat(sprintf("  CRS: WGS84 (4326) → UTM 19S (32719)\n"))
cat(sprintf("  Log: %s\n\n", log_file))

cat("PRÓXIMOS PASOS:\n")
cat("  1. API Key: https://www2.purpleair.com/api\n")
cat("  2. Actualizar PURPLEAIR_API_KEY en CONFIGURACION.R\n")
cat("  3. Datos SINCA: https://sinca.mma.gob.cl/\n")
cat("  4. Guardar en data/sinca_data.csv\n")
cat("  5. Ejecutar: source('MAIN.R')\n\n")

cat("═══════════════════════════════════════════════════════════════════════════════\n\n")