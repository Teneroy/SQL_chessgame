/*_____________PROC INVITE___________*/

DELIMITER //
CREATE PROCEDURE INVITE(user_login varchar(50), user2_login varchar(50), user_password varchar(50))
invite_label : BEGIN
    DECLARE userid INT UNSIGNED DEFAULT 0;
    DECLARE userid2 INT UNSIGNED DEFAULT 0;
    IF(user2_login = user_login)
    THEN
        SELECT "INVITE YOURSELF";
        LEAVE invite_label;
    END IF;
    SET userid2 = getUserId(user2_login);
    IF(userid2 IS NULL)
    THEN
        SELECT "NULL INVITED";
        LEAVE invite_label;
    END IF;
    IF(not checkPassword(user_login, user_password))
    THEN
        SELECT "INCORRECT PSWD";
        LEAVE invite_label;
    END IF;
    SET userid = getUserId(user_login);
    IF(inviteExists(userid, userid2))
    THEN
        SELECT "EXIST";
        LEAVE invite_label;
    END IF;
    INSERT INTO invites(id_inviting, id_invited, date_inv, confirm) VALUES(userid, userid2, CURRENT_DATE, false);
    SELECT "OK";
END //

DELIMITER //
CREATE PROCEDURE WAITRESPONSE(user_login varchar(50), user2_login varchar(50), user_password varchar(50))
waitresponse_label : BEGIN
    DECLARE userid INT UNSIGNED DEFAULT 0;
    DECLARE userid2 INT UNSIGNED DEFAULT 0;
    IF(user2_login = user_login)
    THEN
        SELECT "WAIT BY YOURSELF";
        LEAVE waitresponse_label;
    END IF;
    SET userid2 = getUserId(user2_login);
    IF(userid2 IS NULL)
    THEN
        SELECT "NULL INVITED";
        LEAVE waitresponse_label;
    END IF;
    IF(not checkPassword(user_login, user_password))
    THEN
        SELECT "INCORRECT PSWD";
        LEAVE waitresponse_label;
    END IF;
    SET userid = getUserId(user_login);
    IF((SELECT confirm FROM invites WHERE id_inviting = userid AND id_invited = userid2) = FALSE)
    THEN
        SELECT "WAITING";
        LEAVE waitresponse_label;
    ELSE
        DELETE FROM invites WHERE id_inviting = userid AND id_invited = userid2;
        SELECT id_game FROM usergames WHERE id_user = userid2;
    END IF;
END //

DELIMITER //
CREATE PROCEDURE INVITELISTENER(user_login varchar(50), user_password varchar(50))
invitelistener_label : BEGIN
    DECLARE userid INT UNSIGNED DEFAULT 0;
    DECLARE userid2 INT UNSIGNED DEFAULT 0;
    IF(not checkPassword(user_login, user_password))
    THEN
        SELECT "INCORRECT PSWD";
        LEAVE invitelistener_label;
    END IF;
    SET userid = getUserId(user_login);
    IF(NOT EXISTS (SELECT 1 FROM invites WHERE id_invited = userid LIMIT 1))
    THEN
        SELECT "WAITING";
        LEAVE invitelistener_label;
    END IF;
    SET userid2 = (SELECT id_inviting FROM invites WHERE id_invited = userid LIMIT 1);
	SELECT login FROM users WHERE id_user = userid2;
END //

DELIMITER //
CREATE PROCEDURE CREATEGAME(user_login varchar(50), user_password varchar(50), user2_login varchar(50))
creategame_label : BEGIN
    DECLARE userid INT UNSIGNED DEFAULT 0;
    DECLARE userid2 INT UNSIGNED DEFAULT 0;
    DECLARE user1Color CHAR(5);
    DECLARE user2Color CHAR(5);
    IF(user2_login = user_login)
    THEN
        SELECT "GAME WITH YOURSELF";
        LEAVE creategame_label;
    END IF;
    SET userid2 = getUserId(user2_login);
    IF(userid2 IS NULL)
    THEN
        SELECT "USER2 NULL";
        LEAVE creategame_label;
    END IF;
    IF(not checkPassword(user_login, user_password))
    THEN
        SELECT "INCORRECT PSWD";
        LEAVE creategame_label;
    END IF;
    SET userid = getUserId(user_login);
    IF(NOT EXISTS (SELECT 1 FROM invites WHERE id_inviting = userid2 AND id_invited = userid ))
    THEN
        SELECT "NOT INVITED";
        LEAVE creategame_label;
    END IF;
    IF(RAND() > 0.5)
    THEN
        SET user1Color = 'white';
        SET user2Color = 'black';
    ELSE
        SET user2Color = 'white';
        SET user1Color = 'black';
    END IF;
    /*SET autocommit=0;
    START TRANSACTION;*/
        UPDATE invites SET confirm = TRUE WHERE id_inviting = userid2 AND id_invited = userid;
        INSERT INTO games(id_game, winner, moves) VALUES(NULL, NULL, 0);
        INSERT INTO usercolor(id_user, color) VALUES (userid, user1Color);
        INSERT INTO usercolor(id_user, color) VALUES (userid2, user2Color);
        INSERT INTO usergames(id_game, id_user) VALUES ((SELECT MAX(id_game) FROM  games), userid);
        INSERT INTO usergames(id_game, id_user) VALUES ((SELECT MAX(id_game) FROM  games), userid2);
        CALL FILLBOARD(user_login, user_password, user2_login);
    /*COMMIT;*/
    SELECT id_game FROM usergames WHERE id_user = userid;
