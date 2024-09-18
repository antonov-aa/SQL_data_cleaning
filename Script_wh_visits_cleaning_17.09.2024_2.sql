-- The dataset was uploaded as 'wh_visits_raw' table.
-- Column names were brought lower case and spaces were replaced with underscores before the upload
---- 1. DATA INSPECTION ----

--Check the number of rows in the raw dataset
SELECT
  count(*)
FROM
  wh_visits_raw
--Output: 970 504
;

--Check the number of columns in the raw dataset
SELECT 
  count(*)
FROM 
  information_schema.COLUMNS 
WHERE table_name = 'wh_visits_raw'
--Output: 28
;

--Explore the contence
SELECT
  *
FROM 
  wh_visits_raw
LIMIT
  10
;

--Explore data types
SELECT 
  column_name,
  data_type 
FROM
  information_schema.COLUMNS 
WHERE 
  table_name = 'wh_visits_raw'
--Date-time columns are not recognised as those. Types will need to be changed.
 ;
  
---- 2. REMOVE DUPLICATES ----
 
--Create a copy before cleaning to preserve the original data.
CREATE TABLE 
  wh_visits AS
TABLE 
  wh_visits_raw
;
 
--2.1. Check for duplicates:
WITH wh_visits_dup_cte AS
(
SELECT 
*,
CASE 
	WHEN row_number() OVER(
	  PARTITION BY namelast, 
	  namefirst, 
	  namemid, 
	  uin, 
	  bdgnbr, 
	  access_type,
	  toa, 
	  poa, 
	  tod, 
	  pod, 
	  appt_made_date, 
	  appt_start_date, 
	  appt_end_date, 
	  appt_cancel_date, 
	  total_people, 
	  last_updatedby, 
	  post, 
	  lastentrydate, 
	  terminal_suffix, 
	  visitee_namelast, 
	  visitee_namefirst, 
	  meeting_loc, 
	  meeting_room, 
	  caller_name_last, 
	  caller_name_first, 
	  caller_room, 
	  description,
	  release_date) = 1 THEN 0
	ELSE 1
END AS is_duplicated
FROM wh_visits
)
SELECT
  sum(is_duplicated)
FROM  
  wh_visits_dup_cte
--Output: 1 519
--There are 1 519 duplicated entries to the database. The nature of the data suggests that they should be deleted.
;

--2.2 Deleting duplicated rows

--1.2.1 Add an ID column to the table and populate it
ALTER TABLE 
  wh_visits 
ADD COLUMN 
  id serial PRIMARY KEY
;

--1.2.2 Delete duplicate rows using CTE
WITH wh_visits_checked AS 
(
SELECT
id,
row_number() OVER(
	  PARTITION BY namelast, 
	  namefirst, 
	  namemid, 
	  uin, 
	  bdgnbr, 
	  access_type,
	  toa, 
	  poa, 
	  tod, 
	  pod, 
	  appt_made_date, 
	  appt_start_date, 
	  appt_end_date, 
	  appt_cancel_date, 
	  total_people, 
	  last_updatedby, 
	  post, 
	  lastentrydate, 
	  terminal_suffix, 
	  visitee_namelast, 
	  visitee_namefirst, 
	  meeting_loc, 
	  meeting_room, 
	  caller_name_last, 
	  caller_name_first, 
	  caller_room, 
	  description,
	  release_date) AS duplicated
FROM wh_visits
)
DELETE FROM wh_visits
WHERE id IN (SELECT 
			   id
			 FROM 
			   wh_visits_checked
			 WHERE 
			   duplicated > 1
			)
;

--Check
SELECT 
  count(*)
FROM
  wh_visits
--Output: 968 985 (= 970 504 - 1 519) - correct
;

---- 3. UNIFY EMPTY ENTRIES ----

--3.1 Replace all the empty strings in varchar columns with NULL value
UPDATE 
  wh_visits 
