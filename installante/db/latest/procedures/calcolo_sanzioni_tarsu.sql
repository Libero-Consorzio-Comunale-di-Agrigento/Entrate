--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_sanzioni_tarsu stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure     CALCOLO_SANZIONI_TARSU
/*************************************************************************
Versione  Data              Autore    Descrizione
 6        28/05/2025        RV        #77612
                                      Adeguamento nuovo DL regime sanzionatorio
 5        02/02/2023        AB        Issue #48451
                                      Aggiunta la eliminazione sanzioni per deceduti
 4        23/01/2023        RV        Issue #60310
                                      Aggiunto flag a_flag_ignora_sanz_minima
 3        19/02/2020        VD        Corretta selezione sanzioni per 
                                      sanzione minima: non considerava il
                                      tipo tributo
 2        24/07/2018        VD        Modificata gestione sanzione minima
 1        29/01/2015        VD        Sostituito codice sanzione 115 con
                                      codice 197
**************************************************************************/
(a_cod_fiscale              IN varchar2,
 a_anno                     IN number,
 a_pratica                  IN number,
 a_oggetto_pratica          IN number,
 a_imposta                  IN number,
 a_anno_denuncia            IN number,
 a_data_denuncia            IN date,
 a_imposta_dichiarata       IN number,
 a_nuovo_sanzionamento      IN varchar2,
 a_flag_tardivo             IN varchar2,
 a_utente                   IN varchar2,
 a_interessi_dal            IN date,
 a_interessi_al             IN date,
 a_imposta_magg_tares       IN number,
 a_imposta_dic_magg_tares   IN number,
 a_flag_ignora_sanz_minima  varchar2 default null)
IS
  --
  C_TIPO_TRIBUTO        CONSTANT varchar2(5) := 'TARSU';
  C_TASSA_EVASA         CONSTANT number := 1;
  C_OMESSA_DEN          CONSTANT number := 2;
  C_INFEDELE_DEN        CONSTANT number := 4;
  C_TARD_DEN_SUP_30     CONSTANT number := 5;
  C_TARD_DEN_INF_30     CONSTANT number := 6;
  C_NUOVO               CONSTANT number := 100;
  C_NUOVO_MAGG_TARES    CONSTANT number := 550;
  C_SPESE_NOT           CONSTANT number := 197;
  --
  w_data_scadenza                date;
  w_cod_sanzione                 number;
  w_maggiore_imposta             number;
  w_maggiore_imposta_magg_tares  number;
--w_importo                      number;
--w_importo_magg_tares           number;
  w_add_eca                      number;
  w_mag_eca                      number;
  w_add_pro                      number;
  w_iva                          number;
  w_add_eca2                     number;
  w_mag_eca2                     number;
  w_add_pro2                     number;
  w_iva2                         number;
  w_flag_sanz_p                  varchar2(1);
  w_flag_sanz_t                  varchar2(1);
  w_flag_int                     varchar2(1);
  w_tipo_occ                     varchar2(1);
  w_flag_ruolo                   varchar2(1);
  w_importo_lordo                number;
  w_return                       number;
  w_errore                       varchar2(2000);
  w_flag_sanz_magg_tares         number;
--w_interessi_magg_tares         number;
  --
  errore                         exception;
  --
  w_stato_sogg                   number(2);
  --
  w_data_accertamento            date;
  w_data_riferimento             date;
  --
--
-- (VD - 24/07/2018): variabili per gestione sanzione minima cumulativa
--
  w_imp_sanzione                 number;
  w_percentuale                  number;
  w_riduzione                    number;
  w_riduzione_2                  number;
  --
