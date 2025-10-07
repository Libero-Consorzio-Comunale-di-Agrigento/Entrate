--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_sanzioni_ici stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure CALCOLO_SANZIONI_ICI
/*************************************************************************
  Rev.    Date         Author      Note
  004     26/05/2025   RV          #77612
                                   Adeguamento nuovo DL regime sanzionatorio
  003     23/10/2024   AB          Issue #65970
                                   Spostata una begin di ricerca dati relativi
                                   alla pratica sopra alla if di abs perchè in
                                   alcuni casi non entrava e lasciava null il CF
  002     02/02/2023   AB          Issue #48451
                                   Aggiunta la eliminazione sanzioni per deceduti
  001     24/01/2023   RV          Issue #60310
                                   Aggiunto gestione note x saznione interessi
                                   Creato procedure INSERIMENTO_INTERESSE_ICI_GG (1)
                                   Inserisce nuova sanzione con dettaglio interessi
                                   Creato procedure AGGIORNAMENTO_SANZIONE_GG (2)
                                   Aggiorna sanzione con dettaglio interessi
                                   Creato procedure AGGIUNTA_INTERESSE_ICI_GG (3)
                                   Aggiunge gli interessi alle sanzioni chiamando
                                   la (1) o la (2) in base alla necessita'
                                   Aggiunto flag a_flag_ignora_sanz_minima
  000     xx/xx/xxxx   XX          Versione iniziale
*************************************************************************/
(a_anno                number,
 a_data_accertamento   date,
 a_imposta_dovuta      number,
 a_imposta_dovuta_acconto  number,
 a_mesi_possesso_dic   number,
 a_flag_possesso_dic   varchar2,
 a_importo_versato     number,
 a_imposta             number,
 a_imposta_acconto     number,
 a_mesi_possesso       number,
 a_mesi_possesso_1s    number,
 a_pratica             number,
 a_oggetto_pratica     number,
 a_nuovo_sanzionamento varchar2,
 a_utente             varchar2,
 a_flag_ignora_sanz_minima varchar2 default null)
IS
  --
  sql_errm                varchar2(100);
  --
  w_tipo_tributo          varchar2(5)    := 'ICI';
  --
  w_cod_sanzione          number;
  w_percentuale           number;
  w_sanzione              number;
  w_sanzione_minima       number;
  w_riduzione             number;
  w_riduzione_2           number;
  w_imposta_evasa         number;
  w_imposta_evasa_1s      number;
  w_data_scad_acconto     date;
  w_data_scad_saldo       date;
--w_soprattassa_20        number;
--w_num_sanz              number;
  w_data_partenza         date;
  w_data_arrivo           date;
  w_interessi_dal         date;
  w_interessi_al          date;
  w_giorni                number;
  w_interessi             number;
  w_aliquota_1            number;
  w_giorni_1              number;
  w_soprattassa           number;
  w_interessi_n           number;
  w_fase_euro             number;
  w_1000                  number;
  w_gg_anno               number := 365;
  w_return                number;
  w_ab_principale         number;
  w_terreni_comune        number;
  w_aree_comune           number;
  w_altri_comune          number;
  w_cod_fiscale           varchar2(16);
  w_stato_sogg            number(2);
  --
  w_data_riferimento      date;
  w_sequenza_sanz         number;
  --
------------------------------------------------
CURSOR sel_sanz_data (
  p_cod_sanzione     number
, p_tipo_tributo     varchar2
, p_data_inizio      date
)
IS
  select sanz.percentuale,sanz.sanzione,
         sanz.sanzione_minima,sanz.riduzione,sanz.riduzione_2,
         sanz.sequenza
    from sanzioni sanz
   where tipo_tributo   = p_tipo_tributo
     and cod_sanzione   = p_cod_sanzione
     and p_data_inizio between
         sanz.data_inizio and sanz.data_fine
