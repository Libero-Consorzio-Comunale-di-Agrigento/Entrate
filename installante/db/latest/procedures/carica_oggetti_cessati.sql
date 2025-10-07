--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_oggetti_cessati stripComments:false runOnChange:true 
 
create or replace procedure CARICA_OGGETTI_CESSATI
/*************************************************************************
  Rev.    Date         Author      Note
  5       23/03/2015   VD          Aggiunta data cessazione per pubblicità
                                   temporanea
  4       20/03/2015   VD          Aggiunta gestione inserimento oggetti
                                   per caricamento oggetti da contribuente
                                   cessato
  3       17/03/2015   VD          Modificata insert oggetti_pratica:
                                   mette l'oggetto pratica da cessare
                                   nell'oggetto_pratica_rif
  2       27/02/2015   PM          Aggiunte le insert di alcuni campi
  1       24/02/2015   VD          Prima Creazione
*************************************************************************/
( p_sessione                parametri.sessione%type
, p_nome_parametro          parametri.nome_parametro%type
, p_data_decorrenza         date
, p_data_cessazione         date
, p_pratica                 pratiche_tributo.pratica%type
, p_utente                  oggetti_pratica.utente%type
) as
  w_cod_fiscale             varchar2(16);
  w_tipo_tributo            pratiche_tributo.tipo_tributo%type;
  w_anno                    pratiche_tributo.anno%type;
  w_tipo_evento             pratiche_tributo.tipo_evento%type;
  w_oggetto_pratica         oggetti_pratica.oggetto_pratica%type;
  w_fine_concessione        date;
  sql_errm                  varchar2(100);
  w_errore                  varchar2(2000);
  errore                    exception;
begin
--
-- Si selezionano i dati della pratica di cessazione
--
  begin
    select cod_fiscale
         , tipo_tributo
         , anno
         , tipo_evento
      into w_cod_fiscale
         , w_tipo_tributo
         , w_anno
         , w_tipo_evento
      from PRATICHE_TRIBUTO
     where pratica = p_pratica;
  exception
      when others
      then
         sql_errm := substr (sqlerrm, 1, 100);
         w_errore :=
               'Errore in ricerca pratica '
            || p_pratica
            || ' ('
            || sql_errm
            || ')';
         raise errore;
  end;
  if w_tipo_tributo = 'TOSAP' and
     w_tipo_evento = 'C' then
     w_fine_concessione := p_data_cessazione;
  else
     w_fine_concessione := null;
  end if;
--
  for ogge in (select ogpr.oggetto_pratica
                    , ogpr.oggetto
                    , ogpr.tipo_oggetto
                    , ogpr.tributo
                    , ogpr.categoria
                    , ogpr.tipo_tariffa
                    , ogpr.oggetto_pratica_rif
                    , ogpr.larghezza
                    , ogpr.profondita
                    , ogpr.consistenza_reale
                    , ogpr.quantita
                    , ogpr.consistenza
                    , ogpr.data_concessione
                    , ogpr.num_concessione
                    , ogpr.indirizzo_occ
                    , ogpr.da_chilometro
                    , ogpr.a_chilometro
                    , ogpr.lato
                    , ogpr.cod_pro_occ
                    , ogpr.cod_com_occ
                    , ogpr.tipo_occupazione
                    , ogpr.numero_familiari
                    , ogpr.titolo_occupazione
                    , ogpr.natura_occupazione
                    , ogpr.destinazione_uso
                    , ogpr.assenza_estremi_catasto
                    , ogco.perc_possesso
                    , ogco.flag_ab_principale
                 from parametri para
                    , oggetti_pratica ogpr
                    , oggetti_contribuente ogco
                where para.sessione = p_sessione
                  and para.nome_parametro = p_nome_parametro
                  and ogpr.oggetto_pratica = to_number(para.valore)
                  and ogpr.oggetto_pratica = ogco.oggetto_pratica)
  loop
    w_oggetto_pratica := NULL;
    oggetti_pratica_nr (w_oggetto_pratica);
    begin
      insert into oggetti_pratica ( oggetto_pratica
                                  , oggetto
                                  , pratica
                                  , anno
                                  , tipo_oggetto
                                  , tributo
                                  , categoria
                                  , tipo_tariffa
                                  , oggetto_pratica_rif
                                  , larghezza
                                  , profondita
                                  , consistenza_reale
                                  , quantita
                                  , consistenza
                                  , data_concessione
                                  , num_concessione
                                  , indirizzo_occ
                                  , da_chilometro
                                  , a_chilometro
                                  , lato
                                  , cod_pro_occ
                                  , cod_com_occ
                                  , tipo_occupazione
                                  , fine_concessione
                                  , numero_familiari
                                  , titolo_occupazione
                                  , natura_occupazione
                                  , destinazione_uso
                                  , assenza_estremi_catasto
                                  , utente
                                  , data_variazione
                                  )
      values ( w_oggetto_pratica
             , ogge.oggetto
             , p_pratica
             , w_anno
             , ogge.tipo_oggetto
             , ogge.tributo
             , ogge.categoria
             , ogge.tipo_tariffa
             , decode(w_tipo_evento,'C',nvl(ogge.oggetto_pratica_rif,ogge.oggetto_pratica),null)
             , ogge.larghezza
             , ogge.profondita
             , ogge.consistenza_reale
             , ogge.quantita
             , ogge.consistenza
             , ogge.data_concessione
             , ogge.num_concessione
             , ogge.indirizzo_occ
             , ogge.da_chilometro
             , ogge.a_chilometro
             , ogge.lato
             , ogge.cod_pro_occ
             , ogge.cod_com_occ
             , ogge.tipo_occupazione
             , w_fine_concessione
             , ogge.numero_familiari
             , ogge.titolo_occupazione
             , ogge.natura_occupazione
             , ogge.destinazione_uso
             , ogge.assenza_estremi_catasto
             , p_utente
             , trunc(sysdate)
             );
    exception
      when others
      then
         sql_errm := substr (sqlerrm, 1, 100);
         w_errore :=
               'Errore in inserimento oggetti_pratica da cessare '
            || ogge.oggetto_pratica
            || ' ('
            || sql_errm
            || ')';
         raise errore;
    end;
--
    begin
      insert into oggetti_contribuente
                  ( cod_fiscale
                  , oggetto_pratica
                  , anno
                  , tipo_rapporto
                  , perc_possesso
                  , inizio_occupazione
                  , data_decorrenza
                  , fine_occupazione
                  , data_cessazione
                  , flag_ab_principale
                  , utente
                  , data_variazione
                  )
           values ( w_cod_fiscale
                  , w_oggetto_pratica
                  , w_anno
                  , 'D'
                  , ogge.perc_possesso
                  , p_data_decorrenza
                  , p_data_decorrenza
                  , p_data_cessazione
                  , p_data_cessazione
                  , ogge.flag_ab_principale
                  , p_utente
                  , TRUNC (SYSDATE)
                  );
    exception
      WHEN OTHERS
      THEN
         sql_errm := substr (sqlerrm, 1, 100);
         w_errore :=
               'Errore in inserimento oggetti_pratica da cessare '
            || ogge.oggetto_pratica
            || ' ('
            || sql_errm
            || ')';
         RAISE errore;
    end;
--
  end loop;
exception
   when ERRORE then
      raise_application_error(-20999,w_errore);
end;
/* End Procedure: CARICA_OGGETTI_CESSATI */
/

