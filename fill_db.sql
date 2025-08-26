INSERT INTO "timezones" ("name") 
VALUES
	('Europe/Lisbon'),
	('Europe/Berlin'),
    ('Brazil/West'),
    ('America/Los_Angeles')
ON CONFLICT ("name") DO NOTHING;

SELECT *FROM "timezones";

/*------ ADDING USERS ---------*/
CALL add_user (
	'bob'::VARCHAR(30),
	'bob@outlook.com'::VARCHAR(50),
	'1234'::VARCHAR(50),
	'bob_image.png'::TEXT,
	'bob_banner.jpeg'::TEXT, 
	'male'::VARCHAR(20),
	null::DATE,
	1::INTEGER);
CALL add_user ('jeff', 'jeff@virgilio.it', '1234', 'jeff_image.png', null, null, '1978-01-01', 2);
CALL add_user ('matt', 'matt@proton.me', '1234', null, 'matt_banner.jep', 'male', '1978-01-01', 3);
CALL add_user ('john', 'john@vivaldi.net', '1234', 'john_image.png', null, 'others', '1978-01-01', 5);
CALL add_user ('james', 'james@hotmail.com', '1234', null, null, null, null, null);
CALL add_user ('brian', 'brian@sapo.pt', '1234', 'brian_image.png', null, 'male', null, 2);
CALL add_user ('Anna', 'Anna@protonmail.com', '1234', 'Anna_image.png', null, null, '1978-01-01', 1);
CALL add_user ('Katherine', 'Kat@gmail.com', '1234', null, 'Kat_banner.jep', 'female', '1999-01-01', null);
CALL add_user ('user_to_ban_1', 'user_to_ban_1@gmail.com', '1234', null, null, null, null, null);
CALL add_user ('user_to_ban_2', 'user_to_ban_2@gmail.com', '1234', null, null, null, null, null);

/* MAKE USER ADMIN*/
UPDATE "users" SET "admin" = TRUE WHERE "username" = 'brian';

SELECT * FROM USERS WHERE "username" = 'Katherine';


/*---------------- DELETE USER (and their images)-------------------*/
DO $$
DECLARE
    "uid" INTEGER;
BEGIN
    SELECT "id" INTO uid FROM "users" WHERE "username" = 'Katherine';
	DELETE FROM "images"
	WHERE "id" IN (
		SELECT "image_id" FROM "user_images" WHERE "user_id" = "uid"
		); 
    CALL delete_user(uid);
	
END;
$$;

/*images without connection to user*/
SELECT * FROM "user_images" WHERE "user_id" not in (SELECT "id" FROM "users");
/*images without connection*/
SELECT * FROM "images" WHERE "id" not in (SELECT "image_id" FROM "user_images");
/*all images from Katherine were deleted*/


/*------ ADD AND SETTING PROFILE PIC ---------*/
DO $$
DECLARE
    "uid" INTEGER;
	"new_image_id" INTEGER;
BEGIN
    SELECT "id" INTO uid FROM "users" WHERE "username" = 'matt';
	
    CALL add_profile_pic("uid", 'matt_new_profile_pic.png');
	
	SELECT MAX("image_id") 	INTO "new_image_id" FROM "user_images" 
	WHERE "user_id" = "uid" 
	GROUP BY "user_id";
	
	CALL change_profile_pic ("new_image_id",  "uid");
END;
$$;

/*------ ADD AND SETTING BANNER ---------*/
DO $$
DECLARE
    "uid" INTEGER;
	"new_image_id" INTEGER;
BEGIN
    SELECT "id" INTO uid FROM "users" WHERE "username" = 'jeff';
	
    CALL add_banner_pic (uid, 'jeff_new_banner.png');
	
	SELECT MAX("image_id") 	INTO "new_image_id" FROM "user_images" 
	WHERE "user_id" = "uid" 
	GROUP BY "user_id";
	
	CALL change_banner_pic ("new_image_id", "uid");
END;
$$;


SELECT users.id, users.username, profile_pic.image AS profile_pic, banner.image AS banner FROM users 
LEFT JOIN images AS profile_pic
ON profile_pic.id = users.profile_pic_id
LEFT JOIN images AS banner
ON banner.id = users.banner_id
WHERE username IN ('matt', 'jeff');



