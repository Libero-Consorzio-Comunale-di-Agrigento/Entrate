--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_sanzioni_tasi stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_SANZIONI_TASI
/*************************************************************************
 NOME:        CALCOLO_SANZIONI_TASI
 DESCRIZIONE: Calcolo sanzioni TASI per accertamento (usato solo in PB)
 NOTE:
 Rev.    Date         Author      Note
 000     27/08/2019   VD          Prima emissione
*************************************************************************/
(a_anno                     number,
 a_data_accertamento        date,
 a_imposta_dovuta           number,
 a_imposta_dovuta_acconto   number,
 a_mesi_possesso_dic        number,
 a_flag_possesso_dic        varchar2,
 a_importo_versato          number,
 a_imposta                  number,
 a_imposta_acconto          number,
 a_mesi_possesso            number,
 a_mesi_possesso_1s         number,
 a_pratica                  number,
 a_oggetto_pratica          number,
 a_nuovo_sanzionamento      varchar2,
 a_utente                   varchar2)
IS
sql_errm                varchar2(100);
w_tipo_tributo          varchar2(5)    := 'TASI';
w_cod_sanzione          number;
w_percentuale           number;
w_sanzione              number;
w_sanzione_minima       number;
w_riduzione             number;
w_riduzione_2           number;
w_imposta_evasa         number;
w_imposta_evasa_1s      number;
w_imposta_evasa_2s      number;
w_data_scad_acconto     date;
w_data_scad_saldo       date;
w_soprattassa_20        number;
w_num_sanz              number;
w_data_partenza         date;
w_data_arrivo           date;
w_semestri              number;
w_giorni                number;
w_interessi             number;
w_aliquota_1            number;
w_semestri_1            number;
w_giorni_1              number;
w_perc_soprattassa      number;
w_min_soprattassa       number;
w_soprattassa           number;
w_interessi_n           number;
sT1                     varchar2(4);
iMese                   number;
iAnno                   number;
w_fase_euro             number;
w_1000                  number;
w_gg_anno               number := 365;
w_ab_principale         number;
w_terreni_comune        number;
w_aree_comune           number;
w_altri_comune          number;
CURSOR sel_sanz (p_cod_sanzione number, p_tipo_tributo varchar2) IS
   select sanz.percentuale,sanz.sanzione,
          sanz.sanzione_minima,sanz.riduzione,sanz.riduzione_2
     from sanzioni sanz
    where tipo_tributo   = p_tipo_tributo
      and cod_sanzione   = p_cod_sanzione
    ;