;
------------------------------------------------
-- INSERIMENTO_INTERESSE_ICI_GG
------------------------------------------------
PROCEDURE INSERIMENTO_INTERESSE_ICI_GG
(   a_cod_sanzione     IN number,
    a_tipo_tributo     IN varchar2,
    a_pratica          IN number,
    a_oggetto_pratica  IN number,
    a_giorni           IN number,
    a_interessi        IN number,
    a_dal              IN date,
    a_al               IN date,
    a_base             IN number,
    a_riduzione        IN number,
    a_riduzione_2      IN number,
    a_utente           IN varchar2,
    a_sequenza_sanz    IN number
)
IS
  --
  w_interessi     number;
  --
  w_errore        varchar2(2000);
  errore          exception;
  --
BEGIN
  w_interessi := round(a_interessi,2);
  IF nvl(w_interessi,0) <> 0 THEN
    BEGIN
      insert into sanzioni_pratica
             (cod_sanzione
             ,tipo_tributo
             ,pratica
             ,oggetto_pratica
             ,importo
             ,giorni
             ,riduzione
             ,riduzione_2
             ,note
             ,utente
             ,data_variazione
             ,sequenza_sanz
             )
      values (a_cod_sanzione
             ,a_tipo_tributo
             ,a_pratica
             ,a_oggetto_pratica
             ,w_interessi
             ,a_giorni
             ,a_riduzione
             ,a_riduzione_2
             ,'In: '||to_char(w_interessi)
             ||' gg: '||to_char(a_giorni)
             ||' dal: '||to_char(a_dal,'dd/mm/yyyy')
             ||' al: '||to_char(a_al,'dd/mm/yyyy')
             ||' base: '||to_char(a_base)
             ||' - '
             ,a_utente
             ,trunc(sysdate)
             ,a_sequenza_sanz
             )
      ;
    EXCEPTION
      WHEN others THEN
        w_errore := 'Errore inserimento Sanzioni Pratica';
        RAISE errore;
    END;
  END IF;
EXCEPTION
  WHEN errore THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20999,w_errore);
  WHEN others THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20999,'Errore in Inserimento Interessi GG'||'('||SQLERRM||')');
  --
END INSERIMENTO_INTERESSE_ICI_GG;
------------------------------------------------
-- AGGIORNAMENTO_SANZIONE_GG
------------------------------------------------
PROCEDURE AGGIORNAMENTO_SANZIONE_GG
(   a_pratica         IN number,
    a_cod_sanzione    IN number,
    a_importo         IN number,
    a_giorni          IN number,
    a_dal             IN date,
    a_al              IN date,
    a_base            IN number,
    a_sequenza_sanz   IN number)
IS
  --
  w_giorni          number;
  --
  errore            exception;
  w_errore          varchar2(200);
  --
BEGIN
  if round(a_importo,2) <> 0 then
    BEGIN
      w_giorni := 0;
      select giorni
        into w_giorni
        from sanzioni_pratica
      where pratica      = a_pratica
        and cod_sanzione = a_cod_sanzione
        and sequenza     = a_sequenza_sanz
      ;
      if a_giorni > w_giorni then
        w_giorni := a_giorni;
      end if;
      --
      update sanzioni_pratica
         set importo      = importo + round(a_importo,2)
           , giorni       = w_giorni
           , note         = note
                            ||'In: '||to_char(round(a_importo,2))
                            ||' gg: '||to_char(a_giorni)
                            ||' dal: '||to_char(a_dal,'dd/mm/yyyy')
                            ||' al: '||to_char(a_al,'dd/mm/yyyy')
                            ||' base: '||to_char(a_base)
                            ||' - '
       where pratica      = a_pratica
         and cod_sanzione = a_cod_sanzione
         and sequenza_sanz = a_sequenza_sanz
       ;
    EXCEPTION
      WHEN others THEN
        w_errore := 'Errore aggiornamento Sanzioni Pratica';
        RAISE errore;
    END;
  end if;
EXCEPTION
  WHEN errore THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR (-20999,w_errore||' ('||SQLERRM||')');
  --
