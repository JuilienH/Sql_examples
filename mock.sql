SELECT e.first_name, e.last_name, e.salary,
  d.name as department_name
FROM employees   AS e
JOIN departments AS d ON e.department_id = d.id;

/***average salary by project***/

/*Assumption: an employee has multiple projects and each is treated an an entity per project*/
CREATE TABLE people AS
SELECT  e.id as employee_id, e.salary, p.project_id
FROM employees as e
RIGHT JOIN employees_projects as p
ON e.id=p.employee_id;

SELECT AVG(people.salary)
FROM people
RIGHT JOIN projects 
ON people.project_id=projects.id
GROUP BY projects.id;

/***which attendance drop is biggest between today and yesterday ***/

/*table join first to get the index conlumn (boolean) for attendance*/
/*create table with only two dates per student*/
/*Assumption: any date is filled even though no data for that date*/
CREATE TABLE TimeTable AS
SELECT grade_level,student_id, dates, attendance
FROM Table3
GROUP BY student_id
ORDER BY dates DESC LIMIT 2; /*today and yesterday*/
/*timediff calculation and pick the largest diff*/
/*--Each student should have two rows. Each row for one date*/
CREATE TABLE TimeTable2 AS
SELECT
grade_level,student_id, attendance-LAG(attendance) AS diff /*1-0*/
/*0
  1 0
    1*/
FROM TimeTable
GROUP BY grade_level, student_id
HAVING diff = 1 ;
/*final calculation to get the grade_level that has the largest drop */

SELECT TOP 1
SELECT grade_level, COUNT(student_id) AS CNT_ST
FROM TimeTable2
GROUP BY grade_level
ORDER BY COUNT(student_id) DESC;
/*---Then you can see which grade_level has most stduents dropped today if they showed up yesterday*/


/***Given a employees and departments table, select the top 3 departments with at least ten employees
 and rank them according to the percentage of their employees making over 100K in salary.
***/

/***first attribution***/
/*each user has multiple sessions. In each session, convert or not*/
CREATE TABLE masterTable AS
SELECT attribution.session_id, attribution.conversion, user_session.user_id, user_session.cretaed_at
FROM attribution 
RIGHT JOIN
user_session
ON attribution.session_id=user_session.session_id
WHERE attribution.conversion IS TRUE
/*WHERE: remember to filter on conversion is TRUE*/
/*user_id to link conversion and created_at, then group by user and created_at to get the first time conversion*/
GROUP BY user_session.user_id
ORDER BY user_session.created_at ASC LIMIT 1;
/*the first time a user converted to any buying behavior*/

/***number of users whose transactions are more than once at different days***/
/*users with distinct counts of products purchased*/
CREATE TABLE Uniq_Cnt AS
SELECT DISTINCT user_id, DISTINCT COUNT(product_id) as Uniq_Prod_Cnt /*unique list of user_ids*/
FROM transactions
GROUP BY user_id
HAVING Uniq_Prod_Cnt >=2;
/*remove same-day purchases per user*/
CREATE TABLE Table_update AS
SELECT user_id, CONVERT(VARCHAR(10),created_at,101) AS dates /*this converts date format to be character, 101 is the code for it. But
If created_at has been stored as character, you can count it without conversion.*/
FROM transactions
HAVING dates in
  (SELECT DISTINCT COUNT(CONVERT(VARCHAR(10),created_at,101)) AS dates
  GROUP BY user_id
  FROM TRANSACTIONS
  HAVING dates <>1;)
INNER JOIN
Uniq_Cnt 
ON user_id;

/*Number of upsold customers*/
SELECT COUNT (user_id)
FROM Table_update;

/***percentage of users that had at least one 7-day streak of visiting the same url***/
/*indicators for lag days*/
CREATE TABLE basetable AS
SELECT DISTINCT user_id,
CASE WHEN DATEDIFF(created_at,LAG(created_at,1))=-1 THEN 1
/* 2022-02-09
   2022-02-08 2022-02-09
   2022-02-07 2022-02-08*/
