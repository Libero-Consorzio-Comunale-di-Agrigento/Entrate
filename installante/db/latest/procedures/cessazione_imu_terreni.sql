--liquibase formatted sql 
--changeset abrandolini:20250326_152423_cessazione_imu_terreni stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure     CESSAZIONE_IMU_TERRENI
/*************************************************************************
 La procedure registra le denunce di cessazione per tutti terreni attivi
 al 31/12/2013
 Versione  Data              Autore    Descrizione
   1       29/02/2024        AB        #69780
                                       Utilizzo delle procedure _NR per poter utilizzare le nuove sequence
   0       14/01/2015        VD        Prima emissione
*************************************************************************/

( a_cod_fiscale             varchar2 default '%'
, a_anno                    number
, a_fonte                   number )

IS
  w_utente                  varchar2(8) := 'CIMUT';
  w_conta_pratiche          number(8);
  w_aliquota                number;
  w_cod_fiscale             varchar2(16) := '*';
  w_oggetto                 number;
  w_pratica                 number;
  w_oggetto_pratica         number;
  w_num_ordine              oggetti_pratica.num_ordine%TYPE := 0;
  w_note                    varchar2(2000) := 'Chiusura Automatica del ' || TO_CHAR (SYSDATE, 'dd/mm/yyyy')||' per Popolamento Terreni IMU da CATASTO';
  --Gestione delle eccezioni
  w_errore                  varchar2(2000);
  errore                    exception;
--
-- Selezione dei contribuenti che hanno terreni
--
   cursor sel_cont is
   select ogco.anno,
          ogco.tipo_rapporto,
          ogco.mesi_possesso,
          ogpr.tributo,
          ogpr.valore,
          ogco.cod_fiscale,
          ogge.classe_catasto,
          ogco.flag_possesso,
          prtr.tipo_tributo,
          prtr.tipo_pratica,
          prtr.tipo_evento,
          nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto) tipo_oggetto,
          ogge.oggetto,
          ogge.descrizione,
          nvl(ogpr.categoria_catasto,ogge.categoria_catasto)  categoria,
          nvl(ogpr.classe_catasto,ogge.classe_catasto)  classe,
          decode(prtr.tipo_tributo,'ICI',flag_possesso,null) flag_p,
          ogco.perc_possesso,
          ogco.flag_esclusione,
          ogpr.flag_contenzioso,
          prtr.pratica,
          ogge.data_cessazione,
          ogpr.oggetto_pratica
     from OGGETTI ogge,
          PRATICHE_TRIBUTO prtr,
          OGGETTI_PRATICA ogpr,
          OGGETTI_CONTRIBUENTE ogco
    where prtr.pratica              = ogpr.pratica
      and ogge.oggetto              = ogpr.oggetto
      and ogpr.oggetto_pratica      = ogco.oggetto_pratica
      and ogge.tipo_oggetto         = 1
      and prtr.tipo_tributo         = 'ICI'
      and prtr.cod_fiscale       like a_cod_fiscale
      and ogco.anno||ogco.tipo_rapporto||'S' =
         (select max(b.anno||b.tipo_rapporto||b.flag_possesso)
            from pratiche_tributo c,
                 oggetti_contribuente b,
                 oggetti_pratica a
           where (c.data_notifica is not null and c.tipo_pratica||'' = 'A' and
                  nvl(c.stato_accertamento,'D') = 'D' and
                  nvl(c.flag_denuncia,' ')      = 'S' and
                  c.anno                        < a_anno
                  or (c.data_notifica is null and c.tipo_pratica||'' = 'D')
                 )
             and c.anno                   < a_anno
             and c.tipo_tributo||''       = prtr.tipo_tributo
             and c.pratica                = a.pratica
             and a.oggetto_pratica        = b.oggetto_pratica
             and a.oggetto                = ogpr.oggetto
             and b.tipo_rapporto         in ('C','D','E')
             and b.cod_fiscale            = ogco.cod_fiscale)
           order by 6;
-------------------------
-- INIZIO ELABORAZIONE --
-------------------------
BEGIN
--
-- Si verifica che siano stati inseriti i parametri
--
   if a_anno is null or
      a_fonte is null then
      w_errore := 'Inserire parametri ANNO e FONTE per elaborare i dati';
      raise errore;
   end if;
--
-- Si verifica l'esistenza di pratiche IMU relative ai terreni
-- per anni successivi o uguali all'anno indicato
--
   select count(*)
     into w_conta_pratiche
     from OGGETTI ogge,
          PRATICHE_TRIBUTO prtr,
          OGGETTI_PRATICA ogpr,
          OGGETTI_CONTRIBUENTE ogco
    where prtr.pratica              = ogpr.pratica
      and ogge.oggetto              = ogpr.oggetto
      and ogpr.oggetto_pratica      = ogco.oggetto_pratica
      and ogge.tipo_oggetto         = 1
      and ogco.flag_possesso        is not null
      and ogco.mesi_possesso        > 0
      and prtr.tipo_tributo         = 'ICI'
      and prtr.tipo_pratica        <> 'K'
      and prtr.anno                >= a_anno;
--
   if nvl(w_conta_pratiche,0) > 0 then
      w_errore := 'Esistono pratiche IMU relative a terreni per anno uguale o maggiore all''anno indicato - Impossibile procedere';
      raise errore;
   end if;
