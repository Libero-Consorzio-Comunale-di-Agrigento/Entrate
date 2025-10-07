--liquibase formatted sql 
--changeset abrandolini:20250326_152423_aggiornamento_indirizzi stripComments:false runOnChange:true 
 
create or replace procedure AGGIORNAMENTO_INDIRIZZI
IS
w_cod_via      number;
w_denom_ric      varchar2(60);
w_indirizzo_localita   varchar2(36);
w_num_civ      number;
w_suffisso      varchar2(5);
w_errore      varchar2(2000);
errore         exception;
CURSOR sel_ogge IS
       select anic.anomalia,ogge.oggetto,ogge.indirizzo_localita
    from oggetti ogge,
         anomalie_ici anic
   where ogge.indirizzo_localita   is not null
     and ogge.cod_via      is null
     and ogge.oggetto      = anic.oggetto
     and anic.tipo_anomalia   = 5
       ;
BEGIN
  FOR rec_ogge IN sel_ogge LOOP
      BEGIN
   select devi.cod_via,devi.descrizione
     into w_cod_via,w_denom_ric
     from denominazioni_via devi
    where rec_ogge.indirizzo_localita like '%' || devi.descrizione || '%'
           and devi.descrizione is not null
      and not exists (select 'x'
              from denominazioni_via devi1
             where rec_ogge.indirizzo_localita like
                                  '%' || devi1.descrizione|| '%'
                              and devi1.descrizione is not null
               and devi1.cod_via            != devi.cod_via)
      and rownum = 1
        ;
      EXCEPTION
   WHEN no_data_found then
        w_cod_via := 0;
        WHEN others THEN
             w_errore := 'Errore in ricerca Denominazioni Via '||
                         ' ('||SQLERRM||')';
        RAISE errore;
      END;
      IF w_cod_via != 0 THEN
         BEGIN
           select substr(rec_ogge.indirizzo_localita,
               (instr(rec_ogge.indirizzo_localita,w_denom_ric)
          + length(w_denom_ric)))
             into w_indirizzo_localita
             from dual
           ;
         EXCEPTION
           WHEN no_data_found THEN
                null;
           WHEN others THEN
           w_errore := 'Errore in decodifica indirizzo '||
             '('||rec_ogge.oggetto - rec_ogge.indirizzo_localita||') '||
             '('||SQLERRM||')';
           RAISE errore;
         END;
         BEGIN
           select
              substr(w_indirizzo_localita,
              instr(translate(w_indirizzo_localita,'1234567890','9999999999'),'9'),
             decode(
             sign(4 - (
              length(
              substr(w_indirizzo_localita,
              instr(translate(w_indirizzo_localita,'1234567890','9999999999'),'9')))
              -
              nvl(
             length(
              ltrim(
              translate(
              substr(w_indirizzo_localita,
              instr(translate(w_indirizzo_localita,'1234567890','9999999999'),'9')),
              '1234567890','9999999999'),'9')),0))),-1,4,
              length(
              substr(w_indirizzo_localita,
              instr(translate(w_indirizzo_localita,'1234567890','9999999999'),'9')))
              -
              nvl(
             length(
              ltrim(
              translate(
              substr(w_indirizzo_localita,
              instr(translate(w_indirizzo_localita,'1234567890','9999999999'),'9')),
              '1234567890','9999999999'),'9')),0))
              ),
              ltrim(
              substr(w_indirizzo_localita,
              instr(translate(w_indirizzo_localita,'1234567890','9999999999'),'9')
             +
              length(
              substr(w_indirizzo_localita,
              instr(translate(w_indirizzo_localita,'1234567890','9999999999'),'9')))
              -
             nvl(
              length(
              ltrim(
              translate(
              substr(w_indirizzo_localita,
              instr(translate(w_indirizzo_localita,'1234567890','9999999999'),'9')),
              '1234567890','9999999999'),'9')),0),
             5),
             ' /'
              )
             into w_num_civ,w_suffisso
             from dual
      ;
         EXCEPTION
           WHEN no_data_found THEN
                null;
           WHEN others THEN
           w_errore := 'Errore in decodifica numero civico e suffisso '||
             '('||rec_ogge.oggetto - rec_ogge.indirizzo_localita||') '||
             '('||SQLERRM||')';
           RAISE errore;
         END;
         BEGIN
      update oggetti
         set cod_via   = w_cod_via,
             num_civ  = w_num_civ,
             suffisso = w_suffisso
       where oggetto  = rec_ogge.oggetto
      ;
         EXCEPTION
      WHEN others THEN
           w_errore := 'Errore in aggiornamento Oggetti '||
             '('||SQLERRM||')';
           RAISE errore;
         END;
         BEGIN
      delete anomalie_ici
       where anomalia    = rec_ogge.anomalia
      ;
         EXCEPTION
      WHEN others THEN
           w_errore := 'Errore in cancellazione Anomalie ICI '||
             '('||SQLERRM||')';
           RAISE errore;
         END;
dbms_output.put_line ('Oggetto: '||rec_ogge.oggetto);
dbms_output.put_line ('Ind.Loc: '||rec_ogge.indirizzo_localita);
dbms_output.put_line ('via  : '||w_cod_via);
dbms_output.put_line ('denom: '||w_denom_ric);
dbms_output.put_line ('civ  : '||w_num_civ);
dbms_output.put_line ('suff : '||w_suffisso);
      END IF;
  END LOOP;
  BEGIN
    update anomalie_anno
       set data_elaborazione = trunc(sysdate)
     where tipo_anomalia     = 5
    ;
  EXCEPTION
    WHEN others THEN
         w_errore := 'Errore in aggiornamento Anomalie Anno '||
           '('||SQLERRM||')';
         RAISE errore;
  END;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
    (-20999,w_errore);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
    (-20999,'Errore in aggiornamento Oggetti '||
       '('||SQLERRM||')');
END;
/* End Procedure: AGGIORNAMENTO_INDIRIZZI */
/