END AGGIORNAMENTO_SANZIONE_GG;
------------------------------------------------
-- AGGIUNTA_INTERESSE_ICI_GG
------------------------------------------------
PROCEDURE AGGIUNTA_INTERESSE_ICI_GG
(   a_cod_sanzione     IN number,
    a_tipo_tributo     IN varchar2,
    a_pratica          IN number,
    a_oggetto_pratica  IN number,
    a_giorni           IN number,
    a_interessi        IN number,
    a_dal              IN date,
    a_al               IN date,
    a_base             IN number,
    a_riduzione        IN number,
    a_riduzione_2      IN number,
    a_utente           IN varchar2,
    a_sequenza_sanz    IN number
)
IS
  --
  w_interessi     number;
  w_check         number(1);
  --
  w_errore        varchar2(2000);
  errore          exception;
  --
BEGIN
   w_interessi := round(a_interessi,2);
   IF nvl(w_interessi,0) <> 0 THEN
      w_check := f_check_sanzione(a_pratica,a_cod_sanzione);
      if w_check = 0 THEN
        INSERIMENTO_INTERESSE_ICI_GG(a_cod_sanzione,a_tipo_tributo,a_pratica,a_oggetto_pratica,
                                      a_giorni,a_interessi,a_dal,a_al,a_base,a_riduzione,a_riduzione_2,a_utente,a_sequenza_sanz);
      else
        AGGIORNAMENTO_SANZIONE_GG(a_pratica,a_cod_sanzione,a_interessi,a_giorni,a_dal,a_al,a_base,a_sequenza_sanz);
      end if;
   END IF;
    --
EXCEPTION
  WHEN errore THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20999,w_errore);
  WHEN others THEN
    ROLLBACK;
    RAISE_APPLICATION_ERROR(-20999,'Errore in Aggiunta Interessi GG'||'('||SQLERRM||')');
    --
END AGGIUNTA_INTERESSE_ICI_GG;
--------------------------------------------
-- CALCOLO_SANZIONI_ICI --------------------
--------------------------------------------
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
  --
