#Setup
library(dplyr) #data tidying
library(rgdal)
library(leaflet) #mapping
library(ggmap) #to query lat/lon
library(htmltools)
library(tmap) #thematic maps
options(stringsAsFactors = FALSE)
#Set API key
source('~/ggmap key.R')
ggmap::register_google(key = key)

#Get latitude and longitude
#rebase_tbl<- readRDS("rebase_tbl.rds")
rebase_tbl_complete<- readRDS("rebase_tbl_complete.rds")


# Get latitude and longitude ---------------------------------------------

#Get latitude and longitude using ggmap (adds 2 new columns with lat and lon)

rebase_locs<-mutate_geocode(rebase_tbl_complete, geo)

saveRDS(rebase_locs, file="rebase_locs.rds")

rebase_locs<- readRDS("rebase_locs.rds") %>% mutate_at(., "tempr", as.numeric)



#Look at lat and lon values
summary(rebase_locs$lat)
summary(rebase_locs$lon)


# World map shapefile ----------------------------------------------------
library(raster)
#source
#http://thematicmapping.org/downloads/world_borders.php

countries<- shapefile("TM_WORLD_BORDERS-0.3/TM_WORLD_BORDERS-0.3.shp")

# Add layers data --------------------------------------------------------

#Research data
#source: https://www.scimagojr.com/countryrank.php
source("res.R")

#Volcano data
#source: https://earthworks.stanford.edu/catalog/harvard-glb-volc
source("volc.R")

# Prepare research_data and the shapefile -------------------------------

library(tigris)
research_data_joined<- geo_join(countries, research_data, "NAME", "country")


# leaflet colors ---------------------------------------------------------
library(RColorBrewer)

#Publications map overlay colors
pal<- colorNumeric (
  #palette = colorRamp(c("#18639e", "#b7d4eb"), interpolate="spline"), 
  palette = c('#1C3CBA', '#4359BC', '#5A6DC5', '#7181CE',
              '#8896D7', '#9FABDF', '#B7C0E7',
              '#CFD5EF'),
  domain = research_data_joined$citable_documents,
  reverse = T)

#Growth temperature colors
palgrowth<- colorNumeric (
  #palette = brewer.pal(6, "RdBu"),
  palette = c('#b2182b','#b92f40', '#da6f5e', '#E88D66',
               '#FFAB7A','#BADDEF','#4393c3'),
  domain = rebase_locs$tempr, 
  na.color = '#cccccc',
  reverse = T)

# palette maker: https://coolors.co/b2182b-b92f40-da6f5e-4393c3-baddef

# labels functions --------------------------------------------------------

#Allow newline in each label
twolabels<- function(enz, samplet) {
  htmltools::HTML(
    sprintf(
    "<b>Restriction Enzyme:</b> %s<br/>
     <b>Sample:</b> %s",
    enz, samplet)
    )
}

threelabels<- function(enz, samplet, temp) {
  htmltools::HTML(
    sprintf(
      "<b>Restriction Enzyme:</b> %s<br/>
       <b>Sample:</b> %s<br/>
       <b>Temp:</b> %s°C
      ",
      enz, samplet, temp)
  )
}

# Rebase leaflet map -----------------------------------------------------

#Making the map!
library(parallel)
options(mc.cores = 2L)

