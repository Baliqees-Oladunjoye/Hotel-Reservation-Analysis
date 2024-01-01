select* from hotel_bookings$
-- The table has 119,390rows and 32columns

/*Cleaning the Data
Remove Null and Irrelevant Data*/

--standadized the reservation_status_date format
select reservation_status_date, convert(date, reservation_status_date)
from hotel_bookings$

update hotel_bookings$
set reservation_status_date = convert(date, reservation_status_date)

Alter table hotel_bookings$
add reservationstatusdate date;

update hotel_bookings$
set reservationstatusdate = convert(date, reservation_status_date)


-- changing the o and 1 in is_canceled to a full text
select
		case
			when is_canceled = 1 then 'canceled'
			when is_canceled = 0 then 'not_canceled'
		end as bookings
from hotel_bookings$


-- changing the o and 1 to a full text for repeated guest
select
		case
			when is_repeated_guest = 1 then 'repeatedguest'
			when is_repeated_guest = 0 then 'not_repeatedguest'
		end as repeatedguest
from hotel_bookings$



-- changing the meal format to full text
select
		case
			when meal = 'FB' then 'FullBaord'
			when meal ='HB' then 'HalfBoard'
			when meal = 'BB' then 'BednBreakfast'
			when meal ='SC' then 'NOMEAL'
			when meal ='Undefined' then 'NOMEAL'
		end 
from hotel_bookings$


update hotel_bookings$
set meal = case
			when meal = 'FB' then 'FullBaord'
			when meal ='HB' then 'HalfBoard'
			when meal = 'BB' then 'BednBreakfast'
			when meal ='SC' then 'NOMEAL'
			when meal ='Undefined' then 'NOMEAL'
		end 

-- Creating new table, adding the bookings and repeatedguest as new columns
select
	*,
		case
			when is_canceled = 1 then 'canceled'
			when is_canceled = 0 then 'not_canceled'
		end as bookings,
		case
			when is_repeated_guest = 1 then 'repeatedguest'
			when is_repeated_guest = 0 then 'not_repeatedguest'
		end as repeatedguest
into hotelbookingsfinal
from hotel_bookings$


--check the updated table
select*
from hotelbookingsfinal


-- Delete dupicate rows
with cte as (
		select hotel, lead_time, arrival_date_year, arrival_date_month, arrival_date_week_number, arrival_date_day_of_month,
				stays_in_weekend_nights, stays_in_week_nights, adults, children, babies, meal, country, market_segment, distribution_channel,
				is_repeated_guest, previous_cancellations, previous_bookings_not_canceled, reserved_room_type, assigned_room_type, booking_changes,
				deposit_type, agent, company, days_in_waiting_list, customer_type, adr, required_car_parking_spaces, total_of_special_requests,
				reservation_status, reservationstatusdate, bookings, repeatedguest,
				ROW_NUMBER() OVER (
						PARTITION BY
						hotel, lead_time, arrival_date_year, arrival_date_month, arrival_date_week_number, arrival_date_day_of_month,
				stays_in_weekend_nights, stays_in_week_nights, adults, children, babies, meal, country, market_segment, distribution_channel,
				is_repeated_guest, previous_cancellations, previous_bookings_not_canceled, reserved_room_type, assigned_room_type, booking_changes,
				deposit_type, agent, company, days_in_waiting_list, customer_type, adr, required_car_parking_spaces, total_of_special_requests,
				reservation_status, reservationstatusdate, bookings, repeatedguest
						ORDER BY
							hotel, lead_time, arrival_date_year, arrival_date_month, arrival_date_week_number, arrival_date_day_of_month,
				stays_in_weekend_nights, stays_in_week_nights, adults, children, babies, meal, country, market_segment, distribution_channel,
				is_repeated_guest, previous_cancellations, previous_bookings_not_canceled, reserved_room_type, assigned_room_type, booking_changes,
				deposit_type, agent, company, days_in_waiting_list, customer_type, adr, required_car_parking_spaces, total_of_special_requests,
				reservation_status, reservationstatusdate, bookings, repeatedguest
				) row_num 
			from
				hotelbookingsfinal
)
DELETE FROM cte
where row_num > 1;