--
  begin
    select aliquota
      into w_aliquota
      from rivalutazioni_rendita
     where anno = a_anno
       and tipo_oggetto = 1
         ;
  exception
    when others then
       w_errore := 'Errore nella ricerca dell''aliquota in rivalutazioni rendita' || ' (' || sqlerrm || ')' ;
       raise errore;
  end;
--
  for rec_cont in sel_cont
  loop
    if rec_cont.cod_fiscale <> w_cod_fiscale then
       w_cod_fiscale := rec_cont.cod_fiscale;
       w_num_ordine  := 0;
--
-- Si sta trattando il primo oggetto del contribuente, quindi bisogna inserire
-- pratiche_tributo e...
--
--       begin
--          select nvl(max(pratica),0)
--            into w_pratica
--            from pratiche_tributo
--               ;
--       exception
--          when others then
--             w_errore := ('Errore in ricerca pratica' || ' (' || sqlerrm || ')');
--             raise errore;
--       end;
--       w_pratica := w_pratica + 1;

       w_pratica             := NULL;  --Nr della pratica
       pratiche_tributo_nr(w_pratica); --Assegnazione Numero Progressivo

       begin
         insert into pratiche_tributo ( pratica
                                      , cod_fiscale
                                      , tipo_tributo
                                      , anno
                                      , tipo_pratica
                                      , tipo_evento
                                      , data
                                      , utente
                                      , data_variazione
                                      , note
                                      )
         values (w_pratica
               , w_cod_fiscale
               , 'ICI'
               , a_anno
               , 'D'
               , 'I'
               , trunc(sysdate)
               , w_utente
               , sysdate
               , w_note
               );
       exception
          when others then
             w_errore := ('Errore in in inserimento nuova pratica' || ' (' || sqlerrm || ')');
             raise errore;
       end;
--
--     DENUNCE ICI
--
       begin
          insert into denunce_ici (pratica
                                 , denuncia
                                 , fonte
                                 , utente
                                 , data_variazione
                                 , note)
          values (w_pratica
                , w_pratica
                , a_fonte
                , w_utente
                , sysdate
                , w_note
                );
       exception
         when others then
           w_errore := ('Errore in in inserimento nuova denuncia ici' || ' (' || SQLERRM || ')');
           raise errore;
       end;
--
--     rapporti_tributo
--
       begin
         insert into rapporti_tributo ( pratica
                                      , cod_fiscale
                                      , tipo_rapporto)
         values ( w_pratica
                , w_cod_fiscale
                , 'D');
       exception
         when others then
           w_errore := ('Errore in in inserimento rapporto tributo' || ' (' || sqlerrm || ')');
           raise errore;
       end;
    end if;
--
--     Inserimento dati in oggetti_pratica
--
--    begin
--      select nvl(max(oggetto_pratica),0)
--        into w_oggetto_pratica
--        from oggetti_pratica
--           ;
--    exception
--      when others then
--        w_errore := ('Errore in ricerca oggetto_pratica' || ' (' || sqlerrm || ')');
--        raise errore;
--    end;
--    w_oggetto_pratica := w_oggetto_pratica + 1;

    w_oggetto_pratica := null;
    oggetti_pratica_nr(w_oggetto_pratica); --Assegnazione Numero Progressivo

    w_num_ordine := w_num_ordine + 1;
--
    begin
       insert into oggetti_pratica(oggetto_pratica
                                 , oggetto
                                 , pratica
                                 , anno
                                 , num_ordine
                                 , categoria_catasto
                                 , classe_catasto
                                 , valore
                                 , fonte
                                 , utente
                                 , data_variazione
                                 , note
                                 , tipo_oggetto)
       values(w_oggetto_pratica
            , rec_cont.oggetto
            , w_pratica
            , a_anno
            , w_num_ordine
            , nvl(rec_cont.categoria,'T')
            , rec_cont.classe_catasto
            , round( ( (rec_cont.valore) * (100 + w_aliquota) ) / 100, 2 )
            , a_fonte
            , w_utente
            , sysdate
            , w_note
            , 1)
            ;
      -- dbms_output.put_line('Insert in oggetti_pratica.');
    exception
       when others then
          w_errore := ('Errore in in inserimento oggetto pratica' || ' (' || sqlerrm || ')');
          raise errore;
    end;
--    Inserimento dati in oggetti_contribuente
    begin
      insert into oggetti_contribuente( cod_fiscale
                                      , oggetto_pratica
                                      , anno
                                      , tipo_rapporto
                                      , perc_possesso
                                      , mesi_possesso
                                      , mesi_possesso_1sem
                                      , detrazione
                                      , flag_possesso
                                      , flag_esclusione
                                      , flag_riduzione
                                      , flag_ab_principale
                                      , utente
                                      , data_variazione
                                      , note)
      values( w_cod_fiscale
            , w_oggetto_pratica
            , a_anno
            , 'D'
            , nvl(rec_cont.perc_possesso, 0)
            , 0
            , 0
            , null
            , null
            , null
            , null
            , null
            , w_utente
            , sysdate
            , w_note
            )
       ;
    exception
      when others then
        w_errore := ('Errore in in inserimento oggetto contribuente' || ' (' || sqlerrm || ')');
        raise errore;
    end;
  end loop;
-- COMMIT;
exception
  when errore then
       rollback;
       raise_application_error(-20999, w_errore);
  when others then
       rollback;
       raise_application_error (-20999, 'errore in inserimento_denunce_ici ' || '('||sqlerrm||')');
end;
/* End Procedure: CESSAZIONE_IMU_TERRENI */
/
