--liquibase formatted sql 
--changeset abrandolini:20250326_152429_utilitypackage stripComments:false runOnChange:true 
 
CREATE OR REPLACE PACKAGE Utilitypackage
/******************************************************************************
 NOME:        UtilityPackage
 DESCRIZIONE: Contiene oggetti di utilita generale.
 REVISIONI:
 Rev. Data        Autore  Descrizione
 ---- ----------  ------  ----------------------------------------------------
 1    23/01/2001  MF      Inserimento commento.
 2    17/12/2003  MM      Aggiunta compilazione classi java
 3    19/10/2006  VA      Inserite procedure Disable_all e Enable_All, inseriti
                          i metodi presenti nel Package SIAREF.
 4    14/12/2006  MM      Introduzione del parametro p_java_class in compile_all.
 5    08/10/2007  FT      Aggiunta compilazione synonym
 6    12/12/2007  FT      compile_all: esclusione degli oggetti il cui nome
                          inizia con 'BIN$'
******************************************************************************/
AS
   PROCEDURE Compile_All( p_java_class IN NUMBER DEFAULT 1 );
/******************************************************************************
 DESCRIZIONE: Compila tutti gli oggetti invalidi del Schema
 ARGOMENTI:
 ECCEZIONI:   -
******************************************************************************/
   PROCEDURE Disable_All;
/******************************************************************************
 DESCRIZIONE: Disabilita tutti i trigger e i constraint di Foreign Key e di Check dello Schema
 ARGOMENTI:
 ECCEZIONI:   -
******************************************************************************/
   PROCEDURE Enable_All(p_validate NUMBER DEFAULT 1);
/******************************************************************************
 DESCRIZIONE: Abilita tutti i trigger e i constraint di Foreign Key e di Check dello Schema
 ARGOMENTI:   p_validate      IN     NUMBER   Forza la validate o la novalidate
 ECCEZIONI:   -
******************************************************************************/
   PROCEDURE CREATE_GRANT  (p_grantee IN VARCHAR2,
                             p_object  IN VARCHAR2 := '%',
                             p_type    IN VARCHAR2 := '',
                             p_grant   IN VARCHAR2 := '',
                             p_option  IN VARCHAR2 := '',
                             p_grantor IN VARCHAR2 := USER);
   PROCEDURE GRANT_LIKE     (p_object     IN VARCHAR2,
                             p_likeobject IN VARCHAR2,
                             p_grantor    IN VARCHAR2 DEFAULT USER);
/******************************************************************************
 DESCRIZIONE: Assegna ad un dato oggetto le stesse grant di un'altro esistente
 ARGOMENTI:   p_object      IN     VARCHAR2   Oggetto su cui dare le grant
              p_likeobject  IN     VARCHAR2   Oggetto template
              p_grantor     IN     VARCHAR2   Utente proprietario dell'oggetto
 ECCEZIONI:   -
******************************************************************************/
   PROCEDURE CREATE_SYNONYM  (p_object         IN  VARCHAR2 := '%',
                                p_prefix         IN  VARCHAR2 := '',
                                p_grantor        IN  VARCHAR2 := '%',
                                p_grantee        IN  VARCHAR2 := USER );
/******************************************************************************
 DESCRIZIONE: Crea i sinonimi per gli oggetti a cui si ha accesso
 ARGOMENTI:   p_object  IN     VARCHAR2   Oggetto per cui creare il sinonimo
              p_prefix  IN     VARCHAR2   Eventuale prefisso da apporre al sinonimo
              p_grantee IN     VARCHAR2   Utente proprietario del sinonimo
 ECCEZIONI:   20999, Occorre dare la grant <Create synonym> direttamente all'utente
******************************************************************************/
   PROCEDURE CREATE_VIEW (p_owner            IN  VARCHAR2 ,
                            p_object           IN  VARCHAR2 := '%',
                            p_prefix           IN  VARCHAR2 := '',
                            p_db_link          IN  VARCHAR2 := '');
/******************************************************************************
 DESCRIZIONE: Crea le viste per gli oggetti di un dato utente accessibili
 ARGOMENTI:   p_owner    IN     VARCHAR2   Proprietario degli oggetti
              di cui creare la vista
              p_object   IN     VARCHAR2   Oggetto di cui creare la vista
              p_db_link  IN     VARCHAR2   Eventuale dblink
 ECCEZIONI:   20999, Occorre dare la grant <Create view> direttamente all'utente
******************************************************************************/
   FUNCTION  VERSIONE         RETURN VARCHAR2;