END //

DELIMITER //
CREATE PROCEDURE FILLBOARD(user_login varchar(50), user_password varchar(50), user2_login varchar(50))
fillboard_label : BEGIN
    DECLARE userid INT UNSIGNED DEFAULT getUserId(user_login);
    DECLARE userid2 INT UNSIGNED DEFAULT getUserId(user2_login);
    DECLARE blackid INT UNSIGNED DEFAULT 0;
    DECLARE whiteid INT UNSIGNED DEFAULT 0;
    DECLARE i INT UNSIGNED DEFAULT 0;
    DECLARE j INT UNSIGNED DEFAULT 0;
    IF(not checkPassword(user_login, user_password))
    THEN
        SELECT "INCORRECT PSWD";
        LEAVE fillboard_label;
    END IF;
    IF(user2_login = user_login)
    THEN
        SELECT "SAME LOGINS";
        LEAVE fillboard_label;
    END IF;
    IF(userid2 IS NULL)
    THEN
        SELECT "USER2 NULL";
        LEAVE fillboard_label;
    END IF;
    IF((SELECT color FROM usercolor WHERE id_user = userid) = 'white')
    THEN
        SET blackid = userid2;
        SET whiteid = userid;
    ELSE
        SET blackid = userid;
        SET whiteid = userid2;
    END IF;
    SET i = 2;
    SET j = 1;
    label1: LOOP
        INSERT INTO boardfigures(id_user, `row`, `column`, `type`) VALUES (whiteid, 2, j, 'pawn');
        INSERT INTO boardfigures(id_user, `row`, `column`, `type`) VALUES (blackid, 7, j, 'pawn');
        IF (j = 8) THEN
            LEAVE label1;
        END IF;
        SET j = j + 1;
        ITERATE label1;
    END LOOP label1;
INSERT INTO boardfigures(id_user, `row`, `column`, `type`) VALUES (whiteid, 1, 1, 'bishop');
    INSERT INTO boardfigures(id_user, `row`, `column`, `type`) VALUES (blackid, 8, 1, 'bishop');
    INSERT INTO boardfigures(id_user, `row`, `column`, `type`) VALUES (whiteid, 1, 8, 'bishop');
    INSERT INTO boardfigures(id_user, `row`, `column`, `type`) VALUES (blackid, 8, 8, 'bishop');
    INSERT INTO boardfigures(id_user, `row`, `column`, `type`) VALUES (whiteid, 1, 2, 'knight');
    INSERT INTO boardfigures(id_user, `row`, `column`, `type`) VALUES (blackid, 8, 2, 'knight');
    INSERT INTO boardfigures(id_user, `row`, `column`, `type`) VALUES (whiteid, 1, 7, 'knight');
    INSERT INTO boardfigures(id_user, `row`, `column`, `type`) VALUES (blackid, 8, 7, 'knight');
    INSERT INTO boardfigures(id_user, `row`, `column`, `type`) VALUES (whiteid, 1, 3, 'rook');
    INSERT INTO boardfigures(id_user, `row`, `column`, `type`) VALUES (blackid, 8, 3, 'rook');
    INSERT INTO boardfigures(id_user, `row`, `column`, `type`) VALUES (whiteid, 1, 6, 'rook');
    INSERT INTO boardfigures(id_user, `row`, `column`, `type`) VALUES (blackid, 8, 6, 'rook');
    INSERT INTO boardfigures(id_user, `row`, `column`, `type`) VALUES (whiteid, 1, 4, 'king');
    INSERT INTO boardfigures(id_user, `row`, `column`, `type`) VALUES (blackid, 8, 4, 'king');
    INSERT INTO boardfigures(id_user, `row`, `column`, `type`) VALUES (whiteid, 1, 5, 'queen');
    INSERT INTO boardfigures(id_user, `row`, `column`, `type`) VALUES (blackid, 8, 5, 'queen');
END //

DELIMITER //
CREATE PROCEDURE LISTUSER(user_login varchar(50), user_password varchar(50))
BEGIN
    IF(checkPassword(user_login, user_password))
    THEN
        SELECT login FROM users;
    ELSE
        SELECT "DENIED";
    END IF;
END //

/*_____________FUNC INVITE___________*/

DELIMITER //
CREATE FUNCTION inviteExists(id1 int unsigned, id2 int unsigned)
RETURNS BOOLEAN
BEGIN
    RETURN EXISTS (SELECT 1 FROM invites WHERE id_inviting = id1 AND id_invited = id2);
END //

/*_____________PROC LOGIN___________*/

DELIMITER //
CREATE PROCEDURE LOGIN(user_login varchar(50), user_password varchar(50))
BEGIN
    IF(checkPassword(user_login, user_password))
    THEN
        SELECT "OK";
    ELSE
        SELECT "DENIED";
    END IF;
END //

DELIMITER //
CREATE PROCEDURE REGISTER(user_login varchar(50), user_password varchar(50), user_name varchar(50))
BEGIN
    IF (NOT EXISTS (SELECT 1 FROM users WHERE login = user_login))
    THEN
        INSERT INTO users(id_user, login, `password`, `name`) VALUES(NULL, user_login, (SELECT SHA2(user_password, 256)), user_name);
        SELECT "OK";
    ELSE
        SELECT "USER EXIST";
    END IF;
