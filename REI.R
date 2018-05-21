##This is a work 


#load data from SAS&csv file(I saved the file to the local drive due to confidential issues here)
library(haven)
products <- read.csv("//netid.washington.edu/csde/other/desktop/sym2016/Desktop/pg_sku_recs_cleaned.csv")
> c <- read_sas("C:/Users/sym2016/Downloads/pg_detail_recs_03.sas7bdat", 
                               +     NULL)

#check if I have fully loaded the data
nrow(c)
nrow(products)

#Keep the relevant columns in pg_detail_recs_03
orders = subset(pg_detail_recs_03, select = c(1,3,6,7,9,10,20,21) )
View(orders)

#check the data type and transform
str(orders)

#drop the records where sk_item_id is -3
orders1=subset(orders.df, sk_item_id!=-3)
str(orders1)
View(orders1)


#load sql package and use sql to merge datasets
install.packages("sqldf")
library(sqldf)

orders2<-sqldf("SELECT 
customer_id, 
sk_transaction_id,
trans_type_id,
d_date,
channel_id,
t1.sk_item_id,
current_corporate_price-weighted_avg_cost as profit,
t2.brand
FROM orders1 AS t1 
LEFT JOIN
products AS t2
ON t1.sk_item_id=t2.sk_item_id
                   ")
View(orders_test)
summary.data.frame(orders_test)

#drop the records where brand is null, this means that there are no records in products to match this product, thus hard to tell brands
orders3<- orders_test[-which(is.na(orders_test$brand)), ]
View(orders3)


#calculate the average profit of REI brands items and non-REI brands items
avg_rei<-sqldf("select avg(profit)
FROM orders_full
WHERE brand=1 ")
list(avg_rei)
avg_other<-sqldf("select avg(profit)
FROM orders_full
                 WHERE brand=0 ")
list(avg_other)

#replace the Null value of profit column in the "orders_full" table according to the brand
orders4<-sqldf("UPDATE orders3 
SET 
profit = CASE 
     WHEN brand=1  THEN 14.697
     WHEN brand=0  THEN 21.955
ELSE profit
END
WHERE profit='NA'
 ")




View(order4)

####orders_cleaned <-
  if(orders3$brand==1) {
    orders3$profit[is.na(orders3$profit)]<- 21.955
  } else {
    orders3$profit[is.na(orders3$profit)]<- 14.697
  }
View(orders_cleaned)
str(orders_cleaned)

#drop the records where profit<0, this means that there are no records in products to match this product, thus hard to tell brands
orders4=subset(orders3, profit>0)
summary.data.frame(orders4)

#only keep the records with customers who had return behaviors
orders5<-sqldf("
               SELECT * FROM orders4
                WHERE orders4.customer_id IN(
                  SELECT DISTINCT customer_id from orders4
                  WHERE trans_type_id='RETN'
                  )
               ")
summary.data.frame(orders5)
orders5$profit
test<-sqldf("Select * from orders1 where current_corporate_price-weighted_avg_cost<0 OR current_corporate_price-weighted_avg_cost >100 
            ORDER BY current_corporate_price-weighted_avg_cost")