END Utilitypackage;
/* End Package: UtilityPackage */
/

CREATE OR REPLACE PACKAGE BODY Utilitypackage
AS
s_oracle_ver integer;
PROCEDURE Compile_All
/******************************************************************************
 NOME:        Compile_All
 DESCRIZIONE: Compilazione di tutti gli oggetti invalidi presenti nel DB.
 ARGOMENTI:   p_java_class NUMBER indica se deve essere effettuata la
                                  compilazione anche degli oggetti di tipo
                                  JAVA CLASS.
 ANNOTAZIONI: Tenta la compilazione in cicli successivi.
              Termina la compilazione quando il numero degli oggetti
              invalidi non varia rispetto al ciclo precedente.
 REVISIONI:
 Rev. Data        Autore  Descrizione
 ---- ----------  ------  ----------------------------------------------------
 1    23/01/2001  MF      Inserimento commento.
 2    17/12/2003  MM      Aggiunta compilazione classi java
 4    14/12/2006  MM      Introduzione del parametro p_java_class.
 5    08/10/2007  FT      Aggiunta compilazione synonym
 6    12/12/2007  FT      compile_all: esclusione degli oggetti il cui nome
                          inizia con 'BIN$'
******************************************************************************/
( p_java_class IN NUMBER DEFAULT 1 )
IS
   d_obj_name       VARCHAR2(30);
   d_obj_type       VARCHAR2(30);
   d_command        VARCHAR2(200);
   d_cursor         INTEGER;
   d_rows           INTEGER;
   d_old_rows       INTEGER;
   d_return         INTEGER;
   CURSOR c_obj IS
      SELECT object_name, object_type
        FROM OBJ
       WHERE ( object_type IN ( 'PROCEDURE'
                              , 'TRIGGER'
                              , 'FUNCTION'
                              , 'PACKAGE'
                              , 'PACKAGE BODY'
                              , 'VIEW')
             OR (object_type = 'JAVA CLASS' AND p_java_class = 1)
             OR (object_type = 'SYNONYM' AND s_oracle_ver >= 10)
             )
       AND   status = 'INVALID'
       AND   substr( object_name, 1, 4 ) != 'BIN$'
      ORDER BY  DECODE(object_type
                      ,'PACKAGE',1
                      ,'PACKAGE BODY',2
                      ,'FUNCTION',3
                      ,'PROCEDURE',4
                      ,'VIEW',5
                             ,6)
              , object_name
      ;
BEGIN
   d_old_rows := 0;
   LOOP
      d_rows := 0;
      BEGIN
         OPEN  c_obj;
         LOOP
            BEGIN
               FETCH c_obj INTO d_obj_name, d_obj_type;
               EXIT WHEN c_obj%NOTFOUND;
               d_rows := d_rows + 1;
               IF d_obj_type = 'PACKAGE BODY' THEN
                  d_command := 'alter PACKAGE '||d_obj_name||' compile BODY';
               ELSIF d_obj_type = 'JAVA CLASS' THEN
                  d_command := 'alter '||d_obj_type||' "'||d_obj_name||'" compile';
               ELSE
                  d_command := 'alter '||d_obj_type||' '||d_obj_name||' compile';
               END IF;
               d_cursor  := DBMS_SQL.OPEN_CURSOR;
               DBMS_SQL.PARSE(d_cursor,d_command,dbms_sql.native);
               d_return := DBMS_SQL.EXECUTE(d_cursor);
               DBMS_SQL.CLOSE_CURSOR(d_cursor);
            EXCEPTION
               WHEN OTHERS THEN NULL;
            END;
         END LOOP;
         CLOSE c_obj;
      END;
      IF d_rows = d_old_rows THEN
         EXIT;
      ELSE
         d_old_rows := d_rows;
      END IF;
   END LOOP;
   IF d_rows > 0 THEN
      RAISE_APPLICATION_ERROR(-20999,'Esistono n.'||TO_CHAR(d_rows)||' Oggetti di DataBase non validabili !');
   END IF;
END Compile_All;
FUNCTION VERSIONE  RETURN VARCHAR2 IS
/******************************************************************************
 NOME:        VERSIONE
 DESCRIZIONE: Restituisce la versione e la data di distribuzione del package.
 PARAMETRI:   --
 RITORNA:     stringa varchar2 contenente versione e data.
 NOTE:        Il secondo numero della versione corrisponde alla revisione
              del package.
******************************************************************************/
BEGIN
   RETURN 'V1.6 del 12/12/2007';
