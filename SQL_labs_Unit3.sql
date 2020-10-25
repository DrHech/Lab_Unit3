USE sakila;
SET SQL_SAFE_UPDATES = 0;
SET sql_mode=(SELECT REPLACE(@@sql_mode, 'ONLY_FULL_GROUP_BY', ''));

-- LAB 1

-- 1 number of films per category
select name as category_name, count(*) as num_films
from sakila.category
inner join sakila.film_category
using (category_id)
group by name
order by num_films desc;

-- 2 display the first and last names, as well as the address, of each staff member
select staff.first_name, staff.last_name, address.address
from sakila.address
inner join sakila.staff
on staff.address_id = address.address_id;

-- 3 display the total amount rung up by each staff member in August of 2005
select staff.staff_id, concat(first_name, ' ', last_name) as employee, sum(amount) as `total amount`
from sakila.staff
inner join sakila.payment
on staff.staff_id = payment.staff_id
where month(payment.payment_date) = 8 and year(payment.payment_date) = 2005
group by staff.staff_id;

-- 4 List each film and the number of actors who are listed for that film
select title as `film title`, count(actor_id) as `number of actors`
from sakila.film
inner join sakila.film_actor
on film.film_id = film_actor.film_id
group by film.film_id;

-- 5 list the total paid by each customer
select first_name, last_name, sum(amount) as "total amount paid"
from sakila.customer
inner join sakila.payment
on customer.customer_id = payment.customer_id
group by customer.customer_id
order by last_name;

-- LAB 2

select*from store;

select store.store_id, country.country, city.city from store
join address on address.address_id = store.address_id
join city on city.city_id = address.city_id
join country on country.country_id = city.country_id;

select store.store_id, sum(payment.amount) from store
join customer on customer.store_id = store.store_id
join payment on payment.customer_id = customer.customer_id
group by store.store_id;

select category.name, round(avg(length),2) as average_running_time from category
join film_category on film_category.category_id = category.category_id
join film on film.film_id = film_category.film_id
group by category.name
order by average_running_time desc;

select*from film;

select category.name, round(sum(payment.amount),2) as gross_revenue from category
join film_category on film_category.category_id = category.category_id
join film on film.film_id = film_category.film_id
join inventory on inventory.film_id = film.film_id
join rental on rental.inventory_id = inventory.inventory_id
join payment on payment.rental_id = rental.rental_id
group by category.name
order by sum(payment.amount) desc
limit 5;

select film.title, store.store_id, inventory.inventory_id from film
join inventory on inventory.film_id = film.film_id
join store on store.store_id = inventory.store_id
where film.title = "Academy Dinosaur" and store.store_id = 1;

-- 1
select store_id, city, country
from sakila.store
join (sakila.address join (sakila.city join sakila.country using (country_id)) using (city_id)) using (address_id);

-- 2
select store.store_id, round(sum(amount), 2)
from sakila.store join (sakila.customer join (sakila.payment join sakila.rental using (rental_id)) on customer.customer_id = payment.customer_id) using (store_id)
group by store.store_id;

-- 3
select category.name, avg(length)
from sakila.film join sakila.film_category using (film_id)
                 join sakila.category using (category_id)
group by category.name
order by avg(length) desc;

-- 4
select category.name, avg(length)
from sakila.film join sakila.film_category using (film_id)
                 join sakila.category using (category_id)
group by category.name
order by avg(length) desc;

-- 5
select title, count(*) as `rental frequency`
from sakila.film
join (sakila.inventory join sakila.rental using (inventory_id))
using (film_id)
group by title
order by `rental frequency` desc;

-- 6
select name, category_id, sum(amount) as `gross revenue`
from sakila.payment
join (sakila.rental join (sakila.inventory join (sakila.film_category join sakila.category using (category_id)) using (film_id)) using (inventory_id)) using (rental_id)
group by category_id
order by `gross revenue` desc
limit 5;

-- 7
select store.store_id, inventory.inventory_id
from sakila.inventory join sakila.store using (store_id)
     join sakila.film using (film_id)
     join sakila.rental using (inventory_id)