-- 31,994 duplicate rows were  deleted


--check how many rows left in the table
select *
from hotelbookingsfinal

--Delete unused columns
Alter table hotelbookingsfinal
drop column is_canceled, is_repeated_guest, reservation_status_date

--REMOVE NULL

/*One of the attributes of our data is that the abbreviations used for countries are a uniform 
length of only 3 characters and are NOT null. Two find the values that do not follow this rule, 
we will use this query to search them out and identify them*/
SELECT country
FROM hotelbookingsfinal
WHERE LEN(country) <> 3 OR country IS NULL
GROUP BY country
ORDER BY country
/*The results of this query reveals that there are two values in the ‘country’ column that are not 
3 characters in length (‘CN’ for Canada) and NULL. For the sake of data quality, I will update the values from 
‘CN’ to ‘CAN’ for uniformity, while the corresponding rows with NULL values will be removed from the table, since 
we have no way of filling in this data with the correct values to maintain the integrity of the data. To ensure 
accuracy of the query, an OR statement is added where the rows in which the length of characters is longer 
than 3 for the country in question, this applying directly to the 4 characters in ‘NULL’. When we re-run the 
original query, there are no results as desired.*/

--update CN TO CAN
UPDATE hotelbookingsfinal
SET country = ('CAN')
WHERE country = 'CN';

--Delete Rows with NULL values character greater than 3
DELETE FROM hotelbookingsfinal
WHERE country IS NULL OR LEN(country) > 3;

--check if country column has been updated 
SELECT [country]
FROM hotelbookingsfinal
WHERE LEN(country) <> 3 OR country IS NULL
GROUP BY country
ORDER BY country

---checking for NULL in the children column
SELECT children
FROM hotelbookingsfinal
WHERE children IS NULL
GROUP BY children
--Children column also has NULL value

--Delete Rows with NULL values in the children column
DELETE FROM hotelbookingsfinal
WHERE children IS NULL

-----checking for NULL in the Agent column
SELECT agent
FROM hotelbookingsnotcanceled
WHERE agent IS NULL
GROUP BY agent

DELETE FROM hotelbookingsnotcanceled
WHERE agent IS NULL


----EXPLORING THE DATASET

--check for the month with the highest reservations
select arrival_date_month, count(arrival_date_month) Reservation_count
from hotelbookingsfinal
group by arrival_date_month
order by count(arrival_date_month) desc
/*August and July has the highest reservations, Family summertime outings 
can be a possible explanation for this insight*/

--Hotel Reservation that was not canceled
select hotel, count(bookings) not_canceled_bookings
from hotelbookingsfinal
where bookings = 'not_canceled'
group by hotel
order by count(bookings) desc
--City hotel has highest reservation that was not canceled

select hotel, count(bookings) canceled_bookings
from hotelbookingsfinal
where bookings = 'canceled'
group by hotel
order by count(bookings) desc
--City hotel has highest canceled reservation has it should be since it has highest reservations


--group by arrival year in descending order
SELECT top 5 arrival_date_year,arrival_date_month, count(arrival_date_year) 
FROM hotelbookingsfinal
group by arrival_date_year, arrival_date_month
ORDER BY count(arrival_date_year)  DESC
--2016 has the highest reservations, as it should, it has the highest number of reservation


SELECT arrival_date_year, count(arrival_date_year) Bookings_by_year
FROM hotelbookingsfinal
group by arrival_date_year
ORDER BY count(arrival_date_year)  DESC



--top 5 country with the highest reservations
SELECT top 5 country, count(country)
FROM hotelbookingsfinal
group by country
order by count(country) desc



SELECT stays_in_week_nights, sum(stays_in_week_nights)
FROM hotelbookingsfinal
group by stays_in_week_nights
order by sum(stays_in_week_nights) desc

SELECT stays_in_weekend_nights , sum(stays_in_weekend_nights)
FROM hotelbookingsfinal
group by stays_in_weekend_nights
order by sum(stays_in_weekend_nights) desc

-- Bookings base on market segment
SELECT market_segment , count(bookings)
FROM hotelbookingsfinal
group by market_segment
order by count(bookings) desc
-- The Online TA has the highest bookings