SET 
  namelast = NULLIF(namelast, ''), 
  namefirst = NULLIF(namefirst, ''),
  namemid = NULLIF(namemid, ''), 
  uin = NULLIF(uin, ''), 
  access_type = NULLIF(access_type, ''),
  toa = NULLIF(toa, ''), 
  poa = NULLIF(poa, ''), 
  tod = NULLIF(tod, ''), 
  pod = NULLIF(pod, ''), 
  appt_made_date = NULLIF(appt_made_date, ''), 
  appt_start_date = NULLIF(appt_start_date, ''), 
  appt_end_date = NULLIF(appt_end_date, ''), 
  appt_cancel_date = NULLIF(appt_cancel_date, ''), 
  last_updatedby = NULLIF(last_updatedby, ''), 
  post = NULLIF(post, ''), 
  lastentrydate = NULLIF(lastentrydate, ''), 
  terminal_suffix = NULLIF(terminal_suffix, ''), 
  visitee_namelast = NULLIF(visitee_namelast, ''), 
  visitee_namefirst = NULLIF(visitee_namefirst, ''), 
  meeting_loc = NULLIF(meeting_loc, ''), 
  meeting_room = NULLIF(meeting_room, ''), 
  caller_name_last = NULLIF(caller_name_last, ''), 
  caller_name_first = NULLIF(caller_name_first, ''), 
  caller_room = NULLIF(caller_room, ''), 
  description = NULLIF(description, ''),
  release_date = NULLIF(release_date, '')
; 

--3.2 Replace all 0 with NULL in bage number column (bdgnmbr). NULL values are also peresent in the original dataset, but here 0 is as good as NULL.
UPDATE 
  wh_visits 
SET
  bdgnbr = NULL 
WHERE 
  bdgnbr = 0
;

--Logics behind entries of total_people column is not quite clear: 0 values do not make sense, I will explore this in detail.
--How many total_people have 0 values
SELECT count(*)
FROM wh_visits
WHERE total_people = 0
-- Output: 814
;

--Does total_people column represent a number of people under 1 uin?
----How many unique uins are there?
SELECT 
 count(DISTINCT uin)
FROM 
  wh_visits
--Output: 96 295
;

----Are values of total_people for 1 uin are the same?
SELECT 
 count(DISTINCT (uin, total_people))
FROM 
  wh_visits
--Output: 137 155, no there are uins with with multiple total_people values
;

--Are there any uins with the same number of total_people values as number of people under this uin?
WITH t1 AS (
  SELECT 
	*, 
	count(*) OVER(PARTITION BY uin) AS count_people
  FROM 
    wh_visits)
SELECT
  count(DISTINCT (uin, total_people, count_people))
FROM 
  t1
WHERE 
  count_people = total_people  
--Output: 46 658, almost half of all uins have total_people value the same as entries count.
--I will conclude, that total_people is the number of people under 1 uin, though altered somehow.  
;

--Sum different values of total_people under 1 uin value:
WITH t1 AS (
  SELECT 
	*, 
	count(*) OVER(PARTITION BY uin) AS count_people
  FROM 
    wh_visits), --add count_people column, where there are number of people with the same uin 
t2 AS (
  SELECT
    DISTINCT uin, total_people, count_people
  FROM 
    t1 
      ), -- leave UNIQUE entries of combination of uin and total_people and add count_people column 
t3 AS (
  SELECT
    *,
    sum(total_people) OVER(PARTITION BY uin) AS total_people_2,
    count(*) OVER(PARTITION BY uin) AS count_in_uin
  FROM
    t2
      ) -- sum total_people value UNDER 1 uin AND see how many DISTINCT GROUPS OF people ARE UNDER 1 uin
SELECT
  count(*)
FROM
  t3
WHERE
  total_people_2 = count_people
-- Output: 126 143 - now we see, that a number of uins were split into 2 groups of people in the column total_people. 
-- But there are still around 11 000 entries with count different from the total_value
;  

--What if we only consider non-cancelled visits?
WITH t1 AS (
  SELECT 
	*, 
	count(*) OVER(PARTITION BY uin) AS count_people
  FROM 
    wh_visits
  WHERE 
    appt_cancel_date IS NULL -- adding this clause to the query
    ),
t2 AS (
  SELECT
    DISTINCT uin, total_people, count_people
  FROM 
    t1 
      ),
t3 AS (
  SELECT
    *,
    sum(total_people) OVER(PARTITION BY uin) AS total_people_2,
    count(*) OVER(PARTITION BY uin) AS count_in_uin
  FROM
    t2
      )
SELECT
  count(*)
FROM
  t3
WHERE
  total_people_2 = count_people
-- Output: 126 241 - a bit better
;

--Look at total_people 0 values:
SELECT *
FROM wh_visits
WHERE total_people = 0
-- Almost all of them were cancelled.
;

--How many cancelled appointments?
SELECT count(*)
FROM wh_visits
WHERE appt_cancel_date IS NOT NULL
-- Output: 18 845
-- Here we can conclude, that in some instances, if an appoinment was cancelled total_people received 0 value, but in some instances - not.
-- Discovering the potential logics behind it, I will leave for the future research.
-- In the meantime I will leave total_people column as is.