where film.title = 'Academy Dinosaur'
      and store.store_id = 1
      and not exists (select * from sakila.rental
                      where rental.inventory_id = inventory.inventory_id
                      and rental.return_date is null)
group by store_id, inventory_id;


-- LAB 3

select*from actor;
select*from film_actor;

-- Get All Pairs of Actors that Worked Together

select film_actor.actor_id, film_id, actor.first_name, actor.last_name from film_actor
left join actor on actor.actor_id = film_actor.actor_id
order by film_actor.actor_id;

select a1.actor_id, a1.first_name, a1.last_name, a2.actor_id, a2.first_name, a2.last_name, a2.film_id from (
select film_actor.actor_id, film_id, actor.first_name, actor.last_name from film_actor
left join actor on actor.actor_id = film_actor.actor_id
order by film_actor.actor_id) as a1
join (select film_actor.actor_id, film_id, actor.first_name, actor.last_name from film_actor
left join actor on actor.actor_id = film_actor.actor_id
order by film_actor.actor_id) as a2
on a1.film_id = a2.film_id
and a1.actor_id <> a2.actor_id
order by a1.actor_id, a2.actor_id, film_id;

/*
WITH cte AS (
    SELECT 
        a1.actor_id, 
        a1.first_name, 
        a1.last_name, 
        a2.actor_id,
        a2.first_name,
        a2.last_name,
        ROW_NUMBER() OVER (
            PARTITION BY 
                a1.actor_id, 
				a1.first_name, 
				a1.last_name, 
				a2.actor_id,
				a2.first_name,
				a2.last_name
            ORDER BY 
                a1.actor_id, 
				a1.first_name, 
				a1.last_name, 
				a2.actor_id,
				a2.first_name,
				a2.last_name
        ) row_num
     FROM 
        (select a1.actor_id, a1.first_name, a1.last_name, a2.actor_id, a2.first_name, a2.last_name, a2.film_id from (
		select film_actor.actor_id, film_id, actor.first_name, actor.last_name from film_actor
		left join actor on actor.actor_id = film_actor.actor_id
		order by film_actor.actor_id) as a1
		join (select film_actor.actor_id, film_id, actor.first_name, actor.last_name from film_actor
		left join actor on actor.actor_id = film_actor.actor_id
		order by film_actor.actor_id) as a2
		on a1.film_id = a2.film_id
		and a1.actor_id <> a2.actor_id
		order by a1.actor_id, a2.actor_id, film_id)
)
DELETE FROM cte
WHERE row_num > 1;
*/

-- Get all pairs of customers that have rented the same film more than 3 times.

select*from rental;

select *, count(rental_id) from rental
group by customer_id, inventory_id;

select customer.customer_id, customer.first_name, customer.last_name, film.title, count(rental_id) as number_of_rents from customer
left join rental on rental.customer_id = customer.customer_id
left join inventory on inventory.inventory_id = rental.inventory_id
left join film on film.film_id = inventory.film_id
group by customer.customer_id, customer.first_name, customer.last_name, film.title
order by customer.customer_id;



select a1.title, a1.first_name, a1.last_name, a1.number_of_rents, a2.first_name, a2.last_name, a2.number_of_rents from (
select customer.first_name, customer.last_name, film.title, count(rental_id) as number_of_rents from customer
left join rental on rental.customer_id = customer.customer_id
left join inventory on inventory.inventory_id = rental.inventory_id
left join film on film.film_id = inventory.film_id
group by customer.first_name, customer.last_name, film.title
order by customer.first_name) as a1
join (select customer.first_name, customer.last_name, film.title, count(rental_id) as number_of_rents from customer
left join rental on rental.customer_id = customer.customer_id
left join inventory on inventory.inventory_id = rental.inventory_id
left join film on film.film_id = inventory.film_id
group by customer.first_name, customer.last_name, film.title
order by customer.first_name) as a2
on a1.first_name  <> a2.first_name
and a1.title = a2.title
where a1.number_of_rents > 1 and a2.number_of_rents > 1
order by a1.first_name, a1.last_name, a1.title, a2.first_name, a2.last_name;


