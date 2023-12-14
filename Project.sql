-- ----------------------Advanced SQL Mandatory project -----------------------------

   USE ig_clone;
   
-- 1)How many times does the average user post?

WITH photo_count AS (
	SELECT  u.id AS user_id,u.username, count(p.id) AS photocount
    FROM users u LEFT JOIN photos p
    ON u.id = p.user_id
    GROUP BY u.id)
SELECT AVG(photocount) AS average_user_post FROM photo_count;

--------------------------------------------------------------------------------------------
-- 2)Find the top 5 most used hashtags.

SELECT tag_id, tag_name, DenseRank
FROM (
    SELECT
        t.id AS tag_id, t.tag_name, COUNT(pt.photo_id) AS no_of_photos,
        DENSE_RANK() OVER (ORDER BY COUNT(pt.photo_id) DESC) AS DenseRank
    FROM tags t LEFT JOIN photo_tags pt ON t.id = pt.tag_id
    GROUP BY t.id
) AS photo_count
WHERE DenseRank <= 5;
-- -----------------------------------------------------------------------------------------
-- 3) Find users who have liked every single photo on the site.

SELECT 
	l.user_id, username, COUNT(l.photo_id) AS no_of_likes, 
    ROW_NUMBER() OVER (ORDER BY user_id) AS row_no 
FROM likes l
JOIN users u ON u.id = l.user_id
GROUP BY user_id, username
HAVING no_of_likes=(SELECT count(id) FROM photos)            -- # non-correlated subquery in where clause
ORDER BY user_id;
-- ---------------------------------------------------------------------------------------------
-- 4)Retrieve a list of users along with their usernames and the rank of their account creation,
-- ordered by the creation date in ascending order.

SELECT 
	*, RANK() OVER (ORDER BY created_at ASC) AS rank_account_creation   -- # window function 
FROM users;
-- -----------------------------------------------------------------------------------------------
-- 5)List the comments made on photos with their comment texts, photo URLs, and 
-- usernames of users who posted the comments. Include the comment count for each photo

WITH comment_info AS (
    SELECT
        u.username, p.id AS photo_id, p.image_url, c.comment_text, 
        COUNT(c.id) OVER (PARTITION BY p.id) AS comment_count
    FROM users u
        JOIN comments c ON u.id = c.user_id
        JOIN photos p ON c.photo_id = p.id)
SELECT username, photo_id, image_url, comment_text, comment_count
FROM comment_info;

-- --------------------------------------------------------------------------------------------------------
-- 6) For each tag, show the tag name and the number of photos associated with that tag. 
-- Rank the tags by the number of photos in descending order.
SELECT
	t.id AS tag_id, t.tag_name, COUNT(pt.photo_id) AS no_of_photos,
	DENSE_RANK() OVER (ORDER BY COUNT(pt.photo_id) DESC) AS DenseRank
    FROM tags t
    LEFT JOIN photo_tags pt ON t.id = pt.tag_id
    GROUP BY t.id;
    
-- ---------------------------------------------------------------------------------------
-- 7)List the usernames of users who have posted photos along with the count of photos they have posted. 
-- Rank them by the number of photos in descending order.

SELECT 
	u.id AS user_id, username, count(p.id) AS photo_count, 
    DENSE_RANK() OVER (ORDER BY count(p.id) DESC) AS photo_rank 
FROM users u 
JOIN photos p ON u.id = p.user_id GROUP BY u.id, u.username;                                                                        

-- ----------------------------------------------------------------------------------------------------
-- 8)Display the username of each user along with the creation date of their first posted photo 
-- and the creation date of their next posted photo.

WITH user_creation AS ( 
	SELECT u.id AS user_id, u.username, p.created_at, 
	LEAD(p.created_at) OVER (PARTITION BY p.user_id ORDER BY p.id) AS creation_lead 
	FROM users u
	LEFT JOIN photos p                                                                 -- -- ## - why left join     
	ON p.user_id=u.id)
SELECT user_id, username, 
MIN(created_at) AS firstpost_creation_date,
MIN(creation_lead) AS secondpost_creation_date                                    --  #aggregate and window function in same query-
FROM user_creation
GROUP BY user_id, username
ORDER BY user_id; 

-- -------------------------------------------------------------------------------------------
-- 9)For each comment, show the comment text, the username of the commenter, 
-- and the comment text of the previous comment made on the same photo
SELECT
	c.photo_id, u.username, c.comment_text, 
    LAG(comment_text) OVER (PARTITION BY c.photo_id ORDER BY c.id) AS previous_comment   -- ## - Window function-Lag
FROM comments c
JOIN users u ON c.user_id=u.id
ORDER BY photo_id;
-- --------------------------------------------------------------------------------------
-- 10)Show the username of each user along with the number of photos they have posted and 
-- the number of photos posted by the user before them and after them, based on the creation date.

WITH photo_count AS 
(SELECT u.*, count(p.id) AS photocount FROM users u 
LEFT JOIN photos p 
ON u.id = p.user_id
GROUP BY u.id, u.username, u.created_at)

SELECT id, username, photocount as user_photocount, 
LEAD(photocount) OVER (ORDER BY created_at ASC) AS next_user_photocount,
LAG(photocount) OVER (ORDER BY created_at ASC) AS previous_user_photocount
FROM photo_count 
ORDER BY id;


    
 