END //

/*_____________FUNC LOGIN___________*/

DELIMITER //
CREATE FUNCTION checkPassword(user_login VARCHAR(50), user_password VARCHAR(50))
RETURNS BOOLEAN
BEGIN
    RETURN EXISTS (SELECT 1 FROM users WHERE login = user_login AND `password` = (SELECT LEFT((SELECT SHA2(user_password, 256)), 50)));
END //

DELIMITER //
CREATE FUNCTION getUserId(user_login VARCHAR(50))
RETURNS INT
BEGIN
    RETURN (SELECT id_user FROM users WHERE `login` = user_login);
END //

/*____________PROC GAME____________*/

DELIMITER //
CREATE PROCEDURE MAKEMOVE(user_login varchar(50), user_password varchar(50), row_from tinyint unsigned, column_from tinyint unsigned, row_to tinyint unsigned, column_to tinyint unsigned, game_f int unsigned)
makemove_label : BEGIN
    DECLARE typefigure VARCHAR(15);
    DECLARE userid INT UNSIGNED DEFAULT 0;
    DECLARE userid2 INT UNSIGNED DEFAULT 0;
    DECLARE color CHAR(5);
    DECLARE movecount INT UNSIGNED;
    IF(not checkPassword(user_login, user_password))
    THEN
        SELECT "INCORRECT PSWD";
        LEAVE makemove_label;
    END IF;
    IF((row_from = row_to) AND (column_from = column_to))
    THEN
        SELECT "INCORRECT MOVE";
        LEAVE makemove_label;
    END IF;
    IF((SELECT winner FROM games WHERE id_game = game_f) IS NOT NULL)
    THEN
        IF((SELECT winner FROM games WHERE id_game = game_f) = 0)
        THEN
            SELECT "DRAW";
            LEAVE makemove_label;
        END IF;
        SELECT "WIN,", (SELECT winner FROM games WHERE id_game = game_f);
        LEAVE makemove_label;
    END IF;
    SET color = (SELECT color FROM usercolor WHERE id_user = userid);
    SET movecount = (SELECT moves FROM games WHERE id_game = game_f);
    IF( (color = 'white') AND (movecount % 2) <> 0 )
    THEN
        SELECT 'WAITING';
        LEAVE makemove_label;
    ELSEIF( (color = 'black') AND (movecount % 2) = 0 )
    THEN
        SELECT 'WAITING';
        LEAVE makemove_label;
    END IF;
    SET userid = getUserId(user_login);
    SET userid2 = (SELECT id_user FROM usergames WHERE id_game = game_f AND id_user <> userid);
    SET typefigure = (SELECT `type` FROM  boardfigures WHERE id_user = userid AND `row` = row_from AND `column` = column_from);
    IF(checkFor(userid, userid2, row_from, column_from, row_to, column_to, typefigure))
    THEN
        SET userid2 = (SELECT id_user FROM usergames WHERE id_game = game_f AND id_user <> userid);
        SET autocommit = 0;
        START TRANSACTION;
        UPDATE boardfigures SET `row` = row_to, `column` = column_to WHERE id_user = userid AND `row` = row_from AND `column` = column_from;
        DELETE FROM boardfigures WHERE id_user = userid2 AND `row` = row_to AND `column` = column_to;
        UPDATE games SET moves = (movecount + 1) WHERE id_game = game_f;
        SET movecount = (SELECT COUNT(*) FROM moves WHERE id_user = userid);
        INSERT INTO moves(id_user, move_number, `row_from`, `column_from`, `row_to`, `column_to`) VALUES(userid, (movecount  + 1 ), row_from, column_from, row_to, column_to);
        COMMIT;
        IF(checkWin(userid, userid2))
        THEN
            UPDATE games SET winner = userid WHERE id_game = game_f;
            SELECT "WIN,", (SELECT winner FROM games WHERE id_game = game_f);
            LEAVE makemove_label;
        END IF;
        IF(checkDraw(userid, userid2))
        THEN
            UPDATE games SET winner = 0 WHERE id_game = game_f;
            SELECT "DRAW";
            LEAVE makemove_label;
        END IF;
        SELECT row_from, column_from, row_to, column_to FROM moves WHERE id_user = userid ORDER BY move_number DESC LIMIT 1;
    ELSE
        SELECT "INCORRECT MOVE";
    END IF;
END //

