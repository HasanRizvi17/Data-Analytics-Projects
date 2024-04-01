# Importing the relevant libraries
library(tidyr)
library(dplyr)
library(stringr)
library(readxl)
library(readr)
library(writexl)
library(lubridate)
library(ggplot2)


# Importing the datasets
orders <- read_csv("Orders.csv")
order_items <- read_excel(path = "Order Items.xlsx")
users <- read_excel(path = "Users.xlsx")
retailers <- read_excel(path = "Retailers.xlsx")


# Standardizing the column names to remove spaces
colnames(orders) <- make.names(colnames(orders))
colnames(order_items) <- make.names(colnames(order_items))
colnames(users) <- make.names(colnames(users))
colnames(retailers) <- make.names(colnames(retailers))


# Pre-processing the raw data tables
orders <- orders %>%
  select(c(ID, User.ID, Order.Number, Created.At)) %>%
  rename(order.date = Created.At)

order_items <- order_items %>%
  select(-c(Status, Tag)) %>%
  rename(Quantity = Qt.Y, sku.id = Sk.U.ID) %>%
  mutate(Order.ID = as.numeric(Order.ID)) %>%
  drop_na(sku.id)=

users <- users %>%
  rename(user.name = Name, user.mobile = Mobile, user.email = Email,
         user.created.date = Created.At) %>%
  select(ID, user.name, user.mobile, user.email, user.created.date) %>%
  filter(!(str_detect(string = user.name, pattern = "[Tt][Ee][Ss][Tt]"))) # removing the test users
retailers <- retailers %>%
  rename(Retailer.ID = ID, Retailer.Address = Address, 
         retailstore.Lat.Long = Lat.Lng) %>%
  select(Retailer.ID, User.ID, Store.Name, City.ID, Retailer.Address, 
         retailstore.Lat.Long)

customers <- users %>%
  right_join(x = ., y = retailers, by = c("ID" = "User.ID")) %>%
  rename(User.ID = ID) %>%
  mutate(User.ID = as.numeric(User.ID), 
         City = if_else(City.ID==1, "Karachi", 
                        if_else(City.ID==2, "Lahore", "NA"))) %>%
  select(User.ID, user.name, user.mobile, Store.Name, City,
         Retailer.Address, retailstore.Lat.Long)
colSums(is.na(customers))


#==================================================


# (Ignore) Temporary modeling for downstream analysis

orders_info <- order_items %>%
  left_join(x=., y=orders, by = c("Order.ID"="ID"))
colSums(is.na(orders_info))

# adding the city column
unique(str_sub(orders_info$Order.Number, 1, 3))
# "KHI" "LHR" "002" "001"
orders_info <- orders_info %>%
  mutate(order_amount = Price* Quantity, # order value
         order.date = as.Date(order.date)) %>% # converting timestamp to date
  filter(order.date < "2020-11-02")


#--------------------------------------------------------


### RFM
rfm <- orders_info %>%
  group_by(User.ID, order.date) %>% # clubbing together all orders on the same date as one order
  summarise(total_gmv_value = sum(order_amount, na.rm = TRUE)) %>%
  group_by(User.ID) %>%
  summarise(first_order_date = min(order.date),
            recency = as.numeric(as.Date("2020-11-01") - max(as.Date(order.date))),
            frequency = n(), 
            monetary = sum(total_gmv_value)) %>%
  arrange(recency, desc(frequency), desc(monetary))
rfm <- drop_na(data = rfm, User.ID) # dropping missing values of User.ID
colSums(is.na(rfm))
summary(rfm)


# checking the distributions to make the scoring scale
ggplot(rfm, aes(x=recency)) +
  geom_histogram()
ggplot(rfm, aes(x=frequency)) +
  geom_histogram(binwidth = 10)
ggplot(rfm, aes(x=monetary)) +
  geom_histogram(binwidth = 1000)


