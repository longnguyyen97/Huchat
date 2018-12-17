DROP DATABASE IF EXISTS HUCHAT;
CREATE DATABASE HUCHAT;
USE HUCHAT;

CREATE TABLE ACCOUNT(
    USER_NAME VARCHAR(30) PRIMARY KEY,
    PASSWORD VARCHAR(64)
);

CREATE TABLE USERS(
    USER_NAME VARCHAR(30) NOT NULL,    
    FULL_NAME NVARCHAR(100),
    DOB LONG,
    GENDER BOOLEAN,
    MAIL VARCHAR(50),
    PHONE VARCHAR(11),
    CREATE_AT LONG,
    FOREIGN KEY (USER_NAME) REFERENCES ACCOUNT(USER_NAME) ON UPDATE CASCADE 
) ENGINE = INNODB;

CREATE TABLE ROOMS(
    ROOM_CODE VARCHAR(41) PRIMARY KEY, -- ROOM CODE = GET MILI SECOND + USERNAME
    USER_NAME_OWNER VARCHAR(20) NOT NULL,
    -- PASS = # MEAN ROOM IS_DUAL
    PASSWORD VARCHAR(64),
    -- TRUE MEAN IS_DUAL
    IS_DUAL BOOLEAN,
    PRIVATE BOOLEAN,
    FOREIGN KEY (USER_NAME_OWNER) REFERENCES ACCOUNT(USER_NAME)  ON UPDATE CASCADE 
)ENGINE = INNODB;

CREATE TABLE ROOM_MEMBER(
    ROOM_CODE VARCHAR(41) NOT NULL, 
    USER_NAME_MEMBER VARCHAR(20),
    FOREIGN KEY (ROOM_CODE) REFERENCES ROOMS(ROOM_CODE),
    FOREIGN KEY (USER_NAME_MEMBER) REFERENCES ACCOUNT(USER_NAME)  ON UPDATE CASCADE 
)ENGINE = INNODB;

CREATE TABLE INFO_ROOM(
    ROOM_CODE VARCHAR(41) NOT NULL, 
    ROOM_NAME NVARCHAR(50),
    FOREIGN KEY (ROOM_CODE) REFERENCES ROOMS(ROOM_CODE)  ON UPDATE CASCADE 
)ENGINE = INNODB;

CREATE TABLE CHAT_ROOMS_HISTORY(
    ROOM_CODE VARCHAR(41) NOT NULL,
    USER_NAME VARCHAR(30),
    CONTENT NVARCHAR(1000),
    TIME LONG
);

CREATE TABLE LOG(
    EVENT VARCHAR(100),
    CREATE_AT LONG
);

-------------------------------------LOG-------------------------------------------
DELIMITER $$
CREATE PROCEDURE PROC_INSERT_LOG_EVENT (
    IN ACTION VARCHAR(100))
BEGIN
	INSERT INTO LOG VALUES(ACTION, UNIX_TIMESTAMP(now()));
END; $$
DELIMITER ;

-- call PROC_INSERT_LOG_EVENT("aaaaaaaa");

DELIMITER $$
CREATE PROCEDURE PROC_VIEW_ALL_EVENT ()    
BEGIN
    SELECT EVENT AS "Hành động", FROM_UNIXTIME(CREATE_AT, "%d-%m-%Y %H:%i:%s") AS "Thời gian tạo"
    FROM LOG
    ORDER BY CREATE_AT DESC;
END; $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE PROC_VIEW_EVENT_BETWEEN (
    IN TIME_A LONG,
    IN TIME_B LONG
)    
BEGIN
    SELECT EVENT AS "Hành động", FROM_UNIXTIME(CREATE_AT, "%d-%m-%Y %H:%i:%s") AS "Thời gian tạo"
    FROM LOG
    WHERE TIME_A <= CREATE_AT AND CREATE_AT <= TIME_B
    ORDER BY CREATE_AT DESC;
END; $$
DELIMITER ;
-- SELECT FROM_UNIXTIME(UNIX_TIMESTAMP(now()), "%d-%m-%Y %H:%i:%s");
-------------------------------------LOG-------------------------------------------


