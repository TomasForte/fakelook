CREATE PROCEDURE add_user (
			"_username" VARCHAR(30),
			"_email" VARCHAR(50),
			"_password" VARCHAR(50),
			"_profile_pic" TEXT,
			"_banner_pic"  TEXT,
			"_genre" VARCHAR(20),
			"_birthday" DATE,
			"_timezone_id" INTEGER
)
LANGUAGE plpgsql
AS $$
DECLARE
	"new_profile_pic_id" INTEGER;
	"new_banner_pic_id" INTEGER;
	"new_user_id" INTEGER;
BEGIN
	INSERT INTO "users" (
		"username", "email", "password", "genre", "birthday"
	) VALUES (
		"_username", "_email", "_password", "_genre", "_birthday"
	) RETURNING "id" INTO "new_user_id";

	IF "new_user_id" IS NOT NULL THEN
		INSERT INTO "user_settings"("user_id") 
		VALUES ("new_user_id");

		UPDATE "user_settings" SET "timezone_id" = "_timezone_id" 
		WHERE "user_id" = "new_user_id"
		AND "_timezone_id" IN (SELECT "id" FROM "timezones");
		
		IF "_banner_pic" IS NOT NULL THEN
			INSERT INTO "images"("image") 
			VALUES ("_banner_pic") RETURNING "id" INTO "new_banner_pic_id";	
			
			INSERT INTO "user_images"("user_id","image_id") 
			VALUES ("new_user_id", "new_banner_pic_id");

			UPDATE "users" SET "banner_id" = "new_banner_pic_id" 
			WHERE "id" = "new_user_id" ;
		END IF;
		IF "_profile_pic" IS NOT NULL THEN
			INSERT INTO "images"("image") 
			VALUES ("_profile_pic") RETURNING "id" INTO "new_profile_pic_id";
			
			INSERT INTO "user_images"("user_id","image_id") 
			VALUES ("new_user_id", "new_profile_pic_id");

			UPDATE "users" SET "profile_pic_id" = "new_profile_pic_id" 
			WHERE "id" = "new_user_id";
		END IF;
	END IF;
END;
$$;



CREATE PROCEDURE add_profile_pic (
	"_user_id" INTEGER,
	"_image" TEXT 
)
LANGUAGE plpgsql
AS $$
DECLARE
	"new_profile_pic_id" INTEGER;
BEGIN
	INSERT INTO "images"("image") 
	VALUES ("_image") RETURNING "id" INTO "new_profile_pic_id";
	
	INSERT INTO "user_images"("user_id","image_id") 
	VALUES ("_user_id", "new_profile_pic_id");
END;
$$;	



CREATE PROCEDURE add_banner_pic (
	"_user_id" INTEGER,
	"_image" TEXT 
)
LANGUAGE plpgsql
AS $$
DECLARE
	"new_banner_pic_id" INTEGER;
BEGIN
	INSERT INTO "images"("image") 
	VALUES ("_image") RETURNING "id" INTO "new_banner_pic_id";
	
	INSERT INTO "user_images"("user_id","image_id") 
	VALUES ("_user_id", "new_banner_pic_id");
END;
$$;	



CREATE PROCEDURE change_profile_pic ("_pic_id" INTEGER, "_user_id" INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    "is_valid" BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM "user_images" 
        WHERE "user_id" = "_user_id" AND "image_id" = "_pic_id"
    ) INTO "is_valid";
	IF "is_valid" THEN
		UPDATE "users" SET "profile_pic_id" = "_pic_id" WHERE "id" = "_user_id";
	END IF;
END;
$$;



CREATE PROCEDURE change_banner_pic ("_pic_id" INTEGER, "_user_id" INTEGER)
LANGUAGE plpgsql
AS $$
DECLARE
    "is_valid" BOOLEAN;
BEGIN
	SELECT EXISTS (
		SELECT 1 FROM "user_images" 
		WHERE "user_id" = "_user_id" AND "image_id" = "_pic_id"
    ) INTO "is_valid";
	
	IF "is_valid" THEN
		
		UPDATE "users" SET "banner_id" = "_pic_id" WHERE "id" = "_user_id";	
	END IF;	
END;
$$;