select*from rental;
-- Get all possible pairs of actors and films.



-- 1 Get all pairs of actors that worked together

select fa1.film_id, concat(a1.first_name, ' ', a1.last_name), concat(a2.first_name, ' ', a2.last_name)
from sakila.actor a1
inner join film_actor fa1 on a1.actor_id = fa1.actor_id
inner join film_actor fa2 on (fa1.film_id = fa2.film_id) and (fa1.actor_id != fa2.actor_id)
inner join actor a2 on a2.actor_id = fa2.actor_id;

-- 2 Get all pairs of customers that have rented the same film more than 3 times.

select c1.customer_id, c2.customer_id, count(*) as num_films
from sakila.customer c1
inner join rental r1 on r1.customer_id = c1.customer_id
inner join inventory i1 on r1.inventory_id = i1.inventory_id
inner join film f1 on i1.film_id = f1.film_id
inner join inventory i2 on i2.film_id = f1.film_id
inner join rental r2 on r2.inventory_id = i2.inventory_id
inner join customer c2 on r2.customer_id = c2.customer_id
where c1.customer_id <> c2.customer_id
group by c1.customer_id, c2.customer_id
having count(*) > 3
order by num_films desc;

-- 3 Get all possible pairs of actors and films.

select
    concat(a.first_name,' ', a.last_name) as actor_name
    f.title
from sakila.actor a
cross join sakila.film as f;


-- LAB 4




-- LAB 5

-- How many copies of the film Hunchback Impossible exist in the inventory system?
select*from film;

select film.title, count(inventory.inventory_id) as number_of_copies from film
join inventory on inventory.film_id = film.film_id
group by title
having title = "HUNCHBACK IMPOSSIBLE";

-- List all films longer than the average.
select film.title, film.length from film
where film.length > (select avg(film.length) from film)
order by length desc;

-- Use subqueries to display all actors who appear in the film Alone Trip.
select film.title, concat(actor.first_name," ",actor.last_name) as actor_name from film
join film_actor on film_actor.film_id = film.film_id
join actor on actor.actor_id = film_actor.actor_id
where title like "Alone Trip";

-- Sales have been lagging among young families, and you wish to target all family movies for a promotion. Identify all movies categorized as family films.
select category.name, film.title from category
join film_category on film_category.category_id = category.category_id
join film on film.film_id = film_category.film_id
where category.name like "Family";

-- Get name and email from customers from Canada using subqueries. Do the same with joins.
select concat(customer.first_name," ",customer.last_name) as customer_name, customer.email, country.country as country_name from customer
join address on address.address_id = customer.address_id
join city on city.city_id = address.address_id
join country on country.country_id = city.country_id
where country.country like "Canada";

-- Which are films starred by the most prolific actor?
select actor_id from (
select actor_id, max(number_of_films) from (
select actor_id, count(film_id) as number_of_films from film_actor
group by actor_id
order by number_of_films desc) as sub1) as sub2;

select actor_id, film.title from film_actor
join film on film.film_id = film_actor.film_id
where actor_id in (select actor_id from (
select actor_id, max(number_of_films) from (
select actor_id, count(film_id) as number_of_films from film_actor
group by actor_id
order by number_of_films desc) as sub1) as sub2);

-- Films rented by most profitable customer.
select concat(customer.first_name," ",customer.last_name) as customer_name, round(sum(amount),2) as amount_spent from customer
join payment on payment.customer_id = customer.customer_id
group by customer_name
order by amount_spent desc;

select customer_na from (select concat(customer.first_name," ",customer.last_name) as customer_na, round(sum(amount),2) as amount_spent from customer
join payment on payment.customer_id = customer.customer_id
group by customer_na
order by amount_spent desc
limit 1) as sub1;

