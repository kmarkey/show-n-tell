library(jsonlite)
library(here)

source("functions.R")

# only 1 var, only 1 grade
url_g4 <- "https://www.nationsreportcard.gov/DataService/GetAdhocData.aspx?type=data&subject=reading&grade=4&subscale=RRPCM&jurisdiction=NT,AL,AR,DE,FL,GA,KY,LA,MD,MS,NC,OK,SC,TN,TX,SC,VA,WV&variable=TOTAL&stattype=MN:MN,ALC:BB,ALC:AB,ALC:AP,ALC:AD&Year=2005,2007,2009,2011,2013,2015,2017,2019,2022"

url_g8 <- "https://www.nationsreportcard.gov/DataService/GetAdhocData.aspx?type=data&subject=reading&grade=8&subscale=RRPCM&jurisdiction=NT,AL,AR,DE,FL,GA,KY,LA,MD,MS,NC,OK,SC,TN,TX,SC,VA,WV&variable=TOTAL&stattype=MN:MN,ALC:BB,ALC:AB,ALC:AP,ALC:AD&Year=2005,2007,2009,2011,2013,2015,2017,2019,2022"

url_g12 <- "https://www.nationsreportcard.gov/DataService/GetAdhocData.aspx?type=data&subject=reading&grade=12&subscale=RRPCM&jurisdiction=NT,AL,AR,DE,FL,GA,KY,LA,MD,MS,NC,OK,SC,TN,TX,SC,VA,WV&variable=TOTAL&stattype=MN:MN,ALC:BB,ALC:AB,ALC:AP,ALC:AD&Year=2005,2007,2009,2011,2013,2015,2017,2019,2022"

g4 <- nations_report_card(url_g4)

g8 <- nations_report_card(url_g8)

g12 <- nations_report_card(url_g12)

nrc <- bind_rows(g4, g8, g12)

write_csv(nrc, "data/nations_report_card.csv")