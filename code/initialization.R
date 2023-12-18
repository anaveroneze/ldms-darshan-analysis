###########################################################################
# IMPORTING R libraries for processing data and generating visualizations
# Install R packages as:
# $ install.packages(c("dplyr", "tidyverse", "arrow", "viridis", "patchwork"))
###########################################################################
options(crayon.enabled=FALSE)
library(dplyr)
library(tidyverse) 
library(arrow)
library(lubridate)
library(viridis)
library(patchwork)
library(scales)
library(forcats)

my_theme <- function() {                                                                                                                       
    theme_bw(base_size=10) +                                                                                                                   
    theme(panel.background = element_blank(),                                                                                                  
        legend.box.margin = margin(0,0,0,0),                                                                                                 
        legend.spacing = unit(0, "pt"),                                                                                                      
        legend.position = "top",                                                                                                             
        legend.text = element_text(color = "black", size = 10),                                                                              
        panel.grid.minor = element_blank(),
        panel.grid.major = element_blank(),                                                                                                  
        strip.text.x = element_text(size = 10),                                                                                              
        strip.text.y = element_text(size = 10),                                                                                              
        legend.box.spacing = unit(0, "pt"))                                                                                                  
}