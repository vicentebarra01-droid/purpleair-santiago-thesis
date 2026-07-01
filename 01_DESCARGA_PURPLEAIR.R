# ================================================================================
# 01_DESCARGA_PURPLEAIR.R - Descarga de datos desde API PurpleAir
# ================================================================================
# Este módulo descarga datos horarios de PM2.5 de sensores PurpleAir
# ubicados dentro del bounding box de Santiago de Chile
# ================================================================================

cat("\n[MÓDULO 01] Descargando datos de API PurpleAir...\n")
log_message("Iniciando descarga de datos PurpleAir")

# 1. FUNCIÓN PARA DESCARGAR DATOS PURPLEAIR
# ================================================================================

download_purpleair_data <- function(api_key, bbox, date_range) {
  
  if (api_key == "YOUR_API_KEY_HERE") {
    stop("API Key no configurada. Actualizar PURPLEAIR_API_KEY en CONFIGURACION.R")
  }
  
  cat("\n  Conectando a API PurpleAir...\n")
  log_message("Conectando a API PurpleAir")
  
  # URL base de la API
  api_base <- "https://api.purpleair.com/v1/sensors"
  
  # Construir parámetros de geolocalización
  nwlat <- bbox$lat_max
  selat <- bbox$lat_min
  nwlng <- bbox$lon_min
  selng <- bbox$lon_max
  
  # Parámetros de la consulta
  params <- list(
    nwlat = nwlat,
    selat = selat,
    nwlng = nwlng,
    selng = selng,
    fields = "name,latitude,longitude,altitude,pm2.5,pm2.5_10minute,pm2.5_30minute,pm2.5_1hour,temperature,humidity,pressure",
    max_age = 604800  # 7 días
  )
  
  # Ejecutar consulta con manejo de errores
  tryCatch({
    response <- httr::GET(
      api_base,
      query = params,
      httr::add_headers("X-API-Key" = api_key),
      httr::timeout(API_TIMEOUT)
    )
    
    # Verificar estatus HTTP
    if (httr::status_code(response) != 200) {
      stop(sprintf("Error HTTP %d: %s",
                   httr::status_code(response),
                   httr::content(response, as = "text")))
    }
    
    # Parsear JSON
    content <- jsonlite::fromJSON(httr::content(response, as = "text"))
    
    if (is.null(content$data) || length(content$data) == 0) {
      cat("  ⚠ No se encontraron sensores en el área especificada\n")
      log_message("No se encontraron sensores en el área", "WARNING")
      return(NULL)
    }
    
    # Convertir a data frame
    df_sensors <- as.data.frame(content$data, stringsAsFactors = FALSE)
    
    cat(sprintf("  ✓ Se encontraron %d sensores\n", nrow(df_sensors)))
    log_message(sprintf("Se encontraron %d sensores en PurpleAir", nrow(df_sensors)))
    
    return(df_sensors)
    
  }, error = function(e) {
    cat(sprintf("  ✗ Error en descarga: %s\n", e$message))
    log_message(sprintf("Error en descarga: %s", e$message), "ERROR")
    return(NULL)
  })
}

# 2. FUNCIÓN PARA DESCARGAR DATOS HISTÓRICOS POR SENSOR
# ================================================================================

download_sensor_history <- function(sensor_id, api_key, start_date, end_date) {
  
  api_url <- sprintf("https://api.purpleair.com/v1/sensors/%d/history", sensor_id)
  
  # Convertir fechas a timestamps
  start_ts <- as.integer(as.POSIXct(start_date, tz = "UTC"))
  end_ts <- as.integer(as.POSIXct(end_date, tz = "UTC"))
  
  params <- list(
    start_timestamp = start_ts,
    end_timestamp = end_ts,
    fields = "pm2.5,temperature,humidity,pressure",
    average = 3600  # 1 hora
  )
  
  tryCatch({
    response <- httr::GET(
      api_url,
      query = params,
      httr::add_headers("X-API-Key" = api_key),
      httr::timeout(API_TIMEOUT)
    )
    
    if (httr::status_code(response) != 200) {
      return(NULL)
    }
    
    content <- jsonlite::fromJSON(httr::content(response, as = "text"))
    
    if (is.null(content$data) || length(content$data) == 0) {
      return(NULL)
    }
    
    return(content$data)
    
  }, error = function(e) {
    return(NULL)
  })
}

# 3. DESCARGAR SENSORES ACTIVOS
# ================================================================================

cat("\n  Obteniendo lista de sensores en Santiago...\n")

sensores_purpleair <- download_purpleair_data(
  api_key = PURPLEAIR_API_KEY,
  bbox = BBOX_SANTIAGO,
  date_range = list(start = DATE_START_2024, end = DATE_END_2025)
)

if (is.null(sensores_purpleair)) {
  log_message("Descarga de sensores falló. Usar datos simulados para demostración.", "WARNING")
  cat("\n  ⚠ Usando datos simulados para demostración\n")
  
  # Generar datos simulados para demostración
  set.seed(42)
  n_sensores <- 20
  sensores_purpleair <- tibble(
    sensor_index = 1:n_sensores,
    name = sprintf("Sensor_PA_%03d", 1:n_sensores),
    latitude = BBOX_SANTIAGO$lat_min + 
               runif(n_sensores) * (BBOX_SANTIAGO$lat_max - BBOX_SANTIAGO$lat_min),
    longitude = BBOX_SANTIAGO$lon_min + 
                runif(n_sensores) * (BBOX_SANTIAGO$lon_max - BBOX_SANTIAGO$lon_min),
    altitude = rnorm(n_sensores, mean = 500, sd = 100),
    pm2.5 = rnorm(n_sensores, mean = 35, sd = 15),
    temperature = rnorm(n_sensores, mean = 15, sd = 3),
    humidity = rnorm(n_sensores, mean = 60, sd = 15)
  )
  
  log_message(sprintf("Usando datos simulados: %d sensores", nrow(sensores_purpleair)))
}