ELSE 0
END AS lag1,
CASE WHEN DATEDIFF(LAG(created_at,1),LAG(created_at,2))=-2 THEN 1
ELSE 0
END AS lag2,
/*repeat for the next 4 variables, lag3, lag4, lag5, lag6*/
CASE WHEN SUM(lag1,lag2,lag3,lag4,lag5,lag6)=6 THEN 1
ELSE 0
END AS sevenday_streak /*Create one column indicating the sum=6 or otherwise*/
FROM testTable
GROUP BY user_id, created_at 
ORDER BY created_at DESC;
/*Challenge: Each user's sevenday_streak status can be different, depending on the created_at as the starting date*/
/*--Assumption: For each day, we calculate the percentages as we know one user may be labeled differently--*/
SELECT SUM(sevenday_streak)/COUNT(*) AS percentages
GROUP BY created_at
FROM basetable;
/*percentages of users=count(user_id) when the sume=7/count(user_id) for all*/

/***Last transaction each day***/
/*sort transaction id by date*/
CREATE TABLE basetable AS
SELECT ROW_NUMBER() OVER(PARTITION tranaction_id ORDER BY created_at DESC) AS row_num,
transaction_id, created_at,transaction_amt
FROM table_bank
WHERE row_num=1;
/*Keep first row for each transaction_id*/

/***query result with rating less than 3***/
/*each query returns multiple results, so we use query_id as the unique identifier*/
CREATE TABLE baetable AS
SELECT query_id, result_id,ROUND(AVG(rating),2) AS average_rt,
CASE WHEN ROUND(AVG(rating),2) <=3 THEN 1
ELSE 0
END AS rt_cat
FROM query_table
GROUP BY query_id;
/*average ratings per query and round it to 2 decimal points*/

SELECT SUM(rt_cat)/COUNT(query_id) AS percentage_rt FROM basetable;

/***Top 5 users with the longest streak visit***/
/*hot-coding 1 vs 0 to indicate each day whehter the platfoem is visited*/
CREATE TABLE firsttable AS
SELECT user_id,
       created_at,
       CASE WHEN DATEDIFF(created_at,LAG(created_at,1)) =1 THEN 1
       ELSE 0
       END AS lag1,
       CASE WHEN DATEDIFF(LAG(created_at,1),LAG(created_at,2)) =1 THEN 1
       ELSE 0
       END AS lag2
       /*repeat cae when to code more lag variables*/
GROUP BY user_id
ORDER BY created_at DESC;      
/*Sum the hot-coding value. and take the top 5 highest to identify the users*/
SELECT SUM(lag1,lag2) /*...all the lag variables*/
FROM firsttable
GROUP BY user_id, created_at;/*this date serves as the starting date*/
ORDER BY SUM(lag1,lag2) DESC LIMIT 5;

/***For each user their friends' liked pages***/

/*Join User table & Friend table to pull friends' liked page id*/

CREATE TABLE tabl1 AS

SELECT users.user_id,pageliked.page_id,

      /* COUNT(users.user_id) AS CNT1,*/

       COUNT(pageliked.user_id) AS CNT2

FROM users

INNER JOIN pageliked

ON users.friends_id=pageliked.user_id

GROUP BY users.user_id,pageliked.page_id

ORDER BY COUNT(pageliked.user_id) DESC ; /*For each user, count how many friends like each page */

/*Challenge1: users can be friends of other users. Unaffected the result here*/

/*Challenge2: And we don't want to count the pages liked by the users themselves*/

/*need to use use_id to pull the pages users liked and we need to substract the second

result from the first one*/

CREATE TABLE tabl2 AS

SELECT users.user_id,pageliked.page_id,

      /* COUNT(users.user_id) AS CNT1,*/

       COUNT(pageliked.user_id) AS CNT2

FROM users

INNER JOIN pageliked

ON users.user_id=pageliked.user_id

GROUP BY users.user_id,pageliked.page_id

ORDER BY COUNT(pageliked.user_id) DESC;

 

SELECT *

FROM tabl1

WHERE (user_id NOT IN (SELECT user_id FROM tabl2)

      AND page_id NOT IN (SELECT page_id FROM tabl2));

 

/***%users have never liked or commented***/

CREATE TABLE tabl1 AS

SELECT user.user_id, events.action,

       CASE WHEN events.action NOT IN ('liked','comment') THEN 1

       ELSE 0

       END AS inactive_user

FROM user

LEFT JOIN events