select concat(customer.first_name," ",customer.last_name), film.title from customer
join rental on rental.customer_id = customer.customer_id
join inventory on inventory.inventory_id = rental.inventory_id
join film on film.film_id = inventory.film_id
where concat(customer.first_name," ",customer.last_name) in (select customer_na from (select concat(customer.first_name," ",customer.last_name) as customer_na, round(sum(amount),2) as amount_spent from customer
join payment on payment.customer_id = customer.customer_id
group by customer_na
order by amount_spent desc
limit 1) as sub1)
group by film.title;



-- Customers who spent more than the average
select*from payment;

select concat(customer.first_name," ",customer.last_name) as customer_name, round(sum(amount),2) as amount_spent from customer
join payment on payment.customer_id = customer.customer_id
group by customer_name;

select avg(amount_spent) from (
select concat(customer.first_name," ",customer.last_name) as customer_name, round(sum(amount),2) as amount_spent from customer
join payment on payment.customer_id = customer.customer_id
group by customer_name) as sub1;

select concat(customer.first_name," ",customer.last_name) as customer_name, round(sum(amount),2) as amount_spent from customer
join payment on payment.customer_id = customer.customer_id
group by customer_name
having amount_spent > (select avg(amount_spent) from (
select concat(customer.first_name," ",customer.last_name) as customer_name, round(sum(amount),2) as amount_spent from customer
join payment on payment.customer_id = customer.customer_id
group by customer_name) as sub1)
order by amount_spent;

-- 1 How many copies of the film Hunchback Impossible exist in the inventory system?
select count(film_id) from inventory
where film_id = (
  select film_id from sakila.film
  where title = 'Hunchback Impossible'
);

-- 2 List all films longer than the average.
select title, length from sakila.film
where length > (
  select avg(length) from sakila.film
);

-- 3 Use subqueries to display all actors who appear in the film Alone Trip.
select concat(first_name, ' ', last_name) as `Actor`
from sakila.actor
where actor_id in (
  -- Grab the actor_ids for actors in Alone Trip
  select actor_id
  from sakila.film_actor
  where film_id = (
    -- Grab the film_id for Alone Trip
    select film_id
    from sakila.film
    where title = 'ALONE TRIP'
  )
);

-- 4 Sales have been lagging among young families, and you wish to target all family movies for a promotion. Identify all movies categorized as family films.
select title as `Title`
from sakila.film
where film_id in (
  select film_id
    from sakila.film_category
    where category_id in (
      select category_id
      from sakila.category
      where name = 'Family'
  )
);

-- 5 Get name and email from customers from Canada using subqueries. Do the same with joins.
select concat(first_name, ' ', last_name) as `Customer Name`, email
from sakila.customer
where address_id in (
  select address_id
  from sakila.address
  where city_id in (
    select city_id
    from sakila.city
    where country_id in (
      select country_id
      from sakila.country
      where country = 'Canada'
    )
  )
);

select concat(first_name, ' ', last_name) as `Customer Name`, email
from sakila.customer
join (
  sakila.address join (
    sakila.city join sakila.country
    using (country_id)
  )
  using (city_id)
)
using (address_id)
where country = 'Canada';

-- 6
-- get most prolific author
select actor_id
from sakila.actor
inner join sakila.film_actor
using (actor_id)
inner join sakila.film
using (film_id)
group by actor_id
order by count(film_id) desc
limit 1;

-- now get the films starred by the most prolific actor
select concat(first_name, ' ', last_name) as actor_name, film.title, film.release_year
from sakila.actor
inner join sakila.film_actor
using (actor_id)
inner join film
using (film_id)
where actor_id = (
  select actor_id
  from sakila.actor
  inner join sakila.film_actor
  using (actor_id)
  inner join sakila.film
  using (film_id)
  group by actor_id
  order by count(film_id) desc
  limit 1
)
order by release_year desc;

-- 7
-- most profitable customer

select customer_id
from sakila.ustomer
inner join payment using (customer_id)
group by customer_id
order by sum(amount) desc
limit 1;

-- films rented by most profitable customer
select film_id, title, rental_date, amount
from sakila.film
inner join inventory using (film_id)
inner join rental using (inventory_id)
inner join payment using (rental_id)
where rental.customer_id = (
  select customer_id
  from customer
  inner join payment
  using (customer_id)
  group by customer_id
  order by sum(amount) desc
  limit 1
)
order by rental_date desc;

