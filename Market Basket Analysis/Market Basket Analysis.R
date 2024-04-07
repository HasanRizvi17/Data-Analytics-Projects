library(readr)
library(readxl)
library(writexl)
library(tidyr)
library(plyr)
library(dplyr)
library(stringr)
library(lubridate)
library(ggplot2)
# libraries for market basket analysis
library(Matrix)
library(grid)
library(arules)
library(arulesViz)
library(datasets)


# removing the code where data was first cleaned and pre-processed 


### Market Basket Analysis for Subcategories of products
#------------------------------------------------------------------


orders_subset <- orders_info %>%
  select(User.ID, order_date, order_time, Subcategory) %>%
  mutate(User.ID = as.numeric(User.ID)) %>%
  arrange(User.ID) %>%
  drop_na(Subcategory)
colSums(is.na(orders_subset))


# Group all the items that were bought together by the same customer on the same date
library(plyr)
itemList <- ddply(orders_subset, c("User.ID","order_date"), 
                  function(df){paste(df$Subcategory,collapse = ",")})
# itemList <- rename(x = itemList, item_list = V1) # rename not working
colnames(itemList)[3] = "item_list"
itemList %>% View()


# Remove member number and date
only_items <- itemList %>%
  select(item_list)


# write the dataframe to csv
write.csv(only_items, "Market Basket Analysis/MBA/only_items (subcategories).csv", 
          quote = FALSE, row.names = TRUE)


# Convert CSV file to Basket Format
trans = read.transactions(file="Market Basket Analysis/MBA/only_items (subcategories).csv",
                          rm.duplicates= TRUE, format="basket", sep=",", 
                          cols=1)
print(trans)
# transactions in sparse format with
# 23659 transactions (rows) and
# 67 items (columns)


summary(trans)
# element (itemset/transaction) length distribution:
#   sizes
# 0    1    2    3    4    5    6    7    8    9   10   11   12   13   14   15   16 
# 53 8525 5046 3353 2191 1533 1033  647  465  264  209  140   85   43   19   18   12 
# 17   18   19   20   21   22   23   31 
# 6    6    2    1    2    2    3    1 
# this indicates that there is 1 item in 8525 transactions, 2 items in 5046
#   transactions and so on


# converting basket format transaction data into dataframe class
trans_df <- as(object = trans, Class = "data.frame")
trans_df <- trans_df[2:length(trans_df$items), ] # getting rid of the first row


# to get the proportion of transations of each item is present in 
itemFrequency(trans)[1:5]


# plotting the frequency of items
itemFrequencyPlot(trans, topN=15, type="absolute", col="wheat2",
                  xlab="Item name", ylab="Frequency (absolute)",
                  main="Absolute Item Frequency Plot")
itemFrequencyPlot(trans, topN=15, type="relative", col="wheat2",
                  xlab="Item name", ylab="Frequency (absolute)",
                  main="Absolute Item Frequency Plot")


# transactions per month
orders_subset %>%
  mutate(Month=as.factor(month(order_date))) %>%
  group_by(Month) %>%
  summarise(Transactions=n_distinct(User.ID, order_date)) %>%
  ggplot(aes(x=Month, y=Transactions)) +
  geom_bar(stat="identity", fill="mistyrose2", 
           show.legend=FALSE, colour="black") +
  geom_label(aes(label=Transactions)) +
  labs(title="Transactions per month") +
  theme_bw()


# Transactions per weekday
orders_subset %>%
  mutate(WeekDay=as.factor(weekdays(as.Date(order_date)))) %>%
  group_by(WeekDay) %>%
  dplyr::summarise(Transactions = n_distinct(User.ID, order_date)) %>%
  ggplot(aes(x=WeekDay, y=Transactions)) +
  geom_bar(stat="identity", fill="peachpuff2", 
           show.legend=FALSE, colour="black") +
  geom_label(aes(label=Transactions)) +
  labs(title="Transactions per weekday") +
  scale_x_discrete(limits=c("Monday", "Tuesday", "Wednesday", "Thursday",
                            "Friday", "Saturday", "Sunday")) +
  theme_bw()


# Transactions per hour
orders_subset %>%
  mutate(Hour=as.factor(hour(hms(order_time)))) %>%
  group_by(Hour) %>%
  dplyr::summarise(Transactions=n_distinct(User.ID, order_date)) %>%
  ggplot(aes(x=Hour, y=Transactions)) +
  geom_col(fill="steelblue1", show.legend=FALSE, colour="black") +
  geom_label(aes(label=Transactions)) +
  labs(title="Transactions per hour") +
  theme_bw()