END VERSIONE;
PROCEDURE SQL_execute
( p_stringa VARCHAR2
) IS
/******************************************************************************
 NOME:        SQL_execute
 DESCRIZIONE: Esegue lo statement passato.
 ARGOMENTI:   p_stringa varchar2 statement sql da eseguire
 ECCEZIONI:
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ------------------------------------------------------
 004   27/09/2005  MF      Cambio nomenclatura s_revisione e s_revisione_body.
                           Tolta dipendenza get_stringParm da Package Si4.
                           Inserimento SQL_execute per istruzioni dinamiche.
******************************************************************************/
   d_cursor         INTEGER;
   d_rows_processed INTEGER;
BEGIN
   d_cursor := DBMS_SQL.OPEN_CURSOR;
   DBMS_SQL.PARSE( d_cursor, p_stringa, dbms_sql.native );
   d_rows_processed := DBMS_SQL.EXECUTE( d_cursor );
   DBMS_SQL.CLOSE_CURSOR( d_cursor );
EXCEPTION
   WHEN OTHERS THEN
      DBMS_SQL.CLOSE_CURSOR( d_cursor );
      RAISE;
END SQL_EXECUTE;
PROCEDURE Disable_All
/******************************************************************************
 NOME:        Disable_All
 DESCRIZIONE: Disabilitazione di tutti i Trigger e i Constraint di FK e Check.
 ANNOTAZIONI:
 REVISIONI:
 Rev. Data        Autore  Descrizione
 ---- ----------  ------  ----------------------------------------------------
 1    19/10/2006  VA      Creazione
******************************************************************************/
IS
BEGIN
   /* Disabilito tutti i trigger dello user*/
   FOR c_table IN (SELECT DISTINCT table_name
                     FROM USER_TRIGGERS
                    WHERE base_object_type = 'TABLE') LOOP
      sql_execute('alter table '||c_table.table_name||' disable all triggers');
   END LOOP;
   /* Disabilito i constraint di FK e Check*/
   FOR c_obj IN (SELECT table_name, constraint_name
                   FROM USER_CONSTRAINTS
                  WHERE constraint_type IN ('R','C')) LOOP
      sql_execute('alter table '||c_obj.table_name||' disable constraint '||c_obj.constraint_name);
   END LOOP;
END;
PROCEDURE Enable_All(p_validate NUMBER DEFAULT 1)
/******************************************************************************
 NOME:        Enable_All
 DESCRIZIONE: Abilitazione di tutti i Trigger e i Constraint di FK e Check.
 ANNOTAZIONI:
 REVISIONI:
 Rev. Data        Autore  Descrizione
 ---- ----------  ------  ----------------------------------------------------
 1    19/10/2006  VA      Creazione
******************************************************************************/
IS
d_option VARCHAR2(20) := 'validate';
BEGIN
   IF p_validate = 0 THEN
      d_option := 'novalidate';
   END IF;
   /* Abilito tutti i trigger dello user*/
   FOR c_table IN (SELECT DISTINCT table_name
                     FROM USER_TRIGGERS
                    WHERE base_object_type = 'TABLE') LOOP
      sql_execute('alter table '||c_table.table_name||' enable all triggers');
   END LOOP;
   /* Abilito i constraint di FK e Check*/
   FOR c_obj IN (SELECT table_name, constraint_name
                   FROM USER_CONSTRAINTS
                  WHERE constraint_type IN ('R','C')) LOOP
      sql_execute('alter table '||c_obj.table_name||' enable '||d_option||' constraint '||c_obj.constraint_name);
   END LOOP;
END;
PROCEDURE CREATE_GRANT (p_grantee    IN VARCHAR2,
                        p_object     IN VARCHAR2 := '%',
                        p_type       IN VARCHAR2 := '',
                        p_grant      IN VARCHAR2 := '',
                        p_option     IN VARCHAR2 := '',
                        p_grantor    IN VARCHAR2 := USER ) IS
/******************************************************************************
 ANNOTAZIONI: -
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 0    10/10/03   VA    Prima emissione.
 1    06/11/03   VA    Corretto errore nella nvl.
******************************************************************************/
d_grantee    VARCHAR2(20) := UPPER(p_grantee);
d_object     VARCHAR2(100) := UPPER(p_object);
d_type       VARCHAR2(100) := UPPER(p_type);
d_grant      VARCHAR2(20) := UPPER(p_grant);
d_option     VARCHAR2(20) := UPPER(p_option);
d_grantor    VARCHAR2(20) := UPPER(p_grantor);
CURSOR c_obj IS
    SELECT object_name, object_type
      FROM ALL_OBJECTS
    WHERE object_name LIKE d_object
      AND (object_type IN (d_type)
   OR  NVL(d_type,'1') = '1')
   AND owner = d_grantor
   AND object_name NOT IN ('SI4','SIAREF');
