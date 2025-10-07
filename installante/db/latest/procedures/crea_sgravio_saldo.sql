--liquibase formatted sql 
--changeset abrandolini:20250326_152423_crea_sgravio_saldo stripComments:false runOnChange:true 
 
create or replace procedure CREA_SGRAVIO_SALDO
( p_importo_sgravio         number
, p_importo_sgravio_base    number
, p_cf                      varchar2
, p_anno                    number
, p_titr                    varchar2
, p_ogpr                    number
, p_ruolo                   number
, p_magg_tares              number
, p_flag_tariffa_base       varchar2)
 IS
/*******************************************************************************
 Rev. Data       Autore Descrizione
 ---- ---------- ------ ------------------------------------------------------
 002  25/10/2018 VD     Aggiunta gestione campi calcolati con tariffa base
 001  30/06/2015 VD     Modificata selezione ruoli: ora tratta tutti i tipi
                        ruolo (principale e suppletivi). In presenza di piu
                        suppletivi emette lo sgravio sul suppletivo precedente
                        anziche sul principale.
 *******************************************************************************/
CURSOR sel_ruco IS
  select ruco.ruolo
        ,ruco.cod_fiscale
        ,ruco.sequenza
        ,99 motivo_sgravio
        ,round((ruco.importo-nvl(sgra.importo,0)),2) importo
        ,round((ruco.importo_base-nvl(sgra.importo_base,0)),2) importo_base
        ,ruco.mesi_ruolo
        ,ruco.giorni_ruolo
        ,ruol.importo_lordo
   from ruoli_contribuente   ruco
      , ruoli                ruol
      , oggetti_pratica      ogpr
      , oggetti_imposta      ogim
      , (SELECT ruolo, cod_fiscale, sequenza,
                SUM (NVL (importo, 0)) importo,
                SUM (NVL (maggiorazione_tares, 0)) maggiorazione_tares,
--                SUM (NVL (maggiorazione_eca, 0)) maggiorazione_eca,
--                SUM (NVL (addizionale_eca, 0)) addizionale_eca,
--                SUM (NVL (addizionale_pro, 0)) addizionale_pro,
--                SUM (NVL (iva, 0)) iva,
                SUM (NVL (importo_base, 0)) importo_base
           FROM sgravi
          WHERE cod_fiscale = p_cf
          GROUP BY ruolo, cod_fiscale, sequenza) sgra
  where ruol.ruolo            = ruco.ruolo
    and ogim.oggetto_imposta  = ruco.oggetto_imposta
    and ogim.cod_fiscale      = p_cf
    and ogpr.oggetto_pratica  = ogim.oggetto_pratica
    and nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
                                = p_ogpr
    and ruco.ruolo            = ogim.ruolo
    and ruol.invio_consorzio is not null
    and nvl(ruol.tipo_emissione,'T')   = 'S'
-- (VD - 30/06/2015): commentato per trattare anche eventuali ruoli suppletivi
--    and ruol.tipo_ruolo       = 1 -- Principale
    and ruol.anno_ruolo       = p_anno
    and ruco.cod_fiscale      = p_cf
    and ruol.tipo_tributo||'' = p_titr
    and sgra.ruolo        (+) = ruco.ruolo
    and sgra.cod_fiscale  (+) = ruco.cod_fiscale
    and sgra.sequenza     (+) = ruco.sequenza
--    and sgra.FLAG_AUTOMATICO  (+) = 'S'
  order by 1 desc,2,3 desc
  ;
   w_chk_sgravi                 varchar2(1);
   w_importo                    number;
   w_addizionale_pro            number;
   w_addizionale_eca            number;
   w_maggiorazione_eca          number;
   w_aliquota                   number;
   w_aliquota_iva               number;
   w_tot_addizionali            number;
   w_imp_addizionale_pro        number;
   w_imp_addizionale_eca        number;
   w_imp_maggiorazione_eca      number;
   w_imp_aliquota               number;
   w_compensazione              number;
--
-- (VD - 25/10/2018): Variabile per gestione importi calcolati con tariffa base
--
   w_importo_base               number;
   w_tot_addizionali_base       number;
   w_imp_add_pro_base           number;
   w_imp_add_eca_base           number;
   w_imp_magg_eca_base          number;
   w_imp_aliquota_base          number;
   w_compensazione_base         number;