# Remove quotes from Transaction
trans@itemInfo$labels <- gsub("\"","", trans@itemInfo$labels)


# applying the apriori algorithm
rules <- apriori(data = trans, parameter = list(maxlen = 3, sup = 0.01, 
                                                conf = 0.5, target="rules"))


# Removing unnecessary/repeated/redundant rules
# subset.rules <- which(colSums(is.subset(rules, rules)) > 1) # get subset rules in vector
# length(subset.rules)
# rules_new <- rules[-subset.rules] # remove subset rules.
redundant_rules = is.redundant(rules)
rules_new = rules[!redundant_rules]


# Total number of rules generated
print(length(rules_new))
# summary of the rules
summary(rules_new)


# Converting rules into data frame
# rules_df <- as.data.frame(rules_new) # error, not working
rules_df <- as(rules_new, "data.frame")


# Cleaning the Rules in the dataframe version of rules
rules_df$rules <- str_replace_all(string = rules_df$rules, pattern = "\\{", 
                                  replacement = "")
rules_df$rules <- str_replace_all(string = rules_df$rules, pattern = "\\}", 
                                  replacement = "")
rules_df$rules <- str_replace_all(string = rules_df$rules, pattern = "\"", 
                                  replacement = "")


# inspecting the rules
# inspect(sort(rules_new, by = "lift"))[1:10] # messy output


# saving the results to an excel file
write_xlsx(x = rules_df,
           path = "Market Basket Analysis/MBA/subcategories basket.xlsx")


# Visualizing the association rules
plot(head(rules_new, n=100, by="lift"), engine = "htmlwidget",
     jitter=0)

plot(head(rules_new, n=100, by="lift"), method = "grouped") # messy

# visualizing the top 100 association rules by lift variable 
plot(head(rules_new, n=10, by="lift"), method = "paracoord",
     engine = "default")
# this plot shows that if the customer buys the product at the tail of
#   the arrow, then he is likely to buy the product at the head as well
# The width of the arrows represents support and the intensity of the 
#   color represent confidence. 
# For larger rule sets visual analysis becomes difficult since with an 
#   increasing number of rules also the number of crossovers between 
#   the lines increases

# visualizing the top 100 association rules by lift variable 
plot(head(rules_new, n=100, by="lift"), method = "graph",
     engine = "htmlwidget")



#================================================================



### Market Basket Analysis for Product Names
#------------------------------------------------------------------


orders_subset2 <- orders_info %>%
  select(User.ID, order_date, order_time, product.name) %>%
  mutate(User.ID = as.numeric(User.ID)) %>%
  arrange(User.ID) %>%
  drop_na(product.name)
colSums(is.na(orders_subset2))


# Group all the items that were bought together by the same customer on the same date
library(plyr)
itemList2 <- ddply(orders_subset2, c("User.ID","order_date"), 
                   function(df){paste(df$product.name,collapse = ",")})
# itemList2 <- rename(x = itemList2, item_list = V1) # rename not working
colnames(itemList2)[3] = "item_list"
# itemList2 %>% View()


# Remove member number and date
only_items2 <- itemList2 %>%
  select(item_list)


# write the dataframe to csv
write.csv(only_items2, 
          "Market Basket Analysis/MBA/only_items (products).csv", 
          quote = FALSE, row.names = TRUE)


# Convert CSV file to Basket Format
trans2 = read.transactions(file="Market Basket Analysis/MBA/only_items (products).csv",
                           rm.duplicates= TRUE, format="basket", sep=",", 
                           cols=1)
print(trans2)
# transactions in sparse format with
# 23659 transactions (rows) and
# 67 items (columns)
summary(trans2)


# converting basket format transaction data into dataframe class
trans_df2 <- as(object = trans2, Class = "data.frame")
trans_df2 <- trans_df2[2:length(trans_df2$items), ]


# to get the proportion of transations of each item is present in 
itemFrequency(trans2)[1:5]


# plotting the frequency of items
itemFrequencyPlot(trans2, topN=15, type="absolute", col="wheat2",
                  xlab="Item name", ylab="Frequency (absolute)",
                  main="Absolute Item Frequency Plot")
itemFrequencyPlot(trans2, topN=15, type="relative", col="wheat2",
                  xlab="Item name", ylab="Frequency (absolute)",
                  main="Absolute Item Frequency Plot")