-- AB (23/10/2024) Spostata sopra alla if di abs perchè in alcuni casi non entrava e lasciava null il cf
  --
  BEGIN
    select f_scadenza(a_anno, w_tipo_tributo, 'A',prtr.COD_FISCALE)
          ,f_scadenza(a_anno, w_tipo_tributo, 'S',prtr.COD_FISCALE)
          ,prtr.cod_fiscale
    into   w_data_scad_acconto
          ,w_data_scad_saldo
          ,w_cod_fiscale
    from   pratiche_tributo prtr
    where  prtr.pratica = a_pratica
    ;
  EXCEPTION
    WHEN no_data_found THEN
      RAISE_APPLICATION_ERROR(-20999,'Mancano scadenze per l''anno indicato');
    WHEN others   THEN
      RAISE_APPLICATION_ERROR(-20999,'Errore in ricerca Scadenze');
  END;
  --
  w_imposta_evasa := a_imposta - nvl(a_importo_versato,nvl(a_imposta_dovuta,0));
  IF ABS(w_imposta_evasa) > w_1000 THEN
    --
  -- Elimina sanzioini esistenti
    --
    BEGIN
      delete sanzioni_pratica
       where pratica           = a_pratica
         and oggetto_pratica   = a_oggetto_pratica
      ;
    EXCEPTION
      WHEN others THEN
        RAISE_APPLICATION_ERROR(-20999,'Errore in cancellazione Sanzioni Pratica');
    END;
    --
 -- Data riferimento Sanzioni 131/132/134 - Scadenza della denuncia per l'anno in accertamento
    --
    w_data_riferimento := F_SCADENZA_DENUNCIA(w_tipo_tributo,a_anno);
    --
  -- 131 : IMPOSTA EVASA (DIFFERENZA DIC./LIQ.)
    --
    w_cod_sanzione := 131;
    OPEN sel_sanz_data (w_cod_sanzione, w_tipo_tributo, w_data_riferimento);
    FETCH sel_sanz_data INTO w_percentuale,w_sanzione,w_sanzione_minima,w_riduzione,w_riduzione_2,w_sequenza_sanz;
      IF sel_sanz_data%NOTFOUND THEN
        CLOSE sel_sanz_data;
        RAISE_APPLICATION_ERROR (-20999,'Errore in ricerca Sanzioni ('||w_cod_sanzione||')');
      END IF;
    CLOSE sel_sanz_data;
    --
    if a_anno < 2012 then
      begin
        select decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                     ,1,to_number(null)
                     ,2,to_number(null)
                     ,decode(ogco.flag_ab_principale||substr(ogpr.categoria_catasto,1,1)
                         ,'SA',w_imposta_evasa
                         ,to_number(null)
                         )
                     )
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                     ,1,w_imposta_evasa
                     ,to_number(null)
                     )
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                     ,2,w_imposta_evasa
                     ,to_number(null)
                     )
             , decode(nvl(ogpr.tipo_oggetto,ogge.tipo_oggetto)
                     ,1,to_number(null)
                     ,2,to_number(null)
                     ,decode(ogco.flag_ab_principale||substr(ogpr.categoria_catasto,1,1)
                         ,'SA',to_number(null)
                         ,w_imposta_evasa
                         )
                     )
          into w_ab_principale
             , w_terreni_comune
             , w_aree_comune
             , w_altri_comune
          from oggetti               ogge
             , oggetti_pratica       ogpr
             , oggetti_contribuente  ogco
         where ogpr.oggetto_pratica = a_oggetto_pratica
           and ogpr.oggetto         = ogge.oggetto
           and ogpr.oggetto_pratica = ogco.oggetto_pratica
        ;
      EXCEPTION
        WHEN others THEN
          w_ab_principale   := 0;
          w_terreni_comune  := 0;
          w_aree_comune     := 0;
          w_altri_comune    := 0;
      end;
    else
      w_ab_principale   := 0;
      w_terreni_comune  := 0;
      w_aree_comune     := 0;
      w_altri_comune    := 0;
    end if;
    --
    BEGIN
      insert into sanzioni_pratica
            (pratica,cod_sanzione,tipo_tributo,oggetto_pratica,
             percentuale,importo,riduzione,riduzione_2,
             ab_principale,terreni_comune,
             aree_comune,altri_comune,
             utente,data_variazione,
             sequenza_sanz)
      values (a_pratica,w_cod_sanzione,w_tipo_tributo,a_oggetto_pratica,
             w_percentuale,w_imposta_evasa,w_riduzione,w_riduzione_2,
             w_ab_principale,w_terreni_comune,
             w_aree_comune,w_altri_comune,
             a_utente,trunc(sysdate),
             w_sequenza_sanz)
      ;
    EXCEPTION
      WHEN others THEN
        sql_errm   := substr(SQLERRM,1,100);
        RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento Sanzioni Pratica ('||w_cod_sanzione||') '||'('||sql_errm||')');
    END;
    --
  -- Omessa / Infedele
    --
    IF nvl(a_imposta_dovuta,-1) >= 0 THEN
      w_cod_sanzione := 134;    -- DICHIARAZIONE O DENUNCIA INFEDELE
    ELSE
      w_cod_sanzione := 132;    -- OMESSA PRESENTAZIONE DELLA DENUNCIA
    END IF;
    --
 -- Le Sanzioni con Codice < 100 non sono più necessarie, quindi ignoriamo il loop
    --