# RFM Scoring
# R_score (based on overall GMV)
rfm$R_Score <- NA
rfm$R_Score[rfm$recency>30] <- 1
rfm$R_Score[rfm$recency>14 & rfm$recency<=30] <- 2
rfm$R_Score[rfm$recency>7 & rfm$recency<=14] <- 3
rfm$R_Score[rfm$recency<=7] <- 4
# F_score
rfm$F_Score <- NA
rfm$F_Score[rfm$frequency<5] <- 1
rfm$F_Score[rfm$frequency>=5 & rfm$frequency<10] <- 2
rfm$F_Score[rfm$frequency>=10 & rfm$frequency<20] <- 3
rfm$F_Score[rfm$frequency>=20] <- 4
# M_score
rfm$M_Score <- NA
rfm$M_Score[rfm$monetary<10000] <- 1
rfm$M_Score[rfm$monetary>=10000 & rfm$monetary<50000] <- 2
rfm$M_Score[rfm$monetary>=50000 & rfm$monetary<100000] <- 3
rfm$M_Score[rfm$monetary>=100000] <- 4
# RFM_score
rfm <- rfm %>% mutate(RFM_Score = 100*R_Score + 10*F_Score + M_Score)
colSums(is.na(rfm)) # no missing value


### Customer Segmentation (Custom)
champions <- c(444)
loyal_customers <- c(343,344,433,434,443,441,442)
potential_loyalist <- c(332,333,334,341,342,412,413,414,431,432,421,422,423,424)
recent_customers <- c(411)
needing_attention <- c(221,222,223,224,231,232,233,241,
                       311,312,313,314,321,322,323,324,331)
about_to_sleep <- c(211,212,213,214)
at_risk <- c(121,122,123,131,132,133,141,142)
cant_lose <- c(124,134,143,144,234,242,243,244) # have generated a lot of gmv and/or placed many orders
lost <- c(111,112,113,114)


rfm$segmentRFM <- NA
rfm$segmentRFM[which(rfm$RFM_Score %in% champions)] = "Champions"
rfm$segmentRFM[which(rfm$RFM_Score %in% loyal_customers)] = "Loyal Customers"
rfm$segmentRFM[which(rfm$RFM_Score %in% potential_loyalist)] = "Potential Loyalist"
rfm$segmentRFM[which(rfm$RFM_Score %in% recent_customers)] = "Recent customers"
rfm$segmentRFM[which(rfm$RFM_Score %in% needing_attention)] = "Customer Needing Attention"
rfm$segmentRFM[which(rfm$RFM_Score %in% about_to_sleep)] = "About to Sleep"
rfm$segmentRFM[which(rfm$RFM_Score %in% at_risk)] = "At Risk"
rfm$segmentRFM[which(rfm$RFM_Score %in% cant_lose)] = "Can’t Lose Them"
rfm$segmentRFM[which(rfm$RFM_Score %in% lost)] = "Lost"


rfm <- rfm %>%
  mutate(Overall_AOV = sum(monetary)/sum(frequency))


# joining the RFM dataset to the master customer information table
RFM <- rfm %>%
  left_join(x=., y=customers, by = c("User.ID"="User.ID"))
colSums(is.na(RFM))


# saving to excel file
write_xlsx(RFM, "Customer Segmentation/RFM Analysis/RFM segmentation temp.xlsx")


# distribution of customer count in each segment
RFM %>%
  count(segmentRFM) %>%
  arrange(desc(n)) %>%
  rename(segmentRFM = segmentRFM, Count = n) %>%
  View()
rfm %>%
  group_by(segmentRFM) %>%
  summarise(count = n()) %>%
  ggplot(aes(x = count, y = reorder(segmentRFM, count), fill = segmentRFM)) +
    geom_col() +
    theme(legend.position = "none") +
    scale_x_continuous(breaks=seq(from=0,to=2750,by=250)) +
    labs(title = "Number of Customers by Segment", y = "Segment")


# median values of r by segment
rfm %>%
  group_by(segmentRFM) %>%
  summarise(median_recency = median(recency)) %>%
  ggplot(aes(x = median_recency, y = segmentRFM, fill = segmentRFM)) +
  geom_col()
# median values of f by segment
rfm %>%
  group_by(segmentRFM) %>%
  summarise(median_frequency = median(frequency)) %>%
  ggplot(aes(x = median_frequency, y = segmentRFM, fill = segmentRFM)) +
  geom_col()
# median values of m by segment
rfm %>%
  group_by(segmentRFM) %>%
  summarise(median_monetary = median(monetary)) %>%
  ggplot(aes(x = median_monetary, y = segmentRFM, fill = segmentRFM)) +
  geom_col()
