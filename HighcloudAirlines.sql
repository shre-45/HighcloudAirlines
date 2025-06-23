SELECT * FROM high_cloud.maindata;

-- total airlines
select count(distinct `%Airline ID`) from maindata;

-- total destination country
select count(distinct `Destination Country`) from maindata;

-- total transported passengers
select concat(round(sum(`# Transported Passengers`/1000000),0),"M") from maindata;

-- total distance
select concat(round(sum(`Distance`/1000000),0),"M") from maindata;

-- inserting date_field, load_factor to maindata
set sql_safe_updates=0; 
alter table maindata add column Date_field date;
update maindata
set Date_field = date(concat(Year,"-",`Month (#)`,"-",Day)) ;

alter table maindata add column Load_factor decimal(10,4);
update maindata 
set Load_factor= case
                  when `# Available Seats`=0 then 0
                  ELSE `# Transported Passengers`/`# Available Seats`
                  end;
                  
-- KPI1- creating calendar table
Create table Calendar(
  Date_Field date,
  Year int,
  Month_no int,
  Month_name varchar(50),
  Quarter varchar(50),
  YearMonth varchar(50),
  Weekday_no int,
  Weekday_name varchar(50),
  Financial_Month varchar(50),
  Financial_Quarter varchar(50)
);

Insert into calendar (Date_Field,Year,Month_no,Month_name,Quarter,YearMonth,Weekday_no,Weekday_name,Financial_Month,Financial_Quarter)
select 
   Date_field as Date_Field,
   `Year` as Year,
   `Month (#)` as Month_no,
   monthname(Date_field) as Month_name,
   concat("Q",Quarter(Date_field)) as Quarter,
   concat(`Year`,'-',monthname(Date_field)) as YearMonth,
   dayofweek(Date_field) as Weekday_no,
   dayname(Date_field) as Weekday_name,
   case 
     when monthname(Date_field)='January' then 'FM10'
     when monthname(Date_field)='February' then 'FM11'
     when monthname(Date_field)='March' then 'FM12'
     when monthname(Date_field)='April' then 'FM1'
     when monthname(Date_field)='May' then 'FM2'
     when monthname(Date_field)='June' then 'FM3'
     when monthname(Date_field)='July' then 'FM4'
     when monthname(Date_field)='August' then 'FM5'
     when monthname(Date_field)='September' then 'FM6'
     when monthname(Date_field)='October' then 'FM7'
     when monthname(Date_field)='November' then 'FM8'
     else 'FM9'
     END AS Financial_Month,
   Case
	 when monthname(Date_field) in ('April','May','June') then 'Q1'
     when monthname(Date_field) in ( 'July','August','September') then 'Q2'
     when monthname(Date_field) in ('October','November','December') then 'Q3'
     else 'Q4'
     end as Financial_Quarter
from maindata;

-- KPI 2
-- year wise load factor
select `Year`,concat(round(sum(Load_factor)/(select sum(Load_factor) from maindata)*100,2)," ","%") as "Load factor"
from maindata
group by `Year`;
   
-- month wise loadfactor
select monthname(Date_field) as Month,concat(round(sum(Load_factor)/(select sum(Load_factor) from maindata)*100,2)," ","%") as "Load factor"
from maindata
group by monthname(Date_field),`Month (#)`
order by `Month (#)`;

-- quarter wise load factor
select concat("Q",Quarter(Date_field)) as Quarter,concat(round(sum(Load_factor)/(select sum(Load_factor) from maindata)*100,2)," ","%") as "Load factor"
from maindata
group by concat("Q",Quarter(Date_field))
order by concat("Q",Quarter(Date_field));

-- KPI 3-carrier wise loadfactor
select `Carrier Name`,concat(round(sum(Load_factor)/(select sum(Load_factor) from maindata)*100,2)," ","%") as "Load factor"
from maindata
group by `Carrier Name`
order by round(sum(Load_factor)/(select sum(Load_factor) from maindata)*100,2) desc limit 10 ;

-- KPI 4- Top 10 carriers based on passengers prefernce
SELECT `Carrier Name`,concat(round(sum(`# Transported Passengers`/1000000),2),"M") AS 'Sum of Transported Passengers'
FROM maindata
group by `Carrier Name`
order by SUM(`# Transported Passengers`) desc limit 10 ;

-- KPI 5- Top Routes
select `From - To City` AS "Route",count(*) as "Number of Flights"
from maindata 
group by `From - To City`
order by count(`From - To City`) desc limit 5;

-- KPI 6- load factor on weekend and weekdays
select if (dayofweek(Date_field)=1 or dayofweek(Date_field)=7,"Weekend","Weekday") as "Weekday or Weekdend",
concat(round(sum(Load_factor)/(select sum(Load_factor) from maindata)*100,2)," ","%") as "Load factor"
from maindata
group by if (dayofweek(Date_field)=1 or dayofweek(Date_field)=7,"Weekend","Weekday");yes

-- KPI 7- NO.of flights based on distance gp
select `Distance Interval`,count(`%Airline ID`) as "No. of flights" 
from `distance groups` D,maindata m
where D.`Distance group ID`=m.`%Distance Group ID`
group by `Distance Interval`
order by count(`%Airline ID`) desc;