BEGIN
  BEGIN
     select fase_euro
       into w_fase_euro
       from dati_generali
     ;
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20999,'Mancano i Dati Generali');
  END;
  if w_fase_euro = 1 then
     w_1000  := 1000;
  else
     w_1000  := 1;
  end if;
  w_imposta_evasa := a_imposta - nvl(a_importo_versato,nvl(a_imposta_dovuta,0));
  IF ABS(w_imposta_evasa) > w_1000 THEN
     BEGIN
       delete sanzioni_pratica
        where pratica           = a_pratica
          and oggetto_pratica   = a_oggetto_pratica
       ;
     EXCEPTION
       WHEN others THEN
           RAISE_APPLICATION_ERROR
         (-20999,'Errore in cancellazione Sanzioni Pratica');
     END;
     BEGIN
       select f_scadenza(a_anno, w_tipo_tributo, 'A',prtr.COD_FISCALE)
             ,f_scadenza(a_anno, w_tipo_tributo, 'S',prtr.COD_FISCALE)
       into   w_data_scad_acconto
             ,w_data_scad_saldo
       from   pratiche_tributo prtr
       where  prtr.pratica = a_pratica
       ;
     EXCEPTION
       WHEN no_data_found THEN
        RAISE_APPLICATION_ERROR
         (-20999,'Mancano scadenze per l''anno indicato');
       WHEN others   THEN
        RAISE_APPLICATION_ERROR
         (-20999,'Errore in ricerca Scadenze');
     END;
     OPEN sel_sanz (131,w_tipo_tributo);
     FETCH sel_sanz INTO w_percentuale,w_sanzione,
                            w_sanzione_minima,w_riduzione,w_riduzione_2;
     IF sel_sanz%NOTFOUND THEN
            CLOSE sel_sanz;
            RAISE_APPLICATION_ERROR
                 (-20999,'Errore in ricerca Sanzioni (131)');
     END IF;
     CLOSE sel_sanz;
     BEGIN
         insert into sanzioni_pratica
                (pratica,cod_sanzione,tipo_tributo,oggetto_pratica,
                 percentuale,importo,riduzione,riduzione_2,
                 ab_principale,terreni_comune,
                 aree_comune,altri_comune,
                 utente,data_variazione)
         values (a_pratica,131,w_tipo_tributo,a_oggetto_pratica,
                 w_percentuale,w_imposta_evasa,w_riduzione,w_riduzione_2,
                 w_ab_principale,w_terreni_comune,
                 w_aree_comune,w_altri_comune,
                 a_utente,trunc(sysdate))
         ;
     EXCEPTION
         WHEN others THEN
               sql_errm   := substr(SQLERRM,1,100);
            RAISE_APPLICATION_ERROR
                (-20999,'Errore in inserimento Sanzioni Pratica (131) '||
              '('||sql_errm||')');
     END;
     IF nvl(a_imposta_dovuta,-1) >= 0 THEN
        w_cod_sanzione := 134;
     ELSE
        w_cod_sanzione := 132;
     END IF;
     OPEN sel_sanz (w_cod_sanzione, w_tipo_tributo);
     FETCH sel_sanz
        INTO w_percentuale,w_sanzione,w_sanzione_minima,w_riduzione,w_riduzione_2;
     IF sel_sanz%NOTFOUND THEN
        CLOSE sel_sanz;
        RAISE_APPLICATION_ERROR
           (-20999,'Errore in ricerca Sanzioni ('||w_cod_sanzione||')');
     END IF;
     CLOSE sel_sanz;
     w_soprattassa := f_round(w_imposta_evasa * w_percentuale / 100,0);
     if w_soprattassa > 0 and w_soprattassa < nvl(w_sanzione_minima,0) then
        w_soprattassa := nvl(w_sanzione_minima,0);
     elsif w_soprattassa <= 0 then
        w_riduzione := NULL;
     end if;
     BEGIN
     if w_soprattassa > 0 then
        insert into sanzioni_pratica
               (pratica,cod_sanzione,tipo_tributo,oggetto_pratica,
                percentuale,importo,riduzione,riduzione_2,
                utente,data_variazione)
        values (a_pratica,w_cod_sanzione,w_tipo_tributo,a_oggetto_pratica,
                w_percentuale,w_soprattassa,w_riduzione,w_riduzione_2,
                a_utente,trunc(sysdate))
        ;
     end if;
     EXCEPTION
     WHEN others THEN
            RAISE_APPLICATION_ERROR
          (-20999,'Errore in inserimento Sanzioni Pratica ('||w_cod_sanzione||')');
     END;
     OPEN sel_sanz (133,w_tipo_tributo);
     FETCH sel_sanz INTO w_percentuale,w_sanzione,
                         w_sanzione_minima,w_riduzione,w_riduzione_2;
     IF sel_sanz%NOTFOUND THEN
        CLOSE sel_sanz;
        RAISE_APPLICATION_ERROR
           (-20999,'Errore in ricerca Sanzioni (133)');
     END IF;
     CLOSE sel_sanz;
     w_soprattassa_20 := (w_imposta_evasa * w_percentuale / 100);
     BEGIN
       if w_soprattassa_20 > 0 then
          insert into sanzioni_pratica
                 (pratica,cod_sanzione,tipo_tributo,oggetto_pratica,
                  percentuale,importo,riduzione,riduzione_2,
                  utente,data_variazione)
          values (a_pratica,133,w_tipo_tributo,a_oggetto_pratica,
                  w_percentuale,w_soprattassa_20,w_riduzione,w_riduzione_2,
                  a_utente,trunc(sysdate))
          ;
       end if;
     EXCEPTION
       WHEN others THEN
            RAISE_APPLICATION_ERROR
                 (-20999,'Errore in inserimento Sanzioni Pratica (33)');
     END;
     IF -- a_imposta_dovuta is null  or
        -- (a_mesi_possesso_dic = 12 or a_flag_possesso_dic = 'S')
        nvl(a_mesi_possesso_1s,0) <> 0
     THEN
        w_imposta_evasa_1s := a_imposta_acconto - nvl(a_importo_versato,nvl(a_imposta_dovuta_acconto,0));
        w_imposta_evasa_1s := round(w_imposta_evasa_1s,2);
        IF nvl(w_imposta_evasa_1s,0) > 0 THEN
         --Ho inserito il +1 nella w_data_partenza perchè la considero la data
         --del primo giorno in cui si applicano gli interessi (Piero 05/03/2007)
           w_data_partenza := w_data_scad_acconto + 1;
           w_data_arrivo   := a_data_accertamento;
           w_semestri      := trunc(months_between(w_data_arrivo + 1,w_data_partenza) / 6);
           w_giorni        := w_data_arrivo + 1 - w_data_partenza;
           WHILE w_data_partenza <= w_data_arrivo LOOP
             BEGIN
             --Interessi Giornalieri
              select aliquota
                   , least(w_data_arrivo,data_fine) + 1 - w_data_partenza
                   , least(w_data_arrivo,data_fine) + 1
                into w_aliquota_1
                   , w_giorni_1
                   , w_data_partenza
                from interessi
               where tipo_tributo   = w_tipo_tributo
                 and w_data_partenza  between data_inizio and data_fine
                 and tipo_interesse = 'G'
                 ;
             EXCEPTION
              WHEN no_data_found THEN
                 RAISE_APPLICATION_ERROR
                   (-20999,'Manca il periodo in Interessi');
              WHEN others THEN
                 RAISE_APPLICATION_ERROR
              (-20999,'Errore in ricerca Interessi');
             END;
             IF a_nuovo_sanzionamento = 'S' THEN
                w_interessi_n := f_round(nvl(w_imposta_evasa_1s,0)
                              * w_giorni_1
                              * w_aliquota_1
                              / 100
                              / w_gg_anno,0)
                              + nvl(w_interessi_n,0);
             END IF;
             IF a_nuovo_sanzionamento = 'S' THEN
                w_interessi := f_round(nvl(w_imposta_evasa_1s,0)
                            * w_giorni_1
                            * w_aliquota_1
                            / 100
                            / w_gg_anno,0)
                            + nvl(w_interessi,0);
             END IF;
           END LOOP;
           w_imposta_evasa := w_imposta_evasa - w_imposta_evasa_1s;
           IF a_nuovo_sanzionamento = 'S' THEN
              OPEN sel_sanz (198,w_tipo_tributo);
              FETCH sel_sanz INTO w_percentuale,w_sanzione,
                                  w_sanzione_minima,w_riduzione,w_riduzione_2;
              IF sel_sanz%NOTFOUND THEN
                 CLOSE sel_sanz;
                 RAISE_APPLICATION_ERROR
                    (-20999,'Errore in ricerca Sanzioni (198)');
              END IF;
              CLOSE sel_sanz;
              if nvl(w_interessi,0) <> 0 then
                 BEGIN
                   insert into sanzioni_pratica
                          (pratica,cod_sanzione,tipo_tributo,oggetto_pratica,
                           giorni,importo,riduzione,riduzione_2,
                           utente,data_variazione)
                 values (a_pratica,198,w_tipo_tributo,a_oggetto_pratica,
                         w_giorni,w_interessi_n,w_riduzione,w_riduzione_2,
                         a_utente,trunc(sysdate))
                 ;
                 EXCEPTION
                   WHEN others THEN
                     RAISE_APPLICATION_ERROR
                     (-20999,'Errore in inserimento Sanzioni Pratica (198)');
                 END;
              end if;
           END IF;
        END IF; --  FINE DI IF nvl(w_imposta_evasa_1s,0) > 0 THEN
     END IF;  -- IF a_imposta_dovuta is null .....
     --Ho inserito il +1 nella w_data_partenza perchè la considero la data
     --del primo giorno in cui si applicano gli interessi (Piero 05/03/2007)
     w_data_partenza := w_data_scad_saldo + 1;
     w_data_arrivo   := a_data_accertamento;
     w_semestri      := trunc(months_between(w_data_arrivo + 1,w_data_partenza) / 6);
     w_giorni        := w_data_arrivo + 1 - w_data_partenza;
     w_interessi     := 0;
     w_interessi_n   := 0;
     WHILE w_data_partenza <= w_data_arrivo LOOP
        BEGIN
          select aliquota
               , least(w_data_arrivo,data_fine) + 1 - w_data_partenza
               , least(w_data_arrivo,data_fine) + 1
            into w_aliquota_1,w_giorni_1,w_data_partenza
            from interessi
           where tipo_tributo   = w_tipo_tributo
             and w_data_partenza between data_inizio and data_fine
             and tipo_interesse = 'G'
               ;
        EXCEPTION
          WHEN no_data_found THEN
               RAISE_APPLICATION_ERROR
            (-20999,'Manca il periodo in Interessi');
          WHEN others THEN
               RAISE_APPLICATION_ERROR
            (-20999,'Errore in ricerca Interessi');
        END;
        IF a_nuovo_sanzionamento = 'S' THEN
           w_interessi_n  := f_round(nvl(w_imposta_evasa,0)
                          * w_giorni_1
                          * w_aliquota_1
                          / 100
                          / w_gg_anno,0)
                          + nvl(w_interessi_n,0);
        END IF;
        IF a_nuovo_sanzionamento = 'S' THEN
           w_interessi    := f_round(nvl(w_imposta_evasa,0)
                          * w_giorni_1
                          * w_aliquota_1
                          / 100
                          / w_gg_anno,0)
                          + nvl(w_interessi,0);
        END IF;
     END LOOP;
     IF a_nuovo_sanzionamento = 'S' THEN
        OPEN sel_sanz (199,w_tipo_tributo);
        FETCH sel_sanz INTO w_percentuale,w_sanzione,
                            w_sanzione_minima,w_riduzione,w_riduzione_2;
        IF sel_sanz%NOTFOUND THEN
           CLOSE sel_sanz;
           RAISE_APPLICATION_ERROR
             (-20999,'Errore in ricerca Sanzioni (199)');
        END IF;
        CLOSE sel_sanz;
        if nvl(w_interessi,0) <> 0 then
           BEGIN
              insert into sanzioni_pratica
                     (pratica,cod_sanzione,tipo_tributo,oggetto_pratica,
                      giorni,importo,riduzione,riduzione_2,
                      utente,data_variazione)
              values (a_pratica,199,w_tipo_tributo,a_oggetto_pratica,
                      w_giorni,w_interessi_n,w_riduzione,w_riduzione_2,
                      a_utente,trunc(sysdate))
              ;
           EXCEPTION
             WHEN others THEN
             RAISE_APPLICATION_ERROR
                (-20999,'Errore in inserimento Sanzioni Pratica (199)');
           END;
        end if;
     END IF;
     -- inserisco le spese di notifica
     IF a_nuovo_sanzionamento = 'S' THEN
        inserimento_sanzione(197,w_tipo_tributo,a_pratica,NULL,NULL,NULL,a_utente);
     END IF;    -- fine inserimento spese di notifica
  END IF; -- ABS(w_imposta_evasa) > w_1000
END;
/* End Procedure: CALCOLO_SANZIONI_TASI */
/