/*------ DELETE IMAGE ---------*/
DO $$
DECLARE
    "uid" INTEGER;
	"image_del_id" INTEGER;
BEGIN
    SELECT "id" INTO "uid" FROM "users" WHERE "username" = 'jeff';
	SELECT "banner_id" INTO "image_del_id" FROM "users" WHERE "username" = 'jeff';
	
	CALL delete_image("image_del_id", "uid");
END;
$$;



SELECT "profile" FROM "users" WHERE "username" = 'jeff';


/*------ update user profile ---------*/
DO $$
DECLARE
    "uid" INTEGER;
BEGIN
    SELECT "id" INTO "uid" FROM "users" WHERE "username" = 'jeff';
	
	CALL change_profile('My name is Jeff', "uid");
END;
$$;


SELECT id, username, profile FROM USERS;


/*------ Request, Accepet, Refuse and mute friends ---------*/
DO $$
DECLARE
    "u1id" INTEGER;
	"u2id" INTEGER;
	"u3id" INTEGER;
	"u4id" INTEGER;
BEGIN
    SELECT "id" INTO "u1id" FROM "users" WHERE "username" = 'jeff';
	SELECT "id" INTO "u2id" FROM "users" WHERE "username" = 'matt';
	SELECT "id" INTO "u3id" FROM "users" WHERE "username" = 'john';
	SELECT "id" INTO "u4id" FROM "users" WHERE "username" = 'james';
	
	CALL friend_request("u1id","u2id"); /*jeff requested matt*/
	CALL friend_request("u1id","u3id"); /*jeff requested john*/
	CALL friend_request("u1id","u4id"); /*jeff requested james*/
	CALL friend_request("u2id","u3id"); /*matt requested john*/
	CALL friend_request("u2id","u4id"); /*matt requested james*/
	CALL friend_request("u3id","u4id"); /*john requested james*/

	CALL  accept_friend_request("u2id", "u1id");
	CALL  accept_friend_request("u3id", "u1id");
	CALL  refuse_friend_request("u4id", "u1id"); /*this removes the friend request*/
	CALL  accept_friend_request("u3id", "u2id");
	CALL  refuse_friend_request("u4id", "u2id");
	/*john invited to james was ignored*/

	CALL  update_friend_mute("u2id", "u1id", true);

END;
$$;


SELECT "user1"."username", "user2"."username", "friends"."status" FROM "friends"
INNER JOIN "users" AS "user1"
ON "user1"."id" = "friends"."user_id"
INNER JOIN "users" AS "user2"
ON "user2"."id" = "friends"."friend_id"
ORDER BY "user1"."username";



/*------ GET USER FRIENDS -------*/

SELECT * FROM get_friends(
	(SELECT "id" FROM "users" WHERE "username" = 'jeff'),
	0);



/*------------ BLOCK UNBLOCK USERS -----------*/
DO $$
DECLARE
    "u1id" INTEGER;
	"u2id" INTEGER;
	"u3id" INTEGER;
BEGIN
    SELECT "id" INTO "u1id" FROM "users" WHERE "username" = 'jeff';
	SELECT "id" INTO "u2id" FROM "users" WHERE "username" = 'matt';
	SELECT "id" INTO "u3id" FROM "users" WHERE "username" = 'john';
	
	CALL block_user("u1id","u2id"); /*jefg blocked matt*/
	CALL block_user("u1id","u3id"); /*jeff blocks john*/
	CALL unblock_user("u1id","u3id"); /*jeff unblock john*/

END;
$$;


SELECT "blocker"."username", "blocked"."username" FROM "blocks"
INNER JOIN "users" AS "blocker"
ON "blocker"."id" = "blocks"."blocker_id"
INNER JOIN "users" AS "blocked"
ON "blocked"."id" = "blocks"."blocked_id";


/*------------ Post | Edit | Delete POST -----------*/
DO $$
DECLARE
    "u1id" INTEGER;
	"u2id" INTEGER;
	"u3id" INTEGER;
	"post_id" INTEGER;
	"user_to_ban_1_id" INTEGER;