-- Overall I can say, that total_people is the number of people under 1 uin, though 1 uin can be split into 2 groups in total people column.
-- Other factors also affected total_people column such as the cancellation of the appointment, I also assume that entry inconcistency is present.
  

---- 4. DATA TYPES CORRECTION ----

-- Date-time columns were read as strings. Convert corresponding columns to timestamp.

-- 4.1 Change type of the values in columns
UPDATE 
  wh_visits
SET 
  toa = to_timestamp(toa, 'MM/DD/YYYY HH24:MI') 
; -- returns error, saying wrong format of "PM", meaning some time values are in AM/PM format

--Will look at them:
SELECT 
  *
FROM 
  wh_visits
WHERE 
  toa LIKE '%PM%'
--all in all there are 9 entries, which look strange overall: toa contains just time without a date, 
--tod, pod and appt_made_date contain scalar values. 
;
  
--we will safely delete these faulty 9 entries
DELETE 
  FROM wh_visits 
WHERE 
  toa LIKE '%PM%'
;

--Try to change type of values again
UPDATE 
  wh_visits 
SET 
  toa = to_timestamp(toa, 'MM/DD/YYYY HH24:MI')
--success
;

--Change other date-time columns type one by one to spot faulty data inputs.
UPDATE 
  wh_visits 
SET 
  tod = to_timestamp(tod, 'MM/DD/YYYY HH24:MI') 
;

UPDATE 
  wh_visits
SET 
  appt_made_date = to_timestamp(appt_made_date, 'MM/DD/YYYY HH24:MI') 
;

UPDATE 
  wh_visits
SET 
  appt_start_date = to_timestamp(appt_start_date, 'MM/DD/YYYY HH24:MI') 
;

UPDATE 
  wh_visits 
SET 
  appt_end_date = to_timestamp(appt_end_date, 'MM/DD/YYYY HH24:MI') 
;

UPDATE 
  wh_visits 
SET 
  appt_cancel_date = to_timestamp(appt_cancel_date, 'MM/DD/YYYY HH24:MI') 
;

UPDATE 
  wh_visits 
SET 
  lastentrydate = to_timestamp(lastentrydate, 'MM/DD/YYYY HH24:MI') 
;

UPDATE 
  wh_visits 
SET 
  release_date = to_timestamp(release_date, 'MM/DD/YYYY HH24:MI') 
;
-- All other columns' data type changes were performed successfully

--4.2 Change columns type
ALTER 
  TABLE wh_visits
ALTER COLUMN toa TYPE timestamp USING toa::timestamp without time zone,
ALTER COLUMN tod TYPE timestamp USING tod::timestamp without time zone,
ALTER COLUMN appt_made_date TYPE timestamp USING appt_made_date::timestamp without time zone, --without time zone
ALTER COLUMN appt_start_date TYPE timestamp USING appt_start_date::timestamp without time zone,
ALTER COLUMN appt_end_date TYPE timestamp USING appt_end_date::timestamp without time zone,
ALTER COLUMN appt_cancel_date TYPE timestamp USING appt_cancel_date::timestamp without time zone,
ALTER COLUMN lastentrydate TYPE timestamp USING lastentrydate::timestamp without time zone,
ALTER COLUMN release_date TYPE timestamp USING release_date::timestamp without time zone  --without time zone
;

--Check column types
SELECT  
  column_name,
  data_type 
FROM 
  information_schema.COLUMNS 
WHERE   
  table_name = 'wh_visits'
--Correct
;

---- 5. DATA UNIFICATION ----


-- 5.1 Get rid of unnecessary spaces and different cases

-- Check for spaces in the end or in the beginning of a random varchar column
SELECT  
  namelast,
  char_length(namelast)
FROM 
  wh_visits
WHERE    
  namelast LIKE '% '
  OR namelast LIKE ' %'
-- there are unexpected spaces
;

-- Get rid of spaces in the beginning and in the end of all strings
-- Character entries were done in lowercase and capital letters, while their size has no semantic meaning. 
-- Make every letter capital in the same query
UPDATE 
  wh_visits 
