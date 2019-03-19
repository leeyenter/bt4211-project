setwd("~/GitHub/bt4211-project")

file1 = './data/olist_customers_dataset.csv'
file2 = './data/olist_geolocation_dataset.csv'
file3 = './data/olist_order_items_dataset.csv'
file4 = './data/olist_order_payments_dataset.csv'
file5 = './data/olist_order_reviews_dataset.csv'
file6 = './data/olist_orders_dataset.csv'
file7 = './data/olist_products_dataset.csv'
file8 = './data/olist_sellers_dataset.csv'
file9 = './data/product_category_name_translation.csv'


customers = read.csv(file1, header=TRUE)  #join to orders on customer_id
geo = read.csv(file2, header=TRUE)
items = read.csv(file3, header=TRUE)  #join on order_id
payments = read.csv(file4, header=TRUE)  #join on order_id
reviews = read.csv(file5, header=TRUE)  #join on order_id
orders = read.csv(file6, header=TRUE)  #join on order_id
products = read.csv(file7, header=TRUE)  #join to items on product_id
sellers = read.csv(file8, header=TRUE)  #join to items on seller_id
translation = read.csv(file9, header=TRUE)  #join to products on product_category_name

data = merge(items, orders, by = "order_id")
data = merge(data, customers, by = "customer_id")

library(dplyr)

data = data %>% 
  mutate(shipping_limit_date=as.Date(shipping_limit_date, '%Y-%m-%d %H:%M:%S'), 
         order_purchase_timestamp=as.Date(order_purchase_timestamp, '%Y-%m-%d %H:%M:%S'),
         order_approved_at=as.Date(order_approved_at, '%Y-%m-%d %H:%M:%S'),
         order_delivered_carrier_date=as.Date(order_delivered_carrier_date, '%Y-%m-%d %H:%M:%S'),
         order_delivered_customer_date=as.Date(order_delivered_customer_date, '%Y-%m-%d %H:%M:%S'),
         order_estimated_delivery_date=as.Date(order_estimated_delivery_date, '%Y-%m-%d %H:%M:%S')
  )

data["total_amount"] = data$price + data$freight_value
temp = data %>% 
  group_by(customer_unique_id) %>% 
  summarise(total_amt = sum(total_amount))
data = merge(data, temp, on = "customer_unique_id")
data["total_amount"] = NULL

max(data$order_purchase_timestamp)   ## "2018-09-03"

RFM = data %>% 
  group_by(customer_unique_id) %>% 
  summarise(recency = as.numeric(as.Date("2018-09-03")-max(order_purchase_timestamp)),
            frequency = n_distinct(order_id), 
            monetary = sum(total_amt)/n_distinct(order_id))
RFM = as.data.frame(RFM)

hist(RFM$recency)
table(RFM$frequency)    
hist(RFM$monetary)

data = merge(data, RFM, on = "customer_unique_id")

### customer segmentation by state ########

ggplot(mapping = aes(x = customer_state, y = total_amt), data = data) + geom_boxplot() + ggtitle("Customer Segmentation by State") + theme(plot.title = element_text(hjust = 0.5))

ggplot(aes(x = customer_state, y = frequency), data = data) + geom_point(alpha = 0.1, color = "blue") + ggtitle("Customer Segmentation by State") + theme(plot.title = element_text(hjust = 0.5))

ggplot(aes(x = frequency, y = total_amt), data = data) + geom_point(alpha = 0.1, aes(color = customer_state)) + ggtitle("Customer Segmentation by State") + theme(plot.title = element_text(hjust = 0.5))


## examine outliers

data[data$frequency == 16,]
data[data$total_amt == max(data$total_amt),]

### segmentation by order_status #########

ggplot(aes(x = frequency, y = total_amt), data = data) + geom_point(alpha = 0.1, aes(color = order_status)) + ggtitle("Customer Segmentation by Order Status") + theme(plot.title = element_text(hjust = 0.5))

### underpromising/overpromising delivery time ##########

data["days_late"] = as.numeric(data$order_delivered_customer_date - data$order_estimated_delivery_date)

ggplot(aes(x = days_late, y = frequency), data = data) + geom_point(alpha = 0.1, aes(color = "blue")) + ggtitle("Frequency vs Days Late") + theme(plot.title = element_text(hjust = 0.5))
ggplot(aes(x = days_late, y = total_amt), data = data) + geom_point(alpha = 0.1, aes(color = "blue")) + ggtitle("Total amt vs Days Late") + theme(plot.title = element_text(hjust = 0.5))


### generate a whale curve ########

revenue = data[,c("customer_unique_id", "total_amt")]    
revenue = revenue[!duplicated(revenue$customer_unique_id), ] ## 95420 unique customers.
revenue = sort(revenue$total_amt, decreasing = TRUE)
breaks = 10
revenue.cumsum = cumsum(revenue)
revenue.cumrelfreq = revenue.cumsum / sum(revenue)

plot(seq(0, 100, by=100/(length(revenue)-1)), revenue.cumrelfreq, 
     main="Profitability Skew", 
     xlab="Cumulative customers", 
     ylab="Cumulative revenue")
