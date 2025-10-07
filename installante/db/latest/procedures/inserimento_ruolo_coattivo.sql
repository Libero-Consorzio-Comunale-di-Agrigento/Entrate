--liquibase formatted sql 
--changeset abrandolini:20250326_152423_inserimento_ruolo_coattivo stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure     INSERIMENTO_RUOLO_COATTIVO
/*************************************************************************
 NOME:        INSERIMENTO_RUOLO_COATTIVO
 DESCRIZIONE: Inserimento accertamenti/liquidazioni in ruolo coattivo
 NOTE:        Versione base: viene lanciata a mano in SQL indicando i
              parametri necessari
 Rev.    Date         Author      Note
 12      07/03/2024   AB          #70891
                                  Aggiunto controllo per sanzioni legate a
                                  un tributo con somma < 0
 11      09/01/2024   RV          #62277
                                  Aggiunto filtro tipo_atto <> 90 in select acc
 10      27/03/2023   AB          inserimento per la TARSU, della parte
                                  netta e non lordo. Tolta la round a 2 dec
                                  per la perc_ricalcolo
                                  con importo_ridotto e versato e la diffo
 9       16/03/2023   AB          se il versato è nei termini si il controllo
                                  con importo_ridotto e versato e la diffo
 8       02/08/2022   VD          Gestione liquidazioni saldate con importo
                                  ridotto.
 7       23/06/2022   VD          Corretta funzione per selezionare importi
                                  accertamenti TARSU: ora si utilizza
                                  F_IMPORTI_ACC al posto di F_IMPORTO_F24_VIOL.
 6       07/06/2022   VD          Modificata selezione importo totale pratica
                                  per tipo tributo TARSU: ora si utilizza la
                                  funzione F_IMPORTO_F24_VIOL.
 5       29/11/2021   VD          Aggiunto parametro dovuto/versato:
                                  ora si trattano anche le pratiche per cui
                                  esistono versamenti parziali (e non solo
                                  quelle non versate interamente).
 4       03/06/2020   VD          Aggiunto inserimento sanzioni su
                                  addizionali nella tabella sanzioni_pratica
 3       21/01/2020   VD          Aggiunto raggruppamento per tributo,
                                  per evitare di inserire piu' righe
                                  con lo stesso tributo in presenza di
                                  addizionali
 2       12/11/2019   SM/VD       Aggiunto test per escludere dal
                                  trattamento le sanzioni con tributo nullo
 1       28/01/2019   VD          Aggiunte sanzioni su addizionali TARSU
 0       26/05/2017   VD          Prima emissione
*************************************************************************/
( p_ruolo                         number
, p_tipo_pratica                  varchar2
, p_tipo_evento                   varchar2
, p_notifica_iniz                 date
, p_notifica_fine                 date
, p_utente                        varchar2
, p_diff_dovuto_versato           number default null
)
is
  w_tipo_tributo                  ruoli.tipo_tributo%type;
  w_anno                          ruoli.anno_ruolo%type;
  w_importo_lordo                 ruoli.importo_lordo%type;
  w_importo_ruolo                 number;
  w_perc_ricalcolo                number;
  w_importo_sanzioni              number;
  w_importo_add_evasa             number;
  w_diff_sanzioni                 number;
  w_data_notifica                 date;
  w_inizio_sosp                   date;
  w_fine_sosp                     date;
  w_gg_sosp                       number;
--
  w_errore                        varchar2(2000);
  errore                          exception;
