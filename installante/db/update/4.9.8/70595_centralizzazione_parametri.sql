--liquibase formatted sql
--changeset dmarotta:20250904_123226_70595_centralizzazione_parametri stripComments:false endDelimiter:/

DECLARE
  esiste NUMBER;
BEGIN
  SELECT COUNT(1) INTO esiste FROM user_objects WHERE object_name = 'INSTALLAZIONE_PARAMETRI_PRIVS' AND object_type = 'TABLE';
  IF esiste = 0 THEN
    EXECUTE IMMEDIATE 'CREATE TABLE installazione_parametri_privs AS SELECT * FROM user_tab_privs WHERE table_name = ''INSTALLAZIONE_PARAMETRI''';
  END IF;

  SELECT COUNT(1) INTO esiste FROM user_objects WHERE object_name = 'INSTALLAZIONE_PARAMETRI' AND object_type = 'TABLE';
  IF esiste = 1 THEN
    EXECUTE IMMEDIATE 'RENAME INSTALLAZIONE_PARAMETRI TO INSTALLAZIONE_PARAMETRI_ORIG';
  END IF;
END;
/

CREATE OR REPLACE PROCEDURE popola_regi_ad4_da_parametri
IS
  d_tabella VARCHAR2(100) := 'Tabella ' || USER || ' INSTALLAZIONE_PARAMETRI.';
  d_chiave  VARCHAR2(1000);
  d_stringa VARCHAR2(1000);
  d_ente    VARCHAR2(100);

  PROCEDURE crea_registro_ad4(p_chiave   VARCHAR2,
                              p_stringa  VARCHAR2,
                              p_valore   VARCHAR2,
                              p_commento VARCHAR2) IS
  BEGIN
    AD4_REGISTRO_UTILITY.SCRIVI_STRINGA(p_chiave,
                                        p_stringa,
                                        p_valore,
                                        p_commento,
                                        FALSE);
  EXCEPTION
    WHEN OTHERS THEN
      ad4_key_error_log_pkg.INS(NULL,
                                SYS_CONTEXT('USERENV', 'SID'),
                                SYSDATE,
                                d_tabella ||
                                'Errore in inserimento CHIAVE ' || d_chiave ||
                                ' e STRINGA ' || d_stringa,
                                USER,
                                SUBSTR(SQLERRM, 1, 2000),
                                'E');
      RAISE;
  END;

BEGIN
  select 'C_' || comu.sigla_cfis
    into d_ente
    from ad4_comuni comu, dati_generali dage
   where comu.comune = dage.com_cliente
     and comu.provincia_stato = dage.pro_cliente;

  FOR P IN (SELECT * FROM INSTALLAZIONE_PARAMETRI_ORIG) LOOP
    d_chiave  := 'PRODUCTS/' || d_ente ||
                 '/TR4/${istanza}/INSTALLAZIONE_PARAMETRI';
    d_stringa := p.parametro;
    crea_registro_ad4(d_chiave, d_stringa, p.VALORE, P.descrizione);
  END LOOP;
END;
/

BEGIN
  popola_regi_ad4_da_parametri;
  commit;
END;

/

CREATE OR REPLACE FORCE VIEW INSTALLAZIONE_PARAMETRI
AS
SELECT STRINGA parametro,
      VALORE,
      COMMENTO descrizione,
      CHIAVE,
      STRINGA
  FROM AD4_REGISTRO
WHERE CHIAVE LIKE 'PRODUCTS/%/TR4/'|| '${istanza}' ||'/INSTALLAZIONE_PARAMETRI' AND STRINGA <> '(Predefinito)'
/

CREATE OR REPLACE TRIGGER INSTALLAZIONE_PARAMETRI_TIOIUD
   INSTEAD OF INSERT OR UPDATE OR DELETE
   ON INSTALLAZIONE_PARAMETRI
   FOR EACH ROW
DECLARE
   d_ente     VARCHAR2 (100);
   d_valore   VARCHAR2 (4000) := :new.valore;
BEGIN
   IF INSERTING THEN
     select 'C_' || comu.sigla_cfis
       into d_ente
       from ad4_comuni comu, dati_generali dage
      where comu.comune = dage.com_cliente
        and comu.provincia_stato = dage.pro_cliente;

       AD4_REGISTRO_UTILITY.SCRIVI_STRINGA (
                 'PRODUCTS/' || d_ente || '/TR4/'|| '${istanza}' ||'/INSTALLAZIONE_PARAMETRI',
                 :NEW.parametro,
                 :NEW.VALORE,
                 :NEW.DESCRIZIONE,
                 FALSE);
   END IF;

   IF UPDATING
   THEN
      UPDATE ad4_registro
         SET CHIAVE = :NEW.CHIAVE,
             STRINGA = :NEW.STRINGA,
             VALORE = :NEW.VALORE,
             COMMENTO = :NEW.DESCRIZIONE
       WHERE     CHIAVE = :OLD.CHIAVE
             AND STRINGA = :OLD.STRINGA;
   END IF;

   IF DELETING
   THEN
      DELETE ad4_registro
       WHERE     CHIAVE = :OLD.CHIAVE
             AND STRINGA = :OLD.STRINGA;
   END IF;
EXCEPTION
   WHEN OTHERS
   THEN
      RAISE;
END;
/

BEGIN
   for p in (select grantee from installazione_parametri_privs) loop
      execute immediate 'grant all on installazione_parametri to '||p.grantee;
   END loop;

END;
/