BEGIN
   IF    d_grant IS NULL THEN
         d_grant :='select';
   END IF;
   IF    d_option = 'YES' THEN
         d_option := ' with grant option';
   ELSIF d_option = 'NO' THEN
         d_option := '';
   ELSE  d_option := ' '||d_option;
   END IF;
   FOR v_obj IN c_obj LOOP
      BEGIN
     IF v_obj.object_type IN ('FUNCTION','PACKAGE','PROCEDURE') THEN
        sql_execute('grant execute on '||v_obj.object_name||' to '||d_grantee||' '||d_option);
  ELSE
        sql_execute('grant '||d_grant||' on '||v_obj.object_name||' to '||d_grantee||' '||d_option);
  END IF;
      EXCEPTION
        WHEN OTHERS THEN NULL;
      END;
   END LOOP;
END CREATE_GRANT;
PROCEDURE GRANT_LIKE (p_object      IN VARCHAR2,
                      p_likeobject  IN VARCHAR2,
                      p_grantor     IN VARCHAR2 := USER ) IS
/******************************************************************************
 ANNOTAZIONI: -
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 0    10/10/03   VA    Prima emissione.
 1    06/11/03   VA    Aggiunta possibilita di specificare il Grantor.
******************************************************************************/
d_object         VARCHAR2(20) := UPPER(p_object);
d_likeobject     VARCHAR2(20) := UPPER(p_likeobject);
d_grantor        VARCHAR2(20) := UPPER(p_grantor);
d_option         VARCHAR2(20) :='';
CURSOR c_tab_privs IS
    SELECT *
      FROM ALL_TAB_PRIVS
     WHERE grantor    = d_grantor
       AND table_name = d_likeobject;
BEGIN
FOR v_tab_privs IN c_tab_privs LOOP
   BEGIN
      IF v_tab_privs.grantable = 'YES' THEN
         d_option := ' with grant option';
   ELSE
      d_option := '';
   END IF;
     sql_execute('grant '||v_tab_privs.PRIVILEGE||' on '||d_object||' to '||v_tab_privs.grantee||' '||d_option);
   EXCEPTION
     WHEN OTHERS THEN NULL;
   END;
END LOOP;
END GRANT_LIKE;
PROCEDURE CREATE_SYNONYM   (p_object    IN VARCHAR2 := '%',
                            p_prefix       IN VARCHAR2 := '',
                            p_grantor      IN VARCHAR2 := '%',
                            p_grantee      IN VARCHAR2 := USER ) IS
/******************************************************************************
 ANNOTAZIONI: -
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 0    10/10/03   VA     Prima emissione.
 2    29/03/05   SN     nome del sinonimo come quello nello user che da grant
******************************************************************************/
d_grantee        VARCHAR2(30) := UPPER(p_grantee);
d_prefix         VARCHAR2(20) := UPPER(p_prefix);
d_grantor        VARCHAR2(30) := UPPER(p_grantor);
d_object         VARCHAR2(30) := UPPER(p_object);
CURSOR c_obj IS
    SELECT DISTINCT table_name object_name, table_schema
      FROM ALL_TAB_PRIVS
     WHERE grantee = d_grantee
       AND table_name LIKE d_object
    AND grantor LIKE d_grantor;
