################### IMPORT DATASET ###################
# Drop and Create the table that you will use for importing
drop table mba_no_return_categories;
create table mba_no_return_categories(
transaction_id text,
store int,
date date,	
time time,		
id_cust int,
qty int,	
totprice float,
prod_id int
,prod_desc text
);
select * from mba_no_return_categories;

# Import the dataset to this table
load data local infile 'C:/Users/Berk/Downloads/Marketing Analytics/PW/MBA_No_Return_categories.csv'
into table mba_no_return_categories
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

################### ANALYZE YOUR DATA ###################
SELECT * FROM mba_no_return_categories;
select count(distinct(prod_id)) from mba_no_return_categories;
select count(*) from mba_no_return_categories;

################### ADD THE PRODUCT DESCRIPTIONS IF NEEDED ###################
drop table temporary_table;
create table temporary_table(
transaction_id text,
store int,
date date,	
time time,		
id_cust int,
qty int,	
totprice float,
prod_id int,
prod_code int,
prod_desc text
);
select * from temporary_table;

INSERT INTO temporary_table
SELECT * 
from mba_no_return_categories a
left join products b
on a.prod_id=b.prod_code;

select * from temporary_table;

drop table mba_no_return_categories;
alter table temporary_table
rename to mba_no_return_categories;

alter table mba_no_return_categories
drop column prod_code;

select * from mba_no_return_categories;

################### ELIMINATE THE RETURNED PRODUCTS ###################
#drop table temporary_table;
create table temporary_table like mba_no_return_categories;
insert into temporary_table
select * from mba_no_return_categories
where totprice>0;

select count(*) from temporary_table;

drop table mba_no_return_categories;
alter table temporary_table
rename to mba_no_return_categories;

################### MERGE THE ROWS IN WHICH THERE ARE THE SAME PRODUCTS IN THE SAME RECEIPTS IF NEEDED ###################
#drop table temporary_table;
create table temporary_table like mba_no_return_categories;
select * from temporary_table;

INSERT INTO temporary_table
SELECT transaction_id, store, date, time, id_cust, SUM(qty), sum(totprice), prod_id, prod_desc
FROM mba_no_return_categories
GROUP BY transaction_id, prod_id;

select * from temporary_table;
select count(*) from temporary_table;
select count(distinct(prod_id)) from temporary_table;

drop table mba_no_return_categories;
ALTER TABLE temporary_table
  RENAME TO mba_no_return_categories;

select * from mba_no_return_categories;
select count(*) from mba_no_return_categories;

################### CALCULATE THE NUMBER OF TRANSACTIONS FOR EACH PRODUCT ###################
drop table transaction_count_mba_no_return_categories;
Create Table TRANSACTION_COUNT_mba_no_return_categories (
prod_id INT,
prod_desc text,
Number_of_transactions_Count INT
);

select * from transaction_count_mba_no_return_categories;
select * from mba_no_return_categories;

insert into TRANSACTION_COUNT_mba_no_return_categories 
Select prod_id, prod_desc, count(*) as Number_of_transactions_Count
From mba_no_return_categories
Group by prod_id;

select * from transaction_count_mba_no_return_categories;

################### CALCULATE THE NUMBER OF TRANSACTIONS FOR EACH PRODUCT COUPLES ###################
drop table trans_count_itemset_mba_no_return_categories;
Create Table TRANS_COUNT_Itemset_mba_no_return_categories (
PRODUCT_1 INT,
prod_desc_1 text,
PRODUCT_2 INT,
prod_desc_2 text,
TRANS_COUNT INT
);

insert into TRANS_COUNT_Itemset_mba_no_return_categories
SELECT
PRODUCT_1,
PROD_DESC_1,
PRODUCT_2,
PROD_DESC_2,
COUNT(transaction_id) TRANS_COUNT
FROM
(
SELECT
a.transaction_id,
a.prod_id PRODUCT_1,
a.prod_desc PROD_DESC_1,
b.prod_id PRODUCT_2,
b.prod_desc PROD_DESC_2
FROM marketing_analytics.mba_no_return_categories a, marketing_analytics.mba_no_return_categories b
WHERE a.transaction_id = b.transaction_id
and a.prod_id <> b.prod_id
and a.prod_id < b.prod_id
) Temp
GROUP BY PRODUCT_1, PRODUCT_2;

select * from trans_count_itemset_mba_no_return_categories;

################### CALCULATE AFFINITY MATRICES FOR EACH PRODUCT COUPLES ###################

drop table affinity_matrix_mba_no_return_categories;
Create Table Affinity_Matrix_mba_no_return_categories (
PRODUCT_1 INT,
prod_desc_1 text,
prod_count_1 INT,
PRODUCT_2 INT,
prod_desc_2 text,
prod_count_2 INT,
t_count_itemset INT,
Support float,
confidence float,
lift float
);
select * from affinity_matrix_mba_no_return_categories; #############

select count(distinct(transaction_id)) from mba_no_return_categories;
#select * from mba_no_return_categories;

insert into Affinity_Matrix_mba_no_return_categories
SELECT Product_1, prod_desc_1, prod_count_1,
Product_2, prod_desc_2, prod_count_2, 
t_count_itemset, Support, 
t_count_itemset/42413/support_product_1 as confidence, 
t_count_itemset/42413/(support_product_2*support_product_1) as lift

FROM
(
SELECT m3.*, t3.Number_of_transactions_Count/42413 as support_product_1, t3.Number_of_transactions_Count as prod_count_1
	FROM
	(
	SELECT 
	PRODUCT_1, 
    prod_desc_1,
    Number_of_transactions_Count as prod_count_2,
	PRODUCT_2, 
    prod_desc_2,
	cast(TRANS_COUNT as decimal) as t_count_itemset, 
	cast(TRANS_COUNT as decimal)/42413 as Support,   # 4514 is equal to the number of unique transaction id's.
	Number_of_transactions_Count/42413 as support_product_2    

	FROM 
	TRANS_COUNT_Itemset_mba_no_return_categories t1 
	join TRANSACTION_COUNT_mba_no_return_categories t2 
		on t1.PRODUCT_2=t2.prod_id
	) m3
	join TRANSACTION_COUNT_mba_no_return_categories t3 
		on m3.PRODUCT_1=t3.prod_id
)go;

select * from affinity_matrix_mba_no_return_categories;

################### ANALYZE THE MEANINGFUL PRODUCT COUPLES ###################
SELECT * FROM affinity_matrix_mba_no_return_categories 
WHERE lift > 1 #Lift greater than 1 means that products are dependent
and support > 0.0001 #How often are these products together?
and t_count_itemset > 5
and confidence > 0.2 #How systematically are the together? 