BEGIN
    SELECT "id" INTO "u1id" FROM "users" WHERE "username" = 'jeff';
	SELECT "id" INTO "u2id" FROM "users" WHERE "username" = 'matt';
	SELECT "id" INTO "u3id" FROM "users" WHERE "username" = 'john';
	SELECT "id" INTO "user_to_ban_1_id" FROM "users" WHERE "username" = 'user_to_ban_1';
	
	CALL post_post("u1id", 'This is petty cool');   /*jeff post*/
	CALL post_post("u1id", 'This is petty cool');    /*jeff post*/
	CALL post_post("u1id", 'It was a terrible idea to make everything a procedure');    /*jeff post*/
	CALL post_post("u1id", 'Do you think anyone will see this');   /*jeff post*/
	CALL post_post("u1id", 'I love spamming');     /*jeff post*/
	CALL post_post("u2id", 'I am sayning sth bad but not worth a report');   /*matt post*/
	CALL post_post("user_to_ban_1_id", 'I am super racist');

	CALL post_post("u2id", 'I wish i was rich');    /*matt post*/
	CALL post_post("u2id", 'I am saying sth age restricted');    /*matt post*/
	CALL post_post("u3id", 'What do you guys think of your job');    /*matt john*/

	SELECT min("id") into "post_id" FROM "posts" 
	WHERE "user_id" = "u1id"
	GROUP BY "user_id";
	
	CALL delete_post("post_id", "u1id");

	SELECT min("id") into "post_id" FROM "posts" 
	WHERE "user_id" = "u1id"
	GROUP BY "user_id";
	
	CALL edit_post("post_id", "u1id", 'this post was edited');
	
END;
$$;


SELECT "users"."username", "posts"."content", "edited_at" FROM "posts"
INNER JOIN "users"
ON "users"."id" = "posts"."user_id"
ORDER BY "users"."username";

/*------ POST notification------*/
SELECT 
	"notifications"."user_id" AS "notification_user_id",
	"posts"."user_id" AS "post_user_id",
	"friends"."user_id" AS "friends_user_id",
	"friends"."muted"
FROM "posts"
LEFT JOIN "friends"
ON "friends"."friend_id" = "posts"."user_id"
LEFT JOIN "notifications"
ON "posts"."id" = "notifications"."post_id" AND "notifications"."user_id" = "friends"."user_id"
WHERE "friends"."user_id" is not null; 
/*the where part just remove post from users that have no friends*/


/*------------ Post | Edit | Delete COMMENTS -----------*/
DO $$
DECLARE
    "u1id" INTEGER;
	"u2id" INTEGER;
	"u3id" INTEGER;
	"post1_id" INTEGER;
	"post2_id" INTEGER;
	"comment1_id" INTEGER;
	"comment2_id" INTEGER;
	"comment_to_delete_id" INTEGER;
	"user_to_ban_2_id" INTEGER;
BEGIN
    SELECT "id" INTO "u1id" FROM "users" WHERE "username" = 'jeff';
	SELECT "id" INTO "u2id" FROM "users" WHERE "username" = 'matt';
	SELECT "id" INTO "u3id" FROM "users" WHERE "username" = 'john';
	SELECT "id" INTO "user_to_ban_2_id" FROM "users" WHERE "username" = 'user_to_ban_2';
	SELECT MIN("id") INTO "post1_id" FROM "posts" WHERE "user_id" = "u1id" GROUP BY "user_id";
	SELECT MIN("id") INTO "post2_id" FROM "posts" WHERE "user_id" = "u2id" GROUP BY "user_id";

	/*commenting posts*/
	CALL post_comment("u1id", "post1_id", 'this is a comment to a post');  /*jeff comment*/
	CALL post_comment("u2id", "post2_id", 'I love commenting on posts');   /*matt comment*/
	CALL post_comment("u2id", "post1_id", 'What a great post');            /*matt comment*/
	CALL post_comment("u3id", "post2_id", 'What time is it');                /*john comment*/
	CALL post_comment("u1id", "post1_id", 'my name is jeff');              /*jeff comment*/
	CALL post_comment("u1id", "post2_id", 'I love spamming');              /*jeff comment*/
	CALL post_comment("u2id", "post1_id", 'I am sayning sth bad but not worth a report');     /*matt comment*/
	CALL post_comment("user_to_ban_2_id", "post2_id", 'I am super racist');

	SELECT MIN("id") INTO "comment1_id" FROM "comments" WHERE "post_id" = "post1_id";
	SELECT MIN("id") INTO "comment2_id" FROM "comments" WHERE "post_id" = "post2_id";

	/*commenting comments*/
	CALL post_comment("u1id", "post1_id", 'this is a comment to a comment', "comment1_id");
	CALL post_comment("u2id", "post2_id", 'I love commenting on comments', "comment2_id");
	CALL post_comment("u2id", "post1_id", 'What a great comment', "comment1_id");
	CALL post_comment("u3id", "post2_id", 'I will delete this comment later', "comment2_id");
	CALL post_comment("u1id", "post1_id", 'my name is jeff', "comment2_id");                    
	/*the last one should fail because the post1_id and the original post of comment2_id is not the same*/

	SELECT "id" into "comment_to_delete_id" FROM "comments" 
	WHERE "content" = 'I will delete this comment later';

	/*matt comments the comment that will be delete and his comment will be deleted as well */
	CALL post_comment("u2id", "post2_id", 'this comment should be deleted when the parent is deleted', "comment_to_delete_id");
	
	CALL delete_comment("comment_to_delete_id", "u3id");       /*delete john comments*/


	SELECT min("id") into "comment1_id" FROM "comments" 
	WHERE "user_id" = "u1id"
	GROUP BY "user_id";
	
	CALL edit_comment("comment1_id", "u1id", 'this comment was edited');     /*edit jeff  commetns*/
	
