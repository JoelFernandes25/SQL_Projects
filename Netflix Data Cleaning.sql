USE netflix;

SHOW tables;

-- Look at the data :
SELECT *
FROM netflix
LIMIT 5;

-- Data Types 

DESC netflix;

-- Handling wrong data types 

ALTER TABLE netflix MODIFY COLUMN date_added DATE;
DESC netflix;

-- Handling NULL values 

SELECT *
FROM netflix
WHERE director IS NULL OR director = '';

DELETE FROM netflix
WHERE director IS NULL OR director = '';

SELECT *
FROM netflix
WHERE country IS NULL OR country = '';

-- Imputing 

SELECT country, COUNT(country) AS Frequency
FROM netflix
GROUP BY country
ORDER BY Frequency DESC;

UPDATE netflix
SET country = 'United States'
WHERE country IS NULL OR country = '';

SELECT *
FROM netflix
WHERE cast IS NULL OR cast = '';

DELETE FROM netflix
WHERE cast IS NULL OR cast = '';

SELECT * 
FROM netflix;

-- Checking Duplicates 

SELECT title
FROM netflix
GROUP BY title
HAVING COUNT(*) > 1;

-- Outliers
SELECT *
FROM netflix
WHERE release_year < (SELECT AVG(release_year) - 3 * STDDEV(release_year) FROM netflix)
OR release_year > (SELECT AVG(release_year) + 3 * STDDEV(release_year) FROM netflix);

DELETE FROM netflix
WHERE release_year = 1975;

SELECT *
FROM netflix
WHERE duration < (SELECT AVG(duration) - 3 * STDDEV(duration) FROM netflix)
OR duration > (SELECT AVG(duration) + 3 * STDDEV(duration) FROM netflix);

-- Cleaned Data 

SELECT * 
FROM netflix;

-- Data Exploration

-- 1. Rank countries based on the number of shows on Netflix?

WITH show_counts AS (
  SELECT country, COUNT(*) AS num_shows
  FROM netflix
  WHERE type = 'TV Show'
  GROUP BY country
)
SELECT country, num_shows,
  DENSE_RANK() OVER (ORDER BY num_shows DESC) AS country_rank
FROM show_counts
ORDER BY country_rank;

-- 2. Longest Duration Shows 

SELECT title, duration
FROM netflix
ORDER BY duration DESC
LIMIT 10;

-- 3. Top Genres 

SELECT listed_in, COUNT(*) AS frequency
FROM netflix
GROUP BY listed_in
ORDER BY frequency DESC
LIMIT 10;

-- 4. Which shows have the highest and lowest ratings within each genre?


WITH ranked_shows 
AS 
(
SELECT *,
ROW_NUMBER() OVER (PARTITION BY listed_in ORDER BY rating DESC) AS highest_rank,
ROW_NUMBER() OVER (PARTITION BY listed_in ORDER BY rating) AS lowest_rank
FROM netflix
)
SELECT listed_in, title AS highest_rating_show, rating AS highest_rating
FROM ranked_shows
WHERE highest_rank = 1
UNION ALL
SELECT listed_in, title AS lowest_rating_show, rating AS lowest_rating
FROM ranked_shows
WHERE lowest_rank = 1;

-- 5. For each rating category, what are the top 3 titles with the longest duration?

WITH Ratings
AS
(
SELECT rating, title, duration, 
DENSE_RANK() OVER(PARTITION BY rating ORDER BY duration DESC) AS Titles_Ranked
FROM netflix
)
SELECT rating, title, duration, Titles_Ranked
FROM Ratings
WHERE Titles_Ranked <=3;

-- 6. Which actors/actresses have appeared in the most titles across different countries? Include the count of titles they have appeared in.

WITH Appeared_in 
AS
(
SELECT cast, title, country,duration,
DENSE_RANK() OVER(PARTITION BY cast ORDER BY COUNT(title)) AS Counted
FROM netflix
GROUP BY cast, country
ORDER BY duration DESC
)
SELECT cast, title, country, Counted
FROM Appeared_in;

-- They are unique records not more than 1 entries

-- 7. Which directors have the highest average duration for their titles? Include the average duration and the count of titles directed by them.

WITH Directors 
AS 
(
SELECT director, COUNT(title) AS Title, AVG(duration) AS AvgDuration,
DENSE_RANK() OVER(PARTITION BY director ORDER BY AVG(duration) DESC) AS DurationRank
FROM netflix
GROUP BY director
)
SELECT director, AvgDuration AS Duration, Title, DurationRank
FROM Directors;

-- 8. What is the highest duration among the movies/TV shows in each rating category, and how are they ranked based on their duration?


WITH Released
AS
(
SELECT rating, duration, release_year, COUNT(title) AS Titled, 
DENSE_RANK() OVER(PARTITION BY rating ORDER BY MAX(duration) DESC) AS Ranking
FROM netflix
GROUP BY release_year
)
SELECT rating, duration,release_year, Titled, Ranking
FROM Released;

-- 9. What is the distribution of titled counts among the different ratings and their corresponding release years?

SELECT rating, release_year, COUNT(title) AS Title_Count 
FROM netflix
GROUP BY release_year
ORDER BY Title_Count DESC;
