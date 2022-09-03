/* 
 * Club Member Info
 * An SQL exercise for practicing data cleaning by Jaime M. Shaker jaime.m.shaker@gmail.com
 *   

For this project, you play a role as a Data Analyst the must clean and restructure a dirty dataset.

A survey was done of current club members and we would like to restructure the data to a more organized and usable form.

In this project, we will 

1. Check for duplicate entries and remove them.
2. Remove extra spaces and/or other invalid characters.
3. Separate or combine values as needed.
4. Ensure that certain values (age, dates...) are within certain range.
5. Check for outliers.
6. Correct incorrect spelling or inputted data.
7. Adding new and relevant rows or columns to the new dataset.
8. Check for null or empty values.

Lets take a look at the first few rows to examine the data in its original form.

*/

SELECT 
	*
FROM club_member_info
LIMIT 10;

-- Results:

full_name            |age|maritial_status|email                   |phone       |full_address                                |job_title                   |membership_date|
---------------------+---+---------------+------------------------+------------+--------------------------------------------+----------------------------+---------------+
addie lush           | 40|married        |alush0@shutterfly.com   |254-389-8708|3226 Eastlawn Pass,Temple,Texas             |Assistant Professor         |     2013-07-31|
ROCK CRADICK         | 46|married        |rcradick1@newsvine.com  |910-566-2007|4 Harbort Avenue,Fayetteville,North Carolina|Programmer III              |     2018-05-27|
???Sydel Sharvell    | 46|divorced       |ssharvell2@amazon.co.jp |702-187-8715|4 School Place,Las Vegas,Nevada             |Budget/Accounting Analyst I |     2017-10-06|
Constantin de la cruz| 35|               |co3@bloglines.com       |402-688-7162|6 Monument Crossing,Omaha,Nebraska          |Desktop Support Technician  |     2015-10-20|
  Gaylor Redhole     | 38|married        |gredhole4@japanpost.jp  |917-394-6001|88 Cherokee Pass,New York City,New York     |Legal Assistant             |     2019-05-29|
Wanda del mar        | 44|single         |wkunzel5@slideshare.net |937-467-6942|10864 Buhler Plaza,Hamilton,Ohio            |Human Resources Assistant IV|     2015-03-24|
Jo-ann Kenealy       | 41|married        |jkenealy6@bloomberg.com |513-726-9885|733 Hagan Parkway,Cincinnati,Ohio           |Accountant IV               |     2013-04-17|
Joete Cudiff         | 51|separated      |jcudiff7@ycombinator.com|616-617-0965|975 Dwight Plaza,Grand Rapids,Michigan      |Research Nurse              |     2014-11-16|
mendie alexandrescu  | 46|single         |malexandrescu8@state.gov|504-918-4753|34 Delladonna Terrace,New Orleans,Louisiana |Systems Administrator III   |     1921-03-12|
fey kloss            | 52|married        |fkloss9@godaddy.com     |808-177-0318|8976 Jackson Park,Honolulu,Hawaii           |Chemical Engineer           |     2014-11-05|

/*

Lets create a temp table where we can manipulate and restructure the data without altering the original.     
 
 */