--------------------------------------------
-- CALCOLO_SANZIONI_TARSU ------------------
--------------------------------------------
BEGIN
  BEGIN
    select nvl(cotr.flag_ruolo,'N')
      into w_flag_ruolo
      from oggetti_pratica   ogpr
         , codici_tributo    cotr
     where cotr.tributo         = ogpr.tributo
       and ogpr.oggetto_pratica = a_oggetto_pratica
    ;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      w_flag_ruolo := 'N';
  END;
  BEGIN
    delete sanzioni_pratica
     where pratica         = a_pratica
       and oggetto_pratica = a_oggetto_pratica
    ;
  EXCEPTION
    WHEN others THEN
      RAISE_APPLICATION_ERROR(-20999,'Errore in cancellazione Sanzioni Pratica');
  END;
  BEGIN
    select prtr.data
      into w_data_accertamento
      from pratiche_tributo prtr
     where prtr.pratica  = a_pratica
    ;
  EXCEPTION
    WHEN others THEN
        RAISE_APPLICATION_ERROR(-20999,'Errore ricavando dati Pratica');
  END;
  --
  BEGIN
    select data_scadenza
      into w_data_scadenza
      from scadenze
     where tipo_scadenza = 'D'
       and tipo_tributo  = C_TIPO_TRIBUTO
       and anno          = a_anno
    ;
  EXCEPTION
    WHEN others THEN
    w_errore := 'Errore in ricerca Scadenze '||'('||SQLERRM||')';
    RAISE errore;
  END;
  --
 -- Data riferimento Sanzioni 10x e 55x - Scadenza della denuncia per l'anno in accertamento
  --
  w_data_riferimento := w_data_scadenza;
  --
  begin
    select distinct 1
      into w_flag_sanz_magg_tares
      from carichi_tarsu
     where anno = a_anno
       and maggiorazione_tares is not null
     ;
  exception
    when others then
      w_flag_sanz_magg_tares := 0;
  end;
  --
--  IF a_imposta < nvl(a_imposta_dichiarata,0) THEN
--     w_errore := 'Importo accertato minore rispetto a quello dichiarato';
--     RAISE errore;
--  END IF;
  --
  w_maggiore_imposta := a_imposta - nvl(a_imposta_dichiarata,0);
  w_maggiore_imposta_magg_tares := nvl(a_imposta_magg_tares, 0) - nvl(a_imposta_dic_magg_tares,0);
  BEGIN
    select nvl(f_round(CATA.ADDIZIONALE_ECA * nvl(w_maggiore_imposta,0)/100,1),0),
           nvl(f_round(CATA.MAGGIORAZIONE_ECA * nvl(w_maggiore_imposta,0)/100,1),0),
           nvl(f_round(CATA.ADDIZIONALE_PRO * nvl(w_maggiore_imposta,0)/100,1),0),
           nvl(f_round(CATA.ALIQUOTA * nvl(w_maggiore_imposta,0)/100,1),0),
           nvl(f_round(CATA.ADDIZIONALE_ECA * nvl(a_imposta,0)/100,1),0),
           nvl(f_round(CATA.MAGGIORAZIONE_ECA * nvl(a_imposta,0)/100,1),0),
           nvl(f_round(CATA.ADDIZIONALE_PRO * nvl(a_imposta,0)/100,1),0),
           nvl(f_round(CATA.ALIQUOTA * nvl(a_imposta,0)/100,1),0),
           nvl(CATA.FLAG_SANZIONE_ADD_P,'N'),
           nvl(CATA.FLAG_SANZIONE_ADD_T,'N'),
           nvl(CATA.FLAG_INTERESSI_ADD,'N')
      into w_add_eca, w_mag_eca, w_add_pro, w_iva,
           w_add_eca2, w_mag_eca2, w_add_pro2, w_iva2,
           w_flag_sanz_p, w_flag_sanz_t, w_flag_int
      from carichi_tarsu cata
     where cata.anno            = a_anno
    ;
  EXCEPTION
    WHEN others THEN
      w_errore := 'Errore in ricerca Carichi Tarsu '||'('||SQLERRM||')';
      RAISE errore;
  END;
  BEGIN
    select nvl(max(nvl(ogpr.tipo_occupazione,'P')),'P')
      into w_tipo_occ
      from oggetti_pratica ogpr
     where ogpr.pratica = a_pratica
    ;
  END;
  --
--w_cod_sanzione := C_TASSA_EVASA;
--inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,NULL,w_maggiore_imposta,a_utente);
  w_cod_sanzione := C_TASSA_EVASA + C_NUOVO;
  inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,NULL,w_maggiore_imposta,a_utente,0,w_data_riferimento);
  if w_flag_sanz_magg_tares > 0 and
     w_maggiore_imposta_magg_tares <> 0 then
    w_cod_sanzione := C_TASSA_EVASA + 500;-- EVASA COD 501, MENTRE LE ALTRE HANNO COME BASE IL 550
    inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,NULL,w_maggiore_imposta_magg_tares,a_utente,0,w_data_riferimento);
  end if;
  --