--Agent with the highest reservations
SELECT agent , count(agent)
FROM hotelbookingsfinal
group by agent
order by count(agent) desc
--agent 9,

SELECT deposit_type , count(deposit_type)
FROM hotelbookingsfinal
group by deposit_type
order by count(deposit_type) desc

SELECT meal , count(meal)
FROM hotelbookingsfinal
group by meal
order by count(meal) desc

SELECT reserved_room_type , count(reserved_room_type)
FROM hotelbookingsfinal
group by reserved_room_type
order by count(reserved_room_type) desc

SELECT assigned_room_type, count(assigned_room_type)
FROM hotelbookingsfinal
group by assigned_room_type
order by count(assigned_room_type) desc

SELECT customer_type, count(customer_type)
FROM hotelbookingsfinal
group by customer_type
order by count(customer_type) desc

SELECT required_car_parking_spaces,arrival_date_year, count(required_car_parking_spaces)
FROM hotelbookingsfinal
group by required_car_parking_spaces, arrival_date_year
order by count(required_car_parking_spaces) desc

SELECT lead_time,bookings, count(lead_time)
FROM hotelbookingsfinal
where bookings = 'canceled'
group by lead_time, bookings
order by count(lead_time) desc

SELECT lead_time,bookings, count(lead_time)
FROM hotelbookingsfinal
where bookings = 'not_canceled'
group by lead_time, bookings
order by count(lead_time) desc

SELECT
    bookings,
    COUNT(*) AS reservation_count
FROM
    hotelbookingsfinal
WHERE
    bookings IN ('canceled', 'not_canceled')
GROUP BY
    bookings;



--CREATING A TABLE FOR RESERVATIONS THAT WERE NOT CANCELED
SELECT
    *
INTO
    hotelbookingsnotcanceled
FROM
    hotelbookingsfinal
WHERE
    bookings = 'not_canceled';


select * from hotelbookingsnotcanceled

Select adr, assigned_room_type, arrival_date_year
from  hotelbookingsnotcanceled
group by adr, assigned_room_type, arrival_date_year


--checking the adr count
Select adr, count (adr)
from  hotelbookingsnotcanceled
group by adr
order by adr asc
/* from the result of the adr count, there is negative value of adr, zero values which amounted to 1593 
(the highest adr count) and some other low value, hence questions need to be asked if there has been
(1) Room complimentary stays 
(2) Discounted Rates  or
(3) Operational issues
because in typical hotel revenue management practices, the Average Daily Rate (ADR) is a positive value 
and is not expected to be zero*/

SELECT assigned_room_type, arrival_date_year, adr, count(assigned_room_type)
FROM hotelbookingsnotcanceled
where arrival_date_year = 2015
group by assigned_room_type, arrival_date_year, adr
order by arrival_date_year

--CALCULATONG THE TOTAL REVENUE FOR EACH YEAR
SELECT
    arrival_date_year,
    ROUND(SUM((stays_in_weekend_nights + stays_in_week_nights) * adr), 2) AS total_revenue
FROM
    hotelbookingsnotcanceled
GROUP BY
    arrival_date_year
ORDER BY
    total_revenue DESC;

select * from hotelbookingsfinal


--Total number of Adults, Children and babies checked into the hotels by month and year
SELECT
    arrival_date_year AS checkin_year,
    arrival_date_month AS checkin_month,
    SUM(adults) AS total_adults,
    SUM(children) AS total_children,
    SUM(babies) AS total_babies,
    SUM(adults + children + babies) AS total_guests
FROM
    hotelbookingsnotcanceled
GROUP BY
    arrival_date_year,
      arrival_date_month
ORDER BY
    checkin_year DESC, checkin_month DESC;



SELECT
    adults, arrival_date_year, sum(adults) 
FROM
    hotelbookingsnotcanceled
where arrival_date_year = 2015
GROUP BY
    adults, arrival_date_year
ORDER BY sum(adults) 

--TOTAL BOKINGS THAT WAS NOT CANCELED BY YEAR
select bookings, arrival_date_year, count(bookings)
from hotelbookingsnotcanceled
group by bookings, arrival_date_year
order by count(bookings) desc