DROP TABLE IF EXISTS cleaned_club_member_info;
CREATE TABLE cleaned_club_member_info AS (
	SELECT 
		-- Some of the names have extra spaces and special characters.  Trim access whitespace, remove special characters 
		-- and convert to lowercase.
		-- In this particular dataset, special characters only occur in the first name that can be removed using a simple regex.
		regexp_replace(split_part(trim(lower(full_name)), ' ', 1), '\W+', '', 'g') AS first_name,
		-- Some last names have multiple words ('de palma' or 'de la cruz'). Convert the string to an array to calculate its length and use a 
		-- case statement to find entries with those particular types of surnames.
		CASE
			WHEN array_length(string_to_array(trim(lower(full_name)), ' '), 1) = 3 THEN concat(split_part(trim(lower(full_name)), ' ', 2) || ' ' || split_part(trim(lower(full_name)), ' ', 3))
			WHEN array_length(string_to_array(trim(lower(full_name)), ' '), 1) = 4 THEN concat(split_part(trim(lower(full_name)), ' ', 2) || ' ' || split_part(trim(lower(full_name)), ' ', 3) || ' ' || split_part(trim(lower(full_name)), ' ', 4))
			ELSE split_part(trim(lower(full_name)), ' ', 2)
		END AS last_name,
		-- During data entry, some ages have an additional digit at the end.  Remove the last digit when a 3 digit age value occurs.
		CASE
			-- Check if value is empty.  If empty '' then change value to NULL
			WHEN length(age::text) = 0 THEN NULL
			-- First cast the integer to a string and test the character length.
			-- If condition is true, cast the integer to text, extract first 2 digits and cast back to numeric type.
			WHEN length(age::text) = 3 THEN substr(age::text, 1, 2)::numeric
			ELSE age
		END age,
		-- Trim whitespace from maritial_status column and if empty, ensure its of null type
		CASE
			WHEN trim(maritial_status) = '' THEN NULL
			ELSE trim(maritial_status)
		END AS maritial_status,
		-- Email addresses are necessary and this dataset contains valid email addresses.  Since email addresses are case insensitive,
		-- convert to lowercase and trim off any whitespace.
		trim(lower(email)) AS member_email,
		-- Trim whitespace from phone column and if empty or incomplete, ensure its of null type
		CASE
			WHEN trim(phone) = '' THEN NULL
			WHEN length(trim(phone)) < 12 THEN NULL
			ELSE trim(phone)
		END AS phone,
		-- Members must have a full address for billing purposes.  However many members can live in the same household so address cannot be unique.
		-- Convert to lowercase, trim off any whitespace and split the full address to individual street address, city and state.
		split_part(trim(lower(full_address)), ',', 1) AS street_address,
		split_part(trim(lower(full_address)), ',', 2) AS city,
		split_part(trim(lower(full_address)), ',', 3) AS state,
		-- Some job titles define a level in roman numerals (I, II, III, IV).  Convert levels to numbers.
		-- Trim whitespace from job title, rename to occupation and if empty convert to null type.
		CASE
			WHEN trim(lower(job_title)) = '' THEN NULL
			ELSE 
				CASE
					WHEN array_length(string_to_array(trim(job_title), ' '), 1) > 1 AND lower(split_part(job_title, ' ', array_length(string_to_array(trim(job_title), ' '), 1))) = 'i'
						THEN replace(lower(job_title), ' i', ' 1')
					WHEN array_length(string_to_array(trim(job_title), ' '), 1) > 1 AND lower(split_part(job_title, ' ', array_length(string_to_array(trim(job_title), ' '), 1))) = 'ii'
						THEN replace(lower(job_title), ' ii', ' 2')
					WHEN array_length(string_to_array(trim(job_title), ' '), 1) > 1 AND lower(split_part(job_title, ' ', array_length(string_to_array(trim(job_title), ' '), 1))) = 'iii'
						THEN replace(lower(job_title), ' iii', ' 3')
					WHEN array_length(string_to_array(trim(job_title), ' '), 1) > 1 AND lower(split_part(job_title, ' ', array_length(string_to_array(trim(job_title), ' '), 1))) = 'iv'
						THEN replace(lower(job_title), ' iv', ' 4')
					ELSE trim(lower(job_title))
				END 
		END AS occupation,
		-- A few members show membership_date year in the 1900's.  Change the year into the 2000's.
		CASE 
			WHEN EXTRACT('year' FROM membership_date) < 2000 
				THEN concat(replace(EXTRACT('year' FROM membership_date)::text, '19', '20') || '-' || EXTRACT('month' FROM membership_date) || '-' || EXTRACT('day' FROM membership_date))::date
			ELSE membership_date
		END AS membership_date
	FROM club_member_info
);

-- Let's take a look at our cleaned table data.

SELECT 
	* 
FROM cleaned_club_member_info 
LIMIT 10;

-- Results:

first_name|last_name   |age|maritial_status|member_email            |phone       |street_address       |city         |state         |occupation                 |membership_date|
----------+------------+---+---------------+------------------------+------------+---------------------+-------------+--------------+---------------------------+---------------+
addie     |lush        | 40|married        |alush0@shutterfly.com   |254-389-8708|3226 eastlawn pass   |temple       |texas         |assistant professor        |     2013-07-31|
rock      |cradick     | 46|married        |rcradick1@newsvine.com  |910-566-2007|4 harbort avenue     |fayetteville |north carolina|programmer 3               |     2018-05-27|
sydel     |sharvell    | 46|divorced       |ssharvell2@amazon.co.jp |702-187-8715|4 school place       |las vegas    |nevada        |budget/accounting analyst 1|     2017-10-06|
constantin|de la cruz  | 35|               |co3@bloglines.com       |402-688-7162|6 monument crossing  |omaha        |nebraska      |desktop support technician |     2015-10-20|
gaylor    |redhole     | 38|married        |gredhole4@japanpost.jp  |917-394-6001|88 cherokee pass     |new york city|new york      |legal assistant            |     2019-05-29|
wanda     |del mar     | 44|single         |wkunzel5@slideshare.net |937-467-6942|10864 buhler plaza   |hamilton     |ohio          |human resources assistant 4|     2015-03-24|
joann     |kenealy     | 41|married        |jkenealy6@bloomberg.com |513-726-9885|733 hagan parkway    |cincinnati   |ohio          |accountant 4               |     2013-04-17|
joete     |cudiff      | 51|separated      |jcudiff7@ycombinator.com|616-617-0965|975 dwight plaza     |grand rapids |michigan      |research nurse             |     2014-11-16|
mendie    |alexandrescu| 46|single         |malexandrescu8@state.gov|504-918-4753|34 delladonna terrace|new orleans  |louisiana     |systems administrator 3    |     2021-03-12|
fey       |kloss       | 52|married        |fkloss9@godaddy.com     |808-177-0318|8976 jackson park    |honolulu     |hawaii        |chemical engineer          |     2014-11-05|







