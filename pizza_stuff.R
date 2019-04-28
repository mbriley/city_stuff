library(tidyverse)
library(RSocrata)

#### Setup ----
# token to access Socrata API
token <- read_file('tokens/pizza_rat')

# set gg theme
theme_set(theme_minimal())

#### Find Rat Complaints ----
# query to get all 311 complaints
endpoint_311 <- "https://data.cityofnewyork.us/resource/fhrw-4uyv.csv"
query_311    <- paste0(endpoint_311, "?$where=created_date between '2019-04-20' and '2019-04-27'")

# pull complaints
test_df <- read.socrata(query_311,
                   app_token = token,
                   email = 'troutmikeriley@gmail.com',
                   password = keyringr::decrypt_kc_pw('nyc_data'))

# what types of complaints are there?
test_df %>% count(descriptor, sort = T)

# filter to only things that look like Rat complaints
rats <- df %>% 
  filter(grepl('pest|rat[ |s]|rodent', descriptor, ignore.case = T))


#### Find Pizza Places ----
# Most comprehensive restaurant data listing I can find is
# a list of all NYCDOH inspections
biz_df <- read.socrata('https://data.cityofnewyork.us/resource/43nn-pn8j.csv', 
                       app_token = token, 
                       email = 'troutmikeriley@gmail.com', 
                       password = keyringr::decrypt_kc_pw('nyc_data'))

# the data contains a cuisine description field...
biz_df <- biz_df %>% mutate(pizza = cuisine_description == 'Pizza')

# but there are some restaurants whose name contains "pizza" or "pizzeria"
# that are not categorized as such.
biz_df %>% 
  filter(!pizza & grepl('pizza|pizzeria', dba, ignore.case = T)) %>% 
  count(dba, cuisine_description)

# let's accept an inclusive definition of what it means to be a "pizza place".
biz_df <- biz_df %>% 
  mutate(pizza = ifelse(grepl('pizza|pizzeria', dba, ignore.case = T),
                        TRUE, pizza))

pizza_places <- biz_df %>% 
  filter(pizza) %>% 
  count(camis, dba, boro, zipcode, building, street) %>% 
  rename(complaints = n)


