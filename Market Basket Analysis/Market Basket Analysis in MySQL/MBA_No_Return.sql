################### IMPORT DATASET ###################
# Drop and Create the table that you will use for importing
drop table mba_no_return;
create table mba_no_return(
transaction_id text,
store int,
date date,	
time time,		
id_cust int,
qty int,	
totprice float,
prod_id int
#,prod_desc text
);
select * from mba_no_return;

# Import the dataset to this table
load data local infile 'C:/Users/Berk/Downloads/Marketing Analytics/PW/MBA_No_Return.csv'
into table mba_no_return
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows;

################### ANALYZE YOUR DATA ###################
SELECT * FROM mba_no_return;
select count(distinct(prod_id)) from mba_no_return;
select count(*) from mba_no_return;

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
from mba_no_return a
left join products b
on a.prod_id=b.prod_code;

select * from temporary_table;

drop table mba_no_return;
alter table temporary_table
rename to mba_no_return;

alter table mba_no_return
drop column prod_code;

select * from mba_no_return;

################### ELIMINATE THE RETURNED PRODUCTS ###################
#drop table temporary_table;
create table temporary_table like mba_no_return;
insert into temporary_table
select * from mba_no_return
where totprice>0;

select count(*) from temporary_table;

drop table mba_no_return;
alter table temporary_table
rename to mba_no_return;

################### MERGE THE ROWS IN WHICH THERE ARE THE SAME PRODUCTS IN THE SAME RECEIPTS IF NEEDED ###################
#drop table temporary_table;
create table temporary_table like mba_no_return;
select * from temporary_table;

INSERT INTO temporary_table
SELECT transaction_id, store, date, time, 
id_cust, SUM(qty), sum(totprice), prod_id, prod_desc
FROM mba_no_return
GROUP BY transaction_id, prod_id;

select * from temporary_table;
select count(*) from temporary_table;
select count(distinct(prod_id)) from temporary_table;

drop table mba_no_return;
ALTER TABLE temporary_table
  RENAME TO mba_no_return;

select * from mba_no_return;
select count(*) from mba_no_return;

################### CALCULATE THE NUMBER OF TRANSACTIONS FOR EACH PRODUCT ###################
drop table transaction_count_mba_no_return;
Create Table TRANSACTION_COUNT_mba_no_return (
prod_id INT,
prod_desc text,
Number_of_transactions_Count INT
);

select * from transaction_count_mba_no_return;
select count(*) from mba_no_return;

insert into TRANSACTION_COUNT_mba_no_return 
Select prod_id, prod_desc, count(*) as Number_of_transactions_Count
From mba_no_return
Group by prod_id;

select * from transaction_count_mba_no_return;

################### CALCULATE THE NUMBER OF TRANSACTIONS FOR EACH PRODUCT COUPLES ###################
drop table trans_count_itemset_mba_no_return;
Create Table TRANS_COUNT_Itemset_mba_no_return (
PRODUCT_1 INT,
prod_desc_1 text,
PRODUCT_2 INT,
prod_desc_2 text,
TRANS_COUNT INT
);

insert into TRANS_COUNT_Itemset_mba_no_return
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
FROM marketing_analytics.mba_no_return a, marketing_analytics.mba_no_return b
WHERE a.transaction_id = b.transaction_id
and a.prod_id <> b.prod_id
and a.prod_id < b.prod_id
) Temp
GROUP BY PRODUCT_1, PRODUCT_2;

select * from trans_count_itemset_mba_no_return;

################### CALCULATE AFFINITY MATRICES FOR EACH PRODUCT COUPLES ###################

drop table affinity_matrix_mba_no_return;
Create Table Affinity_Matrix_mba_no_return (
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
select * from affinity_matrix_mba_no_return;

select count(distinct(transaction_id)) from mba_no_return;

insert into Affinity_Matrix_mba_no_return
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
	cast(TRANS_COUNT as decimal)/42413 as Support,   
    # 42413 is equal to the number of unique transaction id's
	Number_of_transactions_Count/42413 as support_product_2    

	FROM 
	TRANS_COUNT_Itemset_mba_no_return t1 
	join TRANSACTION_COUNT_mba_no_return t2 
		on t1.PRODUCT_2=t2.prod_id
	) m3
	join TRANSACTION_COUNT_mba_no_return t3 
		on m3.PRODUCT_1=t3.prod_id
)go;

select * from affinity_matrix_mba_no_return;

################### ANALYZE THE MEANINGFUL PRODUCT COUPLES ###################
SELECT * FROM affinity_matrix_mba_no_return 
WHERE lift > 1 #Lift greater than 1 means that products are dependent
and support > 0.01 #How often are these products together?
and confidence > 0.3 #How systematically are the together? 

