USE DATABASE DEMO_DATABASE;

-------------------------------------------------------------------QUESTION 1 --------------------------------------------------------------------------------
create or replace table candidates
(
candidate_id integer NOT NULL,
skill	varchar);

INSERT INTO candidates
VALUES(123,'Python'),(123,'Tableau'),(123,'SQL'),(123,'SQL'),(234,'R'),(234,'PowerBI'),(234,'SQL Server'),(345,'Python'),(345,'Tableau');

SELECT * FROM candidates;

--SOLUTION : KEY CONCEPTS - GROUP BY & HAVING
SELECT candidate_id,count(distinct skill) as skills_count
FROM candidates
WHERE skill IN ('Python', 'Tableau', 'SQL')
GROUP BY 1
HAVING skills_count = 3
order by 1;

-------------------------------------------------------------------QUESTION 2 --------------------------------------------------------------------------------

create or replace table transactions 
(transaction_id	integer,
account_id	integer,
transaction_type	varchar,
amount	decimal);

INSERT INTO transactions
VALUES(123,101,'Deposit',10.00),
(124,101,'Deposit',20.00),
(125,101,'Withdrawal',5.00),
(126,201,'Deposit',20.00),
(128,201,'Withdrawal',10.00);

SELECT * FROM transactions;

--SOLUTION : KEY CONCEPTS : CASE STATEMENTS 
/* We can determine whether money is deposited or withdrawn with the transaction_type column using a 
CASE WHEN statement and modifying the values of the amount column accordingly.

Let's negate the withdrawn amounts (-1 * amount) and leave the deposited amounts as they are: */

-- Now, we can calculate the ending balance by calculating the SUM of the modified amounts.
-- We'll GROUP BY the account_id so that the sums (which represent the final balances) 
-- will be calculated for each account separately.

SELECT account_id,
  SUM( CASE  WHEN transaction_type = 'Deposit' THEN amount
             ELSE -amount
             END) AS final_balance
FROM transactions
GROUP BY 1;


-------------------------------------------------------------------QUESTION 3 --------------------------------------------------------------------------------
CREATE OR REPLACE TABLE aj_events
(app_id	integer,
event_type	string,
timestamp	datetime);

INSERT INTO AJ_EVENTS
VALUES
(123,'impression', '07/18/2022 11:36:12'),
(123,'impression', '07/18/2022 11:37:12'),
(123,'click', '07/18/2022 11:37:42'),
(234,'impression', '07/18/2022 14:15:12'),
(234,'click', '07/18/2022 14:16:12');

SELECT * FROM AJ_EVENTS;

--SOLUTIONS : KEY-CONCEPTS : CASE-STATEMENTS 
--Solution #1: Using SUM(CASE ...)
SELECT
  app_id,
      CASE WHEN event_type = 'click' THEN 1 ELSE 0 END AS clicks,
      CASE WHEN event_type = 'impression' THEN 1 ELSE 0 END AS impressions
FROM AJ_events
WHERE timestamp >= '2022-01-01' AND timestamp < '2023-01-01';

SELECT app_id,ROUND(100.0 *
    SUM(CASE WHEN event_type = 'click' THEN 1 ELSE 0 END) /
    SUM(CASE WHEN event_type = 'impression' THEN 1 ELSE 0 END), 2)  AS ctr_rate
FROM aj_events
WHERE timestamp >= '2022-01-01' AND timestamp < '2023-01-01'
GROUP BY 1
order by 2 desc;


-- Solution #2: Using COUNT(CASE ...)
SELECT app_id,ROUND(100.0 *
    COUNT(CASE WHEN event_type = 'click' THEN 1 ELSE NULL END) /
    COUNT(CASE WHEN event_type = 'impression' THEN 1 ELSE NULL END), 3)  AS ctr_rate
FROM aj_events
WHERE YEAR(timestamp) = 2022
GROUP BY 1
order by 2 desc;

-------------------------------------------------------------------QUESTION 4 --------------------------------------------------------------------------------
create or replace table songs_history
(
history_id	integer,
user_id	integer,
song_id	integer,
song_plays	integer);

INSERT INTO songs_history
VALUES (10011,777,1238,11),(1245,695,4520,1);

SELECT * FROM songs_history;