--
-- L`applicazione dell`addizionale provinciale per il calcolo delle sanzioni
-- e` subordinata alla presenza del relativo indicatore nei carichi tarsu.
--
  if w_flag_ruolo = 'S' and (   w_tipo_occ = 'P' and w_flag_sanz_p = 'S'
                             or w_tipo_occ = 'T' and w_flag_sanz_t = 'S'
                            ) then
     w_maggiore_imposta :=  w_maggiore_imposta + w_add_pro;
  end if;
  IF nvl(a_imposta_dichiarata,0) = 0 THEN
  --Omessa
  --IF a_flag_tardivo = 'N' THEN
  --   w_cod_sanzione := C_OMESSA_DEN;
  --ELSE
  --   w_cod_sanzione := C_TARD_DEN_SUP_30;
  --END IF;
    --
    -- (VD - 24/07/2018): si calcola la sanzione netta sulle imposte per
    --                    verificare successivamente se il totale supera
    --                    la sanzione minima
    --
  --w_imp_sanzione := f_round(f_importo_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_maggiore_imposta,
  --                                             w_percentuale,w_riduzione,w_riduzione_2,a_pratica,'S',w_data_riferimento),0);
  --inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,to_number(null),w_imp_sanzione,a_utente);
    IF a_flag_tardivo = 'N' THEN
       w_cod_sanzione := C_OMESSA_DEN + C_NUOVO;
    ELSE
       w_cod_sanzione := C_TARD_DEN_SUP_30 + C_NUOVO;
    END IF;
    w_imp_sanzione := f_round(f_importo_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_maggiore_imposta,
                                                 w_percentuale,w_riduzione,w_riduzione_2,a_pratica,'S',w_data_riferimento),0);
    inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,to_number(null),w_imp_sanzione,a_utente,0,w_data_riferimento);
    if w_flag_sanz_magg_tares > 0 then
       IF a_flag_tardivo = 'N' THEN
          w_cod_sanzione := C_OMESSA_DEN + C_NUOVO_MAGG_TARES;
       ELSE
          w_cod_sanzione := C_TARD_DEN_SUP_30 + C_NUOVO_MAGG_TARES;
       END IF;
       --
       -- (VD - 24/07/2018): si calcola la sanzione netta sulla maggiorazione
       --                    TARES per verificare successivamente se il totale
       --                    supera la sanzione minima
       --
       w_imp_sanzione := f_round(f_importo_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_maggiore_imposta_magg_tares,
                                                    w_percentuale,w_riduzione,w_riduzione_2,a_pratica,'S',w_data_riferimento),0);
       inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,to_number(null),w_imp_sanzione,a_utente,0,w_data_riferimento);
    end if;
  ELSE
  --Infedele
  --w_cod_sanzione := C_INFEDELE_DEN;
    --
    -- (VD - 24/07/2018): si calcola la sanzione netta sulle imposte per
    --                    verificare successivamente se il totale supera
    --                    la sanzione minima
    --
  --w_imp_sanzione := f_round(f_importo_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_maggiore_imposta,
  --                                             w_percentuale,w_riduzione,w_riduzione_2,a_pratica,'S',w_data_riferimento),0);
  --inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,to_number(null),w_imp_sanzione,a_utente);
    w_cod_sanzione := C_INFEDELE_DEN + C_NUOVO;
    w_imp_sanzione := f_round(f_importo_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_maggiore_imposta,
                                                 w_percentuale,w_riduzione,w_riduzione_2,a_pratica,'S',w_data_riferimento),0);
    inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,to_number(null),w_imp_sanzione,a_utente,0,w_data_riferimento);
    if w_flag_sanz_magg_tares > 0 then
       w_cod_sanzione := C_INFEDELE_DEN + C_NUOVO_MAGG_TARES;
       --
       -- (VD - 24/07/2018): si calcola la sanzione netta sulla maggiorazione
       --                    TARES per verificare successivamente se il totale
       --                    supera la sanzione minima
       --
       w_imp_sanzione := f_round(f_importo_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,w_maggiore_imposta_magg_tares,
                                                    w_percentuale,w_riduzione,w_riduzione_2,a_pratica,'S',w_data_riferimento),0);
       inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,to_number(null),w_imp_sanzione,a_utente,0,w_data_riferimento);
    end if;
  END IF;
  IF a_anno = a_anno_denuncia THEN
     w_data_scadenza := f_scadenza_denuncia(C_TIPO_TRIBUTO,a_anno_denuncia);
     IF to_number(a_data_denuncia - w_data_scadenza) > 60 THEN
      --w_cod_sanzione := C_TARD_DEN_SUP_30;
      --inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,w_maggiore_imposta,NULL,a_utente,0,w_data_riferimento);
        w_cod_sanzione := C_TARD_DEN_SUP_30 + C_NUOVO;
        inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,w_maggiore_imposta,NULL,a_utente,0,w_data_riferimento);
        if w_flag_sanz_magg_tares > 0 then
          w_cod_sanzione := C_TARD_DEN_SUP_30 + C_NUOVO_MAGG_TARES;
          inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,w_maggiore_imposta_magg_tares,NULL,a_utente,0,w_data_riferimento);
        end if;
     ELSIF to_number(a_data_denuncia - w_data_scadenza) > 30 THEN
      --w_cod_sanzione := C_TARD_DEN_INF_30;
      --inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,w_maggiore_imposta,NULL,a_utente,0,w_data_riferimento);
        w_cod_sanzione := C_TARD_DEN_INF_30 + C_NUOVO;
        inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,w_maggiore_imposta,NULL,a_utente,0,w_data_riferimento);
        if w_flag_sanz_magg_tares > 0 then
          w_cod_sanzione := C_TARD_DEN_INF_30 + C_NUOVO_MAGG_TARES;
          inserimento_sanzione(w_cod_sanzione,C_TIPO_TRIBUTO,a_pratica,a_oggetto_pratica,w_maggiore_imposta_magg_tares,NULL,a_utente,0,w_data_riferimento);
        end if;
     END IF;
  END IF;
  --
-- Gli interessi si applicano all'imposta + i carichi tarsu secondo l`indicatore dei carichi tarsu
  --
  if w_flag_ruolo = 'S' and (   w_tipo_occ = 'P' and w_flag_sanz_p = 'S'
                             or w_tipo_occ = 'T' and w_flag_sanz_t = 'S'
                            ) then
     w_maggiore_imposta :=  w_maggiore_imposta - w_add_pro;
  end if;
  IF a_interessi_dal is not null THEN
    IF w_maggiore_imposta = 0 THEN
      if w_flag_ruolo = 'S' and w_flag_int = 'S' then
         w_importo_lordo := a_imposta + w_add_eca2 + w_mag_eca2 + w_add_pro2 + w_iva2;
      else
         w_importo_lordo := a_imposta;
      end if;
    ELSE
      if w_flag_ruolo = 'S' and w_flag_int = 'S' then
         w_importo_lordo := w_maggiore_imposta + w_add_eca + w_mag_eca + w_add_pro + w_iva;
      else
         w_importo_lordo := w_maggiore_imposta;
      end if;
    END IF;
    inserimento_interessi(a_pratica,a_oggetto_pratica,
                           a_interessi_dal,a_interessi_al,
                           w_importo_lordo,C_TIPO_TRIBUTO,
                           'S',a_utente,a_interessi_dal
                           );
    if w_flag_sanz_magg_tares > 0 then
      if w_maggiore_imposta_magg_tares <> 0 then
          w_importo_lordo := w_maggiore_imposta_magg_tares;
      else
        w_importo_lordo := a_imposta_magg_tares;
      end if;
      inserimento_int_magg_tares(a_pratica,a_oggetto_pratica,
                                 a_interessi_dal,a_interessi_al,
                                 w_importo_lordo,C_TIPO_TRIBUTO,
                                 'S',a_utente,a_interessi_dal
                                 );
    END IF;
  END IF;
  --
  -- (VD - 24/07/2018): a fine trattamento, si verifica se la somma delle
  --                    sanzioni su imposta e maggiorazione TARES supera
  --                    l'importo minimo. Se sì, si lasciano i dati invariati,
  --                    altrimenti si tiene una sola riga di sanzione con
  --                    l'importo minimo
  -- (VD - 19/02/2020): aggiunta condizione di where su tipo tributo
  --
  for sami in (select min(sapr.cod_sanzione) cod_sanzione
                    , min(sapr.sequenza_sanz) sequenza_sanz
                    , sum(sapr.importo)      imp_sanzione
                    , sanz.sanzione_minima
                 from sanzioni_pratica sapr
                    , sanzioni         sanz
                where sapr.pratica = a_pratica
                  and sapr.cod_sanzione = sanz.cod_sanzione
                  and sapr.sequenza_sanz = sanz.sequenza
                  and sapr.tipo_tributo = sanz.tipo_tributo
                  and substr(sanz.tipo_causale,1,1) in ('O','P','T')
                  and sanz.sanzione_minima is not null
                group by sanz.sanzione_minima)
  loop
    --
    -- (RV - 23/01/2023): aggiunto flag per ignora sanzione minima (Solo x TR4WEB)
    --                    TR4WEB fa la sua verifica dopo aver
    --                    calcolato i totali su più oggetti
    --
    if nvl(a_flag_ignora_sanz_minima,'N') = 'N' then
      
      if sami.imp_sanzione < sami.sanzione_minima then
         --
         -- (VD - 24/07/2018): se il totale delle sanzioni sull'imposta non
         --                    supera la sanzione minima, si aggiorna il
         --                    primo codice sanzione (sperando che sia quello
         --                    dell'imposta) e si alimimano gli altri
         --
         begin
           update sanzioni_pratica sapr
              set sapr.importo = sami.sanzione_minima
                , sapr.note = decode(sapr.note,'','',sapr.note||'; ')||
                              'Sanzione minima - Totale sanzioni orig. '||to_char(sami.imp_sanzione)
            where sapr.pratica       = a_pratica
              and sapr.cod_sanzione  = sami.cod_sanzione
              and sapr.sequenza_sanz = sami.sequenza_sanz;
         exception
           when others then
             w_errore := 'Errore in update SANZIONI_PRATICA (Pratica: '||
                         a_pratica||', Sanzione: '||sami.cod_sanzione||') - '||sqlerrm;
             raise errore;
         end;
         begin
           delete from sanzioni_pratica sapr
            where sapr.pratica = a_pratica
              and sapr.cod_sanzione <> sami.cod_sanzione
              and sapr.cod_sanzione in (select sanz.cod_sanzione
                                          from sanzioni sanz
                                         where substr(sanz.tipo_causale,1,1) in ('O','P','T')
                                           and sanz.sanzione_minima is not null);
         exception
           when others then
             w_errore := 'Errore in delete SANZIONI_PRATICA (Pratica: '||
                         a_pratica||') - '||sqlerrm;
             raise errore;
         end;
      end if;
    end if;
  end loop;
  --
  BEGIN
    select count(*)
      into w_return
      from sanzioni_pratica
     where pratica = a_pratica
    ;
  END;
  --
  -- Inserisco le spese di notifica solo su nuovo sanzionamento e se emesse altre sanzioni.
  --
  IF a_nuovo_sanzionamento = 'S' and w_return > 0 THEN
    w_cod_sanzione := C_SPESE_NOT;
    inserimento_sanzione(w_cod_sanzione,'TARSU',a_pratica,NULL,NULL,NULL,a_utente,0,w_data_accertamento);
  END IF;
  --
  -- (AB - 02/02/2023): se il contribuente è deceduto, si eliminano
  --                    le sanzioni lasciando solo imposta evasa,
  --                    interessi e spese di notifica
  BEGIN
    select stato
      into w_stato_sogg
      from soggetti sogg, contribuenti cont
     where sogg.ni = cont.ni
       and cont.cod_fiscale = a_cod_fiscale
    ;
  EXCEPTION
    WHEN others THEN
      w_errore := 'Errore in ricerca Soggetti '||SQLERRM;
      RAISE errore;
  END;
  if w_stato_sogg = 50 then
    ELIMINA_SANZ_LIQ_DECEDUTI(a_pratica);
  end if;
EXCEPTION
  WHEN errore THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
    (-20999,w_errore);
  WHEN others THEN
       ROLLBACK;
       RAISE_APPLICATION_ERROR
    (-20999,'Errore durante il Calcolo Sanzioni '||'('||SQLERRM||')');
END;
/* End Procedure: CALCOLO_SANZIONI_TARSU */
/