# Remove quotes from Transaction
trans2@itemInfo$labels <- gsub("\"","", trans2@itemInfo$labels)


# applying the apriori algorithm
rules2 <- apriori(data = trans2, parameter = list(sup = 0.01, 
                                                  conf = 0.5, target="rules"))

  
# Removing unnecessary/repeated/redundant rules
subset.rules2 <- which(colSums(is.subset(rules2, rules2)) > 1) # get subset rules in vector
length(subset.rules2)
rules_new2 <- rules2[-subset.rules2] # remove subset rules.
# redundant_rules = is.redundant(rules2)
# rules_new2 = rules2[!redundant_rules]


# Total number of rules generated
print(length(rules_new2))
# summary of the rules
summary(rules_new2)


# Converting rules into data frame
# rules_df <- as.data.frame(rules_new) # error, not working
rules_df2 <- as(rules_new2, "data.frame")


# Cleaning the Rules in the dataframe version of rules
rules_df2$rules <- str_replace_all(string = rules_df2$rules, pattern = "\\{", 
                                   replacement = "")
rules_df2$rules <- str_replace_all(string = rules_df2$rules, pattern = "\\}", 
                                   replacement = "")
rules_df2$rules <- str_replace_all(string = rules_df2$rules, pattern = "\"", 
                                   replacement = "")


write_xlsx(x = rules_df2,
           path = "Market Basket Analysis/MBA/products basket.xlsx")


# Visualizing the association rules
plot(head(rules_new2, n=100, by="lift"), engine = "htmlwidget",
     jitter=0)

plot(head(rules_new2, n=100, by="lift"), method = "grouped")

# visualizing the top 100 association rules by lift variable 
plot(head(rules_new2, n=15, by="lift"), method = "paracoord",
     engine = "default")
# this plot shows that if the customer buys the product at the tail of
#   the arrow, then he is likely to buy the product at the head as well
# The width of the arrows represents support and the intensity of the 
#   color represent confidence. 
# For larger rule sets visual analysis becomes difficult since with an 
#   increasing number of rules also the number of crossovers between 
#   the lines increases 

# visualizing the top 100 association rules by lift variable 
plot(head(rules_new2, n=100, by="lift"), method = "graph",
     engine = "htmlwidget")



#================================================================



### Market Basket Analysis for SKU/Product Names
#------------------------------------------------------------------


orders_subset3 <- orders_info %>%
  select(User.ID, order_date, sku.name) %>%
  mutate(User.ID = as.numeric(User.ID)) %>%
  arrange(User.ID) %>%
  drop_na(sku.name)
colSums(is.na(orders_subset3))


# Group all the items that were bought together by the same customer on the same date
library(plyr)
itemList3 <- ddply(orders_subset3, c("User.ID","order_date"), 
                   function(df){paste(df$sku.name,collapse = ",")})
# itemList2 <- rename(x = itemList2, item_list = V1) # rename not working
colnames(itemList3)[3] = "item_list"
# itemList2 %>% View()


# Remove member number and date
only_items3 <- itemList3 %>%
  select(item_list)


# write the dataframe to csv
write.csv(only_items3, 
          "Market Basket Analysis/MBA/only_items (SKUs).csv", 
          quote = FALSE, row.names = TRUE)


# Convert CSV file to Basket Format
trans3 = read.transactions(file="Market Basket Analysis/MBA/only_items (SKUs).csv",
                           rm.duplicates= TRUE, format="basket", sep=",", 
                           cols=1)
print(trans3)
# transactions in sparse format with
# 23659 transactions (rows) and
# 67 items (columns)
summary(trans3)


# converting basket format transaction data into dataframe class
trans_df3 <- as(object = trans3, Class = "data.frame")
trans_df3 <- trans_df3[2:length(trans_df3$items), ]


# to get the proportion of transations of each item is present in 
itemFrequency(trans3)[1:5]


# plotting the frequency of items
# itemFrequencyPlot(trans3, topN=15, type="absolute", col="wheat2",
#                   xlab="Item name", ylab="Frequency (absolute)",
#                   main="Absolute Item Frequency Plot")
# itemFrequencyPlot(trans3, topN=15, type="relative", col="wheat2",
#                   xlab="Item name", ylab="Frequency (absolute)",
#                   main="Absolute Item Frequency Plot")


# Remove quotes from Transaction
trans3@itemInfo$labels <- gsub("\"","", trans3@itemInfo$labels)