ON user.user_id=events.user_id;

 

SELECT ROUND(SUM(inactive_user)*100/COUNT(user_id),2) AS percentages

FROM tabl1;

 

/***% ads appearing in the feeds and % ads appearing in the moments***/

/*All ads as the base table for other tables to append on*/

CREATE TABLE basetable AS

SELECT ad.id AS id1,comment.user_id AS id2,feed.user_id AS id3,

       CASE WHEN comment.user_id IS NULL THEN 0

       ELSE 1

       END AS comment_user,

       CASE WHEN feed.user_id IS NULL THEN 0

       ELSE 1

       END AS feed_user

FROM ad

LEFT JOIN comment

ON ad.id=comment.ad_id

LEFT JOIN feed

ON ad.id=feed.ad_id;

 

/*if user_id not appearing in the appended tables, then coded as 0 (not exist)*/

SELECT SUM(comment_user)/COUNT(id1) AS percentages_comment,

       SUM(feed_user)/COUNT(id1) AS percentages_feed

FROM basetable;

 

/***how many different users give a like, one option of actions on June 20, 2020***/

CREATE TABLE basetable AS

SELECT DISTINCT user_id, created_at

       CASE WHEN action_field ='like' THEN 1

       ELSE 0

       END AS like_action

FROM events

WHERE created_at ='2020-06-20' ;

 

SELECT COUNT(user_id)

FROM basetable

WHERE like_action = 1;


/***likers' likers***/

/*My interpretation is to count the users that like back on the users who liked them*/

/*As long as we see paired user_id and liker_id appeared in two rows, we know a pair

like each other */

/*A B same as B A*/

CREATE TABLE basetable AS

SELECT t1.user_id, t1.liker_id,t1.liked

FROM table1 AS t1
INNER JOIN table1 AS t2
ON (t1.user_id=t2.liker_id AND t1.liker_id=t2.user_id AND t1.liked IS TRUE)
WHERE t2.liked IS TRUE;

 /*
 A B
 B A
 C D
 E F
 D C
 F E
 */

SELECT COUNT(*)/2 AS count_liked_pairs

FROM basetable;

 

/***Popular actions***/

CREATE TABLE basetable AS

SELECT user_id,created_at,

       CASE WHEN actions='like' THEN 1

       ELSE 0

       END AS like_act,

       CASE WHEN actions='post' THEN 1

       ELSE 0

       END AS post_act,

       CASE WHEN actions='comment' THEN 1

       ELSE 0

       END AS comment_act

FROM events;

 

SELECT SUM(like_act),

       SUM(post_act),

       SUM(comment_act)

FROM basetable

WHERE created_at BETWEEN '2020-11-21' AND '2020-12-25';

/*create two subtables and join them */

WITH table1 AS(
  SELECT id, salary FROM students
  INNER JOIN
  offer 
  ON students.id=offer.id),
    table2 AS(
  SELECT id, salary FROM friend
  INNER JOIN 
  offer 
  ON friend.id=offer.id)
SELECT table1.id,table1.salary,table2.id,table2.salary
FROM table1
LEFT JOIN
ON table1.id=table2.id
WHERE table2.salary gt table1.salary;

/*Pivoting two columns, name and occupations using CASW WHEN END from the second table with new column added in*/
SELECT
(CASE WHEN occupation='Doctor' THEN name ELSE Null END) AS Doctor,
(CASE WHEN occupation='Singer' THEN name ELSE Null END) AS Singer
FROM 
  (SELECT name, occupation,
  ROW_NUMBER() OVER (PARTITION BY occupation ORDER BY name) AS row_num
  FROM first_table
  
  ) AS second_table
GROUP BY row_num

/*subgquery examples*/
/*1. the table source is a subquery*/

SELECT *
FROM
(SELECT FROM) AS sub_table;

/*2. The conditions are caculated and need to use HAVING clause to reference it*/
SELECT *
FROM main__table
HAVING value=
(SELECT MAX(variable) FROM main_table WHERE) or (SELECT AVG(varaible2) FROM main_table WHERE);

/*3. one of the tables to be join is a subquery*/
SELECT a.id, b.id
FROM a
JOIN
(SELECT id, name, salary, location FROM tbl ) AS b

ON a.id=b.id;