--  FOR w_num_sanz IN 1..2 LOOP
      OPEN sel_sanz_data (w_cod_sanzione, w_tipo_tributo, w_data_riferimento);
      FETCH sel_sanz_data INTO w_percentuale,w_sanzione,w_sanzione_minima,w_riduzione,w_riduzione_2,w_sequenza_sanz;
        IF sel_sanz_data%NOTFOUND THEN
          CLOSE sel_sanz_data;
          RAISE_APPLICATION_ERROR(-20999,'Errore in ricerca Sanzioni ('||w_cod_sanzione||')');
        END IF;
      CLOSE sel_sanz_data;
      --
      w_soprattassa := f_round(w_imposta_evasa * w_percentuale / 100,0);
      if w_soprattassa > 0 and w_soprattassa < nvl(w_sanzione_minima,0) then
        if nvl(a_flag_ignora_sanz_minima,'N') = 'N' then
          w_soprattassa := nvl(w_sanzione_minima,0);
        end if;
      elsif w_soprattassa <= 0 then
        w_riduzione := NULL;
      end if;
      --
      BEGIN
        if w_soprattassa > 0 then
          insert into sanzioni_pratica
                 (pratica,cod_sanzione,tipo_tributo,oggetto_pratica,
                  percentuale,importo,riduzione,riduzione_2,
                  utente,data_variazione,
                  sequenza_sanz)
          values (a_pratica,w_cod_sanzione,w_tipo_tributo,a_oggetto_pratica,
                  w_percentuale,w_soprattassa,w_riduzione,w_riduzione_2,
                  a_utente,trunc(sysdate),
                  w_sequenza_sanz)
          ;
        end if;
      EXCEPTION
        WHEN others THEN
          sql_errm   := substr(SQLERRM,1,100);
          RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento Sanzioni Pratica ('||w_cod_sanzione||') '||'('||sql_errm||')');
      END;
      --
--    w_cod_sanzione := w_cod_sanzione - 100;
--  END LOOP;
    --
  -- 133 : PARZIALE OD OMESSO VERSAMENTO
    --
--    w_cod_sanzione ;= 133;
--    OPEN sel_sanz (w_cod_sanzione,w_tipo_tributo);
--    FETCH sel_sanz INTO w_percentuale,w_sanzione,w_sanzione_minima,w_riduzione;
--      IF sel_sanz%NOTFOUND THEN
--        CLOSE sel_sanz;
--        RAISE_APPLICATION_ERROR(-20999,'Errore in ricerca Sanzioni ('||w_cod_sanzione||')');
--      END IF;
--    CLOSE sel_sanz;
--    w_soprattassa := f_round(w_imposta_evasa * w_percentuale / 100,0);
--    if w_soprattassa > 0 and w_soprattassa < nvl(w_sanzione_minima,0) then
--       w_soprattassa := nvl(w_sanzione_minima,0);
--    elsif w_soprattassa <= 0 then
--       w_riduzione := NULL;
--    end if;
--    BEGIN
--      if w_soprattassa > 0 then
--        insert into sanzioni_pratica
--               (pratica,cod_sanzione,tipo_tributo,oggetto_pratica,
--                percentuale,importo,riduzione,
--                utente,data_variazione)
--        values (a_pratica,w_cod_sanzione,w_tipo_tributo,a_oggetto_pratica,
--                w_percentuale,w_soprattassa,w_riduzione,
--                a_utente,trunc(sysdate))
--        ;
--     end if;
--   EXCEPTION
--     WHEN others THEN
--        sql_errm   := substr(SQLERRM,1,100);
--        RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento Sanzioni Pratica ('||w_cod_sanzione||') '||'('||sql_errm||')');
--   END;
    --
  -- 31 : IMPOSTA EVASA (DIFFERENZA DIC./LIQ.)
    --
/**
    w_cod_sanzione := 31;
    OPEN sel_sanz (w_cod_sanzione,w_tipo_tributo);
    FETCH sel_sanz INTO w_percentuale,w_sanzione,w_sanzione_minima,w_riduzione,w_riduzione_2;
      IF sel_sanz%NOTFOUND THEN
        CLOSE sel_sanz;
        RAISE_APPLICATION_ERROR(-20999,'Errore in ricerca Sanzioni ('||w_cod_sanzione||')');
      END IF;
    CLOSE sel_sanz;
    BEGIN
      insert into sanzioni_pratica
             (pratica,cod_sanzione,tipo_tributo,oggetto_pratica,
              percentuale,importo,riduzione,riduzione_2,
              utente,data_variazione)
      values (a_pratica,w_cod_sanzione,w_tipo_tributo,a_oggetto_pratica,
              w_percentuale,w_imposta_evasa,w_riduzione,w_riduzione_2,
              a_utente,trunc(sysdate))
      ;
    EXCEPTION
      WHEN others THEN
        sql_errm   := substr(SQLERRM,1,100);
        RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento Sanzioni Pratica ('||w_cod_sanzione||') '||'('||sql_errm||')');
    END;
**/
    --
  -- 33 : SOPRATTASSA 20% (PARZIALE OD OMESSO VERSAMENTO)
    --