# applying the apriori algorithm
rules3 <- apriori(data = trans3, parameter = list(maxlen = 2, sup = 0.01, 
                                                  conf = 0.2, target="rules"))


# Removing unnecessary/repeated/redundant rules
# subset.rules3 <- which(colSums(is.subset(rules3, rules3)) > 1) # get subset rules in vector
# length(subset.rules3)
# rules_new3 <- rules3[-subset.rules3] # remove subset rules.
redundant_rules = is.redundant(rules3)
rules_new3 = rules3[!redundant_rules]


# Total number of rules generated
print(length(rules_new3))
# summary of the rules
summary(rules_new3)


# Converting rules into data frame
# rules_df <- as.data.frame(rules_new) # error, not working
rules_df3 <- as(rules_new3, "data.frame")
# write(rules, "C:\\Users\\Deepanshu\\Downloads\\rules.csv", sep=",")


# Cleaning the Rules in the dataframe version of rules
rules_df3$rules <- str_replace_all(string = rules_df3$rules, pattern = "\\{", 
                                   replacement = "")
rules_df3$rules <- str_replace_all(string = rules_df3$rules, pattern = "\\}", 
                                   replacement = "")
rules_df3$rules <- str_replace_all(string = rules_df3$rules, pattern = "\"", 
                                   replacement = "")


write_xlsx(x = rules_df3,
           path = "Market Basket Analysis/MBA/SKUs basket.xlsx")





#================================================================



# now identify which products are the top ones, and try to bundle them 
#   with the ones which the apriori algorithm predicts the customers are
#   likely to buy with them


# Taking subsets of association rules:
# Sometimes the marketing team requires to promote a specific product, say 
#   they want to promote berries, and want to find out how often and with 
#   which items the berries are purchased. The subset function enables one 
#   to find subsets of transactions, items or rules. The %in% operator is 
#   used for exact matching
berryrules <- subset(asso_rules, items %in% "berries")
inspect(berryrules)

# Show only particular product rules
inspect( subset( rules, subset = rhs %pin% "Product H" ))

# What are customers likely to buy before they purchase "Product A"
rules<-apriori(data=dt, parameter=list(supp=0.001,conf = 0.8), 
               appearance = list(default="lhs",rhs="Product A"),
               control = list(verbose=F))
rules<-sort(rules, decreasing=TRUE,by="confidence")
inspect(rules[1:5])

# What are customers likely to buy if they purchased "Product A"
rules<-apriori(data=dt, parameter=list(supp=0.001,conf = 0.8), 
               appearance = list(default="rhs",lhs="Product A"),
               control = list(verbose=F))
rules<-sort(rules, decreasing=TRUE,by="confidence")
inspect(rules[1:5])


#========================================================================


# # identifying the top SKUs in terms of appearances in different orders
# top_SKUs_orders_in <- orders_info %>%
#   group_by(sku.name) %>%
#   dplyr::summarise(num_of_orders_in = n_distinct(User.ID, order_date)) %>%
#   dplyr::arrange(dplyr::desc(num_of_orders_in))

# identifying the top SKUs in terms of quantities ordered
top_SKUs <- orders_info %>%
  group_by(sku.name) %>%
  dplyr::summarise(total_units_ordered = sum(Quantity), price = max(Price)) %>%
  dplyr::arrange(dplyr::desc(total_units_ordered))
top_SKUs_asc <- orders_info %>%
  group_by(sku.name) %>%
  dplyr::summarise(total_units_ordered = sum(Quantity)) %>%
  dplyr::arrange(total_units_ordered)
# top 10 SKUs
# 1 Cocomo Chocolate - (Rs 5 x 24)	19530
# 2	Lemon Max - (Rs 13)	10311
# 3	Fruitien Mango - (200 ml x 24)	9741
# 4	Sooper - Half Roll - (Rs 20 x 6)	9110
# 5	MilkPak - Milk - (250 ml x 27)	9102
# 6	Tarang - Milk - (180 ml x 24)	8042
# 7	Peanut Pik - Half Roll - (Rs 20 x 6)	7349
# 8	Sooper Chocolate - Half Roll - (Rs 20 x 6)	7104
# 9	Olpers - Milk - (250 ml x 27)	6737
# 10	Dairy Omung - (250 ml x 27)


# now see the products which these SKUs belong to have any low
#   running SKUs as well so that we can promote them
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "Cocomo")) %>%
  View("Cocomo")
# Cocomo Chocolate - (Rs 5 x 24) (19530 units) can be used to promote
#   Cocomo Chocolate - (Rs 10 x 12)	(601 units)
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "Lemon Max")) %>%
  View("Lemon Max")
