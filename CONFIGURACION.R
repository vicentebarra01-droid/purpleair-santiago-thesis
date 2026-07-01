# ================================================================================
# CONFIGURACIÓN CENTRAL - PARÁMETROS GLOBALES DEL PROYECTO
# ================================================================================

# 1. CREDENCIALES Y RUTAS
PURPLEAIR_API_KEY <- "YOUR_API_KEY_HERE"
SINCA_CSV_PATH <- "./data/sinca_data.csv"

# 2. ÁREA DE ESTUDIO: SANTIAGO DE CHILE
BBOX_SANTIAGO <- list(
  lat_min = -33.75,
  lat_max = -33.05,
  lon_min = -70.90,
  lon_max = -70.40
)

SANTIAGO_CENTER <- list(lat = -33.4489, lon = -70.6693)

# 3. PERÍODOS DE ANÁLISIS
ANALYSIS_PERIODS <- list(
  list(year = 2024, months = 6:8),
  list(year = 2025, months = 6:8)
)

DATE_START_2024 <- "2024-06-01"
DATE_END_2024 <- "2024-08-31"
DATE_START_2025 <- "2025-06-01"
DATE_END_2025 <- "2025-08-31"

# 4. SISTEMAS DE COORDENADAS
CRS_WGS84 <- 4326
CRS_UTM19S <- 32719

# 5. PARÁMETROS DE CLUSTERING
K_CLUSTERS <- 5
SEED_VALUE <- 42
MAX_ITERATIONS <- 100
STANDARDIZE_DATA <- TRUE

# 6. PREPROCESAMIENTO
PM25_MAX_THRESHOLD <- 500
NA_THRESHOLD_PERCENT <- 30
PM25_VALID_MIN <- 0
PM25_VALID_MAX <- 500

# 7. VARIABLES A EXTRAER
PURPLEAIR_VARIABLES <- c(
  "pm2.5", "pm2.5_10minute", "pm2.5_30minute",
  "pm2.5_1hour", "pm1_0", "pm10_0",
  "temperature", "humidity", "pressure"
)

# 8. TEMPORALIDAD
TEMPORAL_RESOLUTION <- "hourly"
TIMEZONE <- "America/Santiago"

# 9. EXPORTACIÓN SIG
OUTPUT_GPKG <- "./output/spatial/santiago_pm25.gpkg"
OUTPUT_SHP_PREFIX <- "./output/spatial/santiago_pm25"
OUTPUT_GEOJSON <- "./output/spatial/santiago_pm25.geojson"

# 10. VISUALIZACIÓN
CLUSTER_PALETTE <- "Spectral"
GGPLOT_THEME <- "minimal"
POINT_SIZE <- 3
POINT_ALPHA <- 0.7

# 11. PARÁMETROS API
MAX_API_RETRIES <- 3
API_RETRY_DELAY <- 2
API_TIMEOUT <- 30
MAX_SENSORS <- 500

# 12. VALIDACIÓN
CALCULATE_SILHOUETTE <- TRUE
CALCULATE_WCSS <- TRUE
TEST_MULTIPLE_K <- FALSE
K_TEST_RANGE <- 2:8

# 13. DIRECTORIOS
OUTPUT_DIRS <- list(
  raw = "./output/raw",
  processed = "./output/processed",
  spatial = "./output/spatial",
  maps = "./output/maps",
  reports = "./output/reports"
)

# 14. LOGGING
LOG_VERBOSE <- TRUE
LOG_TO_FILE <- TRUE
LOG_FILE_PATH <- "./logs"

# 15. VALIDACIÓN DE CONFIGURACIÓN
validate_config <- function() {
  errors <- c()
  warnings <- c()
  
  if (PURPLEAIR_API_KEY == "YOUR_API_KEY_HERE") {
    warnings <- c(warnings, "⚠ API Key no configurada")
  }
  
  if (BBOX_SANTIAGO$lat_min >= BBOX_SANTIAGO$lat_max) {
    errors <- c(errors, "✗ Bounding box inválido: lat_min >= lat_max")
  }
  if (BBOX_SANTIAGO$lon_min >= BBOX_SANTIAGO$lon_max) {
    errors <- c(errors, "✗ Bounding box inválido: lon_min >= lon_max")
  }
  
  if (K_CLUSTERS < 2 || K_CLUSTERS > 20) {
    errors <- c(errors, "✗ K_CLUSTERS debe estar entre 2 y 20")
  }
  
  if (length(errors) > 0) {
    cat("\n❌ ERRORES DE CONFIGURACIÓN:\n")
    for (err in errors) cat(sprintf("%s\n", err))
    stop("Corregir errores antes de continuar")
  }
  
  if (length(warnings) > 0) {
    cat("\n⚠️  ADVERTENCIAS:\n")
    for (warn in warnings) cat(sprintf("%s\n", warn))
  }
  
  cat("\n✅ Configuración validada\n")
}