begin
  --
  -- Controllo esistenza ruolo
  --
  begin
    select tipo_tributo
         , anno_ruolo
         , nvl(importo_lordo,'N')
      into w_tipo_tributo
         , w_anno
         , w_importo_lordo
      from ruoli
     where ruolo = p_ruolo;
  exception
    when others then
      w_errore := 'Errore in ricerca ruolo '||p_ruolo||' - '||sqlerrm;
      raise errore;
  end;
  --
  GET_INPA_SOSP_FERIE(w_anno,w_inizio_sosp,w_fine_sosp,w_gg_sosp);
  --
  -- Trattamento accertamenti/liquidazioni
  -- (EA/VD - 30/05/2017): al contrario di quanto accade nella window,
  --                       qui non trattiamo le eventuali pratiche
  --                       inserite in una ingiunzione definitiva o provvisoria
  --                       Sara' possibile trattarle manualmente dall'apposita
  --                       fase in PB.
  -- (VD - 29/11/2021): si esclude la condizione di where sull'esistenza di
  --                    versamenti. Il controllo verrà eseguito successivamente
  --                    confrontando l'importo della pratica con il totale
  --                    versato, in modo da trattare anche le pratiche
  --                    parzialmente versate
  -- (VD - 07/06/2022): modificata selezione importo totale pratica per tipo
  --                    tributo TARSU
  -- (VD - 22/06/2022): modificata selezione importo totale pratica per tipo
  --                    tributo TARSU
  -- (VD - 02/08/2022): aggiunta selezione importo ridotto, data notifica e
  --                    data massima di versamento
  for acc in (select prtr.pratica
                   , prtr.cod_fiscale
                   , decode(prtr.tipo_tributo
                           --,'TARSU',F_IMPORTO_F24_VIOL(prtr.importo_ridotto,to_number(null),'N',prtr.tipo_tributo,prtr.anno,'E','N')
                           ,'TARSU',decode(nvl(cata.flag_lordo,'N')
                                          ,'S',F_IMPORTI_ACC(PRTR.PRATICA,'N','LORDO')
                                          ,F_IMPORTI_ACC(PRTR.PRATICA,'N','NETTO')
                                          )
                           ,prtr.importo_totale
                           ) importo_totale
    -- (VD - 02/08/2022): aggiunta selezione importo ridotto e data notifica
                   , decode(prtr.tipo_tributo
                           ,'TARSU',decode(nvl(cata.flag_lordo,'N')
                                          ,'S',F_IMPORTI_ACC(PRTR.PRATICA,'S','LORDO')
                                          ,F_IMPORTI_ACC(PRTR.PRATICA,'S','NETTO')
                                          )
                           ,prtr.importo_ridotto
                           ) importo_ridotto
                   , decode(prtr.tipo_tributo
                           --,'TARSU',F_IMPORTO_F24_VIOL(prtr.importo_ridotto,to_number(null),'N',prtr.tipo_tributo,prtr.anno,'E','N')
                           ,'TARSU',decode(w_importo_lordo
                                          ,'S',F_IMPORTI_ACC(PRTR.PRATICA,'N','LORDO')
                                          ,F_IMPORTI_ACC(PRTR.PRATICA,'N','NETTO')
                                          )
                           ,prtr.importo_totale
                           ) importo_netto
                   , prtr.data_notifica
    -- (VD - 29/11/2021): si seleziona il totale versato per pratica, per
    --                    verificare se la pratica e' da trattare oppure no
                   , (select nvl(sum(importo_versato),0) from versamenti where pratica = prtr.pratica) importo_versato
    -- (VD - 02/08/2022): aggiunta selezione data massima di versamento
                   , (select max(data_pagamento) from versamenti where pratica = prtr.pratica) data_versamento
                   , nvl(cata.flag_lordo,'N') cata_lordo
                   , cata.addizionale_pro
                from pratiche_tributo prtr
                   , carichi_tarsu    cata
               where prtr.tipo_tributo = w_tipo_tributo
                 and prtr.anno = w_anno
                 and cata.anno = w_anno
                 and ((nvl(p_tipo_pratica,'T') = 'T' and prtr.tipo_pratica in ('A','L')) or
                      prtr.tipo_pratica = nvl(p_tipo_pratica,'T'))
                 and ((nvl(p_tipo_evento,'T') = 'T' and prtr.tipo_evento in ('A', 'U')) or
                      prtr.tipo_evento = decode(nvl(p_tipo_evento,'T'),'M','U',nvl(p_tipo_evento,'T')))
    -- (RV - 09/01/2024): aggiunto filtro per sole pratiche non rateizzate
                 and nvl(prtr.tipo_atto,0) <> 90
                 and nvl(prtr.importo_totale,0) > 0
                 and prtr.pratica_rif is null
                 and nvl(prtr.stato_accertamento,'D') = 'D'
                 and prtr.data_notifica is not null
                 and prtr.data_notifica between nvl(p_notifica_iniz,to_date('01/01/1900','dd/mm/yyyy'))
                                            and nvl(p_notifica_fine,to_date('31/12/2999','dd/mm/yyyy'))
                 --and not exists (select 'x' from versamenti vers
                 --                 where vers.pratica = prtr.pratica)
--                 and not exists (select 'x'
--                                   from sanzioni_pratica sapr
--                                  where sapr.pratica = prtr.pratica
--                                    and (sapr.ruolo is not null or
--                                         sapr.importo < 0))
                 -- AB 07/03/2024 Aggiunta la condizione sulla sum dell'importo legato al tributo e non alla siola sanzione
                 and not exists (select 1
                                   from sanzioni sanz, sanzioni_pratica sapr
                                  where sanz.tipo_tributo = sapr.tipo_tributo
                                    and sanz.cod_sanzione = sapr.cod_sanzione
                                    and sanz.sequenza     = sapr.sequenza_sanz
                                    and sapr.pratica = prtr.pratica
                                  group by sapr.pratica, sanz.tributo
                                 having (max(sapr.ruolo) is not null or
                                         sum(sapr.importo) < 0))
               order by pratica)
  loop
    -- (VD - 02/08/2022): se la data di notifica ricade nel periodo di 
    --                    sospensione, si considera come notifica il primo 
    --                    giorno successivo alla fine della sospensione
    w_data_notifica := acc.data_notifica;
    if w_inizio_sosp is not null and w_fine_sosp is not null and w_gg_sosp is not null then
       if w_data_notifica between w_inizio_sosp and w_fine_sosp then
          w_data_notifica := w_fine_sosp + 1;
       end if;
    end if;
    w_data_notifica := w_data_notifica + 60;