DELIMITER //
CREATE PROCEDURE CHECKSTATE(user_login varchar(50), user_password varchar(50), game_f int unsigned)
checkstate_label : BEGIN
    DECLARE userid2 INT UNSIGNED;
    DECLARE userid INT UNSIGNED;
    DECLARE color CHAR(5);
    DECLARE movecount INT UNSIGNED;
    DECLARE winnergame INT UNSIGNED;
    IF(not checkPassword(user_login, user_password))
    THEN
        SELECT  "INCORRECT PSWD";
        LEAVE checkstate_label;
    END IF;
    SET winnergame = (SELECT winner FROM games WHERE id_game = game_f);
    IF(winnergame IS NULL)
    THEN
        SET userid = getUserId(user_login);
        SET userid2 = (SELECT id_user FROM usergames WHERE id_user <> userid AND id_game = game_f);
        SET color = (SELECT `usercolor`.`color` FROM usercolor WHERE id_user = userid);
        SET movecount = (SELECT moves FROM games WHERE id_game = game_f);
        IF( (color = 'white') AND (movecount % 2) <> 0 )
        THEN
            SELECT 'WAITING';
            LEAVE checkstate_label;
        ELSEIF( (color = 'black') AND (movecount % 2) = 0 )
        THEN
            SELECT 'WAITING';
            LEAVE checkstate_label;
        END IF;
        SELECT row_from, column_from, row_to, column_to, move_number FROM moves WHERE id_user = userid2 ORDER BY move_number DESC LIMIT 1;
        LEAVE checkstate_label;
    END IF;
    IF(winnergame = 0)
    THEN
        SELECT "DRAW";
    ELSE
        SELECT "WIN,",winnergame;
    END IF;
END //

DELIMITER //
CREATE PROCEDURE GETCOLOR(user_login varchar(50))
BEGIN
    SELECT color FROM usercolor WHERE id_user = getUserId(user_login);
END //



/*____________FUNC GAME____________*/

DELIMITER //
CREATE FUNCTION checkDraw(user_f INT UNSIGNED, user2_f INT UNSIGNED)
RETURNS BOOLEAN
BEGIN
    DECLARE u1count INT DEFAULT 0;
    DECLARE u2count INT DEFAULT 0;
    DECLARE type_fig VARCHAR(15) DEFAULT "";
    IF((SELECT SUM(cnt) FROM (SELECT COUNT(*) as cnt FROM boardfigures WHERE (id_user = 9 OR id_user = 7) GROUP BY id_user) as m1) = 2)
    THEN
        RETURN TRUE;
    END IF;
    SET u1count = (SELECT COUNT(*) FROM boardfigures WHERE id_user = user_f GROUP BY id_user);
    SET u2count = (SELECT COUNT(*) FROM boardfigures WHERE id_user = user2_f GROUP BY id_user);
    IF(u1count = 2 AND u2count = 1)
    THEN
        SET type_fig = (SELECT `type` FROM boardfigures WHERE id_user = user_f AND `type` <> 'king');
        RETURN ( type_fig =  'knight' OR type_fig = 'bishop' );
    END IF;
    IF(u1count = 1 AND u2count = 2)
    THEN
        SET type_fig = (SELECT `type` FROM boardfigures WHERE id_user = user2_f AND `type` <> 'king');
        RETURN ( type_fig =  'knight' OR type_fig = 'bishop' );
    END IF;
    IF(u1count = 2 AND u2count = 2)
    THEN
        SET type_fig = (SELECT `type` FROM boardfigures WHERE id_user = user_f AND `type` <> 'king');
        RETURN ( type_fig = 'bishop' AND ((SELECT `type` FROM boardfigures WHERE id_user = user2_f AND `type` <> 'king') = 'bishop') );
    END IF;
    IF(u1count = 1 AND u2count = 3)
    THEN
        RETURN ((SELECT COUNT(*) FROM boardfigures WHERE id_user = user2_f AND `type` <> 'king' GROUP BY id_user) = 2);
    END IF;
    IF(u1count = 3 AND u2count = 1)
    THEN
        RETURN ((SELECT COUNT(*) FROM boardfigures WHERE id_user = user_f AND `type` <> 'king' GROUP BY id_user) = 2);
    END IF;
    RETURN FALSE;
END //

DELIMITER //
CREATE FUNCTION checkWin(user_f INT UNSIGNED, user2_f INT UNSIGNED)
RETURNS BOOLEAN
BEGIN
    DECLARE kPosI TINYINT DEFAULT 0;
    DECLARE kPosJ TINYINT DEFAULT 0;
    SET kPosI = (SELECT `row` FROM boardfigures WHERE id_user = user2_f AND `type` = 'king');
    SET kPosJ = (SELECT `column` FROM boardfigures WHERE id_user = user2_f AND `type` = 'king');
    IF( not dangerPos(user2_f, user_f, kPosI, kPosJ) )
    THEN
        RETURN FALSE;
    END IF;
    IF( isMatKing(user2_f, user_f, kPosI, kPosJ) )
    THEN
        RETURN TRUE;
    END IF;
    RETURN FALSE;
END //

