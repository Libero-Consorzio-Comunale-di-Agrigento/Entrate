alter trigger AD4.ISTANZE_TD disable;
/
delete from ad4.istanze ista where ista.istanza = '&user';
/
alter trigger AD4.ISTANZE_TD enable;
/

delete from gsd.databasechangelog dacl
where filename like '%Tr4GSD_g.sql%';
/

delete from ad4.databasechangelog dacl
 where dacl.filename in
       ('integration/ad4/sql/Ad4Tr4_gx.sql',
        'integration/ad4/sql/Ad4Tr4_g.sql');
/        

update ad4_istanze ista
   set ista.installazione = ''
 where ista.istanza = '&user';
/

commit;



-- Script Oracle per eliminare e creare l'utente &user

-- Verifica se l'utente &user esiste e, in caso affermativo, lo elimina
DECLARE
  v_count NUMBER;
BEGIN
  SELECT COUNT(*)
  INTO v_count
  FROM dba_users
  WHERE username = '&user';

  IF v_count > 0 THEN
    EXECUTE IMMEDIATE 'DROP USER &user CASCADE';
    DBMS_OUTPUT.PUT_LINE('Utente &user eliminato.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('L''utente &user non esiste.');
  END IF;
END;
/

-- Crea l'utente &user
CREATE USER &user
IDENTIFIED BY TR4
DEFAULT TABLESPACE PAL
TEMPORARY TABLESPACE TEMP
PROFILE DEFAULT;

-- Grant/Revoke role privileges
GRANT CONNECT TO &user;
GRANT RESOURCE TO &user;

-- Grant/Revoke system privileges
GRANT ALTER SESSION TO &user;
GRANT CREATE CLUSTER TO &user;
GRANT CREATE DATABASE LINK TO &user;
GRANT CREATE INDEXTYPE TO &user;
GRANT CREATE MATERIALIZED VIEW TO &user;
GRANT CREATE PROCEDURE TO &user;
GRANT CREATE PUBLIC SYNONYM TO &user;
GRANT CREATE ROLE TO &user;
GRANT CREATE SEQUENCE TO &user;
GRANT CREATE SESSION TO &user;
GRANT CREATE SYNONYM TO &user;
GRANT CREATE TABLE TO &user;
GRANT CREATE TRIGGER TO &user;
GRANT CREATE TYPE TO &user;
GRANT CREATE VIEW TO &user;
GRANT DEBUG ANY PROCEDURE TO &user;
GRANT DEBUG CONNECT SESSION TO &user;
GRANT DROP PUBLIC SYNONYM TO &user;
GRANT SELECT ANY DICTIONARY TO &user;
GRANT UNLIMITED TABLESPACE TO &user;

/
begin
 DBMS_OUTPUT.PUT_LINE('Utente &user creato e privilegi assegnati.');
end;
/