select country, market_segment
from hotelbookingsnotcanceled
group by country, market_segment
order by country




--ANALYZING THE DATA 

--Should there be increase in parking lot size to accommodate a growing number of guests?
SELECT SUM(required_car_parking_spaces) AS 'Total Spaces Required', arrival_date_year AS 'Year', hotel AS 'Hotel'
FROM hotelbookingsnotcanceled
GROUP BY arrival_date_year, hotel
ORDER BY arrival_date_year;
/*For Resort hotel, the result shows more than 100% increase in demand for parking lot from 2015 to 2016, while from 
2016 to 2017, there is a decrease in demand for parking lot , for City Hotel, from 2015 to 2016 there is a six times 
increase in demand for parking lot, while from 2016 to 2017 there is a decrease in demand for parking lot, the decrease
in the demand for the parking lot for boths hotels from 2016 to 2017 will be attributed to decrease in number of guest for 
2016 to 2017. Even though there is a decrease in demand for parking lot in 2016 to 2017, we still cannot ignore the 
even higher increase of nearly 285% increase overall in parking spaces required from 2015 to 2016. From this we can 
say that an additional parking lot would be beneficial for both hotel chains given the dramatic increase of at least 
double the previous years parking from 2015 to 2016. It is best to expand this parking (as the budget allows) 
for locations in more populous areas that see more travelers passing through.
*/

--Are we seeing annual growth in our revenue?
--CALCULATONG THE TOTAL REVENUE FOR EACH YEAR
SELECT
    arrival_date_year,
    ROUND(SUM((stays_in_weekend_nights + stays_in_week_nights) * adr), 2) AS total_revenue
FROM
    hotelbookingsnotcanceled
GROUP BY
    arrival_date_year
ORDER BY
    total_revenue DESC;
/*We can observe from the query results that we did achieve a substantial increase in revenue 
from 2015 to 2016 in both hotel chains. There was a slight decrease in revenue from 2016 to 2017, 
but the 2017 revenue was never decreased lower than the initial value for the revenue data- 
the 2015 revenue. Something must have happened in 2017 which would have resulted into decrease in 
bookings and is/are the most likely factors that would explain why the 2017 revenues did not exceed 
the previous year revenue. 
From these results, I confirm that we have been achieving growth in our annual revenue as desired.
*/


--What trends can we see in the guest-specific data?
SELECT DISTINCT [arrival_date_year] AS Year,
COUNT(CASE WHEN children > 0 THEN 1 END) AS 'Children',
COUNT(CASE WHEN babies > 0 THEN 1 END) AS 'Infants',
COUNT(CASE WHEN adults > 0 THEN 1 END) AS 'Adults'
FROM hotelbookingsnotcanceled
GROUP BY arrival_date_year
ORDER BY arrival_date_year;
/*From the year 2015 to 2016, there was a 374% increase in child guests and a 204% increase 
in infant guests. The number of child and infant guests decreased in the year 2017, yet 
still remained 291% higher in child guests and 32% higher in infant guests, by comparison
From these results, we can conclude that there has been a large boost in the number of 
children and infants from year 2015 to 2017. This shows that we can expect a steady increase 
over the next few years in guests from these categories, and must therefore take the appropriate 
steps to introduce more family friendly options in the future to increase customer satisfaction 
and hotel reservations.
*/


--Checking the top 10 Agents that made the most revenue
SELECT top 10
    arrival_date_year,
    Agent,
    ROUND(SUM((stays_in_weekend_nights + stays_in_week_nights) * adr), 2) AS total_revenue
FROM
    hotelbookingsnotcanceled
GROUP BY
    arrival_date_year, Agent
ORDER BY
    arrival_date_year DESC, total_revenue DESC;
--I discovered a value 'NULL' in the agent column

--checking for how many 'NULL' value is in the agent column
select agent, COUNT(Agent)
from hotelbookingsnotcanceled
where agent = 'NULL'
group by agent
order by agent
--there are 10636 of the NULLs, so i will have to drop it so it won't interfare with my results