SET 
  namefirst = UPPER(TRIM(namefirst)),
  namelast = UPPER(TRIM(namelast)),
  namemid = UPPER(TRIM(namemid)),
  uin = UPPER(TRIM(uin)),
  access_type = UPPER(TRIM(access_type)),
  poa = UPPER(TRIM(poa)),
  pod = UPPER(TRIM(pod)),
  last_updatedby = UPPER(TRIM(last_updatedby)),
  post = UPPER(TRIM(post)),
  terminal_suffix = UPPER(TRIM(terminal_suffix)),
  visitee_namelast = UPPER(TRIM(visitee_namelast)),
  visitee_namefirst = UPPER(TRIM(visitee_namefirst)),
  meeting_loc = UPPER(TRIM(meeting_loc)),
  meeting_room = UPPER(TRIM(meeting_room)),
  caller_name_last = UPPER(TRIM(caller_name_last)),
  caller_name_first = UPPER(TRIM(caller_name_first)),
  caller_room = UPPER(TRIM(caller_room)),
  description = UPPER(TRIM(description)) 
  
--5.2 Check for different entries of the same values (columns: access_type, poa, pod, last_updatedby, post, terminal_suffix, 
--meeting_loc, meeting_room, caller_name_last, caller_name_first, caller_room, visitee_namefirst, visitee_namelast)
--and unify them
  
SELECT
  DISTINCT access_type
FROM
  wh_visits
--no problem found, empty strings are present
;

SELECT
  DISTINCT poa 
FROM
  wh_visits
--'A401' seems to be the same as 'A0401'
;

UPDATE 
  wh_visits
SET 
  poa = 'A0401'
WHERE 
  poa = 'A401'
;

SELECT
  DISTINCT pod 
FROM
  wh_visits
--'A401' seems to be the same as 'A0401'
;

UPDATE 
  wh_visits
SET 
  pod = 'A0401'
WHERE 
  pod = 'A401'
;

SELECT
  DISTINCT last_updatedby 
FROM 
  wh_visits
--no problem found, empty strings are present
; 

SELECT 
  DISTINCT post 
FROM
  wh_visits
--only one unique value and empty strings are present, the column can be deleted
;

SELECT
  DISTINCT terminal_suffix 
FROM
  wh_visits
--no problem found, empty strings are present, but seems very similar to last_updatedby column. Check if there are any differences
;

SELECT
  count(*)
FROM
  wh_visits
WHERE 
  terminal_suffix <> last_updatedby
--there are differences, leave as it is
;

--Meeting_loc - building, meeting_room - room, these 2 columns should be considered together
SELECT
  DISTINCT meeting_loc, meeting_room
FROM
  wh_visits
-- Problems: meeting_loc identifier in meeting_room; arbitrary spaces in naming; 
-- the word "floor" is typed in many different ways; the word "room" is used sometimes
;
--Deleting meeting_loc identifiers, dots, #, spaces, words: 'ROOM', 'RM', unify the word 'Floor to 'FL' :
UPDATE 
  wh_visits 
SET 
  meeting_room = REPLACE(
                   REPLACE(
                     REPLACE(
                       REPLACE(
                         REPLACE(
                           REPLACE(
                             REPLACE(
                               REPLACE(
                                 REPLACE(
                                   REPLACE(
                                     REPLACE(
                                       REPLACE(
                                         REPLACE(
                                           REPLACE(
                                             REPLACE(meeting_room, 'NEOB',''),
                                           '#', ''),
                                         '.', ''),
                                       'ROOM',''),
                                     'RM', ''),
                                   ' ', ''),
                                 'FIRST', '1'),
                               'FLOOR', 'FL'),
                             'FLOO', 'FL'),
                           'FLO', 'FL'),
                         'FLR', 'FL'),
                       'THF', ' F'),
                     'STF', ' F'),
                   'NDF', ' F'),
                 'RDF', ' F')
--Other changes will introduce ambiguity or need to be performed manually for each pattern
;

--caller_name_last, caller_name_first should be considered together
SELECT 
  DISTINCT caller_name_first, caller_name_last
FROM
  wh_visits
ORDER BY
  caller_name_last
--Double surnames/names can be with and without space in between
;
--Delete spaces in names and surnames
UPDATE 
  wh_visits 
SET
  caller_name_last = REPLACE(caller_name_last, ' ', ''),
  caller_name_first = REPLACE(caller_name_first, ' ', '') 
;

SELECT
  DISTINCT caller_room 
FROM
  wh_visits
--empty strings only, the column can be deleted
; 

--visitee_namefirst, visitee_namelast should be considered together. 
SELECT
  DISTINCT visitee_namefirst, visitee_namelast 
FROM
  wh_visits
;
--There are a lot of people to visit in the white house, therefore here I introduce restriction for data cleaning: 
--we will only be interested in visits to the President of the US (POTUS) - Barack Obama, other records will stay as they are
--records of visits to the President will be marked as: visitee_namelast 'OBAMA', visitee_namefirst 'BARACK'
--records of 2 or more people as visitee including the President will stay as they are.
;

