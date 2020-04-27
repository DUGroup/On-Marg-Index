#This file constructs the ON-MARG data and merges it with
#Statistics Canada DA Boundary files for mapping.

# Getting Started with On-Marg data ---------------------------------------
library(httr)       #Access and download the online file
library(XLConnect)  #Load data from the downloaded excel file
library(sf)         #Managing ESRI Shape files and geometry
library(viridis)    #Color pallette
library(ggplot2)    #Plotting shape file

##########Download the OnMarg datafile - working with Worksheet 4 with DA data
GET("https://www.publichealthontario.ca/-/media/data-files/index-on-marg.xls?la=en", 
    write_disk(tf <- tempfile(fileext = ".xls")))  #save as temporary file

wb <- loadWorkbook(tf)           #load the excel file

#Excel File layout:
# Worksheet 1: 2016 ON-Marg: file description
# Worksheet 2: Variable Descriptions
# Worksheet 3: Disclaimers
# Worksheet 4: DA_2016
# Worksheet 5: 2016_CTUID
# Worksheet 6: 2016_ADAUID
# Worksheet 7: 2016_CSDUID
# Worksheet 8: 2016_CCSUID
# Worksheet 9: 2016_CDUID
# Worksheet 10: 2016_CMAUID
# Worksheet 11: 2016_PHUUID
# Worksheet 12: 2016_LHINUID
# Worksheet 13: 2016_LHINSRUID

# Load in Worksheet
OnMarg.raw <- readWorksheet(wb, sheet=4) #load the data from the

##########Download the Statistics Canada DA Boundary Shape file
#create temporary files
temp <- tempfile()
temp2 <- tempfile()

#download the zip folder from the internet save to 'temp' 
#this is a large file and will take a while
download.file("http://www12.statcan.gc.ca/census-recensement/2011/geo/bound-limit/files-fichiers/2016/lda_000a16a_e.zip",temp)

#unzip the contents in 'temp' and save unzipped content in 'temp2'
unzip(zipfile = temp, exdir = temp2)

#finds the filepath of the shapefile (.shp) file in the temp2 unzip folder
#the $ at the end of ".shp$" ensures you are not also finding files such as .shp.xml 
DA_SHP_file<-list.files(temp2, pattern = ".shp$",full.names=TRUE)

#Load the DA shape file
DA <- st_read(DA_SHP_file, stringsAsFactors = FALSE)

#decide on a CRS that you want to use:  
CRStoUse <- st_crs("+init=EPSG:4269")  #NAD83 UTM zone 17N
DA.reprojected <- st_transform(DA, CRStoUse)

#align the CRS
OnMargDA <- merge(DA.reprojected, OnMarg.raw, by = "DAUID") %>%
  mutate(Summary = (Instability_q_DA16 +
                    Deprivation_q_DA16 +
                    Dependency_q_DA16 +
                    Ethniccon_q_DA16)/4)

#plot the provincial DA shape file

ggplot(data = OnMargDA, aes(fill=Summary, color=Summary)) +
  geom_sf() +
  scale_fill_viridis() + 
  scale_color_viridis() +
  ggtitle("OnMarg Data") +
  coord_sf()