BEGIN
  BEGIN
     select nvl(addizionale_pro,0)
           ,nvl(addizionale_eca,0)
           ,nvl(maggiorazione_eca,0)
           ,nvl(aliquota,0)
       into w_addizionale_pro
           ,w_addizionale_eca
           ,w_maggiorazione_eca
           ,w_aliquota
       from carichi_tarsu
      where anno              = p_anno
      ;
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
        w_addizionale_pro    := 0;
        w_addizionale_eca    := 0;
        w_maggiorazione_eca  := 0;
        w_aliquota           := 0;
        w_aliquota_iva       := null;
     WHEN others THEN
        RAISE_APPLICATION_ERROR(-20919,'Errore in ricerca Carichi Tarsu'||
                                        ' ('||sqlerrm||')');
  END;
  BEGIN
    insert into motivi_sgravio
    select 99, 'ECCEDENZA DI GETTITO'
      from dual
     where not exists (select 'x'
                         from motivi_sgravio
                        where motivo_sgravio = 99);
  END;
  w_importo := p_importo_sgravio;
  w_importo_base := p_importo_sgravio_base;
  FOR rec_ruco IN sel_ruco LOOP
    --
    -- (VD - 05/12/2014: Aggiunto nvl su maggiorazione tares
    --
--    dbms_output.put_line('Trattamento ruolo: '||rec_ruco.ruolo);
    IF w_importo + nvl(p_magg_tares,0) > 0 THEN
         -- Commentata perchè anche se lo sgravio è maggiore dell'importo del ruolo
         -- lo inseriamo comunque tutto
         -- if rec_ruco.importo >= w_importo_sgravio then
         --    w_importo := w_importo_sgravio;
         --    w_importo_sgravio := 0;
         -- else
         --    w_importo := rec_ruco.importo;
         --    w_importo_sgravio := w_importo_sgravio - rec_ruco.importo;
         -- end if;
       if nvl(rec_ruco.importo_lordo,'N') = 'N' then
          w_addizionale_pro       := 0;
          w_addizionale_eca       := 0;
          w_maggiorazione_eca     := 0;
          w_aliquota              := 0;
       end if;
       if w_importo > 0 then
          w_imp_addizionale_pro   := round(w_importo * w_addizionale_pro / 100,2);
          w_imp_addizionale_eca   := round(w_importo * w_addizionale_eca / 100,2);
          w_imp_maggiorazione_eca := round(w_importo * w_Maggiorazione_eca / 100,2);
          w_imp_aliquota          := round(w_importo * w_aliquota / 100,2);
          w_tot_addizionali       := nvl(w_imp_addizionale_pro,0)
                                   + nvl(w_imp_addizionale_eca,0)
                                   + nvl(w_imp_maggiorazione_eca,0)
                                   + nvl(w_imp_aliquota,0);
          w_importo   := w_importo + w_tot_addizionali + nvl(p_magg_tares,0);
       else
          w_importo   := w_importo + nvl(p_magg_tares,0);
       end if;
       if w_importo_base > 0 then
          w_imp_add_pro_base      := round(w_importo_base * w_addizionale_pro / 100,2);
          w_imp_add_eca_base      := round(w_importo_base * w_addizionale_eca / 100,2);
          w_imp_magg_eca_base     := round(w_importo_base * w_Maggiorazione_eca / 100,2);
          w_imp_aliquota_base     := round(w_importo_base * w_aliquota / 100,2);
          w_tot_addizionali_base  := nvl(w_imp_add_pro_base,0)
                                   + nvl(w_imp_add_eca_base,0)
                                   + nvl(w_imp_magg_eca_base,0)
                                   + nvl(w_imp_aliquota_base,0);
          w_importo_base := w_importo_base + w_tot_addizionali_base;
       else
          w_importo_base := w_importo_base;
       end if;
       BEGIN
         insert into sgravi
                ( ruolo, cod_fiscale, sequenza, sequenza_sgravio
                , motivo_sgravio, importo
                , addizionale_eca, maggiorazione_eca, addizionale_pro, iva
                , mesi_sgravio, giorni_sgravio, flag_automatico,tipo_sgravio
                , maggiorazione_tares, note, ruolo_inserimento
                , importo_base, addizionale_eca_base, maggiorazione_eca_base
                , addizionale_pro_base, iva_base
                )
         values ( rec_ruco.ruolo, rec_ruco.cod_fiscale, rec_ruco.sequenza, null
                , rec_ruco.motivo_sgravio, w_importo
                , w_imp_addizionale_eca, w_imp_maggiorazione_eca, w_imp_addizionale_pro, w_imp_aliquota
                , rec_ruco.mesi_ruolo, rec_ruco.giorni_ruolo, 'S','D'
                , p_magg_tares, 'Inserito da ruolo: '||p_ruolo,p_ruolo
                , w_importo_base, w_imp_add_eca_base, w_imp_magg_eca_base
                , w_imp_add_pro_base, w_imp_aliquota_base
                )
         ;
       EXCEPTION
         WHEN others THEN
           RAISE_APPLICATION_ERROR(-20919,'Errore in inserimento sgravio '||
                                          ' cod_fiscale '||rec_ruco.cod_fiscale||
                                          ' sequenza '||rec_ruco.sequenza||
                                          ' ('||sqlerrm||')');
       END;
-- Inserimento anche della Compensazione nel Ruolo a Saldo per avere il dato anche qui (22/10/2103) AB
       BEGIN
            insert into motivi_compensazione
            select 99, 'ECCEDENZA DI GETTITO'
              from dual
             where not exists (select 'x'
                                 from motivi_compensazione
                                where motivo_compensazione = 99);
       END;
       BEGIN
         select compensazione
              , compensazione_base
           into w_compensazione
              , w_compensazione_base
           from compensazioni_ruolo
          where cod_fiscale =  rec_ruco.cod_fiscale
            and anno = p_anno
            and ruolo = p_ruolo
            and oggetto_pratica = p_ogpr
            and flag_automatico = 'S'
         ;
       EXCEPTION
          WHEN no_data_found THEN
             w_compensazione := 0;
          WHEN others THEN
            RAISE_APPLICATION_ERROR(-20919,'Errore in ricerca Compensazione Ruolo '||
                                          ' cod_fiscale '||rec_ruco.cod_fiscale||
                                          ' oggetto_pratica '||p_ogpr||
                                          ' ('||sqlerrm||')');
       END;
       IF w_compensazione > 0 THEN
          BEGIN
             update compensazioni_ruolo
                 set compensazione =  compensazione + w_importo
                   , note = note||' + '||w_importo
                   , compensazione_base = decode(p_flag_tariffa_base
                                                ,'S',nvl(compensazione_base,0) + nvl(w_importo_base,0)
                                                    ,compensazione_base)
             where cod_fiscale =  rec_ruco.cod_fiscale
                and anno = p_anno
                and ruolo = p_ruolo
                and oggetto_pratica = p_ogpr
             ;
          EXCEPTION
             WHEN others THEN
                RAISE_APPLICATION_ERROR(-20919,'Errore in aggiornamento  Compensazione Ruolo '||
                                              ' cod_fiscale '||rec_ruco.cod_fiscale||
                                              ' oggetto_pratica '||p_ogpr||
                                              ' ('||sqlerrm||')');
          END;
       ELSE -- w_compensazione > 0
          BEGIN
                insert into compensazioni_ruolo
                       ( cod_fiscale, anno, ruolo, oggetto_pratica, motivo_compensazione, compensazione
                       , utente, note, flag_automatico, compensazione_base)
                values ( rec_ruco.cod_fiscale, p_anno, p_ruolo, p_ogpr, 99, w_importo
                          ,'AUTO','Compensazione inserita come Discarico automatico in Acconto '||w_importo, 'S',
                          decode(p_flag_tariffa_base,'S',w_importo_base,to_number(null)))
                ;
          EXCEPTION
                WHEN others THEN
                  RAISE_APPLICATION_ERROR(-20919,'Errore in inserimento Compensazione Ruolo '||
                                                 ' cod_fiscale '||rec_ruco.cod_fiscale||
                                                 ' oggetto_pratica '||p_ogpr||
                                                 ' ('||sqlerrm||')');
          END;
       END IF;  -- Compensazione presente
--         WHEN others THEN
--           RAISE_APPLICATION_ERROR(-20919,'Errore in ricerca sgravio '||
--                                          ' cod_fiscale '||rec_ruco.cod_fiscale||
--                                          ' sequenza '||rec_ruco.sequenza||
--                                          ' ('||sqlerrm||')');
--       END;
    END IF;
  END LOOP;
END;
/* End Procedure: CREA_SGRAVIO_SALDO */
/