CREATE PROCEDURE delete_image ("_image_id" INTEGER, "_user_id" INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
	DELETE FROM "images" 
	WHERE id = "_image_id"
	  AND EXISTS (
	      SELECT 1 FROM user_images
	      WHERE user_id = _user_id AND image_id = _image_id
	);

	UPDATE "users" SET "banner_id" = null 
	WHERE "id" = "_user_id" AND "banner_id" = "_image_id";
	
	UPDATE "users" SET "profile_pic_id" = null 
	WHERE "id" = "_user_id" AND "profile_pic_id" = "_image_id";
END;
$$;



CREATE PROCEDURE delete_user ("_user_id" INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
	DELETE FROM "users" WHERE "id" = "_user_id";
END;
$$;



CREATE PROCEDURE change_profile ("_profile" TEXT, "_user_id" INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
	UPDATE "users" SET "profile" = "_profile" WHERE "id" = "_user_id";
END;
$$;



CREATE PROCEDURE change_settings (
	"_user_id" INTEGER,
	"_timezone_id" INTEGER,
	"_date_format" DATEFORMAT,
	"_hide_info" BOOLEAN,
	"_hide_post" BOOLEAN,
	"_private_message" BOOLEAN )
LANGUAGE plpgsql
AS $$
BEGIN
	UPDATE "user_settings" 
	SET 
		"timezone_id" = "_timezone_id",
		"date_format" = "_date_format",
		"hide_info" = "_hide_info", 
		"hide_post" = "_hide_post",
		"private_message" = "_private_message"
	WHERE "user_id" = "_user_id";
END;
$$;



CREATE PROCEDURE friend_request(
	"_user_id" INTEGER,
	"_friend_id" INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO "friends" ("user_id", "friend_id") 
	VALUES ("_user_id", "_friend_id");
END;
$$;



CREATE PROCEDURE accept_friend_request(
	"_user_id" INTEGER,
	"_friend_id" INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
	IF (
		SELECT true FROM "friends" 
		WHERE "user_id" = "_friend_id" AND "friend_id" = "_user_id"
	) THEN
		UPDATE "friends" SET
			"status" = 'accepted',
			"accepted_at" = CURRENT_DATE
		WHERE "user_id" = "_friend_id" AND "friend_id" = "_user_id";
		
		INSERT INTO "friends" ("user_id", "friend_id", "status", "accepted_at")
		VALUES ("_user_id", "_friend_id", 'accepted', CURRENT_DATE);
	END IF;
END;
$$;



CREATE PROCEDURE refuse_friend_request(
	"_user_id" INTEGER,
	"_friend_id" INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
	DELETE FROM "friends" WHERE "user_id" = "_friend_id" AND "friend_id" = "_user_id";
END;
$$;



CREATE PROCEDURE remove_friend(
	"_user_id" INTEGER,
	"_friend_id" INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
	DELETE FROM "friends" WHERE "user_id" = "_friend_id" AND "friend_id" = "_user_id";
	DELETE FROM "friends" WHERE "user_id" = "_user_id" AND "friend_id" = "_friend_id";
END;
$$;



CREATE PROCEDURE update_friend_mute (
	"_user_id" INTEGER,
	"_friend_id" INTEGER,
	"_muted" BOOLEAN)
LANGUAGE plpgsql
AS $$
BEGIN
	UPDATE "friends" SET "muted" = "_muted" 
	WHERE "user_id" = "_friend_id" AND "friend_id" = "_user_id";
END;
$$;



CREATE FUNCTION get_friends(
    "_user_id" INTEGER,
	"page" INTEGER
)
RETURNS TABLE (    
	"id" INTEGER,
    "username" VARCHAR(30),
    "profile_pic_id" INTEGER,
    "image" TEXT 
)
LANGUAGE plpgsql
AS $$
BEGIN
	RETURN QUERY
	SELECT 
		"users"."id",
		"users"."username",
		"users"."profile_pic_id",
		"images"."image" 
	FROM "friends"
	INNER JOIN "users"
		ON "users"."id" = "friends"."friend_id"
	LEFT JOIN "images"
		ON "users"."profile_pic_id" = "images"."id"
	WHERE "friends"."user_id" = "_user_id"
	OFFSET "page"*20
	LIMIT 20;
END;
$$;



CREATE PROCEDURE block_user (
	"_blocker_id" INTEGER,
	"_blocked_id" INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO "blocks" ("blocker_id", "blocked_id")
	VALUES ("_blocker_id", "_blocked_id");
END;
$$;



CREATE PROCEDURE unblock_user (
	"_blocker_id" INTEGER,
	"_blocked_id" INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
	DELETE FROM "blocks" 
	WHERE "blocker_id" = "_blocker_id" AND "blocked_id" = "_blocked_id";
END;
$$;



CREATE PROCEDURE post_post (	
	"_user_id" INTEGER,
	"_content" TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO "posts" ("user_id", "content") 
	VALUES ("_user_id", "_content");
END;
$$;



CREATE PROCEDURE edit_post (	
	"_id" INTEGER,
	"_user_id" INTEGER,
	"_content" TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
	UPDATE "posts" 
	SET "content" = "_content" 
	WHERE "id" = "_id"
	AND "user_id" = "_user_id";
END;
$$;


CREATE PROCEDURE delete_post (	
	"_id" INTEGER,
	"_user_id" INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
	DELETE FROM "posts" 
	WHERE "id" = "_id"
	AND "user_id" = "_user_id";
END;
$$;



CREATE PROCEDURE post_comment (	
	"_user_id" INTEGER,
	"_post_id" INTEGER,
	"_content" TEXT,
	"_comment_id" INTEGER DEFAULT null 
)
LANGUAGE plpgsql
AS $$
BEGIN
	IF "_comment_id" is null THEN
		INSERT INTO "comments" ("user_id", "post_id", "content", "comment_id") 
		VALUES ("_user_id", "_post_id", "_content", null);
	ELSIF ((SELECT "post_id" FROM "comments" WHERE "id" = "_comment_id") = "_post_id") THEN
		INSERT INTO "comments" ("user_id", "post_id", "content", "comment_id") 
		VALUES ("_user_id", "_post_id", "_content", "_comment_id");
	ELSE
		RAISE NOTICE 'FAILED TO ADD COMMENT';
	END IF;
END;
$$;



CREATE PROCEDURE edit_comment (	
	"_id" INTEGER,
	"_user_id" INTEGER,
	"_content" TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
	UPDATE "comments" 
	SET "content" = "_content" 
	WHERE "id" = "_id"
	AND "user_id" = "_user_id";
END;
$$;


CREATE PROCEDURE delete_comment (	
	"_id" INTEGER,
	"_user_id" INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
	DELETE FROM "comments" 
	WHERE "id" = "_id"
	AND "user_id" = "_user_id";
END;
$$;



CREATE PROCEDURE add_reaction_to_post (
	"_post_id" INTEGER,
	"_user_id" INTEGER,
	"_reaction_id" INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO "post_reactions" ("post_id", "user_id", "reaction_id")
	VALUES ("_post_id", "_user_id", "_reaction_id");
END;
$$;



CREATE PROCEDURE remove_reaction_to_post (
	"_post_id" INTEGER,
	"_user_id" INTEGER,
	"_reaction_id" INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
	DELETE FROM "post_reactions"
	WHERE "post_id" = "_post_id"
		AND "user_id" = "_user_id"
		AND "reaction_id" = "_reaction_id";
END;
$$;



CREATE PROCEDURE add_reaction_to_comment (
	"_comment_id" INTEGER,
	"_user_id" INTEGER,
	"_reaction_id" INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
	INSERT INTO "comment_reactions" ("comment_id", "user_id", "reaction_id")
	VALUES ("_comment_id", "_user_id", "_reaction_id");
END;
$$;



CREATE PROCEDURE remove_reaction_to_comment (
	"_comment_id" INTEGER,
	"_user_id" INTEGER,
	"_reaction_id" INTEGER
)
LANGUAGE plpgsql
AS $$
BEGIN
	DELETE FROM "comment_reactions"
	WHERE "comment_id" = "_comment_id"
		AND "user_id" = "_user_id"
		AND "reaction_id" = "_reaction_id";
END;
$$;



CREATE FUNCTION get_feed (
			"_user_id" INTEGER,
			"page" INTEGER
)
RETURNS TABLE (    
	"post_id" INTEGER,
	"post_content" TEXT,
	"user_id" INTEGER,
    "username" VARCHAR(30),
    "profile_pic" TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
	RETURN QUERY
	SELECT 
		"posts"."id",
		"posts"."content",
		"posts"."user_id",
		"users"."username",
		"images"."image" 
	FROM "posts"
	INNER JOIN "users"
		ON "users"."id" = "posts"."user_id"
	LEFT JOIN "images"
		ON "users"."profile_pic_id" = "images"."id" 
	WHERE "posts"."user_id" NOT IN (
			SELECT "blocker_id" FROM "blocks" WHERE "blocked_id" = "_user_id"
		)
	AND NOT "posts"."user_id" = "_user_id"
	ORDER BY "posts"."created_at" DESC
	OFFSET "page"*20
	LIMIT 20;
END;
$$;



CREATE FUNCTION get_post_comments (
			"_post_id" INTEGER,
			"page" INTEGER
)
RETURNS TABLE (    
	"comment_id" INTEGER,
	"comment_content" TEXT,
	"user_id" INTEGER,
    "username" VARCHAR(30),
    "profile_pic" TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
	RETURN QUERY
	SELECT 
		"comments"."id",
		"comments"."content",
		"comments"."user_id",
		"users"."username",
		"images"."image"
	FROM "comments"
	INNER JOIN "users"
		ON "users"."id" = "comments"."user_id"
	LEFT JOIN "images"
		ON "users"."profile_pic_id" = "images"."id" 
	WHERE "comments"."post_id" = "_post_id"
	AND "comments"."comment_id" is null
	ORDER BY "comments"."created_at" DESC
	OFFSET "page"*20
	LIMIT 20;
END;
$$;



CREATE FUNCTION get_comment_comments (
			"_comment_id" INTEGER,
			"page" INTEGER
)
RETURNS TABLE (    
	"comment_id" INTEGER,
	"comment_content" TEXT,
	"user_id" INTEGER,
    "username" VARCHAR(30),
    "profile_pic" TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
	RETURN QUERY
	SELECT 
		"comments"."id",
		"comments"."content",
		"comments"."user_id",
		"users"."username",
		"images"."image" 
	FROM "comments"
	INNER JOIN "users"
		ON "users"."id" = "comments"."user_id"
	LEFT JOIN "images"
		ON "users"."profile_pic_id" = "images"."id" 
	WHERE "comments"."comment_id" = "_comment_id"
	ORDER BY "comments"."created_at" DESC
	OFFSET "page"*20
	LIMIT 20;
END;
$$;



CREATE FUNCTION get_post_reactions (
			"_post_id" INTEGER
)
RETURNS TABLE (    
	"post_id" INTEGER,
	"reaction_id" INTEGER,
	"reaction_icon" TEXT,
    "reaction_total" INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
	RETURN QUERY
	SELECT 
		"post_id",
		"reaction"."id",
		"reaction"."icon",
		COUNT(*) AS "reaction_total"
	FROM "posts"
	LEFT JOIN "post_reactions"
		ON "post_reactions"."post_id" = "posts"."id"
	LEFT JOIN "reactions"
		ON "reactions"."id" = "post_reactions"."reaction_id"
	WHERE "posts"."post_id" = "_post_id"
	GROUP BY "reaction_id";
END;
$$;



CREATE FUNCTION get_comment_reactions (
			"_comment_id" INTEGER
)
RETURNS TABLE (    
	"comment_id" INTEGER,
	"reaction_id" INTEGER,
	"reaction_icon" TEXT,
    "reaction_total" INTEGER)
LANGUAGE plpgsql
AS $$
BEGIN
	RETURN QUERY
	SELECT 
		"comment_id",
		"reaction"."id",
		"reaction"."icon",
		COUNT(*) AS "reaction_total"
	FROM "comments"
	LEFT JOIN "comment_reactions"
		ON "comment_reactions"."post_id" = "comments"."id"
	LEFT JOIN "reactions"
		ON "reactions"."id" = "post_reactions"."reaction_id"
	WHERE "comments"."post_id" = "_post_id"
	GROUP BY "reaction_id";
END;
$$;



CREATE PROCEDURE add_report_post(
    user_id INTEGER,
    post_id INTEGER,
    type VARCHAR(30),
    message TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    report_id INTEGER;
BEGIN
    INSERT INTO reports(type, message)
    VALUES (type, message)
    RETURNING id INTO report_id;

    INSERT INTO post_reports(user_id, post_id, report_id)
    VALUES (user_id, post_id, report_id);
END;
$$;



CREATE PROCEDURE add_report_comment(
    user_id INTEGER,
    comment_id INTEGER,
    type VARCHAR(30),
    message TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    report_id INTEGER;
BEGIN
    INSERT INTO reports(type, message)
    VALUES (type, message)
    RETURNING id INTO report_id;

    INSERT INTO comment_reports(user_id, comment_id, report_id)
    VALUES (user_id, comment_id, report_id);
END;
$$;