DELIMITER //
CREATE FUNCTION isMatKing(user_f INT UNSIGNED, user2_f INT UNSIGNED, king_row TINYINT UNSIGNED, king_col TINYINT UNSIGNED)
RETURNS BOOLEAN
BEGIN
    DECLARE possibleMoves INT DEFAULT 8;
    DECLARE i INT DEFAULT 0;
    DECLARE j INT DEFAULT 0;
    IF(king_col - 1 = 0)
    THEN
        SET possibleMoves = (possibleMoves - 1);
    ELSEIF( (NOT EXISTS(SELECT 1 FROM boardfigures WHERE id_user = user_f AND `row` = king_row AND `column` = (king_col - 1))) )
    THEN
        IF(dangerPos(user2_f, user_f, king_row, (king_col - 1)))
        THEN
            SET possibleMoves = (possibleMoves - 1);
        END IF;
	ELSE
    	SET possibleMoves = (possibleMoves - 1);
    END IF;

    IF(king_col + 1 = 9)
    THEN
        SET possibleMoves = (possibleMoves - 1);
    ELSEIF( (NOT EXISTS(SELECT 1 FROM boardfigures WHERE id_user = user_f AND `row` = king_row AND `column` = (king_col + 1))) )
    THEN
        IF(dangerPos(user2_f, user_f, king_row, (king_col + 1)))
        THEN
            SET possibleMoves = (possibleMoves - 1);
        END IF;
    ELSE
    	SET possibleMoves = (possibleMoves - 1);
    END IF;
    SET i = king_row + 1;
    SET j = -1;
    IF (i <> 9)
    THEN
        label1: LOOP
            IF (j = 2) THEN
                LEAVE label1;
            END IF;
            IF((king_col + j) = 0 OR (king_col + j) = 9)
            THEN
                SET possibleMoves = (possibleMoves - 1);
            ELSEIF( NOT EXISTS(SELECT 1 FROM boardfigures WHERE id_user = user_f AND `row` = i AND `column` = (king_col + j)) )
            THEN
                IF(dangerPos(user2_f, user_f, i, (king_col + j)))
                THEN
                    SET possibleMoves = (possibleMoves - 1);
                END IF;
            ELSE
            	SET possibleMoves = (possibleMoves - 1);
            END IF;
            SET j = j + 1;
            ITERATE label1;
        END LOOP label1;
    ELSE
        SET possibleMoves = (possibleMoves - 3);
    END IF;
    SET i = king_row - 1;
    SET j = -1;
    IF (i <> 0)
    THEN
        label1: LOOP
            IF (j = 2) THEN
                LEAVE label1;
            END IF;
            IF((king_col + j) = 0 OR (king_col + j) = 9)
            THEN
                SET possibleMoves = (possibleMoves - 1);
            ELSEIF( NOT EXISTS(SELECT 1 FROM boardfigures WHERE id_user = user_f AND `row` = i AND `column` = (king_col + j)) )
            THEN
                IF(dangerPos(user2_f, user_f, i, (king_col + j)))
                THEN
                    SET possibleMoves = (possibleMoves - 1);
                END IF;
            ELSE
            	SET possibleMoves = (possibleMoves - 1);
            END IF;
            SET j = j + 1;
            ITERATE label1;
        END LOOP label1;
    ELSE
        SET possibleMoves = (possibleMoves - 3);
    END IF;
    RETURN (possibleMoves <= 0);
END //

DELIMITER //
CREATE FUNCTION dangerPos(user_f INT UNSIGNED, user2_f INT UNSIGNED, king_row TINYINT UNSIGNED, king_col TINYINT UNSIGNED)
RETURNS BOOLEAN
BEGIN
	DECLARE i TINYINT;
    DECLARE j TINYINT;
    DECLARE t VARCHAR (15);
    DECLARE flag BOOLEAN DEFAULT FALSE;
    DECLARE done INT DEFAULT FALSE;
    DECLARE cursor_i CURSOR FOR SELECT `row`, `column`, `type` FROM boardfigures WHERE id_user = user2_f;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    OPEN cursor_i;
    read_loop: LOOP
        FETCH cursor_i INTO i, j, t;
        IF(done)
        THEN
            LEAVE read_loop;
        END IF;
        IF(t = "pawn")
        THEN
            SET flag = checkPawn(user2_f, user_f, i, j, king_row, king_col);
      	ELSEIF(t = "rook")
        THEN
            SET flag = checkRook(user2_f, user_f, i, j, king_row, king_col);
        ELSEIF(t = "knight")
        THEN
            SET flag = checkKnight(user2_f, user_f, i, j, king_row, king_col);
        ELSEIF(t = "bishop")
        THEN
            SET flag = checkBishop(user2_f, user_f, i, j, king_row, king_col);
        ELSEIF(t = "queen")
        THEN
            IF(!checkRook(user2_f, user_f, i, j, king_row, king_col))
            THEN
                SET flag = checkBishop(user2_f, user_f, i, j, king_row, king_col);
            ELSE
                SET flag = TRUE;
            END IF;
        END IF;
        IF(flag) THEN
            LEAVE read_loop;
        END IF;

        ITERATE read_loop;
    END LOOP;
    CLOSE cursor_i;
    RETURN flag;
END //


DELIMITER //
CREATE FUNCTION checkFor(user_f INT UNSIGNED, user2_f INT UNSIGNED, row_from TINYINT UNSIGNED, col_from TINYINT UNSIGNED, row_to TINYINT UNSIGNED, col_to TINYINT UNSIGNED, fig_type varchar(15))
RETURNS BOOLEAN
BEGIN
IF(fig_type = "pawn")
THEN
    RETURN checkPawn(user_f, user2_f, row_from, col_from, row_to, col_to);
END IF;
IF(fig_type = "rook")
THEN
    RETURN checkRook(user_f, user2_f, row_from, col_from, row_to, col_to);
END IF;
IF(fig_type = "knight")
THEN
    RETURN checkKnight(user_f, user2_f, row_from, col_from, row_to, col_to);
END IF;
IF(fig_type = "bishop")
THEN
    RETURN checkBishop(user_f, user2_f, row_from, col_from, row_to, col_to);
END IF;
IF(fig_type = "king")
THEN
    RETURN checkKing(user_f, user2_f, row_from, col_from, row_to, col_to);