rebase_map<- leaflet(rebase_locs) %>%
  ## Set view settings
  setMaxBounds( lng1 = -180 , 
                lat1 = 85,
                lng2 = 180,
                lat2 = -85 ) %>% 
  setView(lng = 0, lat = 0, zoom = 1) %>% 
  addProviderTiles("CartoDB.Positron", group = "Base map") %>% 
  
  ## Overlay groups
  # Organisms-only layer
  addCircles(lng = ~lon, lat = ~lat, 
             label = ~map2(rebase_locs$REnz, 
                           rebase_locs$sample_type, twolabels), 
             group = "Organisms"
              ) %>%
  
  # Layer to color map by research articles, with organism points added
  addPolygons(data = research_data_joined, stroke = FALSE,
              smoothFactor = 0.5, fillOpacity = 0.8,
              color = ~pal(research_data_joined$citable_documents),
              group = "Research Articles per Country") %>% 
  addCircles(data = rebase_locs, lng = ~lon, lat = ~lat, 
             #label = ~map2(rebase_locs$REnz, 
                            #rebase_locs$sample_type, labels),
             color = "#000000", radius = 5,
             group = "Research Articles per Country") %>%
  addLegend("bottomright", pal = pal, 
            values = research_data_joined$citable_documents,
            title = "Total Research Publications 1996-2018",
            opacity = 0.8, 
            group = "Research Articles per Country") %>%
  
  # Layer for volcanic data
  addCircles(data = volcano_data_sh, 
             lng = ~volcano_data_sh$LON, lat = ~volcano_data_sh$LAT, 
             stroke = F, opacity = 0.3,
             dashArray = T,
             fillOpacity = 0.3,
             radius = 30,
             color = '#C1539B',
             group = "Volcanic Activity") %>% 
  
  # Layer adding organism points colored by growth temperature
  addCircles(lng = ~lon, lat = ~lat,
             label = ~pmap(list(rebase_locs$REnz, 
                           rebase_locs$sample_type,
                           rebase_locs$tempr),
                           threelabels),
             group = "Organisms by growth temperature",
             color = ~palgrowth(tempr)) %>% 
  addLegend("bottomright", pal = palgrowth, 
            values = rebase_locs$tempr,
            title = "Growth temperature",
            labFormat = labelFormat(suffix = "°C"),
            opacity = 1, 
            group = "Organisms by growth temperature") %>%
 
  
  ## Layers control
  addLayersControl(
    baseGroups = c("Base map"),
    overlayGroups = c("Organisms", "Research Articles per Country",
                      "Organisms by growth temperature",
                      "Volcanic Activity"),
    options = layersControlOptions(collapsed = FALSE)
    ) %>% 
    hideGroup(c("Research Articles per Country", 
                "Organisms by growth temperature","Volcanic Activity"))

  
rebase_map


# end map ----------------------------------------------------------------



















































#leaflet(options = leafletOptions(minZoom = 10, maxZoom = 1))

pal <- colorNumeric (
  palette = colorRamp(c("#18639e", "#b7d4eb"), interpolate="spline"), 
  domain = research_data_joined$citable_documents,
  reverse = F)

leaflet() %>% 
  setView(lng = 0, lat = 0, zoom = 1) %>% 
  addProviderTiles("CartoDB.Positron", group = "Base map") %>% 
  addPolygons(data = research_data_joined, stroke = FALSE,
              smoothFactor = 0.5, fillOpacity = 0.8,
              color = ~pal(research_data_joined$citable_documents),
              group = "Publications 1996-2018") %>% 
  addLegend("bottomright", pal = pal, 
            values = research_data_joined$citable_documents,
            title = "R",
            opacity = 1,
            group = "Publications 1996-2018")



# fix labels -------------------------------------------------------------


# https://rpubs.com/bhaskarvk/leaflet-labels


html_print( paste(
  paste0(HTML("<p></p>","Restriction Enzyme","<p></p>"), 
         rebase_locs$REnz), 
  paste0("Sample", rebase_locs$sample_type),
  sep =  ""  ) ) 

html_print( HTML(paste(
     "<p>","Restriction Enzyme:", " ", rebase_locs$REnz, "<p></p>",
     "Sample:", " ", rebase_locs$sample_type, 
    sep =  "" )   ) )


labels<- function(x) {
  HTML(paste(
    "Restriction Enzyme:", " ", x['REnz'], "/n",
    "Sample:", " ", x['sample_type'], 
    sep =  "" )   ) 
}

rebase_locs3<-rebase_locs[1:10]

apply(rebase_locs3, 1, labels)

apply_labels<- function(x) {
  for (i in nrow(x)) {
  HTML(paste(
    "<p>","Restriction Enzyme:", " ", x[i,'REnz'], "<p></p>",
    "Sample:", " ", x[i,'sample_type'], 
    sep =  "" )    )}}

html_print( htmltools::HTML("<em>Restriction Enzyme:</em>"))


html_print(
apply(rebase_locs, 1, function(x) {
  HTML(paste(
  "<p>","Restriction Enzyme:", " ", rebase_locs[x,'REnz'], "<p></p>",
        "Sample:", " ", rebase_locs[x,'sample_type'], 
  sep =  "" )    )})
)