END;
$$;


SELECT "users"."username", "comments"."content", "comments"."post_id", "comments"."comment_id", "edited_at" FROM "comments"
INNER JOIN "users"
ON "users"."id" = "comments"."user_id"
ORDER BY "users"."username";




/* --------------- ADDING REACTIONS -----------------*/
INSERT INTO "reactions"("name", "icon")
VALUES
	('like','like_icon.png'),
	('love', 'love_icon.png'),
	('angry', 'angry_icon.png'),
	('sleepy', 'sleepy_icon.png');


SELECT * FROM "reactions";


/*----------  ADDING REACTIONS TO COMMENTS AND POSTS ----------*/
DO $$
DECLARE
    "u1id" INTEGER;
	"u2id" INTEGER;
	"u3id" INTEGER;
	"reaction1_id" INTEGER;
	"reaction2_id" INTEGER;
	"reaction3_id" INTEGER;
	"post1_id" INTEGER;
	"post2_id" INTEGER;
	"comment1_id" INTEGER;
	"comment2_id" INTEGER;
BEGIN
    SELECT "id" INTO "u1id" FROM "users" WHERE "username" = 'jeff';
	SELECT "id" INTO "u2id" FROM "users" WHERE "username" = 'matt';
	SELECT "id" INTO "u3id" FROM "users" WHERE "username" = 'john';
	SELECT "id" INTO "reaction1_id" FROM "reactions" WHERE "name" = 'like';
	SELECT "id" INTO "reaction2_id" FROM "reactions" WHERE "name" = 'angry';
	SELECT "id" INTO "reaction3_id" FROM "reactions" WHERE "name" = 'sleepy';
	SELECT "id" INTO "post1_id" FROM "posts" ORDER BY RANDOM() LIMIT 1;
	SELECT "id" INTO "post2_id" FROM "posts" ORDER BY RANDOM() LIMIT 1;
	SELECT "id" INTO "comment1_id" FROM "comments" ORDER BY RANDOM() LIMIT 1;
	SELECT "id" INTO "comment2_id" FROM "comments" ORDER BY RANDOM() LIMIT 1;

	CALL add_reaction_to_post("post1_id", "u1id", "reaction1_id");
	CALL add_reaction_to_post("post2_id", "u2id", "reaction2_id");
	CALL add_reaction_to_post("post1_id", "u3id", "reaction2_id");
	CALL add_reaction_to_post("post2_id", "u1id", "reaction3_id");
	CALL remove_reaction_to_post("post1_id", "u1id", "reaction1_id");


	CALL add_reaction_to_comment("comment1_id", "u1id", "reaction1_id");
	CALL add_reaction_to_comment("comment2_id", "u2id", "reaction2_id");
	CALL add_reaction_to_comment("comment1_id", "u3id", "reaction2_id");
	CALL add_reaction_to_comment("comment2_id", "u1id", "reaction3_id");
	CALL remove_reaction_to_comment("comment1_id", "u1id", "reaction1_id");
	