/**
    w_cod_sanzione := 33;
    OPEN sel_sanz (w_cod_sanzione,w_tipo_tributo);
    FETCH sel_sanz INTO w_percentuale,w_sanzione,w_sanzione_minima,w_riduzione,w_riduzione_2;
      IF sel_sanz%NOTFOUND THEN
        CLOSE sel_sanz;
        RAISE_APPLICATION_ERROR(-20999,'Errore in ricerca Sanzioni ('||w_cod_sanzione||')');
      END IF;
    CLOSE sel_sanz;
    w_soprattassa_20 := (w_imposta_evasa * w_percentuale / 100);
    BEGIN
      if w_soprattassa_20 > 0 then
        insert into sanzioni_pratica
               (pratica,cod_sanzione,tipo_tributo,oggetto_pratica,
                percentuale,importo,riduzione,riduzione_2,
                utente,data_variazione)
        values (a_pratica,w_cod_sanzione,w_tipo_tributo,a_oggetto_pratica,
                w_percentuale,w_soprattassa_20,w_riduzione,w_riduzione_2,
                a_utente,trunc(sysdate))
        ;
      end if;
    EXCEPTION
      WHEN others THEN
        sql_errm   := substr(SQLERRM,1,100);
        RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento Sanzioni Pratica ('||w_cod_sanzione||') '||'('||sql_errm||')');
    END;
**/
    --
  -- Calcolo Interessi Acconto
    --
    IF nvl(a_mesi_possesso_1s,0) <> 0 THEN
      IF a_anno < 2001 THEN
        w_imposta_evasa_1s := (((w_imposta_evasa / a_mesi_possesso) * nvl(a_mesi_possesso_1s,0)) * 0.9);
      ELSE
        w_imposta_evasa_1s := a_imposta_acconto - nvl(a_importo_versato,nvl(a_imposta_dovuta_acconto,0));
      END IF;
      --
      w_imposta_evasa_1s := round(w_imposta_evasa_1s,2);
      IF nvl(w_imposta_evasa_1s,0) > 0 THEN
        w_data_partenza := w_data_scad_acconto + 1;
        w_data_arrivo   := a_data_accertamento;
        w_giorni        := w_data_arrivo + 1 - w_data_partenza;
        w_interessi_dal := w_data_partenza;
        w_interessi_al  := a_data_accertamento;
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
              RAISE_APPLICATION_ERROR(-20999,'Manca il periodo in Interessi');
            WHEN others THEN
              RAISE_APPLICATION_ERROR(-20999,'Errore in ricerca Interessi');
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
        --
      -- 198 : INTERESSI DI MORA (ACCONTO)
        --
        w_imposta_evasa := w_imposta_evasa - w_imposta_evasa_1s;
        IF a_nuovo_sanzionamento = 'S' THEN
          w_cod_sanzione := 198;
          OPEN sel_sanz_data (w_cod_sanzione, w_tipo_tributo, w_data_scad_acconto);
          FETCH sel_sanz_data INTO w_percentuale,w_sanzione,w_sanzione_minima,w_riduzione,w_riduzione_2,w_sequenza_sanz;
            IF sel_sanz_data%NOTFOUND THEN
              CLOSE sel_sanz_data;
              RAISE_APPLICATION_ERROR(-20999,'Errore in ricerca Sanzioni ('||w_cod_sanzione||')');
            END IF;
          CLOSE sel_sanz_data;
          if nvl(w_interessi,0) <> 0 then
            BEGIN
              AGGIUNTA_INTERESSE_ICI_GG(w_cod_sanzione,w_tipo_tributo,a_pratica,a_oggetto_pratica,
                                           w_giorni,w_interessi_n,w_interessi_dal,w_interessi_al,
                                           w_imposta_evasa_1s,w_riduzione,w_riduzione_2,a_utente,
                                           w_sequenza_sanz);
            EXCEPTION
             WHEN others THEN
              sql_errm   := substr(SQLERRM,1,100);
              RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento Sanzioni Pratica ('||w_cod_sanzione||') '||'('||sql_errm||')');
            END;
          end if;
        END IF;