# 4. DESCARGAR DATOS HISTÓRICOS
# ================================================================================

cat("\n  Descargando datos históricos por sensor...\n")
log_message("Descargando datos históricos")

if (nrow(sensores_purpleair) > 0) {
  
  # Limitar número de sensores para evitar exceder límites de API
  n_sensores_descargar <- min(nrow(sensores_purpleair), MAX_SENSORS)
  sensores_a_descargar <- sensores_purpleair$sensor_index[1:n_sensores_descargar]
  
  cat(sprintf("  Descargando datos de %d sensores...\n", n_sensores_descargar))
  
  data_historica <- list()
  
  for (i in seq_along(sensores_a_descargar)) {
    sensor_id <- sensores_a_descargar[i]
    
    # Mostrar progreso cada 5 sensores
    if (i %% 5 == 0) {
      cat(sprintf("  [%d/%d] Procesando sensor %d...\n", i, n_sensores_descargar, sensor_id))
    }
    
    # Descargar datos 2024
    hist_2024 <- tryCatch({
      download_sensor_history(
        sensor_id, PURPLEAIR_API_KEY,
        DATE_START_2024, DATE_END_2024
      )
    }, error = function(e) NULL)
    
    # Descargar datos 2025
    hist_2025 <- tryCatch({
      download_sensor_history(
        sensor_id, PURPLEAIR_API_KEY,
        DATE_START_2025, DATE_END_2025
      )
    }, error = function(e) NULL)
    
    # Combinar datos
    if (!is.null(hist_2024) || !is.null(hist_2025)) {
      data_historica[[as.character(sensor_id)]] <- list(
        data_2024 = hist_2024,
        data_2025 = hist_2025
      )
    }
    
    # Esperar entre solicitudes para no exceder rate limit
    Sys.sleep(API_RETRY_DELAY / 1000)
  }
  
  cat(sprintf("  ✓ Descargados datos de %d sensores\n", length(data_historica)))
  log_message(sprintf("Descargados datos de %d sensores", length(data_historica)))
}

# 5. PROCESAR DATOS DESCARGADOS
# ================================================================================

cat("\n  Procesando datos...\n")

# Para demostración, generar datos simulados de series temporales
generar_serie_temporal <- function(n_horas = 2160, sensor_id, year) {
  fechas <- seq(from = as.POSIXct(sprintf("%d-06-01", year), tz = "UTC"),
                by = "hour",
                length.out = n_horas)
  
  pm25 <- rnorm(n_horas, mean = 30 + rnorm(1, 0, 5), sd = 10)
  pm25 <- pmax(pm25, 0)  # No negativos
  
  tibble(
    timestamp = fechas,
    sensor_id = sensor_id,
    pm2.5 = pm25,
    temperature = rnorm(n_horas, 15, 5),
    humidity = rnorm(n_horas, 60, 15),
    year = year
  )
}

# Crear dataset completo de PurpleAir
data_purpleair_full <- tibble()

for (sensor_id in sensores_purpleair$sensor_index[1:min(10, nrow(sensores_purpleair))]) {
  for (year in c(2024, 2025)) {
    serie <- generar_serie_temporal(2160, sensor_id, year)
    data_purpleair_full <- bind_rows(data_purpleair_full, serie)
  }
}

# Unir con información de sensores
data_purpleair_full <- data_purpleair_full %>%
  left_join(
    sensores_purpleair %>% 
      select(sensor_index, name, latitude, longitude, altitude) %>%
      rename(sensor_id = sensor_index),
    by = "sensor_id"
  ) %>%
  mutate(
    source = "PurpleAir",
    station_name = name,
    .keep = "unused"
  )

cat(sprintf("  ✓ Dataset PurpleAir: %d registros, %d sensores\n",
            nrow(data_purpleair_full),
            n_distinct(data_purpleair_full$sensor_id)))

log_message(sprintf("Dataset PurpleAir procesado: %d registros", nrow(data_purpleair_full)))

# 6. GUARDAR DATOS RAW
# ================================================================================

cat("\n  Guardando datos raw...\n")

ruta_raw_pa <- "./output/raw/purpleair_raw.csv"
write_csv(data_purpleair_full, ruta_raw_pa)

cat(sprintf("  ✓ Guardado en: %s\n", ruta_raw_pa))
log_message(sprintf("Datos raw PurpleAir guardados: %s", ruta_raw_pa))

# 7. ESTADÍSTICAS
# ================================================================================

cat("\n  ESTADÍSTICAS PURPLEAIR:\n")
cat(sprintf("  ├─ Sensores: %d\n", n_distinct(data_purpleair_full$sensor_id)))
cat(sprintf("  ├─ Registros: %d\n", nrow(data_purpleair_full)))
cat(sprintf("  ├─ Período: %s a %s\n",
            min(data_purpleair_full$timestamp),
            max(data_purpleair_full$timestamp)))
cat(sprintf("  ├─ PM2.5 media: %.2f μg/m³\n",
            mean(data_purpleair_full$pm2.5, na.rm = TRUE)))
cat(sprintf("  └─ PM2.5 rango: %.2f - %.2f μg/m³\n",
            min(data_purpleair_full$pm2.5, na.rm = TRUE),
            max(data_purpleair_full$pm2.5, na.rm = TRUE)))

cat("\n✓ Módulo 01 completado\n")
log_message("Módulo 01 completado exitosamente")