END;
$$;	

/*basically it only shows 3 reactions instead of the 4 added since 1 was then deleted*/
SELECT * FROM "post_reactions";
SELECT * FROM "comment_reactions";




/*--------- get user feed ---------*/
SELECT * FROM get_feed(
    (SELECT id FROM "users" WHERE "username" = 'matt'),
    0 /*this is the page in case there is over 20 posts*/
);
/*--------- get post comments ---------*/
SELECT * FROM get_post_comments(
	(SELECT "posts"."id" FROM "posts"
			INNER JOIN "comments"
			ON "comments"."post_id" = "posts"."id"
		WHERE "comments"."comment_id" IS null /*means the comment was made directly to the post and not a comment*/
		GROUP BY "posts"."id"
		ORDER BY COUNT(*) DESC /*get the comments to the post with the most comments*/
		LIMIT 1),
	0	/*this is the page in case there is over 20 comments*/
);
/*--------- get comments comments ---------*/
SELECT * FROM get_comment_comments(
	(SELECT "c2"."id" FROM "comments" AS "c1"
			INNER JOIN "comments" AS "c2"
			ON "c2"."id" = "c1"."comment_id"
		GROUP BY "c2"."id"
		ORDER BY COUNT(*) DESC /* list of comment to the comment with the most comments*/
		LIMIT 1),
	0	
);

/*these 2 get the reactions from random posts to try multiple times until post with reaction appears*/
SELECT * FROM get_post_reactions(
	(SELECT "id" FROM posts
		ORDER BY RANDOM()
		LIMIT 1
	)	
);
SELECT * FROM get_comment_reactions(
	(SELECT "id" FROM posts
		ORDER BY RANDOM()
		LIMIT 1
	)	
);


/*------------ Report Comment and Post -----------*/
DO $$
DECLARE
    "u1id" INTEGER;
	"u2id" INTEGER;
	"u3id" INTEGER;
	"p1_id" INTEGER; /*racist post*/
	"p2_id" INTEGER; /*spamming post*/
	"p3_id" INTEGER; /*harmless post*/
	"c1_id" INTEGER; /*racist comment*/
	"c2_id" INTEGER; /*spamming comment*/
	"c3_id" INTEGER; /*harmless comment*/
BEGIN
    SELECT "id" INTO "u1id" FROM "users" WHERE "username" = 'jeff';
	SELECT "id" INTO "u2id" FROM "users" WHERE "username" = 'matt';
	SELECT "id" INTO "u3id" FROM "users" WHERE "username" = 'john';
	
	SELECT "id" INTO "p1_id" FROM "posts" 
		WHERE "content" LIKE '%racist%';
	SELECT "id" INTO "p2_id" FROM "posts" 
		WHERE "content" LIKE '%spamming%';
	SELECT "id" INTO "p3_id" FROM "posts" 
		WHERE "content" LIKE 'I am sayning sth bad but not worth a report';

	SELECT "id" INTO "c1_id" FROM "comments" 
		WHERE "content" LIKE '%racist%';	
	SELECT "id" INTO "c2_id" FROM "comments" 
		WHERE "content" LIKE '%spamming%';	
	SELECT "id" INTO "c3_id" FROM "comments" 
		WHERE "content" LIKE 'I am sayning sth bad but not worth a report';

	
	CALL add_report_post("u1id", "p1_id", 'Hate Speech',  'this post is very racist');
	CALL add_report_post("u2id", "p1_id", 'Hate Speech',  'how isnt this post deleted yet are the mod asleep');
	CALL add_report_post("u3id", "p1_id", 'Hate Speech',  'ban the user');

	CALL add_report_comment("u1id", "c1_id", 'Hate Speech',  'this post is very racist');
	CALL add_report_comment("u2id", "c1_id", 'Hate Speech',  'how isnt this post deleted yet are the mod asleep');
	CALL add_report_comment("u3id", "c1_id", 'Hate Speech',  'ban the user');


	CALL add_report_post("u1id", "p2_id", 'Spam',  'this is spam');
	CALL add_report_post("u2id", "p2_id", 'Spam',  'He keeps spamming');

	CALL add_report_comment("u1id", "c2_id", 'Spam',  'this is spam');
	CALL add_report_comment("u2id", "c2_id", 'Spam',  'He keeps spamming');


	CALL add_report_post("u1id", "p3_id", 'other',  'I feel offended');

	CALL add_report_comment("u2id", "c3_id", 'other',  'I fell offended');