---------------------------------INFO_USERS----------------------------------------

DELIMITER $$
CREATE PROCEDURE PROC_UPDATE_INFO_USER (
	IN N_USER_NAME VARCHAR(30),  
    IN N_FULL_NAME NVARCHAR(100),
    IN N_DOB LONG,
    IN N_GENDER BOOLEAN,
    IN N_MAIL VARCHAR(50),
    IN N_PHONE VARCHAR(11))
BEGIN
    UPDATE USERS 
    SET FULL_NAME = N_FULL_NAME,
        DOB = N_DOB,
        GENDER = N_GENDER,
        MAIL = N_MAIL,
        PHONE = N_PHONE
    WHERE USER_NAME = N_USER_NAME;
END; $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE PROC_GET_INFO_USER(
    IN N_USER_NAME VARCHAR(30))
BEGIN
    SELECT *
    FROM USERS
    WHERE USER_NAME = N_USER_NAME;
END; $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE PROC_GET_ALL_PUBLIC_INFO_USER()
BEGIN
    SELECT USER_NAME, FULL_NAME, GENDER
    FROM USERS;
END; $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE PROC_FIND_USER(
    IN N_USER_NAME VARCHAR(30))
BEGIN
    DECLARE U VARCHAR(32);
    SET U = "%";
    SET U = CONCAT(U, N_USER_NAME, U);
    (SELECT USER_NAME
    FROM ACCOUNT
    WHERE USER_NAME LIKE N_USER_NAME) 
    UNION DISTINCT
    (SELECT USER_NAME
    FROM ACCOUNT
    WHERE USER_NAME LIKE U); 
END; $$
DELIMITER ;
----------------------------------INFO_USERS----------------------------------------

------------------------------------LOGIN------------------------------------------
DELIMITER $$
CREATE PROCEDURE PROC_LOGIN_EVENT (
    IN N_USER_NAME VARCHAR(30))
BEGIN
    SET N_USER_NAME = CONCAT("LOGIN WITH USER NAME ", N_USER_NAME);
    CALL PROC_INSERT_LOG_EVENT(N_USER_NAME);
END; $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE PROC_LOGOUT_EVENT (
    IN USER_NAME VARCHAR(30))
BEGIN
	SET USER_NAME = CONCAT("LOGOUT WITH USER NAME ", USER_NAME);
	CALL PROC_INSERT_LOG_EVENT(USER_NAME);
END; $$
DELIMITER ;

------------------------------------LOGIN------------------------------------------

-----------------------------------ACCOUNT-----------------------------------------
DELIMITER $$
CREATE PROCEDURE PROC_INSERT_ACCOUNT (
	IN N_USER_NAME VARCHAR(30),  
	IN PASSWORD VARCHAR(64),
    IN EMAIL VARCHAR(50))
BEGIN
    INSERT INTO ACCOUNT VALUES(N_USER_NAME, PASSWORD);
    INSERT INTO USERS(USER_NAME, FULL_NAME, MAIL, CREATE_AT) VALUES(N_USER_NAME, N_USER_NAME, EMAIL, UNIX_TIMESTAMP(now()));
END; $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE PROC_CHANGE_PASSWORD_ACCOUNT (
	IN N_USER_NAME VARCHAR(30),  
	IN N_PASSWORD VARCHAR(64))
BEGIN
    UPDATE ACCOUNT 
    SET PASSWORD = N_PASSWORD 
    WHERE ACCOUNT.USER_NAME = N_USER_NAME;
END; $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE PROC_DELETE_ACCOUNT (
	IN N_USER_NAME VARCHAR(30))
BEGIN
    UPDATE ACCOUNT
    SET USER_NAME = CONCAT("#", UNIX_TIMESTAMP(now()), USER_NAME)
    WHERE USER_NAME LIKE N_USER_NAME;
END; $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE PROC_VIEW_DELETED_ACCOUNT()
BEGIN
    SELECT USER_NAME 
    FROM ACCOUNT
    WHERE USER_NAME LIKE "#%";