-- 8 Customers who spent more than the average.
select customer_id, sum(amount) as payment
from sakila.customer
inner join payment using (customer_id)
group by customer_id
having sum(amount) > (
  select avg(total_payment)
  from (
    select customer_id, sum(amount) total_payment
    from payment
    group by customer_id
  ) t
)
order by payment desc;

-- LAB 6

-- List each pair of actors that have worked together.


select film_actor.actor_id, film_id, actor.first_name, actor.last_name from film_actor
left join actor on actor.actor_id = film_actor.actor_id
order by film_actor.actor_id;

drop view actor_pair;
create view actor_pair as
select a1.actor_id as id1, a1.first_name as first1, a1.last_name as last1, a2.actor_id as id2, a2.first_name as first2, a2.last_name as last2, a2.film_id from (
select film_actor.actor_id, film_id, actor.first_name, actor.last_name from film_actor
left join actor on actor.actor_id = film_actor.actor_id
order by film_actor.actor_id) as a1
join (select film_actor.actor_id, film_id, actor.first_name, actor.last_name from film_actor
left join actor on actor.actor_id = film_actor.actor_id
order by film_actor.actor_id) as a2
on a1.film_id = a2.film_id
and a1.actor_id <> a2.actor_id
order by a1.actor_id, a2.actor_id, film_id;


select distinct(concat(first1," , ",first2)) from actor_pair;


-- For each film, list actor that has acted in more films.



-- 1 List each pair of actors that have worked together.
select fa1.film_id, concat(a1.first_name, ' ', a1.last_name), concat(a2.first_name, ' ', a2.last_name)
from sakila.actor a1
inner join film_actor fa1 on a1.actor_id = fa1.actor_id
inner join film_actor fa2 on (fa1.film_id = fa2.film_id) and (fa1.actor_id != fa2.actor_id)
inner join actor a2 on a2.actor_id = fa2.actor_id;

-- 2 For each film, list actor that has acted in more films.
with actor_movies as (
  select actor_id, count(film_id) as num_films
  from film_actor
  group by actor_id
)

select f.title, concat(a.first_name, ' ', a.last_name) as best_actor
from (
  select film_id, actor_id, rank() over (
    partition by film_id
    order by num_films
    desc
  ) as m
from film_actor
inner join actor_movies
using (actor_id)) t
inner join actor a on t.actor_id = a.actor_id
inner join film f on t.film_id = f.film_id
where m = 1;


-- LAB 7

-- 1 Get number of monthly active customers.
with customer_activity as (
  select customer_id, convert(rental_date, date) as Activity_date,
  date_format(convert(rental_date,date), '%M') as Activity_Month,
  date_format(convert(rental_date,date), '%Y') as Activity_year
  from sakila.rental
)
select count(distinct customer_id) as Active_users, Activity_year, Activity_Month
from customer_activity
group by Activity_year, Activity_Month
order by Activity_year, Activity_Month;

-- 2 Active users in the previous month.
with customer_activity as (
  select customer_id, convert(rental_date, date) as Activity_date,
  date_format(convert(rental_date,date), '%M') as Activity_Month,
  date_format(convert(rental_date,date), '%Y') as Activity_year
  from sakila.rental
),
monthly_active_users as (
  select count(distinct customer_id) as Active_users, Activity_year, Activity_Month
  from customer_activity
  group by Activity_year, Activity_Month
  order by Activity_year, Activity_Month
),
cte_activity as (
  select Active_users, lag(Active_users,1) over (partition by Activity_year) as last_month, Activity_year, Activity_month
  from monthly_active_users
)
select * from cte_activity
where last_month is not null;

