# ================================================================================
# 02_LECTURA_SINCA.R - Lectura y preprocesamiento de datos SINCA
# ================================================================================
# Este módulo lee datos del CSV local de SINCA y prepara para integración
# ================================================================================

cat("\n[MÓDULO 02] Cargando datos SINCA...\n")
log_message("Iniciando carga de datos SINCA")

# 1. FUNCIÓN PARA LEER SINCA
# ================================================================================

read_sinca_data <- function(csv_path) {
  
  if (!file.exists(csv_path)) {
    cat(sprintf("  ⚠ Archivo SINCA no encontrado: %s\n", csv_path))
    log_message(sprintf("Archivo SINCA no encontrado: %s", csv_path), "WARNING")
    return(NULL)
  }
  
  tryCatch({
    cat(sprintf("  Leyendo: %s\n", csv_path))
    
    # Intentar diferentes encodings
    data <- read_csv(csv_path, locale = locale(encoding = "UTF-8"))
    
    cat(sprintf("  ✓ Leído exitosamente: %d filas, %d columnas\n",
                nrow(data), ncol(data)))
    
    return(data)
    
  }, error = function(e) {
    cat(sprintf("  ✗ Error al leer CSV: %s\n", e$message))
    log_message(sprintf("Error al leer SINCA: %s", e$message), "ERROR")
    return(NULL)
  })
}

# 2. GENERAR DATOS SINCA SIMULADOS
# ================================================================================
# Usar esto si no tienes archivo SINCA disponible

generar_datos_sinca_simulados <- function() {
  
  cat("\n  Generando datos SINCA simulados para demostración...\n")
  
  # Estaciones SINCA reales en Santiago
  estaciones_sinca <- tibble(
    station_id = c("PA01", "PA02", "PA03", "PA04", "PA05"),
    station_name = c(
      "Estación Quinta Normal",
      "Estación Las Condes",
      "Estación Pudahuel",
      "Estación La Florida",
      "Estación Cerrillos"
    ),
    latitude = c(-33.4356, -33.3850, -33.3928, -33.5154, -33.5034),
    longitude = c(-70.6789, -70.6100, -70.7667, -70.5578, -70.6967),
    altitude = c(500, 520, 480, 620, 510)
  )
  
  # Generar series temporales
  set.seed(42)
  data_sinca <- tibble()
  
  for (i in 1:nrow(estaciones_sinca)) {
    estacion <- estaciones_sinca[i, ]
    
    for (year in c(2024, 2025)) {
      fechas <- seq(from = as.POSIXct(sprintf("%d-06-01", year), tz = "UTC"),
                    by = "hour",
                    length.out = 2160)
      
      pm25 <- rnorm(2160, mean = 25 + rnorm(1, 0, 3), sd = 8)
      pm25 <- pmax(pm25, 0)
      
      serie <- tibble(
        timestamp = fechas,
        station_id = estacion$station_id,
        station_name = estacion$station_name,
        latitude = estacion$latitude,
        longitude = estacion$longitude,
        altitude = estacion$altitude,
        pm2.5 = pm25,
        temperature = rnorm(2160, 14, 5),
        humidity = rnorm(2160, 65, 15),
        source = "SINCA",
        year = year
      )
      
      data_sinca <- bind_rows(data_sinca, serie)
    }
  }
  
  return(data_sinca)
}

# 3. CARGAR DATOS SINCA
# ================================================================================

cat("\n  Intentando cargar datos SINCA...\n")

data_sinca <- read_sinca_data(SINCA_CSV_PATH)

if (is.null(data_sinca)) {
  cat("\n  Usando datos SINCA simulados\n")
  data_sinca <- generar_datos_sinca_simulados()
  log_message("Usando datos SINCA simulados")
} else {
  # Normalizar estructura si es necesario
  data_sinca <- data_sinca %>%
    mutate(
      source = "SINCA",
      .keep = "all"
    )
}

# 4. VALIDAR Y LIMPIAR DATOS SINCA
# ================================================================================

cat("\n  Validando estructura de SINCA...\n")

# Asegurar columnas necesarias
columnas_requeridas <- c("timestamp", "station_name", "latitude", "longitude", 
                         "pm2.5", "source")

columnas_faltantes <- setdiff(columnas_requeridas, names(data_sinca))

if (length(columnas_faltantes) > 0) {
  cat(sprintf("  ⚠ Columnas faltantes: %s\n", paste(columnas_faltantes, collapse = ", ")))
  # Agregar columnas faltantes con NA
  for (col in columnas_faltantes) {
    data_sinca[[col]] <- NA
  }
}

# Convertir timestamp a POSIXct si es necesario
if (!inherits(data_sinca$timestamp, "POSIXct")) {
  data_sinca <- data_sinca %>%
    mutate(timestamp = as.POSIXct(timestamp, tz = "UTC"))
}

# Asegurar que latitude y longitude son numéricos
data_sinca <- data_sinca %>%
  mutate(
    latitude = as.numeric(latitude),
    longitude = as.numeric(longitude),
    pm2.5 = as.numeric(pm2.5)
  )

# Filtrar por bounding box
data_sinca <- data_sinca %>%
  filter(
    latitude >= BBOX_SANTIAGO$lat_min,
    latitude <= BBOX_SANTIAGO$lat_max,
    longitude >= BBOX_SANTIAGO$lon_min,
    longitude <= BBOX_SANTIAGO$lon_max
  )

cat(sprintf("  ✓ Datos SINCA validados: %d registros\n", nrow(data_sinca)))

# 5. ESTADÍSTICAS SINCA
# ================================================================================

cat("\n  ESTADÍSTICAS SINCA:\n")
cat(sprintf("  ├─ Estaciones: %d\n", n_distinct(data_sinca$station_name)))
cat(sprintf("  ├─ Registros: %d\n", nrow(data_sinca)))
cat(sprintf("  ├─ Período: %s a %s\n",
            min(data_sinca$timestamp),
            max(data_sinca$timestamp)))
cat(sprintf("  ├─ PM2.5 media: %.2f μg/m³\n",
            mean(data_sinca$pm2.5, na.rm = TRUE)))
cat(sprintf("  └─ PM2.5 rango: %.2f - %.2f μg/m³\n",
            min(data_sinca$pm2.5, na.rm = TRUE),
            max(data_sinca$pm2.5, na.rm = TRUE)))

# 6. GUARDAR DATOS RAW
# ================================================================================

cat("\n  Guardando datos raw SINCA...\n")

ruta_raw_sinca <- "./output/raw/sinca_raw.csv"
write_csv(data_sinca, ruta_raw_sinca)

cat(sprintf("  ✓ Guardado en: %s\n", ruta_raw_sinca))
log_message(sprintf("Datos raw SINCA guardados: %s", ruta_raw_sinca))

cat("\n✓ Módulo 02 completado\n")
log_message("Módulo 02 completado exitosamente")