--deleting the 'NULL' values in the Agent column
delete from hotelbookingsnotcanceled
where agent = 'NULL'



--Re-Checking the top 10 Agents that made the most revenue
SELECT top 10
    arrival_date_year,
    Agent,
    ROUND(SUM((stays_in_weekend_nights + stays_in_week_nights) * adr), 2) AS total_revenue
FROM
    hotelbookingsnotcanceled
GROUP BY
    arrival_date_year, Agent
ORDER BY
    arrival_date_year DESC, total_revenue DESC;


--Adding the revenue generated as a column
ALTER TABLE hotelbookingsnotcanceled
ADD revenue AS (stays_in_weekend_nights + stays_in_week_nights) * adr;


--Agent Performance Trends
SELECT TOP 10 agent as Agent, MAX(revenue) as 'Top Sales', arrival_date_year AS Year, hotel AS 'Hotel'
FROM hotelbookingsnotcanceled
GROUP BY arrival_date_year, agent, hotel
ORDER BY [Top Sales] DESC;


SELECt *
from hotelbookingsnotcanceled


--CREATING TABLES
--(1) Agent Performance base on Revenue
SELECT TOP 10
    agent AS Agent,
    MAX(revenue) AS 'Top Sales',
    arrival_date_year AS Year,
    hotel AS 'Hotel'
INTO Agent_Performance
FROM hotelbookingsnotcanceled
GROUP BY arrival_date_year, agent, hotel
ORDER BY 'Top Sales' DESC;

--(2)count of children,Infant, Adult
SELECT 
	DISTINCT [arrival_date_year] AS Year,
	COUNT(CASE WHEN children > 0 THEN 1 END) AS 'Children',
	COUNT(CASE WHEN babies > 0 THEN 1 END) AS 'Infants',
	COUNT(CASE WHEN adults > 0 THEN 1 END) AS 'Adults'
into Count_of_chil_inf_adlt
FROM hotelbookingsnotcanceled
GROUP BY arrival_date_year
ORDER BY arrival_date_year;

--(3) Total Revenue each Year
SELECT
    arrival_date_year,
    ROUND(SUM((stays_in_weekend_nights + stays_in_week_nights) * adr), 2) AS total_revenue
into Total_revenue_by_year
FROM
    hotelbookingsnotcanceled
GROUP BY
    arrival_date_year
ORDER BY
    total_revenue DESC;

--(4) Parking lot required by year
SELECT 
	SUM(required_car_parking_spaces) AS 'Total Spaces Required', arrival_date_year AS 'Year', hotel AS 'Hotel'
into Parking_lot_required_by_year
FROM hotelbookingsnotcanceled
GROUP BY arrival_date_year, hotel
ORDER BY arrival_date_year;

--(5) Canceled and not Canceled bookings
SELECT
    bookings,
    COUNT(*) AS reservation_count
into Canceled_and_not_Canceled_bookings
FROM
    hotelbookingsfinal
WHERE
    bookings IN ('canceled', 'not_canceled')
GROUP BY
    bookings;

--(6)Months with the highest reservations
select 
	arrival_date_month, count(arrival_date_month) Reservation_count
into Reservation_count_by_month
from hotelbookingsnotcanceled
group by arrival_date_month
order by count(arrival_date_month) desc

--(7) Bookings by year
SELECT 
	arrival_date_year, count(arrival_date_year) Bookings_by_year
into Bookings_by_year
FROM hotelbookingsfinal
group by arrival_date_year
ORDER BY count(arrival_date_year)  DESC

--(8) Bookings by year and hotel
SELECT 
	arrival_date_year, hotel, count(arrival_date_year) Bookings_by_year
into Hotel_bookings_by_year
FROM hotelbookingsfinal
group by arrival_date_year, hotel
ORDER BY count(arrival_date_year)  DESC

--(9) Top 5 countries with the highest reservations
SELECT TOP 5
    country AS country,
    MAX(revenue) AS 'Top Sales by country',
    arrival_date_year AS Year,
    hotel AS 'Hotel'
INTO Country_Performance
FROM hotelbookingsnotcanceled
GROUP BY arrival_date_year, hotel, country
ORDER BY 'Top Sales by country' DESC;