END IF;
IF(fig_type = "queen")
THEN
    IF(!checkRook(user_f, user2_f, row_from, col_from, row_to, col_to))
    THEN
        RETURN checkBishop(user_f, user2_f, row_from, col_from, row_to, col_to);
    ELSE
        RETURN TRUE;
    END IF;
END IF;
RETURN TRUE;
END //

DELIMITER //
CREATE FUNCTION checkKing(user_f INT UNSIGNED, user2_f INT UNSIGNED, row_from TINYINT UNSIGNED, col_from TINYINT UNSIGNED, row_to TINYINT UNSIGNED, col_to TINYINT UNSIGNED)
RETURNS BOOLEAN
BEGIN
	DECLARE col1 INT DEFAULT col_from;
    DECLARE col2 INT DEFAULT col_to;
    DECLARE row1 INT DEFAULT row_from;
    DECLARE row2 INT DEFAULT row_to;
    IF(row_from = row_to AND col_from = col_to)
    THEN
        RETURN FALSE;
    END IF;
    IF(EXISTS (SELECT 1 FROM boardfigures WHERE `row` = row_to AND `column` = col_to AND id_user = user_f))
    THEN
        RETURN FALSE;
    END IF;
    IF((SELECT ABS(row1 - row2)) > 1)
    THEN
        RETURN FALSE;
    END IF;
    IF((SELECT ABS(col1 - col2)) > 1)
    THEN
        RETURN FALSE;
    END IF;
    IF(dangerPos(user_f, user2_f, row_to, col_to))
    THEN
        RETURN FALSE;
    END IF;
    RETURN TRUE;
END //

DELIMITER //
CREATE FUNCTION checkPawn(user_f INT UNSIGNED, user2_f INT UNSIGNED, row_from TINYINT, col_from TINYINT, row_to TINYINT, col_to TINYINT)
RETURNS BOOLEAN
BEGIN
    DECLARE color CHAR(5) DEFAULT '';
    DECLARE existSecFigure INT UNSIGNED DEFAULT 0;
    DECLARE rf INT DEFAULT row_from;
    DECLARE rt INT DEFAULT row_to;
    DECLARE cf INT DEFAULT col_from;
    DECLARE ct INT DEFAULT col_to;
    SET color = (SELECT color FROM usercolor WHERE id_user = user_f);
    IF( (color = 'white' AND row_to < row_from) OR (color = 'black' AND row_from < row_to) OR ((SELECT ABS(rt - rf)) <> 1) )
    THEN
        RETURN FALSE;
    END IF;
    SET existSecFigure = (SELECT id_user FROM boardfigures WHERE `row` = row_to AND `column` = col_to AND (id_user = user_f OR id_user = user2_f));
    IF( existSecFigure IS NOT NULL )
    THEN
        IF(existSecFigure = user_f)
        THEN
            RETURN FALSE;
        END IF;
        IF(col_to = col_from)
        THEN
            RETURN FALSE;
        END IF;
    END IF;
    IF((existSecFigure IS NULL) AND (col_to <> col_from))
    THEN
        RETURN FALSE;
    END IF;
    RETURN TRUE;
END //

DELIMITER //
CREATE FUNCTION checkRook(user_f INT UNSIGNED, user2_f INT UNSIGNED, row_from TINYINT UNSIGNED, col_from TINYINT UNSIGNED, row_to TINYINT UNSIGNED, col_to TINYINT UNSIGNED)
RETURNS BOOLEAN
BEGIN
    DECLARE oper1 INT DEFAULT 1;
    DECLARE oper2 INT DEFAULT 1;
    DECLARE i INT DEFAULT 1;
    DECLARE j INT DEFAULT 1;
    DECLARE rf INT DEFAULT row_from;
    DECLARE rt INT DEFAULT row_to;
    DECLARE cf INT DEFAULT col_from;
    DECLARE ct INT DEFAULT col_to;
    IF( EXISTS (SELECT  1 FROM boardfigures WHERE id_user = user_f AND `row` = row_to AND `column` = col_to) )
    THEN
        RETURN FALSE;
    END IF;
    IF(row_from <> row_to)
    THEN
        IF ((SELECT ABS(rf - rt)) <> (SELECT ABS(cf - ct)))
        THEN

            RETURN FALSE;
        END IF;
        IF(row_from < row_to)
        THEN
            SET oper1 = 1;
        ELSE
            SET oper1 = -1;
        END IF;
        IF(col_from < col_to)
        THEN
            SET oper2 = 1;
        ELSE
            SET oper2 = -1;
        END IF;
        SET i = row_from;
        SET j = col_from;
        label_uniq: LOOP
            SET i = i + oper1;
            SET j = j + oper2;
            IF (i = row_to)
            THEN
                LEAVE label_uniq;
            END IF;
            IF (EXISTS (SELECT 1 FROM boardfigures WHERE (id_user = user_f OR id_user = user2_f) AND `row` = i AND `column` = j))
            THEN
                RETURN FALSE;
            END IF;
            ITERATE label_uniq;
        END LOOP label_uniq;
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END//