# buy 1 Lemon Max - (Rs 13 x 12), get 1 Lemon Max - (Rs 13) free
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "Fruitien")) %>%
  View("Fruitien")
# use Fruitien Mango - (200 ml x 24) to promote Fruitien Apple - (200 ml x 24)
#   Offer the combined bundle at a lower price that the sum of their
#   individual prices (400 + 400 = 800)
# buy 1 Fruitien Juice  Mango - (1 L x 12) and get 1 Fruitien 
#   Juice - (Kids Pack) at 25% off (which is a high running SKU)
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "Sooper")) %>%
  View("Sooper")
# all SKUs are running well
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "MilkPak")) %>%
  View("MilkPak")
# all SKUs are running well
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "Tarang")) %>%
  View("Tarang")
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "Olpers")) %>%
  View("Olpers")
# use MilkPak - Cream - (200 ml x 24) to promote Olpers - Cream - (200 ml x 24)
#   Offer the combined bundle at a lower price that the sum of their
#   individual prices
# both are cream goods of different products. Cross selling can be done here
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "Dairy Omung")) %>%
  View("Dairy Omung")
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "Coca Cola")) %>%
  View("Coca Cola")
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "Sprite")) %>%
  View("Sprite")
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "Fanta")) %>%
  View("Fanta")
# use Coca Cola - (1.5 Ltr. x 6) to promote Fanta - (1.5 Ltr. x 6)
#   Offer the combined bundle at a lower price that the sum of their
#   individual prices
# we are targeting the (1.5 Ltr. x 6) SKUs of these beverages here as these
#   are the most demanded
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "Nesfruita")) %>%
  View("Nesfruita")



### find the rules for the top 10 SKUs

# getting the rules with SKUs with "Cocomo" in their names
as(subset(rules3, items %pin% "Cocomo Chocolate"), 
   Class = "data.frame") %>% View("Cocomo rules")
# {Cocomo Chocolate - (Rs 5 x 24)}, {Sooper - Half Roll - (Rs 20 x 6)}, {Prince Chocolate - Tiki Pack - (Rs 5 x 24)}
# check the units ordered for the SKUs that have rules with MilkPak
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "Sooper")) %>%
  View("Sooper")
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "Prince")) %>%
  View("Prince")
# could bundle {Cocomo Chocolate - (Rs 5 x 24)} with Prince Choco 
#   Jammies (Rs 10 x 15) (an SKU different from the one that the top sooper
#   SKU forms a rule with. But considering it is from the same product, it
#   fare well and be worth a shot)
# buy 1 {Cocomo Chocolate - (Rs 5 x 24)} get 1 {Cocomo Chocolate - (Rs 5 x 24)}
#   at Rs.10 off
# choosing to bundle cocomo with this SKU as it is of higher price and could
#   improve AOV


# getting the rules with SKUs with "Lemon Max" in their names
as(subset(rules3, items %pin% "Max"), 
   Class = "data.frame") %>% View("Lemon Max rules")
# no rules


# getting the rules with SKUs with "Fruitien" in their names
as(subset(rules3, items %pin% "Fruitien"), 
   Class = "data.frame") %>% View("Fruitien Rules")
# no rules


# getting the rules with SKUs with "MilkPak" in their names
as(subset(rules3, items %pin% "MilkPak"), 
   Class = "data.frame") %>% View("MilkPak Rules")
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "Dairy Omung")) %>%
  View("Dairy Omung")
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "Tarang")) %>%
  View("Tarang")
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "Dalda")) %>%
  View("Dalda")
# like done above, we could bundle milkpak cream with olpers cream to
#   promote the latter using the former's popularity


# getting the rules with SKUs with "Sooper" in their names
as(subset(rules3, items %pin% "Sooper"), 
   Class = "data.frame") %>% View("Sooper Rules")
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "Sooper")) %>%
  View("Sooper")
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "Rio")) %>%
  View("Rio")
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "Tuc")) %>%
  View("Tuc")
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "Candi")) %>%
  View("Candi")
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "Zeera Plus")) %>%
  View("Zeera Plus")
top_SKUs %>%
  filter(str_detect(string = sku.name, pattern = "Peanut Pik")) %>%
  View("Peanut Pik")


# getting the rules with SKUs with "Dalda" in their names
as(subset(rules3, items %pin% "Dalda"), 
   Class = "data.frame") %>% View("Dalda Rules")
# no important rules