END; $$
DELIMITER ;
-----------------------------------ACCOUNT-----------------------------------------

----------------------------------ROOM----------------------------------------
DELIMITER $$
CREATE PROCEDURE PROC_GET_LIST_ROOM_OF_USER(
    IN N_USER_NAME VARCHAR(30))
BEGIN
    SELECT A.ROOM_CODE, USER_NAME_OWNER, ROOM_NAME 
    FROM ROOM_MEMBER A, INFO_ROOM B, ROOMS C
    WHERE USER_NAME_MEMBER LIKE N_USER_NAME AND A.ROOM_CODE = B.ROOM_CODE AND B.ROOM_CODE = C.ROOM_CODE; 
END; $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE PROC_CREATE_ROOM(
    IN N_USER_NAME VARCHAR(30),
    IN N_PASSWORD VARCHAR(64),
    IN N_ROOM_NAME NVARCHAR(50),
    IN N_IS_DUAL BOOLEAN,
    IN MODE BOOLEAN)
BEGIN
    DECLARE N_ROOM_CODE VARCHAR(41);
    SET N_ROOM_CODE = CONVERT(UNIX_TIMESTAMP(now()), CHAR (41));
    SET N_ROOM_CODE = CONCAT(N_ROOM_CODE, N_USER_NAME);
    INSERT INTO ROOMS VALUES(N_ROOM_CODE, N_USER_NAME, N_PASSWORD, N_IS_DUAL, MODE);
    INSERT INTO INFO_ROOM(ROOM_CODE, ROOM_NAME) VALUES(N_ROOM_CODE, N_ROOM_NAME);
    INSERT INTO ROOM_MEMBER(ROOM_CODE, USER_NAME_MEMBER) VALUES(N_ROOM_CODE, N_USER_NAME);
END; $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE PROC_GET_PUBLIC_INFO_OF_ROOM(
    IN N_ROOM_CODE VARCHAR(41))
BEGIN
    SELECT A.ROOM_CODE, ROOM_NAME 
    FROM INFO_ROOM B, ROOMS C
    WHERE N_ROOM_CODE = A.ROOM_CODE AND A.ROOM_CODE = B.ROOM_CODE AND B.ROOM_CODE = C.ROOM_CODE; 
END; $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE PROC_GET_ALL_PUBLIC_ROOM()
BEGIN
    SELECT B.ROOM_CODE, ROOM_NAME 
    FROM INFO_ROOM B, ROOMS C
    WHERE IS_DUAL = FALSE AND B.ROOM_CODE = C.ROOM_CODE AND PRIVATE = FALSE; 
END; $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE PROC_JOIN_ROOM(
    IN N_ROOM_CODE VARCHAR(41),
    IN N_USER_NAME VARCHAR(30),
    IN N_PASSWORD VARCHAR(64))
BEGIN
	IF EXISTS (SELECT ROOM_CODE FROM ROOMS WHERE ROOM_CODE = N_ROOM_CODE AND PASSWORD = N_PASSWORD)
    THEN
		INSERT INTO ROOM_MEMBER VALUES(N_ROOM_CODE, N_USER_NAME);
	END IF;
END; $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE PROC_CREATE_DUO_CHAT(
    IN N_USER_NAME VARCHAR(30),
    IN N_USER_NAME_2 VARCHAR(30))
BEGIN
    DECLARE CONCAT_USER_NAME VARCHAR(41);
    SET CONCAT_USER_NAME = CONCAT(N_USER_NAME, "#", N_USER_NAME_2);
    CALL PROC_CREATE_ROOM(CONCAT_USER_NAME, CONCAT_USER_NAME, "#", TRUE, TRUE);
END; $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE PROC_CHECK_DUO_CHAT(
    IN N_CONCAT_USER_NAME VARCHAR(41))
BEGIN
    SELECT ROOM_CODE
    FROM ROOMS
    WHERE ROOMS.ROOM_CODE LIKE N_CONCAT_USER_NAME AND PASSWORD = "#";