DELIMITER //
CREATE FUNCTION checkKnight(user_f INT UNSIGNED, user2_f INT UNSIGNED, row_from TINYINT , col_from TINYINT , row_to TINYINT , col_to TINYINT )
RETURNS BOOLEAN
BEGIN
    DECLARE cf INT default col_from;
    DECLARE ct int default col_to;
    DECLARE rf int default row_from;
    DECLARE rt int default row_to;
    IF(col_from = col_to OR row_from = row_to)
    THEN
        RETURN FALSE;
    END IF;
    IF( not ( ((SELECT ABS(cf - ct)) = 2 AND (SELECT  ABS(rf - rt)) = 1) OR ((SELECT  ABS(cf - ct)) = 1 AND (SELECT  ABS(rf - rt)) = 2) ) )
    THEN
        RETURN FALSE;
    END IF;
    IF( EXISTS (SELECT  1 FROM boardfigures WHERE id_user = user_f AND `row` = row_to AND `column` = col_to) )
    THEN
        RETURN FALSE;
    END IF;
    RETURN TRUE;
END //

DELIMITER //
CREATE FUNCTION checkBishop(user_f INT UNSIGNED, user2_f INT UNSIGNED, row_from TINYINT , col_from TINYINT , row_to TINYINT , col_to TINYINT )
RETURNS BOOLEAN
BEGIN
    DECLARE incI INT  DEFAULT 0;
    DECLARE incJ INT  DEFAULT 0;
    DECLARE i INT DEFAULT 0;
    DECLARE j INT DEFAULT 0;
    DECLARE cf INT default col_from;
    DECLARE ct int default col_to;
    DECLARE rf int default row_from;
    DECLARE rt int default row_to;
    IF( (SELECT ABS(rt - rf)) = (SELECT ABS(ct - cf)) )
    THEN
        RETURN FALSE;
    END IF;
    IF(col_to <> col_from AND row_to <> row_from)
    THEN
        RETURN FALSE;
    END IF;
    IF( EXISTS (SELECT  1 FROM boardfigures WHERE id_user = user_f AND `row` = row_to AND `column` = col_to) )
    THEN
        RETURN FALSE;
    END IF;
    if(row_to <> row_from)
    THEN
        IF( row_to > row_from )
        THEN
            SET incI = 1;
        ELSE
            SET incI = -1;
        END IF;
        SET i = row_from;
        label1_1: LOOP
            SET i = i + incI;
            IF (i = row_to) THEN
                LEAVE label1_1;
            END IF;
            IF (EXISTS (SELECT 1 FROM boardfigures WHERE (id_user = user_f OR id_user = user2_f) AND `row` = i AND `column` = col_to))
            THEN
                RETURN FALSE;
            END IF;
            ITERATE label1_1;
        END LOOP label1_1;
    ELSE
        IF( col_to > col_from)
        THEN
            SET incI = 1;
        ELSE
            SET incI = -1;
        END IF;
        SET i = col_from;
        label1_2: LOOP
            SET i = i + incI;
            IF (i = col_to) THEN
                LEAVE label1_2;
            END IF;
            IF (EXISTS (SELECT 1 FROM boardfigures WHERE (id_user = user_f OR id_user = user2_f) AND `row` = row_to AND `column` = i))
            THEN
                RETURN FALSE;
            END IF;
            ITERATE label1_2;
        END LOOP label1_2;
    END IF;
    RETURN TRUE;
END //

-- DELIMETER //
-- CREATE FUNCTION kingDanger(user_f INT UNSIGNED, user2_f INT UNSIGNED, king_row TINYINT UNSIGNED, king_col TINYINT UNSIGNED, en_row TINYINT UNSIGNED, en_col TINYINT UNSIGNED, en_type varchar(30))
-- RETURNS BOOLEAN
-- BEGIN
--     IF(en_type == "pawn")
--     THEN
--         IF(checkPaswn())
--         THEN
--             RETURN TRUE;
--         ELSE
--             RETURN FALSE;
--         END IF;
--     END IF;
--     IF(en_type == "king")
--     THEN
--         IF(checkPaswn())
--         THEN
--             RETURN TRUE;
--         ELSE
--             RETURN FALSE;
--         END IF;
--     END IF;
--     IF(en_type == "pawn")
--     THEN
--         IF(checkPaswn())
--         THEN
--             RETURN TRUE;
--         ELSE
--             RETURN FALSE;
--         END IF;
--     END IF;
-- END //

/*____________________________*/



