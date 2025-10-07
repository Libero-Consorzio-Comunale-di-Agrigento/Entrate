--liquibase formatted sql
--changeset dmarotta:20250418_080113_install_common stripComments:false runOnChange:true

CREATE OR REPLACE PACKAGE install_common AS

  /**
  * Verifica l'esistenza di un tipo tributo nella tabella tipi_tributo.
  *
  * @param a_tipo_tributo Il codice del tipo tributo da verificare.
  * @return 1 se il tipo tributo esiste, 0 altrimenti.
  */
  FUNCTION check_tipo_tributo(a_tipo_tributo IN VARCHAR2) RETURN NUMBER;

  /**
  * Verifica l'esistenza di un tipo modello nella tabella tipi_modello.
  *
  * @param a_tipo_modello Il codice del tipo modello da verificare.
  * @return 1 se il tipo modello esiste, 0 altrimenti.
  */
  FUNCTION check_tipo_modello(a_tipo_modello IN VARCHAR2) RETURN NUMBER;

  /**
  * Aggiorna un modello, se non esiste lo crea.
  *
  * @param a_tipo_tributo        Il tipo tributo del modello.
  * @param a_descrizione         La descrizione del modello.
  * @param a_descrizione_ord     La descrizione ordinata del modello.
  * @param a_path                Il path del modello.
  * @param a_nome_dw             Il nome del data warehouse del modello.
  * @param a_flag_sottomodello   Se il modello e un sottomodello.
  * @param a_codice_sottomodello Il codice del sottomodello.
  * @param a_flag_editabile      Se il modello e editabile.
  * @param a_db_function         La funzione del db per il modello.
  * @param a_flag_standard       Se il modello e standard.
  * @param a_flag_f24            Se il modello e utilizzabile per la f24.
  * @param a_flag_avviso_agid    Se il modello e utilizzabile per l'avviso agid.
  * @param a_flag_web            Se il modello e utilizzabile per il web.
  */
  procedure update_modello(a_tipo_tributo        in varchar2,
                           a_descrizione         in varchar2,
                           a_descrizione_ord     in varchar2,
                           a_path                in varchar2,
                           a_nome_dw             in varchar2,
                           a_flag_sottomodello   in varchar2,
                           a_codice_sottomodello in varchar2,
                           a_flag_editabile      in varchar2,
                           a_db_function         in varchar2,
                           a_flag_standard       in varchar2,
                           a_flag_f24            in varchar2,
                           a_flag_avviso_agid    in varchar2,
                           a_flag_web            in varchar2);

END install_common;
/
CREATE OR REPLACE PACKAGE BODY install_common AS

  FUNCTION check_tipo_tributo(a_tipo_tributo IN VARCHAR2) RETURN NUMBER IS
    w_contatore NUMBER;
  BEGIN
    SELECT COUNT(*)
      INTO w_contatore
      FROM tipi_tributo
     WHERE tipo_tributo = a_tipo_tributo;

    IF w_contatore = 0 THEN
      dbms_output.put_line('Tipo tributo ' || a_tipo_tributo ||
                           ' non configurato.');
    ELSE
      dbms_output.put_line('Tipo tributo ' || a_tipo_tributo ||
                           ' configurato.');
    END IF;

    RETURN w_contatore;
  END check_tipo_tributo;

  FUNCTION check_tipo_modello(a_tipo_modello IN VARCHAR2) RETURN NUMBER IS
    w_contatore NUMBER;
  BEGIN
    SELECT COUNT(*)
      INTO w_contatore
      FROM tipi_modello
     WHERE tipo_modello = a_tipo_modello;

    IF w_contatore = 0 THEN
      dbms_output.put_line('Tipo modello ' || a_tipo_modello ||
                           ' non presente.');
    ELSE
      dbms_output.put_line('Tipo modello ' || a_tipo_modello ||
                           ' presente.');
    END IF;

    RETURN w_contatore;

  END check_tipo_modello;

  procedure update_modello(a_tipo_tributo        in varchar2,
                           a_descrizione         in varchar2,
                           a_descrizione_ord     in varchar2,
                           a_path                in varchar2,
                           a_nome_dw             in varchar2,
                           a_flag_sottomodello   in varchar2,
                           a_codice_sottomodello in varchar2,
                           a_flag_editabile      in varchar2,
                           a_db_function         in varchar2,
                           a_flag_standard       in varchar2,
                           a_flag_f24            in varchar2,
                           a_flag_avviso_agid    in varchar2,
                           a_flag_web            in varchar2) IS
    w_modello number;
  begin
    select min(modello)
      into w_modello
      from modelli
     where tipo_tributo = a_tipo_tributo
       and descrizione_ord = a_descrizione_ord
       and ((path = a_path) or ((path is null and a_path is null) and
           (descrizione = a_descrizione)));

    if w_modello is null then
      dbms_output.put_line('Nuovo Modello : ' || a_descrizione);
      insert into modelli
        (tipo_tributo,
         descrizione,
         descrizione_ord,
         path,
         nome_dw,
         flag_sottomodello,
         codice_sottomodello,
         flag_editabile,
         db_function,
         flag_standard,
         flag_f24,
         flag_avviso_agid,
         flag_web)
      values
        (a_tipo_tributo,
         a_descrizione,
         a_descrizione_ord,
         a_path,
         a_nome_dw,
         a_flag_sottomodello,
         a_codice_sottomodello,
         a_flag_editabile,
         a_db_function,
         a_flag_standard,
         a_flag_f24,
         a_flag_avviso_agid,
         a_flag_web);
    else
      if a_flag_sottomodello = 'S' then
        dbms_output.put_line('Sottomodello non aggiornabile : ' ||
                             a_descrizione || ' (' || w_modello || ')');
      else
        dbms_output.put_line('Aggiornamento Modello : ' || a_descrizione || ' (' ||
                             w_modello || ')');
        update modelli
           set descrizione         = a_descrizione,
               nome_dw             = a_nome_dw,
               flag_sottomodello   = a_flag_sottomodello,
               codice_sottomodello = a_codice_sottomodello,
               flag_editabile      = a_flag_editabile,
               db_function         = a_db_function,
               flag_standard       = a_flag_standard,
               flag_f24            = a_flag_f24,
               flag_avviso_agid    = a_flag_avviso_agid
         where modello = w_modello;
      end if;
    end if;
  end update_modello;

END install_common;
/
