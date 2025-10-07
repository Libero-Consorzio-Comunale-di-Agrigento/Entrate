--liquibase formatted sql 
--changeset abrandolini:20250326_152423_gestione_noog_pratica stripComments:false runOnChange:true 
 
create or replace procedure GESTIONE_NOOG_PRATICA
/*************************************************************************
 NOME:        GESTIONE_NOOG_PRATICA
 DESCRIZIONE: Gestisce inserimento/aggiornamento/eliminazione delle
              notifiche oggetto.
 NOTE:
  Rev.    Date         Author      Note
  1       10/04/2019   VD          Aggiunti commenti
                                   Esclusi dal trattamento oggetti di
                                   pratiche con tipo tributo diverso
                                   da ICI/TASI (la modifica è stata effettuata
                                   anche in PB. Controllo ridondante,
                                   aggiunto per gestire eventuali urgenze
                                   presso clienti non ancora aggiornati)
  0       30/12/2009               Prima emissione
*************************************************************************/
( a_cod_fiscale     IN varchar2
, a_pratica           IN number
, a_data_notifica   IN date
, a_stato         IN varchar2
)
IS
  w_tipo_tributo     varchar2(5);
  w_anno_notifica    number;
  w_errore               varchar2(2000);
  errore                 exception;
cursor sel_ogge is
select distinct ogpr.oggetto
  from oggetti_pratica     ogpr
     , riferimenti_oggetto riog
 where ogpr.pratica  = a_pratica
   and riog.oggetto  = ogpr.oggetto
   and not exists
       ( select 1
             from notifiche_oggetto noog
          where noog.oggetto      = ogpr.oggetto
            and noog .cod_fiscale = a_cod_fiscale
       )
     ;
cursor sel_ogge2 is
select distinct ogpr.oggetto
  from oggetti_pratica     ogpr
     , riferimenti_oggetto riog
 where ogpr.pratica  = a_pratica
   and riog.oggetto  = ogpr.oggetto
   and exists
       ( select 1
             from notifiche_oggetto noog
          where noog.oggetto      = ogpr.oggetto
            and noog .cod_fiscale = a_cod_fiscale
            and noog.pratica      = a_pratica
            and noog.anno_notifica <> to_number(to_char(a_data_notifica,'yyyy'))
       )
     ;
BEGIN
   BEGIN
     select tipo_tributo
       into w_tipo_tributo
       from pratiche_tributo
      where pratica = a_pratica;
   EXCEPTION
     WHEN OTHERS THEN
       w_tipo_tributo := 'XXX';
   END;
   IF w_tipo_tributo in ('ICI','TASI') then
      IF a_data_notifica is null or nvl(a_stato,'D') <> 'D' THEN
         BEGIN
            delete notifiche_oggetto
             where pratica = a_pratica
               and cod_fiscale = a_cod_fiscale
            ;
         EXCEPTION
             WHEN others THEN
                  w_errore := 'Errore in cancellazione Notifiche Oggetto ('
                           ||a_pratica||') '||'('||SQLERRM||')';
                  RAISE errore;
         END;
      ELSE
         w_anno_notifica := to_number(to_char(a_data_notifica,'yyyy'));
         FOR rec_ogge in sel_ogge
         LOOP
           BEGIN
             insert into notifiche_oggetto
                    (cod_fiscale,pratica,oggetto,anno_notifica,note)
             values (a_cod_fiscale,a_pratica,rec_ogge.oggetto,w_anno_notifica,'Inserito da Liquidazione')
             ;
           EXCEPTION
              WHEN others THEN
                   w_errore := 'Errore in inserimento notifiche_oggetto ('
                            ||rec_ogge.oggetto||') '||'('||SQLERRM||')';
                   RAISE errore;
           END;
         END LOOP;
         FOR rec_ogge2 in sel_ogge2
         LOOP
           BEGIN
             update notifiche_oggetto
                set anno_notifica = w_anno_notifica
              where cod_fiscale   = a_cod_fiscale
                and pratica       = a_pratica
                and oggetto       = rec_ogge2.oggetto
             ;
           EXCEPTION
              WHEN others THEN
                   w_errore := 'Errore in modifica notifiche_oggetto ('
                            ||rec_ogge2.oggetto||') '||'('||SQLERRM||')';
                   RAISE errore;
           END;
         END LOOP;
      END IF;
   END IF;
   commit;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
      (-20999,w_errore);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
     (-20999,'Errore in Gestione NOOG Pratica '||'('||SQLERRM||')');
END;
/* End Procedure: GESTIONE_NOOG_PRATICA */
/