-- DELIMITER //
-- CREATE PROCEDURE CREATEUSER(user_login varchar(50), user_password varchar(50), user_name varchar(50))
-- BEGIN
-- IF (exists(SELECT 1 FROM users WHERE login = user_login))
-- THEN
--     SELECT "OK";
-- ELSE
--     INSERT INTO Users VALUES(name, login, password, NULL);
-- END IF;
-- END //
--
-- DELIMITER //
-- CREATE PROCEDURE INVITE(id_inviting, id_invited, pswd)
-- BEGIN
-- IF not exists(SELECT 1 FROM users WHERE id_inviting = `id-user`)
-- THEN
--     SELECT "02";
-- END IF;
-- IF not exists(SELECT 1 FROM users WHERE id_invited = `id-user`)
-- THEN
--     SELECT "03";
-- END IF;
-- IF (exists(SELECT 1 FROM invites WHERE id_inviting = `id-inviting`))
-- THEN
--     DELETE FROM invites WHERE id_inviting = `id-inviting`;
-- END IF;
-- INSERT INTO invites VALUES(id_inviting, id_invited, GETDATE());
-- END //
--
-- DELIMITER //
-- CREATE PROCEDURE CHECKINVITE(id_user, pswd)
-- BEGIN
-- SET gameID = searchGame;
-- IF exists(gameID)
-- THEN
--     SELECT gameID;
-- END IF;
-- IF checkInvited(id_user)
-- THEN
--     SELECT "User was invited";
-- END IF;
-- SET idInvited = (SELECT `id-invited` FROM invites WHERE `id-inviting` = id_user)
-- IF idInvited is not null
-- THEN
--     DELETE FROM invites WHERE id_user = `id-inviting` AND idInvited = `id-invited`;
--     CALL CREATEGAME(id_user, idInvited);
-- END IF;
-- IF checkInviting(id_user)
-- THEN
--     SELECT "User is waiting for response";
-- END IF;
-- END //
--
-- DELIMITER //
-- CREATE PROCEDURE CHECKUSER(user_login, user_password)
-- BEGIN
-- SET RESULT = (SELECT 1 FROM users WHERE login = user_login AND password == user_password)
-- IF exists(RESULT)
-- THEN
--     SELECT "User was found";
-- ELSE
--     SELECT "User not found";
-- END IF;
-- END //
--
-- DELIMITER //
-- CREATE PROCEDURE GETUSERID(user_login, user_password)
-- BEGIN
-- SET RESULT = (SELECT `id-user` FROM users WHERE login = user_login AND password == user_password)
-- IF exists(RESULT)
-- THEN
--     SELECT RESULT;
-- ELSE
--     SELECT "User not found";
-- END IF;
-- END //
--
-- DELIMITER //
-- CREATE PROCEDURE MAKEMOVE(id_user, id_game, row, col)
-- BEGIN
--
-- END //
--
-- /*___________*/
--
-- DELIMETER //
-- CREATE FUNCTION checkInvited(id_invited INT UNSIGNED)
-- RETURNS BOOLEAN
-- BEGIN
-- RETURN EXISTS (SELECT 1 FROM invites WHERE `id-invited` = id_invited);
-- END //
--
-- DELIMETER //
-- CREATE FUNCTION checkInviting(id_inviting INT UNSIGNED)
-- RETURNS BOOLEAN
-- BEGIN
-- RETURN EXISTS (SELECT 1 FROM invites WHERE `id-inviting` = id_inviting);
-- END //
--
-- DELIMETER //
-- CREATE FUNCTION searchGame(id_user INT UNSIGNED)
-- RETURNS INT UNSIGNED
-- BEGIN
-- RETURN (SELECT `id-game-ug` FROM usergames WHERE `id-user-ug` = id_user);
-- END //





CREATE TABLE games(id_game int unsigned, winner int unsigned, moves int unsigned);
ALTER TABLE games ADD CONSTRAINT pk PRIMARY KEY(id_game);
ALTER TABLE `games` modify column id_game INT NOT NULL AUTO_INCREMENT;

CREATE TABLE users(id_user int unsigned, login varchar(50), password varchar(50), name varchar(50));
ALTER TABLE users ADD CONSTRAINT pk PRIMARY KEY(id_user);
ALTER TABLE `users` modify column id_user INT NOT NULL AUTO_INCREMENT;

CREATE TABLE invites(id_inviting int unsigned, id_invited int unsigned, date_inv DATE, confirm BOOLEAN);
ALTER TABLE invites ADD CONSTRAINT pk PRIMARY KEY(id_inviting, id_invited);

CREATE TABLE usercolor(id_user int unsigned, color char(5));
ALTER TABLE usercolor ADD CONSTRAINT pk PRIMARY KEY(id_user);

CREATE TABLE boardfigures(id_user int unsigned, `row` TINYINT UNSIGNED, `column` TINYINT UNSIGNED, type varchar(15));
ALTER TABLE boardfigures ADD CONSTRAINT pk PRIMARY KEY(id_user, `row`, `column`);

CREATE TABLE moves(id_user int unsigned, move_number int unsigned, row_from TINYINT UNSIGNED, column_from TINYINT UNSIGNED, row_to TINYINT UNSIGNED, column_to TINYINT UNSIGNED);
ALTER TABLE moves ADD CONSTRAINT pk PRIMARY KEY(id_user, move_number);

CREATE TABLE usergames(id_game int unsigned, id_user int unsigned);
ALTER TABLE usergames ADD CONSTRAINT pk PRIMARY KEY(id_game);

ALTER TABLE `usergames` ADD CONSTRAINT FOREIGN KEY(id_game) REFERENCES games(id_game);
ALTER TABLE `usergames` ADD CONSTRAINT FOREIGN KEY(id_user) REFERENCES users(id_user);
ALTER TABLE `usercolor` ADD CONSTRAINT FOREIGN KEY(id_user) REFERENCES users(id_user);
ALTER TABLE `boardfigures` ADD CONSTRAINT FOREIGN KEY(id_user) REFERENCES usercolor(id_user);
ALTER TABLE `moves` ADD CONSTRAINT FOREIGN KEY(id_user) REFERENCES users(id_user);
ALTER TABLE `invites` ADD CONSTRAINT FOREIGN KEY(id_invited) REFERENCES users(id_user);
ALTER TABLE `invites` ADD CONSTRAINT FOREIGN KEY(id_inviting) REFERENCES users(id_user);
