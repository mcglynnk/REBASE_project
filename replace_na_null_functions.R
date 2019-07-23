replace_null<- function(x) {
  # Function to replace null values with na.
  #
  gsub(pattern="NULL", replacement = NA, x)
}

replace_na<- function(x) {
  # Function to replace "NA" values with NA. 
  #     *but NOT species names like 'Natrinema'!
  #
  ifelse(nchar(x) < 3,   #if pattern
         gsub(pattern="[Nn][Aa]", replacement = NA, x), #yes
         x) #no
}