CREATE OR REPLACE TABLE songs_weekly
(
user_id	integer,
song_id	integer,
listen_time	datetime);

INSERT INTO songs_weekly
VALUES 
(777,1238,'08/01/2022 12:00:00'),
(695,4520,'08/04/2022 08:00:00'),
(125,9630,'08/04/2022 16:00:00'),
(695,9852,'08/07/2022 12:00:00');

SELECT * FROM songs_weekly;

/*
Goal: Output the user id, song id and cumulative count of the song plays as of 4 August 2022.

Find the count of song plays by the user and song.
Combine the output with the historical streaming data.
Obtain the user id, song id and cumulative count of the song plays.
We’re using song plays and streaming interchangeably, but it should mean the same.

Step 1: Find the count of song plays by the user and song

According to the assumptions, the weekly table holds streaming data from 1 August 2022 to 7 August 2022. 
Since the question asks for data up to 4 August 2022 (inclusive), we have to filter to the specified date.

*/

select DATE(listen_time) from songs_weekly;

SELECT user_id, song_id, COUNT(song_id) AS song_plays
FROM songs_weekly
WHERE DATE(listen_time) <= '2022-08-04'
GROUP BY 1, 2;

--SOLUTION : KEY-CONCEPTS : UNION-ALL

-- Step 2: Combine the output with the historical streaming data
SELECT user_id, song_id, song_plays
FROM songs_history

UNION ALL

SELECT user_id, song_id, COUNT(song_id) AS song_plays
FROM songs_weekly
WHERE listen_time <= '08/04/2022 23:59:59'
GROUP BY user_id, song_id;

/* The trick for a UNION ALL to work is:

The number and the order of the fields in SELECT for both queries must be the same.
The data types must be compatible. */

--Step 3: Obtain the user id, song id and cumulative count of the song plays
-- Now that we have a table containing the historical streaming data up to 4 August 2022, 
-- let's work on the final step: 
-- Find the cumulative count of song plays and order them in descending order.

SELECT user_id, song_id, SUM(song_plays) AS song_count
FROM (
  SELECT user_id, song_id, song_plays
  FROM songs_history
  UNION ALL
  SELECT user_id, song_id, COUNT(song_id) AS song_plays
  FROM songs_weekly
  WHERE listen_time <= '08/04/2022 23:59:59'
  GROUP BY 1,2
) AS report
GROUP BY 1, 2
ORDER BY 3 DESC;


-------------------------------------------------------------------QUESTION 5 --------------------------------------------------------------------------------
CREATE OR REPLACE TABLE transactions 
(
transaction_id	integer,
type	string,
amount	decimal,
transaction_date	timestamp
);

INSERT INTO transactions
VALUES (19153,'deposit',65.90,'07/10/2022 10:00:00'),
       (53151,'deposit',178.55,'07/08/2022 10:00:00'),
       (29776,'withdrawal',25.90,'07/08/2022 10:00:00'),
       (16461,'withdrawal',45.99,'07/08/2022 10:00:00'),
       (77134,'deposit',32.60,'07/10/2022 10:00:00');
       
SELECT * FROM transactions;

/*
------ Solution
To start off, it is much easier if we start to solve the problem from the end - 
i.e. we want to have daily cumulative balances that reset every month.
Thus, to obtain two different granularities of transaction_date column we can utilize DATE_TRUNC function.

In order to obtain balances instead of solely transaction values, 
we can use CASE to assign positive sign to deposit and negative to withdrawals, and then just sum and group the values on a daily level 
(there might be multiple transactions during the day).

As the next step, we utilize SUM with a window function and calculate the sum partitioning 
by month - this makes sure that the cumulative sum is set to zero each month.
*/

SELECT transaction_day,
  SUM(balance) OVER ( PARTITION BY transaction_month ORDER BY transaction_day) AS balance
FROM 
(
SELECT
    DATE_TRUNC('day', transaction_date) AS transaction_day,
    DATE_TRUNC('month', transaction_date) AS transaction_month,
    SUM(CASE WHEN type = 'deposit'    THEN amount
             WHEN type = 'withdrawal' THEN -amount END) AS balance
  FROM transactions
  GROUP BY 1,2
)
ORDER BY 1;
