--Find all the records of visits to the President and unify them
UPDATE 
  wh_visits
SET 
  visitee_namefirst = 'BARACK',
  visitee_namelast = 'OBAMA'
WHERE 
  (visitee_namelast IN ('BARACK', 'OBAMA', 'PRESIDENT', 'POTUS')
  OR visitee_namefirst IN ('BARACK', 'OBAMA', 'PRESIDENT', 'POTUS'))
  AND visitee_namefirst NOT LIKE '%/%' --to exclude entries with other people 
  AND visitee_namefirst NOT IN ('VICE', 'MALIA')
  AND visitee_namelast <> 'VP'
;

UPDATE 
  wh_visits
SET 
  visitee_namefirst = 'BARACK',
  visitee_namelast = 'OBAMA'
WHERE 
  visitee_namefirst IN ('POTUS', 'PRESIDENT') 
  AND visitee_namelast ISNULL
;

UPDATE 
  wh_visits
SET 
  visitee_namefirst = 'BARACK',
  visitee_namelast = 'OBAMA'
WHERE 
  visitee_namelast = 'POTUS'
  AND visitee_namefirst ISNULL
;

--Look at the entries
SELECT  
  visitee_namefirst, 
  visitee_namelast,
  count(*) AS num
FROM
  wh_visits
GROUP BY
  visitee_namefirst, 
  visitee_namelast
ORDER BY num DESC
LIMIT 200


---- 6. DELETE COLUMNS ----

--I have previously identified 2 columns to be deleted
 
--Delete columns post and caller_room
ALTER 
  TABLE wh_visits
DROP COLUMN post,
DROP COLUMN caller_room
; 

---- 7. FINAL TOUCH ----

--Check for duplicates once more
WITH wh_visits_dup_cte AS
(
SELECT 
*,
CASE 
	WHEN row_number() OVER(
	  PARTITION BY namelast, 
	  namefirst, 
	  namemid, 
	  uin, 
	  bdgnbr, 
	  access_type,
	  toa, 
	  poa, 
	  tod, 
	  pod, 
	  appt_made_date, 
	  appt_start_date, 
	  appt_end_date, 
	  appt_cancel_date, 
	  total_people, 
	  last_updatedby,  
	  lastentrydate, 
	  terminal_suffix, 
	  visitee_namelast, 
	  visitee_namefirst, 
	  meeting_loc, 
	  meeting_room, 
	  caller_name_last, 
	  caller_name_first, 
	  description,
	  release_date) = 1 THEN 0
	ELSE 1
END AS is_duplicated
FROM wh_visits
)
SELECT
  sum(is_duplicated)
FROM  
  wh_visits_dup_cte
-- Output: 22
;

--Delete duplicate rows
WITH wh_visits_checked AS (
SELECT
  id,
  row_number() OVER(
	  PARTITION BY namelast, 
	  namefirst, 
	  namemid, 
	  uin, 
	  bdgnbr, 
	  access_type,
	  toa, 
	  poa, 
	  tod, 
	  pod, 
	  appt_made_date, 
	  appt_start_date, 
	  appt_end_date, 
	  appt_cancel_date, 
	  total_people, 
	  last_updatedby, 
	  lastentrydate, 
	  terminal_suffix, 
	  visitee_namelast, 
	  visitee_namefirst, 
	  meeting_loc, 
	  meeting_room, 
	  caller_name_last, 
	  caller_name_first, 
	  description,
	  release_date) AS duplicated
FROM wh_visits
)
DELETE FROM wh_visits
WHERE 
  id IN (SELECT 
		   id
	     FROM 
		   wh_visits_checked
		 WHERE 
		   duplicated > 1
	    )
;

--Delete id column
ALTER 
  TABLE wh_visits
DROP COLUMN id
;




---- SEE RESULTS ----

SELECT 
  count(*)
FROM
  wh_visits
-- Total entries: 970 504 -> 968 954
;

SELECT 
  count(*)
FROM 
  information_schema.COLUMNS 
WHERE table_name = 'wh_visits'
-- Total columns: 28 -> 26
;

SELECT
  count(DISTINCT (caller_name_last, caller_name_first))
FROM
  wh_visits
-- Unique caller names: 1230 -> 1224
;

SELECT
  count(DISTINCT (meeting_room, meeting_loc))
FROM
  wh_visits
-- Unique locations: 2 279 -> 2 046
;

SELECT
  count(DISTINCT (visitee_namefirst , visitee_namelast))
FROM
  wh_visits
-- Unique visitees: 6 505 -> 5 885
;