d_esiste VARCHAR2(1);
privilegi_insufficienti EXCEPTION ;
PRAGMA EXCEPTION_INIT(privilegi_insufficienti,-1031);
d_sinonimo ALL_SYNONYMS.synonym_name%TYPE;
d_msg_errore VARCHAR2(32767);
d_errore BOOLEAN := FALSE;
BEGIN
FOR d_obj IN c_obj LOOP
  d_errore := FALSE;
  BEGIN
   SELECT '1'
     INTO d_esiste
     FROM ALL_SYNONYMS
    WHERE OWNER = 'PUBLIC'
      AND SYNONYM_NAME = d_obj.object_name
      AND TABLE_OWNER  = d_obj.table_schema
      AND TABLE_NAME   = d_obj.object_name;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN -- non esiste il sinonimo pubblico uguale
       BEGIN
       SELECT synonym_name
         INTO d_sinonimo
         FROM ALL_SYNONYMS
        WHERE owner      = d_grantee
          AND table_name = d_obj.object_name
          AND table_owner = d_obj.table_schema;
       EXCEPTION
         WHEN NO_DATA_FOUND THEN
           d_sinonimo :=  d_obj.object_name;
         WHEN TOO_MANY_ROWS THEN
           d_msg_errore := d_msg_errore || CHR(10) || d_obj.table_schema||'.'||d_obj.object_name;
           d_errore := TRUE;
       END;
       IF NOT d_errore THEN
          BEGIN
            sql_execute('drop synonym '||d_sinonimo);
          EXCEPTION
            WHEN OTHERS THEN NULL;
          END;
          BEGIN
            sql_execute('create synonym '||d_grantee||'.'||d_prefix||d_sinonimo||' for '||d_obj.table_schema||'.'||d_obj.object_name);
          EXCEPTION
            WHEN privilegi_insufficienti THEN
                 RAISE_APPLICATION_ERROR (-20999,'ERRORE dare le grant di sistema dirette', TRUE);
            WHEN OTHERS THEN  DBMS_OUTPUT.PUT_LINE ('errore ' || SQLERRM);NULL;
          END;
       END IF;
    WHEN TOO_MANY_ROWS THEN
       NULL;
  END;
END LOOP;
IF d_msg_errore IS NOT NULL THEN
   RAISE_APPLICATION_ERROR (-20999,'NON tutti i sinonimi sono stati creati.'|| CHR(10)
                                   ||' Esistono troppi sinonimi per gli oggetti:' || d_msg_errore);
END IF;
END CREATE_SYNONYM;
PROCEDURE CREATE_VIEW   (p_owner      IN VARCHAR2 ,
                         p_object     IN VARCHAR2 :='%',
                         p_prefix     IN VARCHAR2 := '',
                         p_db_link    IN VARCHAR2 :='') IS
/******************************************************************************
 ANNOTAZIONI: -
 REVISIONI:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 0    10/10/03   VA    Prima emissione.
 1    24/10/03   VA    Aggiunta possibilita di un prefisso nella creazione delle viste.
******************************************************************************/
d_owner        VARCHAR2(20) := UPPER(p_owner);
d_object       VARCHAR2(30) := UPPER(p_object);
d_prefix       VARCHAR2(20) := UPPER(p_prefix);
d_db_link    VARCHAR2(30) := '@'||p_db_link;
d_name         VARCHAR2(30);
TYPE cv_type IS REF CURSOR;
CV        cv_type;
CURSOR c_obj IS
    SELECT object_name,owner
      FROM ALL_OBJECTS
     WHERE owner = d_owner
       AND object_name LIKE d_object
    AND object_type IN ('TABLE','VIEW');
d_select VARCHAR2(200) := 'SELECT tname FROM tab'||d_db_link||' where tname like '''||d_object||''' and tabtype in (''TABLE'',''VIEW'')';
privilegi_insufficienti EXCEPTION ;
PRAGMA EXCEPTION_INIT(privilegi_insufficienti,-1031);
BEGIN
IF d_db_link = '@' THEN
   FOR v_obj IN c_obj LOOP
          BEGIN
            sql_execute('create or replace view '||d_prefix||v_obj.object_name||' as select * from '||v_obj.owner||'.'||v_obj.object_name);
          EXCEPTION
            WHEN privilegi_insufficienti THEN
                 RAISE_APPLICATION_ERROR (-20999,'ERRORE dare le grant di sistema dirette', TRUE);
            WHEN OTHERS THEN NULL;
          END;
   END LOOP;
ELSE
   OPEN CV FOR d_select;
   LOOP
      FETCH CV INTO d_name;
   EXIT WHEN CV%NOTFOUND;
   BEGIN
         sql_execute('create or replace view '||d_prefix||d_name||' as select * from '||d_name||d_db_link);
      EXCEPTION
            WHEN privilegi_insufficienti THEN
                 RAISE_APPLICATION_ERROR (-20999,'ERRORE dare le grant di sistema dirette', TRUE);
            WHEN OTHERS THEN NULL;
      END;
   END LOOP;
END IF;
END CREATE_VIEW;
begin
   select to_number( substr( substr( banner
                                   , instr( upper( banner )
                                          , 'RELEASE'
                                          ) + 8
                                   )
                           , 1
                           , instr( substr( banner
                                          , instr( upper( banner )
                                                 , 'RELEASE' ) + 8
                                          )
                                  , '.'
                                  ) -1
                           )
                   )
     into s_oracle_ver
     from v$version
    where upper(banner) like '%ORACLE%'
   ;
END Utilitypackage;
/* End Package Body: UtilityPackage */
/