-- AB (27/03/2023 non mettiamo a ruolo se il versato è maggiore del netto    
    if acc.importo_netto <= acc.importo_versato then  
       w_importo_ruolo := 0;
    else
        w_importo_ruolo := acc.importo_totale - acc.importo_versato;
        if acc.importo_versato > 0 then
           -- (VD -02/08/2022): se il versamento dell'importo ridotto e' stato
           --                   effettuato entro 60 gg dalla data di notifica,
           --                   la pratica non e' da trattare
    --       if acc.data_versamento <= w_data_notifica and
    --          acc.importo_ridotto <= acc.importo_versato then 
    --          w_importo_ruolo := 0
    --       end if;

           -- AB 16/03/2023 se il versato è nei termini si il controllo con importo_ridotto e versato e la diff
           if acc.data_versamento <= w_data_notifica and
              (acc.importo_ridotto - acc.importo_versato) <= nvl(p_diff_dovuto_versato,1) then
              w_importo_ruolo := 0;
           end if;
        end if;
    end if;
    
    if w_importo_ruolo > nvl(p_diff_dovuto_versato,1) then
       -- (AB 27/03/32022):  Tolta la round a 2 per avere dati piu precisi, 
       --                    anche se con maggiore difficoltà nel calcolarli a mano
       w_perc_ricalcolo := 100 - (acc.importo_versato * 100 / acc.importo_totale);
       -- (VD - 03/06/2020): Aggiunto inserimento sanzioni su addizionali
       --                    nella tabella sanzioni_pratica
       -- (VD - 29/11/2021): Spostato inserimento prima del trattamento in modo
       --                    da avere tutte le sanzioni gia' inserite
       --                    Solo per la TARSU
       if w_tipo_tributo = 'TARSU' then
          for sanz in (select sanz.cod_sanzione
                            , F_SANZIONI_ADDIZIONALI(acc.pratica,sanz.cod_sanzione) imp_ruolo
                         from sanzioni     sanz
                            , tipi_tributo titr
                        where sanz.cod_sanzione in (891,892,893,894)
                          and sanz.tipo_tributo = 'TARSU'
                          and F_SANZIONI_ADDIZIONALI(acc.pratica,sanz.cod_sanzione) > 0
                          and titr.tipo_tributo = w_tipo_tributo
                          and w_importo_lordo = 'S'
                          and sanz.tributo is not null
                          and not exists (select 'x'
                                            from sanzioni_pratica sapr
                                           where sapr.pratica = acc.pratica
                                             and sapr.cod_sanzione = sanz.cod_sanzione
                                         )
                      )
          loop
            begin
              insert into sanzioni_pratica
                   ( pratica,cod_sanzione,tipo_tributo
                   , ruolo, importo_ruolo, utente
                   )
              values ( acc.pratica, sanz.cod_sanzione, w_tipo_tributo
                    , p_ruolo, sanz.imp_ruolo, p_utente
                    );
            exception
              when others then
                w_errore:= 'Errore in inserimento SAPR '||acc.pratica||' - '||sqlerrm;
                raise errore;
            end;
          end loop;
       end if;
       --
       -- Aggiornamento ruolo su SANZIONI_PRATICA
       --
       begin
         update SANZIONI_PRATICA
            set ruolo         = p_ruolo
              , importo_ruolo = round(importo * w_perc_ricalcolo / 100,2)
          where pratica = acc.pratica;
       exception
         when others then
           w_errore:= 'Errore in aggiornamento SAPR '||acc.pratica||' - '||sqlerrm;
           raise errore;
       end;
       -- Si verifica se il totale inserito nelle pratiche coincide con il
       -- totale da mettere a ruolo
       select nvl(sum(importo_ruolo),0)
         into w_importo_sanzioni
         from sanzioni_pratica
        where pratica = acc.pratica
       ;
       if w_tipo_tributo = 'TARSU' then  -- rideterminazione dell'importo a ruolo toglioendo l'add_pro dell'evasa
           select nvl(sum(f_round(importo_ruolo*acc.addizionale_pro/100,1)),0)
             into w_importo_add_evasa
             from sanzioni sanz, sanzioni_pratica sapr
            where sanz.cod_sanzione = sapr.cod_sanzione
              and sanz.sequenza     = sapr.sequenza_sanz
              and sanz.tipo_tributo = sapr.tipo_tributo
              and nvl(tipo_causale,'X') = 'E'
              and pratica = acc.pratica
           ;
           w_importo_ruolo := w_importo_ruolo - w_importo_add_evasa;  
       end if;
--       if acc.pratica = 302573 then
--        w_errore:= 'Sanzioni '||w_importo_sanzioni||' Importo_ruolo '||w_importo_ruolo||
--                   ' vers '||acc.importo_versato||' no evasa '||w_importo_NO_evasa||' evasa '||w_importo_evasa||' perc '||w_perc_ricalcolo;
--        raise errore;
--       end if;
       --
       if w_importo_sanzioni <> w_importo_ruolo then
          w_diff_sanzioni := w_importo_ruolo - w_importo_sanzioni;
          begin
            update sanzioni_pratica sapr
               set sapr.importo_ruolo = sapr.importo_ruolo + w_diff_sanzioni
             where sapr.pratica = acc.pratica
               and rowid = (select min(sap1.rowid)
                              from sanzioni_pratica sap1
                             where sap1.pratica = acc.pratica
                               and sap1.importo_ruolo = (select max(sap2.importo_ruolo)
                                                           from sanzioni_pratica sap2
                                                          where sap2.pratica = acc.pratica)
                           );
          exception
            when others then
              w_errore:= 'Errore in aggiornamento SAPR (arr.) '||acc.pratica||' - '||sqlerrm;
              raise errore;
          end;
       end if;
       --
       -- Inserimento ruoli_contribuente
       -- (VD - 21/01/2020): utilizzata la select come vista implicita,
       --                    per raggruppare gli importi per tributo
       --
       for sanz in (select ruco.tributo
                         , sum(ruco.importo) importo
                      from
                   (select sanz.tributo
                         , sum(sapr.importo_ruolo) importo
                      from sanzioni_pratica sapr,
                           sanzioni         sanz
                     where sapr.pratica      = acc.pratica
                       and sanz.cod_sanzione = sapr.cod_sanzione
                       and sanz.sequenza     = sapr.sequenza_sanz
                       and sanz.tipo_tributo = sapr.tipo_tributo
                       and sanz.tributo is not null                -- (12/11/2019 - SM)
                     group by sanz.tributo
                  -- (VD - 29/11/2021): commentato ricalcolo sanzioni su addizionali
                  --                    perche' tali sanzioni vengono inserite
                  --                    nella tabella sanzioni_pratica
                  /*union
                    select sanz.tributo
                         , F_SANZIONI_ADDIZIONALI(acc.pratica,sanz.cod_sanzione)
                      from sanzioni     sanz
                         , tipi_tributo titr
                     where sanz.cod_sanzione in (891,892,893,894)
                       and sanz.tipo_tributo = 'TARSU'
                       and F_SANZIONI_ADDIZIONALI(acc.pratica,sanz.cod_sanzione) > 0
                       and titr.tipo_tributo = w_tipo_tributo
                       and w_importo_lordo = 'S'
                       and sanz.tributo is not null                -- (12/11/2019 - SM)
                       and not exists (select 'x'
                                         from ruoli_contribuente ruco
                                        where ruco.ruolo   = p_ruolo
                                          and ruco.pratica = acc.pratica
                                      )
                  -- (VD - 29/05/2020): commentato ricalcolo sanzioni su addizionali
                  --                    perche' tali sanzioni vengono inserite
                  --                    nella tabella sanzioni_pratica
                    union
                    select distinct sanzioni.tributo tributo,
                           F_SANZIONI_ADDIZIONALI(acc.pratica,sanzioni.cod_sanzione)
                      FROM sanzioni,
                           ruoli_contribuente,
                           tipi_tributo
                     WHERE ruoli_contribuente.ruolo          = p_ruolo
                       and sanzioni.cod_sanzione             in (891,892,893,894)
                       and sanzioni.tipo_tributo             = w_tipo_tributo
                       and sanzioni.tributo is not null            -- (12/11/2019 - SM)
                       and ruoli_contribuente.pratica        = acc.pratica
                       and sanzioni.tributo                  = ruoli_contribuente.tributo
                       and F_SANZIONI_ADDIZIONALI(acc.pratica,SANZIONI.cod_sanzione) > 0 */
                     order by 1) ruco
                    group by ruco.tributo)
       loop
         if sanz.importo < 0 then
            w_errore := 'importo < '||sanz.importo||' per cod_fiscale: '||acc.cod_fiscale||
                        ' pratica: '|| acc.pratica||' perc: '||w_perc_ricalcolo;
            raise errore;
         end if;
         begin
           insert into ruoli_contribuente
                 (ruolo
                 ,cod_fiscale
                 ,pratica
                 ,tributo
                 ,importo
                 ,utente
                 )
           values ( p_ruolo
                  , acc.cod_fiscale
                  , acc.pratica
                  , sanz.tributo
                  , sanz.importo
                  , p_utente
                  )
                 ;
         exception
           when others then
             w_errore:= 'Errore in inserimento RUCO '||acc.pratica||' - '||sqlerrm;
             raise errore;
         end;
       end loop;
    end if;
  end loop;
exception
  when errore then
       rollback;
       raise_application_error(-20999, w_errore);
  when others then
       rollback;
       raise_application_error (-20999, 'INSERIMENTO_RUOLO_COATTIVO ('||SQLERRM||')');
END;
/* End Procedure: INSERIMENTO_RUOLO_COATTIVO */
/
