############### Parallel DSSAT ############################
########### Load functions necessary
path_functions <- "/home/jeisonmesa/Proyectos/BID/DSSAT-R/"
path_project <- "/home/jeisonmesa/Proyectos/BID/bid-cc-agricultural-sector/"

# Cargar data frame entradas para DSSAT


load(paste0(path_project, "14-ObjectsR/Soil.RData"))
rm(list=setdiff(ls(), c("Extraer.SoilDSSAT", "values", "Soil_profile", "Cod_Ref_and_Position_Generic", "make_soilfile"
                        , "Soil_Generic", "wise", "in_data", "read_oneSoilFile", "path_functions", "path_project", "Cod_Ref_and_Position")))


load(paste0(path_project, "/08-Cells_toRun/matrices_cultivo/Rice_riego.Rdat"))
load(paste0(path_project, "/08-Cells_toRun/matrices_cultivo/Rice_secano.Rdat"))

source(paste0(path_functions, "main_functions.R"))     ## Cargar funciones principales
source(paste0(path_functions, "make_xfile.R"))         ## Cargar funcion para escribir Xfile DSSAT
source(paste0(path_functions, "make_wth.R")) 
source(paste0(path_functions, "dssat_batch.R"))
source(paste0(path_functions, "DSSAT_run.R"))

# Separacion Aplicacion de Nitrogeno
# Cambiar crop_riego o crop_secano (para cada cultivo cambia la aplicacion de  nitrogeno tanto la cantidad como el dia de la aplicacion)

day0 <- crop_riego$N.app.0d
day_aplication0 <- rep(0, length(day0))

day30 <- crop_riego$N.app.30d
day_aplication30 <- rep(30, length(day30))

amount <- data.frame(day0, day30)
day_app <- data.frame(day_aplication0, day_aplication30)


# Configurando el experimento para WFD (datos Historicos 1971-1999)

years <- 71:99
data_xfile <- list()
data_xfile$crop <- "RICE" 
data_xfile$exp_details <- "*EXP.DETAILS: BID17101RZ RICE LAC"
data_xfile$name <- "./JBID.RIX" 
data_xfile$CR <- "RI"
data_xfile$INGENO <- "IB0118"
data_xfile$CNAME <- "IRNA"
data_xfile$initation <- crop_riego$mirca.start
data_xfile$final <- crop_riego$mirca.end
data_xfile$system <- "irrigation"  ## Irrigation or rainfed, if is irrigation then automatic irrigation
data_xfile$year <- years[1]
data_xfile$nitrogen_aplication <- list(amount = amount, day_app = day_app)
data_xfile$smodel <- "RIXCER"     ##  Fin Model
data_xfile$bname <- "DSSBatch.v45"


## to test
## Xfile(data_xfile, 1) 


## Cargar datos climaticos WFD

load(paste0(path_project, "14-ObjectsR/wfd/", "ValorWFD.RDat"))

# Climate Data Set
climate_data <- list()
climate_data$year <- 71:99       ## Years where they will simulate yields
climate_data$Srad <- Srad        ## [[year]][pixel, ]   
climate_data$Tmax <- TempMax     ## [[year]][pixel, ]
climate_data$Tmin <- TempMin     ## [[year]][pixel, ]
climate_data$Prec <- Prec        ## [[year]][pixel, ]
climate_data$lat <- crop_riego[,"y"]        ## You can include a vector of latitude
climate_data$long <- crop_riego[, "x"]         ## You can include a vector of longitude
climate_data$wfd <- "wfd"       ## Switch between "wfd" and "model"
climate_data$id <- crop_riego[, "Coincidencias"]

## Entradas para las corridas de DSSAT 

input_data<- list()
input_data$xfile <- data_xfile
# Xfile(input_data$xfile, 158)
input_data$climate <- climate_data

dir_dssat <- "/home/jeisonmesa/Proyectos/BID/DSSAT/bin/csm45_1_23_bin_ifort/"
dir_base <- "/home/jeisonmesa/Proyectos/BID/bid-cc-agricultural-sector/Scratch"


## to test
# input <- input_data
# run_dssat(input_data, 7, dir_dssat, dir_base)


### Comienzo de la paralelilzacion
library(snowfall)
sfInit(parallel = T, cpus = 25)

##EXportar los datos en cada procesador
sfExport("input_data")
sfExport("crop_riego")
sfExport("amount")
sfExport("day_app")


## Exportar los directorios necesarios para corrida en cada procesador
sfExport("dir_dssat")
sfExport("dir_base")
sfExport("path_functions")
sfExport("path_project")


## Exportar las funciones necesarias en cada procesador
sfSource(paste0(path_functions, "main_functions.R"))     ## Cargar funciones principales
sfSource(paste0(path_functions, "make_xfile.R"))         ## Cargar funcion para escribir Xfile DSSAT
sfSource(paste0(path_functions, "make_wth.R")) 
sfSource(paste0(path_functions, "dssat_batch.R"))
sfSource(paste0(path_functions, "DSSAT_run.R"))
sfExport("Soil_Generic")
sfExport("Cod_Ref_and_Position_Generic")
sfExport("read_oneSoilFile")
sfExport("in_data")
sfExport("wise")
sfExport("make_soilfile")
sfExport("Extraer.SoilDSSAT")
sfExport("values")
sfExport("Soil_profile")
sfExport("Cod_Ref_and_Position")

# Correr
for(i in 1600:1640){}
run_dssat(input_data, 1600, dir_dssat, dir_base)

}
Run <- lapply(5:10, function(i) run_dssat(input_data, i, dir_dssat, dir_base))

Run <- sfLapply(1:dim(crop_riego)[1], function(i) run_dssat(input_data, i, dir_dssat, dir_base))



 Codigo_identificadorSoil <- 3456966
sfStop()
