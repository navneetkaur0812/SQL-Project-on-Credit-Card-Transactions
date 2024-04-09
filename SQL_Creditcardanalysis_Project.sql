select *
from credit_card_transactions;

select exp_type from credit_card_transactions group by exp_type;

select distinct card_type from credit_card_transactions;

select min(transaction_date), max(transaction_date) from credit_card_transactions;

--Q1: write a query to print top 5 cities with highest spends and their percentage contribution of total credit card spends 

select top 5 city, highest_spends, round((highest_spends/total_spend)*100, 2) as perc 
from 
(
select city, sum(amount) as highest_spends, (
select sum(amount) from credit_card_transactions) as total_spend
from credit_card_transactions 
group by city ) m
order by highest_spends desc;

--Q2: write a query to print highest spend month and amount spent in that month for each card type

with cte as 
(
select card_type, datepart(year, transaction_date) as year, datepart(month, transaction_date) as month, sum(amount) as total_spend
from 
credit_card_transactions 
group by card_type, datepart(year, transaction_date), datepart(month, transaction_date) 
) , cte1 as 
(
select *, dense_rank() over(partition by card_type order by total_spend desc) as rank 
from cte 
) 
select * from cte1 
where rank = 1;

/*--Q3: write a query to print the transaction details(all columns from the table) for each card type when
it reaches a cumulative of 1000000 total spends(We should have 4 rows in the o/p one for each card type) */

with m as 
(
Select *, sum(amount) over (partition by card_type order by transaction_date, transaction_id asc) as total_spends
from credit_card_transactions 
), abc as 
(
select *, dense_rank() over(partition by card_type order by total_spends asc) as rank from 
 m
where total_spends > = 1000000 
)
select * from
 abc 
where rank =1



--Q4: write a query to find city which had lowest percentage spend for gold card type

select top 1 city, (gold_total/total)*100 as perc 
from
(
select city,
sum(case when card_type = 'Gold' then amount end) as gold_total, 
sum(amount) as total
from credit_card_transactions 
group by city 
) m 
where (gold_total/total)*100 is not null
order by perc asc;

--OR

select top 1* from 
(
select city, sum(amount) as total_spend, 
sum(case when card_type = 'Gold' then amount end) as gold_sum, 
sum(case when card_type = 'Gold' then amount end)/sum(amount)*100 as perc_spend
from credit_card_transactions 
group by city 
) m
where perc_spend is not null
order by perc_spend asc;


--Q5: write a query to print 3 columns:  city, highest_expense_type , lowest_expense_type (example format : Delhi , bills, Fuel)

with m as 
(
select city, exp_type, sum(amount) as spend
from credit_card_transactions 
group by city, exp_type 
) , cte as 
(
select *,
dense_rank() over(partition by city order by spend desc) as highest_rank,
dense_rank() over(partition by city order by spend asc) as lowest_rank
from m 
)
select cte.city, 
(case when cte.highest_rank = 1 then cte.exp_type end) as highest_exp_type,
(case when cte1.lowest_rank = 1 then cte1.exp_type end) as lowest_exp_type
from cte join cte as cte1 on cte.city = cte1.city and cte.highest_rank = 1 and cte1.lowest_rank =1 

 --Q6: write a query to find percentage contribution of spends by females for each expense type

 with cte as 
 (
 select exp_type,  
 sum (case when gender = 'F' then amount end) as female_spend, 
 sum(amount) as total_spend 
 from credit_card_transactions 
group by exp_type
 ) 
 select *, (female_spend/total_spend)*100 as perc 
 from cte;

 --Q7: which card and expense type combination saw highest month over month growth in Jan-2014 

with m as 
 (
 select card_type, exp_type, datepart(year, transaction_date) as year,
 datepart(month, transaction_date) as current_month, sum(amount) as current_spend
 from credit_card_transactions 
 group by card_type, exp_type, datepart(year, transaction_date), datepart(month, transaction_date)
 ), abc as 
 (
 select *, lag(current_spend, 1) over(partition by card_type, exp_type order by year, current_month asc) as prev_spend
 from m 
 )
 select top 1 card_type, exp_type, (current_spend - prev_spend) as mom_growth 
 from abc 
 where year = '2014' and current_month = 1
 order by mom_growth desc

 --Q8: during weekends which city has highest total spend to total no of transcations ratio

 select top 1 city, (total_spend/no_of_transactions) as ratio
 from
 (
 select city, sum(amount) as total_spend, count(transaction_id) as no_of_transactions 
 from credit_card_transactions 
 where datepart(weekday, transaction_date) in (7,1)
 group by city 
 ) m
 order by ratio desc;
 
 --Q9: which city took least number of days to reach its 500th transaction after the first transaction in that city

 select top 1 city, datediff(day, first_transaction_date, last_transaction_date) as no_of_days
 from
 (
 select *, row_number() over(partition by city order by transaction_date) as transaction_no, 
 min(transaction_date) over (partition by city) as first_transaction_date, 
 (case when row_number() over(partition by city order by transaction_date) = 500 then transaction_date end) as last_transaction_date
 from credit_card_transactions 
 ) m 
 where transaction_no = 500 
 order by no_of_days asc;
 
 













