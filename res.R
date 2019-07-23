
#source:
#https://www.scimagojr.com/countryrank.php
research_data<- readxl::read_xlsx("papersdata.xlsx")


# clean data -------------------------------------------------------------

research_data<- research_data %>% 
  rename_all(., lst(tolower)) %>% 
  rename(.,  citable_documents = `citable documents`,
         self_citations = `self-citations`) %>% 
  dplyr::select(rank, country, citable_documents)


# ----------------------------------------------------------------------
