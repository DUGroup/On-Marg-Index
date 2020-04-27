#This file uses the merged On-Marg Stats Canada Boundary
#to create an index using a point file.

# Creating an Index with On-Marg Data -------------------------------

#The following code requires a DA shape file (you can use the one created above)
#and a geocoded point shape file  

#A note about the point file:
#In each of the following contexts, the point file could represent:
# Health: Each record is a patient (point) which can be grouped by hospital
# Municipality: Each record is a resident (point) which can be grouped by services used
# Education: Each record is a student (point) which can be grouped by school
# Retail: Each record is a customer (point) which can be grouped by product purchased

library(sf)
library(ggplot2)
library(dplyr)
library(data.table)

#file locations
Shapefile <- "C:/GIS/OnMarg - 1920 Geo/DDSB_DA_ONMarg16_UTMNAD81Z17N.shp"
Pointfile <- "C:/GIS/Points.shp"

#loading shape data  (here I have used my own)
OnMarg <- st_read(Shapefile, stringsAsFactors = FALSE)
Geocode <- st_read(Pointfile, stringsAsFactors = FALSE)

#aligning CRS
#Check to see whether the CRS types are the same
st_crs(OnMarg)
st_crs(Geocode)

#decide on a CRS that you want to use:  
CRStoUse <- st_crs("+init=EPSG:4269")  #NAD83 UTM zone 17N
Geocode.reprojected <- st_transform(Geocode, CRStoUse)
OnMarg.reprojected <- st_transform(OnMarg, CRStoUse)

#####View shapefile metadata
#geometry type
st_geometry_type(OnMarg)

#boundary extent
st_bbox(OnMarg)

#####plot the map
ggplot() +
  geom_sf(data=OnMarg.reprojected) +
  geom_sf(data=Geocode.reprojected) +
  ggtitle("DDSB DAs and OnMarg Data") +
  coord_sf()

##spatial join - add the attributes of the polygons (OnMarg.reprojected) 
##to the geocoded points (Geocode.reprojected)
##First make sure both objects are using the same CRS
SJtest <- st_join(Geocode.reprojected, left = FALSE, OnMarg.reprojected)

#Point Summaries - attached ONMarg Values to points based on the DA's they are located in
#in the following code:
#"Groupname" is the field in your geocode file that each record belongs to
#"GroupCode" is also a field in your geocode file that each record belongs to
#In my example I had a text label (Groupname) and a numeric label (GroupCode)
#that each record belonged to.
#Change the variables listed in the group_by() to the fields in your dataframe
#that identifies the group each record belongs to.

GroupSummary <- SJtest %>%
  group_by(Groupname, GroupCode) %>%
  summarize(OnMargIndex = mean(as.numeric(Summary)))

#check to see what the spatially joined data looks like
GroupSummary

#check to see what the spatially joined object looks like plotted
#note that although there are only Point records, every individual
#point (record) appears to be retained in the geometry
ggplot() +
  geom_sf(data=GroupSummary) +
  ggtitle("Group Summary and OnMarg Data") +
  coord_sf()
 
#Convert the spatially joined shape object to a dataframe
PointSummary.df <- st_drop_geometry(GroupSummary)

