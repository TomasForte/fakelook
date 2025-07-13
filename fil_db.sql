INSERT INTO "timezones" ("name") 
VALUES
	('Europe/Lisbon'),
	('Europe/Berlin'),
    ('Brazil/West'),
    ('America/Los_Angeles')
ON CONFLICT ("name") DO NOTHING;


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

/*------ ADD AND SETTING PROFILE PIC ---------*/
DO $$
DECLARE
    "uid" INTEGER;
	"new_image_id" INTEGER;
BEGIN
    SELECT "id" INTO uid FROM "users" WHERE "username" = 'matt';
	
    CALL add_profile_pic(uid, 'matt_new_profile_pic.png');
	
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

/*------ DELETE user ---------*/
DO $$
DECLARE
    "uid" INTEGER;
BEGIN
    SELECT "id" INTO "uid" FROM "users" WHERE "username" = 'bob';
	
	CALL delete_user("uid");
END;
$$;


/*------ update user profile ---------*/
DO $$
DECLARE
    "uid" INTEGER;
BEGIN
    SELECT "id" INTO "uid" FROM "users" WHERE "username" = 'jeff';
	
	CALL change_profile('My name is Jeff', "uid");
END;
$$;


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
	
	CALL friend_request("u1id","u2id");
	CALL friend_request("u1id","u3id");
	CALL friend_request("u1id","u4id");
	CALL friend_request("u2id","u3id");
	CALL friend_request("u2id","u4id");
	CALL friend_request("u3id","u4id");

	CALL  accept_friend_request("u2id", "u1id");
	CALL  accept_friend_request("u3id", "u1id");
	CALL  refuse_friend_request("u4id", "u1id");
	CALL  accept_friend_request("u3id", "u2id");
	CALL  refuse_friend_request("u4id", "u2id");

	CALL  update_friend_mute("u2id", "u1id", true);

END;
$$;

/*------ GET USER FRIENDS -------*/
DO $$
DECLARE
    "uid" INTEGER;
BEGIN
    SELECT "id" INTO "uid" FROM "users" WHERE "username" = 'jeff';
	
	PERFORM * FROM get_friends("uid",1);
END;
$$;


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
	
	CALL block_user("u1id","u2id");
	CALL block_user("u1id","u3id");
	CALL unblock_user("u1id","u3id");

END;
$$;


/*------------ Post | Edit | DELETE Comment -----------*/
DO $$
DECLARE
    "u1id" INTEGER;
	"u2id" INTEGER;
	"u3id" INTEGER;
	"post_id" INTEGER;
BEGIN
    SELECT "id" INTO "u1id" FROM "users" WHERE "username" = 'jeff';
	SELECT "id" INTO "u2id" FROM "users" WHERE "username" = 'matt';
	SELECT "id" INTO "u3id" FROM "users" WHERE "username" = 'john';
	
	CALL post_post("u1id", 'This is petty cool');
	CALL post_post("u1id", 'This is petty cool');
	CALL post_post("u1id", 'It was a terrible idea to make everything a procedure');
	CALL post_post("u1id", 'Do you think anyone will see this');
	CALL post_post("u1id", 'I am saying sth racist');

	CALL post_post("u2id", 'I whish i was rich');
	CALL post_post("u2id", 'I am saying sth age restricted');
	CALL post_post("u3id", 'What do you guys think of your job');

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


/*------------ Post | Edit | DELETE Comment -----------*/
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
BEGIN
    SELECT "id" INTO "u1id" FROM "users" WHERE "username" = 'jeff';
	SELECT "id" INTO "u2id" FROM "users" WHERE "username" = 'matt';
	SELECT "id" INTO "u3id" FROM "users" WHERE "username" = 'john';
	SELECT MIN("id") INTO "post1_id" FROM "posts" WHERE "user_id" = "u1id" GROUP BY "user_id";
	SELECT MIN("id") INTO "post2_id" FROM "posts" WHERE "user_id" = "u2id" GROUP BY "user_id";

	/*commenting posts*/
	CALL post_comment("u1id", "post1_id", 'this is a comment to a post');
	CALL post_comment("u2id", "post2_id", 'I love commenting on posts');
	CALL post_comment("u2id", "post1_id", 'What a great post');
	CALL post_comment("u3id", "post2_id", 'What time is it');
	CALL post_comment("u1id", "post1_id", 'my name is jeff');

	SELECT MIN("id") INTO "comment1_id" FROM "comments" WHERE "post_id" = "post1_id";
	SELECT MIN("id") INTO "comment2_id" FROM "comments" WHERE "post_id" = "post2_id";

	/*commenting comments*/
	CALL post_comment("u1id", "post1_id", 'this is a comment to a comment', "comment1_id");
	CALL post_comment("u2id", "post2_id", 'I love commenting on comments', "comment2_id");
	CALL post_comment("u2id", "post1_id", 'What a great comment', "comment1_id");
	CALL post_comment("u3id", "post2_id", 'I will delete this comment later', "comment2_id");
	CALL post_comment("u1id", "post1_id", 'my name is jeff', "comment2_id"); /*this one should fail*/


	SELECT "id" into "comment_to_delete_id" FROM "comments" 
	WHERE "content" = 'I will delete this comment later';

	CALL post_comment("u2id", "post2_id", 'this comment should be deleted when the parent is deleted', "comment_to_delete_id");
	CALL delete_comment("comment_to_delete_id", "u3id");

	SELECT min("id") into "comment1_id" FROM "comments" 
	WHERE "user_id" = "u1id"
	GROUP BY "user_id";
	
	CALL edit_comment("comment1_id", "u1id", 'this post was edited');
	
END;
$$;

INSERT INTO "reactions"("name", "icon")
VALUES
	('like','like_icon.png'),
	('love', 'love_icon.png'),
	('angry', 'angry_icon.png'),
	('sleepy', 'sleepy_icon.png');





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
	SELECT "id" INTO "post1_id" FROM "posts" LIMIT 1;
	SELECT "id" INTO "post2_id" FROM "posts" LIMIT 1;
	SELECT "id" INTO "comment1_id" FROM "comments" LIMIT 1;
	SELECT "id" INTO "comment2_id" FROM "comments" LIMIT 1;

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

/*--------- get feed to a specific user ---------*/
SELECT * FROM get_feed(
    (SELECT id FROM "users" WHERE "username" = 'jeff'),
    0
);


SELECT * FROM get_post_comments(
	(SELECT "posts"."id" FROM "posts"
			INNER JOIN "comments"
			ON "comments"."post_id" = "posts"."id"
		WHERE "comments"."comment_id" IS null
		GROUP BY "posts"."id"
		ORDER BY COUNT(*) DESC
		LIMIT 1),
	0	
);

SELECT * FROM get_comments_comments(
	(SELECT "comments"."id" FROM "comments"
			INNER JOIN "comments" AS "c2"
			ON "comments"."id" = "comments"."comment_id"
		GROUP BY "comments"."id"
		ORDER BY COUNT(*) DESC
		LIMIT 1),
	0	
);






SELECT * FROM comments;
DELETE FROM comments;
SELECT * FROM post_reactions;
SELECT * FROM get_friends(31,1);
SELECT * FROM friends;
SELECT * FROM users;
SELECT * FROM user_images;