/**
        IF a_nuovo_sanzionamento = 'S' THEN
          w_cod_sanzione := 98;
          OPEN sel_sanz_data (w_cod_sanzione, w_tipo_tributo, w_data_scad_acconto);
          FETCH sel_sanz_data INTO w_percentuale,w_sanzione,w_sanzione_minima,w_riduzione,w_riduzione_2,w_sequenza_sanz;
            IF sel_sanz_data%NOTFOUND THEN
              CLOSE sel_sanz_data;
              RAISE_APPLICATION_ERROR(-20999,'Errore in ricerca Sanzioni ('||w_cod_sanzione||')');
            END IF;
          CLOSE sel_sanz_data;
          if nvl(w_interessi,0) <> 0 then
            BEGIN
              AGGIUNTA_INTERESSE_ICI_GG(w_cod_sanzione,w_tipo_tributo,a_pratica,a_oggetto_pratica,
                                           w_giorni,w_interessi,w_interessi_dal,w_interessi_al,
                                           w_imposta_evasa_1s,w_riduzione,w_riduzione_2,a_utente,
                                           w_sequenza_sanz);
            EXCEPTION
              WHEN others THEN
                sql_errm := substr(SQLERRM,1,100);
                RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento Sanzioni Pratica ('||w_cod_sanzione||') '||'('||sql_errm||')');
            END;
          end if;
        END IF;
**/
      END IF;  -- Esiste Evaso in Acconto
    END IF;  -- Mesi Possesso 1Sem <> 0
    --
  -- Calcolo Interessi Saldo
    --
    w_data_partenza := w_data_scad_saldo + 1;
    w_data_arrivo   := a_data_accertamento;
    w_giorni        := w_data_arrivo + 1 - w_data_partenza;
    w_interessi     := 0;
    w_interessi_n   := 0;
    w_interessi_dal := w_data_partenza;
    w_interessi_al  := a_data_accertamento;
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
              RAISE_APPLICATION_ERROR(-20999,'Manca il periodo in Interessi');
         WHEN others THEN
              RAISE_APPLICATION_ERROR(-20999,'Errore in ricerca Interessi');
      END;
      IF a_nuovo_sanzionamento = 'S' THEN
        w_interessi_n := f_round(nvl(w_imposta_evasa,0)
                 * w_giorni_1
                 * w_aliquota_1
                 / 100
                 / w_gg_anno,0)
                + nvl(w_interessi_n,0);
      END IF;
      IF a_nuovo_sanzionamento = 'S' THEN
        w_interessi := f_round(nvl(w_imposta_evasa,0)
                 * w_giorni_1
                 * w_aliquota_1
                 / 100
                 / w_gg_anno,0)
                + nvl(w_interessi,0);
      END IF;
    END LOOP;
    --
  -- x99 : INTERESSI DI MORA
    --
    IF a_nuovo_sanzionamento = 'S' THEN
      w_cod_sanzione := 199;
      OPEN sel_sanz_data (w_cod_sanzione, w_tipo_tributo, w_data_scad_saldo);
      FETCH sel_sanz_data INTO w_percentuale,w_sanzione,w_sanzione_minima,w_riduzione,w_riduzione_2,w_sequenza_sanz;
        IF sel_sanz_data%NOTFOUND THEN
          CLOSE sel_sanz_data;
          RAISE_APPLICATION_ERROR(-20999,'Errore in ricerca Sanzioni ('||w_cod_sanzione||')');
        END IF;
      CLOSE sel_sanz_data;
      if nvl(w_interessi,0) <> 0 then
        BEGIN
          AGGIUNTA_INTERESSE_ICI_GG(w_cod_sanzione,w_tipo_tributo,a_pratica,a_oggetto_pratica,
                                         w_giorni,w_interessi_n,w_interessi_dal,w_interessi_al,
                                         w_imposta_evasa,w_riduzione,w_riduzione_2,a_utente,
                                         w_sequenza_sanz);
        EXCEPTION
          WHEN others THEN
            sql_errm   := substr(SQLERRM,1,100);
            RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento Sanzioni Pratica ('||w_cod_sanzione||') '||'('||sql_errm||')');
        END;
      end if;
    END IF;