END;
$$;


SELECT * FROM "reports"
INNER JOIN "comment_reports"
ON "comment_reports"."report_id" = "reports"."id";


SELECT * FROM "reports"
INNER JOIN "post_reports"
ON "post_reports"."report_id" = "reports"."id";


/* ------------- CHECK pending reports  ------------ */

SELECT "content_type", "content_id", "report_count"
FROM (
	SELECT 
	    'post' AS "content_type",
	    "post_id" AS "content_id",
	    COUNT(*) AS "report_count"
	FROM "post_reports"
	INNER JOIN "reports"
		ON "reports"."id" = "post_reports"."report_id"
	WHERE "reports"."status" != 'Closed'
	GROUP BY "post_id"
	UNION ALL
	SELECT 
	    'comment' AS "content_type",
	    "comment_id" AS "content_id",
	    COUNT(*) AS "report_count"
	FROM "comment_reports"
	INNER JOIN "reports"
		ON "reports"."id" = "comment_reports"."report_id"
	WHERE "reports"."status" != 'Closed'
	GROUP BY "comment_id"
) AS "combined_reports"
WHERE "content_id" IS NOT NULL
ORDER BY "report_count" DESC;


/* --------------------- HANDLE REPORTS -------------------------*/
DO $$
DECLARE
    "admin_id" INTEGER;
	"rp1_id" INTEGER;  /*random report for a post with hate speech*/
	"rp2_id" INTEGER;  /*random report for a post with spam*/
	"rp3_id" INTEGER;  /*random report for a harmless post*/
	"rc1_id" INTEGER;  /*random report for a comment with hate speech*/
	"rc2_id" INTEGER;  /*random report for a comment with spam*/
	"rc3_id" INTEGER;  /*random report for a harmless comment*/
BEGIN
    SELECT MIN("id") INTO "admin_id" FROM "users" WHERE "admin" = TRUE;
	
	SELECT "id" INTO "rp1_id" FROM "reports" 
	WHERE "identifier" = 'posts'
	AND "type" = 'Hate Speech'
	ORDER BY random()
	LIMIT 1;
	
	SELECT "id" INTO "rp2_id" FROM "reports" 
	WHERE "identifier" = 'posts'
	AND "type" = 'Spam'
	ORDER BY random()
	LIMIT 1;
	
	SELECT "id" INTO "rp3_id" FROM "reports" 
	WHERE "identifier" = 'posts'
	AND "type" = 'other'
	ORDER BY random()
	LIMIT 1;
	
	SELECT "id" INTO "rc1_id" FROM "reports" 
	WHERE "identifier" = 'comments'
	AND "type" = 'Hate Speech'
	ORDER BY random()
	LIMIT 1;
	
	SELECT "id" INTO "rc2_id" FROM "reports" 
	WHERE "identifier" = 'comments'
	AND "type" = 'Spam'
	ORDER BY random()
	LIMIT 1;
	
	SELECT "id" INTO "rc3_id" FROM "reports" 
	WHERE "identifier" = 'comments'
	AND "type" = 'other'
	ORDER BY random()
	LIMIT 1;

	/* 3rd arg is to remove content 4th is to banned USER*/
	CALL report_handling("admin_id", "rp1_id", True, True);
	CALL report_handling("admin_id", "rp2_id", True, False);
	CALL report_handling("admin_id", "rp3_id", False, False);
	CALL report_handling("admin_id", "rc1_id", True, True);
	CALL report_handling("admin_id", "rc2_id", True, False);
	CALL report_handling("admin_id", "rc3_id", False, False);
	
END;
$$;

SELECT * FROM reports;
SELECT * FROM post_reports;
SELECT * FROM comment_reports;

/*   -----show the reports for a given content (if it was not removed) ---------*/
SELECT * FROM get_content_report('posts', 6, true);
/*1 arg identifier, 2nd content id, 3rd show closed reports*/