END; $$
DELIMITER ;

-- -------------------------------ROOM----------------------------------------

-- -------------------------------CHAT----------------------------------------
DELIMITER $$
CREATE PROCEDURE PROC_SEND_MESSAGE(
    IN N_ROOM_CODE VARCHAR(41),
    IN N_USER_NAME VARCHAR(30),
    IN N_CONTENT NVARCHAR(1000))
BEGIN
    INSERT INTO CHAT_ROOMS_HISTORY VALUES(N_ROOM_CODE, N_USER_NAME, N_CONTENT, UNIX_TIMESTAMP(now()));
END; $$
DELIMITER ;

DELIMITER $$
CREATE PROCEDURE PROC_GET_HISTORY_OF_CHAT_ROOM(
    IN N_ROOM_CODE VARCHAR(41))
BEGIN
    SELECT * FROM CHAT_ROOMS_HISTORY WHERE ROOM_CODE LIKE N_ROOM_CODE ORDER BY TIME ASC; 
END; $$
DELIMITER ;
---------------------------------CHAT----------------------------------------

----------------------------------TRIGGER------------------------------------------
DELIMITER $$
CREATE TRIGGER TRIG_CREATE_ACCOUNT AFTER INSERT
    ON ACCOUNT
    FOR EACH ROW
    BEGIN
        CALL PROC_INSERT_LOG_EVENT(CONCAT("CREATE ACCOUNT WITH USER NAME : ", NEW.USER_NAME));
    END$$
 DELIMITER ;

DELIMITER $$
CREATE TRIGGER TRIG_UPDATE_ACCOUNT AFTER UPDATE
    ON ACCOUNT
    FOR EACH ROW
    BEGIN
        IF NEW.USER_NAME LIKE "#%" THEN CALL PROC_INSERT_LOG_EVENT(CONCAT("DELETE ACCOUNT WITH USER NAME : ", NEW.USER_NAME));
        ELSE
            CALL PROC_INSERT_LOG_EVENT(CONCAT("UPDATE ACCOUNT PASSWORD WITH USER NAME : ", NEW.USER_NAME));
		END IF;
    END $$
 DELIMITER ;

-- ---------------------------------TRIGGER----------------------------------------- --
-- CALL PROC_DELETE_ACCOUNT("tttt");
-- CALL PROC_CHANGE_PASSWORD_ACCOUNT ("MON", "YEYEYE");
CALL PROC_INSERT_ACCOUNT ("Bamboo","6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b", "tamdaulong207@gmail.com");
CALL PROC_INSERT_ACCOUNT ("KarlMarx", "6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b", "communist@gmail.com");
CALL PROC_INSERT_ACCOUNT ("tttt","e3b98a4da31a127d4bde6e43033f66ba274cab0eb7eb1c70ec41402bf6273dd8","a@gmail.com");
-- CALL PROC_INSERT_ACCOUNT ("test","a");
CALL PROC_UPDATE_INFO_USER("karlMarx", "Karl Marx", 1544854215, true, "communist@gmail.com", "00000001");
CALL PROC_CREATE_ROOM("KarlMarx", "","KarlMarx", FALSE, FALSE);
CALL PROC_SEND_MESSAGE("1544854215Bamboo", "Bamboo", "aaaaA");
CALL PROC_GET_HISTORY_OF_CHAT_ROOM("1544854215Bamboo");
-- CALL PROC_JOIN_ROOM("-- 1544663293TTTT", "Bamboo", "-");
CALL PROC_JOIN_ROOM("1544854215Bamboo", "a","-");
SELECT * FROM ROOMS WHERE ROOM_CODE LIKE "1544854215Bamboo" AND ROOMS.PASSWORD = "-";
CALL PROC_FIND_USER("t");
-- SELECT * FROM `group` 
-- System.currentTimeMillis()
-- DELETE  FROM `ACCOUNT` WHERE PASSWORD = "XXX";
DELETE from CHAT_ROOMS_HISTORY WHERE 1=1;
DELIMITER $$

END; $$
DELIMITER ;
