--liquibase formatted sql
--changeset dmarotta:20250619_141030_80258_insert_fonti runOnChange:true stripComments:false endDelimiter:/

declare

  c_max_fonti         CONSTANT NUMBER := 99;
  c_descrizione_fonte CONSTANT VARCHAR2(100) := 'PORTALE WEB';
  c_codice_inpa       CONSTANT VARCHAR2(100) := 'FONT_PWEB';
  c_descrizione_inpa  CONSTANT VARCHAR2(100) := 'Fonte per dichiarazione da Portale WEB';
  w_fonte NUMBER;
  w_count NUMBER;

begin
  SELECT count(*)
    into w_count
    FROM installazione_parametri
   WHERE parametro = c_codice_inpa;

  if w_count = 0 then
    WITH numeri AS
     (SELECT LEVEL - 1 AS n FROM dual CONNECT BY LEVEL <= c_max_fonti)
    SELECT MIN(n) AS primo_valore_libero
      into w_fonte
      FROM numeri
     WHERE n NOT IN (SELECT fonte FROM FONTI);

    if w_fonte is null then
      raise_application_error(-20999,
                              'Impossibile trovare un numero libero per la fonte');
    end if;

    -- Chiave per la fonte trovata, si aggiunge alle fonti ed alla inpa
    insert into fonti
      (fonte, descrizione)
    values
      (w_fonte, c_descrizione_fonte);
    insert into installazione_parametri
      (parametro, valore, descrizione)
    values
      (c_codice_inpa, w_fonte, c_descrizione_inpa);

    commit;
  end if;
end;
/
