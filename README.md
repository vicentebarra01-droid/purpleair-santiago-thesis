# Análisis de Zonificación Espacial de PM2.5 en Santiago de Chile

**Proyecto de Tesis**: Integración de datos PurpleAir y SINCA para characterización espacial de calidad del aire.

## 📋 Descripción

Script completo en R para análisis de zonificación espacial de PM2.5 en Santiago de Chile usando:
- **Datos PurpleAir**: Sensores distribuidos (API)
- **Datos SINCA**: Estaciones del Sistema Nacional de Información de Calidad del Aire
- **Período de análisis**: Junio-Julio-Agosto 2024 y 2025

## 🎯 Objetivos

1. Descargar datos horarios de PM2.5 desde API PurpleAir
2. Integrar con datos SINCA locales
3. Preprocesamiento y homologación de datos
4. Análisis espacial y clustering (K-means)
5. Generación de zonificación espacial
6. Exportación a formatos SIG (GeoPackage, Shapefile)
7. Visualización mediante mapas temáticos

## 📁 Estructura del Proyecto

```
purpleair-santiago-thesis/
├── README.md                          # Este archivo
├── CONFIGURACION.R                    # Parámetros y variables globales
├── 00_SETUP_INITIAL.R                 # Setup de librerías e inicialización
├── 01_DESCARGA_PURPLEAIR.R            # Descarga de datos API PurpleAir
├── 02_LECTURA_SINCA.R                 # Lectura y preprocesamiento SINCA
├── 03_PREPROCESAMIENTO.R              # Limpieza e integración de datos
├── 04_ANALISIS_ESPACIAL.R             # Análisis espacial y clustering
├── 05_ZONIFICACION.R                  # Generación de zonificación
├── 06_EXPORTACION_SIG.R               # Exportación a QGIS (.gpkg, .shp)
├── 07_VISUALIZACION.R                 # Mapas y gráficos
├── 08_ANALISIS_EXPLORATORIO.R         # EDA y estadísticas
├── MAIN.R                             # Script maestro (ejecutar este)
└── data/
    └── sinca_data.csv                 # [Cargar manualmente]
```

## 🚀 Inicio Rápido

### Requisitos Previos

1. **R >= 4.0** y **RStudio** (recomendado)
2. **API Key de PurpleAir**: https://www2.purpleair.com/api
3. **Datos SINCA**: https://sinca.mma.gob.cl/

### Instalación

```bash
git clone https://github.com/vicentebarra01-droid/purpleair-santiago-thesis.git
cd purpleair-santiago-thesis
```

### Configuración

1. Editar `CONFIGURACION.R`:
```r
PURPLEAIR_API_KEY <- "tu_api_key_aqui"
K_CLUSTERS <- 5
```

2. Cargar datos SINCA en `data/sinca_data.csv`

### Ejecución

```r
source("MAIN.R")
```

## 📊 Outputs

- `santiago_pm25.gpkg`: GeoPackage para QGIS
- `integrado_pm25.csv`: Dataset procesado
- Mapas PNG y visualizaciones
- Log detallado de análisis

## 📚 Referencias

- [PurpleAir API](https://www2.purpleair.com/api)
- [SINCA](https://sinca.mma.gob.cl/)
- [sf - Simple Features](https://r-spatial.github.io/sf/)
- [tidyverse](https://www.tidyverse.org/)

---

**Última actualización**: 2026-07-01