/**
    IF a_nuovo_sanzionamento = 'S' THEN
      w_cod_sanzione := 99;
      OPEN sel_sanz_data (w_cod_sanzione, w_tipo_tributo, w_data_scad_saldo);
      FETCH sel_sanz_data INTO w_percentuale,w_sanzione,w_sanzione_minima,w_riduzione,w_riduzione_2,w_sequenza_sanz;
        IF sel_sanz_data%NOTFOUND THEN
          CLOSE sel_sanz_data;
          RAISE_APPLICATION_ERROR(-20999,'Errore in ricerca Sanzioni ('||w_cod_sanzione||')');
        END IF;
      CLOSE sel_sanz_data;
      if nvl(w_interessi,0) <> 0 then
        BEGIN
          AGGIUNTA_INTERESSE_ICI_GG(w_cod_sanzione,w_tipo_tributo,a_pratica,a_oggetto_pratica,
                                       w_giorni,w_interessi,w_interessi_dal,w_interessi_al,
                                       w_imposta_evasa,w_riduzione,w_riduzione_2,a_utente,
                                       w_sequenza_sanz);
        EXCEPTION
          WHEN others THEN
            sql_errm   := substr(SQLERRM,1,100);
            RAISE_APPLICATION_ERROR(-20999,'Errore in inserimento Sanzioni Pratica ('||w_cod_sanzione||') '||'('||sql_errm||')');
        END;
      end if;
    END IF;
**/
    --
 -- Inserisco le spese di notifica se non e gia presente la 197 in quella pratica
    --
    w_cod_sanzione := 197;
    BEGIN
      select count(*)
        into w_return
        from sanzioni_pratica
       where pratica = a_pratica
         and cod_sanzione = w_cod_sanzione
      ;
    END;
    IF a_nuovo_sanzionamento = 'S' and w_return = 0 THEN
      inserimento_sanzione(w_cod_sanzione,w_tipo_tributo,a_pratica,NULL,NULL,NULL,a_utente,0,a_data_accertamento);
    END IF;
  END IF; -- ABS(w_imposta_evasa) > w_1000
  --
  -- (AB - 02/02/2023): se il contribuente è deceduto, si eliminano
  --                    le sanzioni lasciando solo imposta evasa,
  --                    interessi e spese di notifica
  --
  BEGIN
    select stato
      into w_stato_sogg
      from soggetti sogg, contribuenti cont
     where sogg.ni = cont.ni
       and cont.cod_fiscale = w_cod_fiscale
    ;
  EXCEPTION
    WHEN others THEN
      sql_errm := substr(SQLERRM,1,100);
      RAISE_APPLICATION_ERROR(-20999,'Errore in ricerca Soggetto CF: '||w_cod_fiscale||', Pratica: '||a_pratica||'('||sql_errm||')');
  END;
  if w_stato_sogg = 50 then
    ELIMINA_SANZ_LIQ_DECEDUTI(a_pratica);
  end if;
END;
/* End Procedure: CALCOLO_SANZIONI_ICI */
/