-- 3 Percentage change in the number of active customers.
with customer_activity as (
  select customer_id, convert(rental_date, date) as Activity_date,
  date_format(convert(rental_date,date), '%M') as Activity_Month,
  date_format(convert(rental_date,date), '%Y') as Activity_year
  from sakila.rental
),
monthly_active_users as (
  select count(distinct customer_id) as Active_users, Activity_year, Activity_Month
  from customer_activity
  group by Activity_year, Activity_Month
  order by Activity_year, Activity_Month
),
cte_activity as (
  select Active_users, lag(Active_users,1) over (partition by Activity_year) as last_month, Activity_year, Activity_month
  from monthly_active_users
)
select (Active_users-last_month)/Active_users*100 as percentage_change, activity_year, activity_month
from cte_activity
where last_month is not null;

-- 4 Retained customers every month.
with customer_activity as (
  select customer_id, convert(rental_date, date) as Activity_date,
  date_format(convert(rental_date,date), '%M') as Activity_Month,
  date_format(convert(rental_date,date), '%Y') as Activity_year,
  convert(date_format(convert(rental_date,date), '%m'), UNSIGNED) as month_number
  from sakila.rental
),
distinct_users as (
  select distinct customer_id , Activity_month, Activity_year, month_number
  from customer_activity
)
select count(distinct d1.customer_id) as Retained_customers, d1.Activity_month, d1.Activity_year
from distinct_users d1
join distinct_users d2
on d1.customer_id = d2.customer_id and d1.month_number = d2.month_number + 1
group by d1.Activity_month, d1.Activity_year
order by d1.Activity_year, d1.month_number;


-- LAB 8

-- Create a query or queries to extract the information you think may be relevant for building the prediction model. It should include some film features and some rental features.

select*from film;
select distinct(amount) from payment;
select*from rental
order by rental_date desc;
select*from inventory;

/*
select film.title, concat(actor.first_name," ",actor.last_name) as actor_name from film
join film_actor on film_actor.film_id = film.film_id
join actor on actor.actor_id = film_actor.actor_id
order by title;
*/


-- film_id, number in inventory, rental duration, rental_rate, length, replacement cost, rating, rented last month
select film.title, release_year, film.rental_duration, film.rental_rate, film.length, film.replacement_cost, film.rating
from film;

select rental_id, date_format(convert(rental_date,date), "%Y%m%d") as rent_date from rental;

-- Whether the film was rented last month (say June)
select film.title, count(inventory.film_id) as number_of_rents from film 
left join inventory on inventory.film_id = film.film_id
left join rental on rental.inventory_id = inventory.inventory_id and rental.rental_date > 20050761 and rental.rental_date <= 20050631
group by film.title
order by film.title;

select title, if(number_of_rents > 0, "Y","N") as rented_in_june from (
select film.title, count(inventory.film_id) as number_of_rents from film 
left join inventory on inventory.film_id = film.film_id
left join rental on rental.inventory_id = inventory.inventory_id and rental.rental_date > 20050601 and rental.rental_date <= 20050631
group by film.title
order by film.title
) as sub1
order by title;

-- Whether the film was rented next month (say July)
select film.title, count(inventory.film_id) as number_of_rents from film 
left join inventory on inventory.film_id = film.film_id
left join rental on rental.inventory_id = inventory.inventory_id and rental.rental_date > 20050701 and rental.rental_date <= 20050731
group by film.title
order by film.title;

select title, if(number_of_rents > 0, "Y","N") as rented_july from (
select film.title, count(inventory.film_id) as number_of_rents from film 
left join inventory on inventory.film_id = film.film_id
left join rental on rental.inventory_id = inventory.inventory_id and rental.rental_date > 20050701 and rental.rental_date <= 20050731
group by film.title
order by film.title
) as sub1
order by title;



-- Selecting top 10 most prolofic actors and creating a column - whether a film has one of those 10 in cast
-- returns top 10 actor_id appeared in most movies
select film_id, if( film_id in (
select distinct(film_id) from film_actor
where actor_id in
(
select actor_id as p_actor from
(
    select actor_id, count(film_id) as film_count, row_number() over (order by count(film_id) desc) as magic
    from film_actor
    group by actor_id
    order by count(film_id) desc
) as alias_1
where magic > 0 and magic <=10
)
) , 'YES', 'NO') as pop_actor from film
;
