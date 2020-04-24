#This file uses the merged On-Marg Stats Canada Boundary
#to create an index using a point file.

# Creating an Index with On-Marg Data -------------------------------

#The following code requires a DA shape file (you can use the one created above)
#and a geocoded point shape file  

library(sf)

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

#School Summaries

SchoolSummary <- SJtest %>%
  group_by(Schoolname, SchoolCode) %>%
  summarize(OnMargIndex = mean(as.numeric(Summary)))

#check to see what the spatially joined data looks like
SchoolSummary

#check to see what the spatially joined object looks like plotted
#note that although there are only school records, every individual
#student point appears to be retained in the geometry
ggplot() +
  geom_sf(data=SchoolSummary) +
  ggtitle("School Summary and OnMarg Data") +
  coord_sf()

#Convert the spatially joined shape object to a dataframe
SchoolSummary.df <- st_drop_geometry(SchoolSummary)

