--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_rateazione_aggi stripComments:false runOnChange:true 
 
CREATE OR REPLACE procedure     CALCOLO_RATEAZIONE_AGGI
/*************************************************************************
 NOME:        CALCOLO_RATEAZIONE_AGGI

 DESCRIZIONE: Calcolo rateazione per liquidazioni e accertamenti

 NOTE:        Nuova versione: tiene conto di oneri di riscossione e
              interessi di dilazione. Non si applica il metodo francese.
              E' possibile determinare comunque una rata costante.

 Rev.    Date         Author      Note
 000     12/05/2022   VD          Prima emissione.
 001     22/11/2022   DM          Corretto calcolo in presenza di versamento.
 002     15/12/2022   DM          La quadratura della rata sull'aggio viene
                                  effettuata solo se l'aliquota aggio è > 0
 003     30/01/2023   AB          Evitata la ricerca del codice f24 per il CUNI
 004     28/02/2023   AB          gestiti i due nuovi campi quota_tassa e quota Tefa
 005     08/03/2023   AB          #62306
                                  gestita la possibilità di calcolare o meno gli oneri di riscossione
 007     20/04/2023   AB          #63750
                                  differenziata la TEFA per la TARSU, solo dal 2021 in poi
 008     19/05/2023   AB          #63408 e #59046
                                  Se presente scadenza_prima_rata in pratiche_tributo si prende quella
 009     23/11/2023   AB          #68410
                                  Spostata la determinazione di importo_rata all'interno del loop
                                  dei dettagli delle rate, non prima
 009     04/01/2024   AB          #69243
                                  Trattamento della sospensione ferie anche per anni successivi alla prima rata
 010     10/12/2024   AB          #76942
                                  Sistemato controllo su sanz con data_inizio
 011     04/09/2025   RV          #82832
                                  Sistemato calcolo ratr in caso di flag_int_rate_solo_evasa = 'S'
*************************************************************************/
( a_pratica                       in number
, a_utente                        in varchar2
) is

  w_importo                       number;
  w_importo_pratica               number;
  w_importo_mora                  number;
  w_importo_versato               number;
  w_data_rateazione               date;
  w_data_rateazione_iniz          date;
  w_scadenza_prima_rata           date;
  w_data_notifica                 date;
  w_numero_rate                   number;
  w_numero_periodi                number;
  w_numero_mesi                   number;
  w_aliquota_rata                 number;
  w_anno                          number;
  w_tipo_tributo                  varchar2(5);
  w_rate_fime                     varchar2(1);
  w_tipo_importo_base             varchar2(1);
  w_tipo_calcolo                  varchar2(1);
  w_flag_rate_oneri               varchar2(1);
--
  w_inizio_sosp                   date;
  w_fine_sosp                     date;
  w_gg_sosp                       number;
  w_gg_iniz                       number;
  w_flag_sosp_ferie               varchar2(1);
  w_decorrenza_aggio              date;
  w_decorrenza_interessi          date;
  w_gg_anno                       number := 365;
--
  w_cod_tributo_int               number;
  w_cod_tributo_cap               number;
  w_cod_tributo_imp               number;
--
  w_imposta_evasa                 number;
  w_importo_oneri                 number;
  w_oneri_rata                    number;
  w_importo_rata                  number;
  w_importo_rata_arr              number;
  w_diff_rata                     number;

  w_aliquota_aggio                number;
  w_importo_aggio                 number;
  w_aggio_massimo                 number;
  w_aliquota_dilazione            number;
  w_importo_dilazione             number;

  w_tot_imposta                   number;
  w_tot_oneri                     number;
  w_tot_aggio                     number;
  w_tot_dilazione                 number;
  w_tot_importo                   number;
  w_tot_importo_arr               number;
  w_tot_rate_arr                  number;
  w_conta_rate_int                number;
  w_Add_Pro_perc                  number;

  w_errore                        varchar2(2000);
  errore                          exception;

  type t_riga_rata                is record
  ( t_scadenza_rata               date
  , t_flag_sosp_ferie             varchar2(1)
  , t_quota_imposta               number
  , t_quota_oneri                 number
  , t_quota_interessi             number
  , t_residuo_capitale            number
  , t_residuo_interessi           number
  , t_giorni_aggio                number
  , t_aliquota_aggio              number
  , t_aggio                       number
  , t_aggio_rimodulato            number
  , t_giorni_dilazione            number
  , t_aliquota_dilazione          number
  , t_dilazione                   number
  , t_dilazione_rimodulata        number
  , t_importo_base                number
  , t_importo_rata                number
  , t_importo_rata_arr            number
  , t_quota_tassa                 number
  , t_quota_tefa                  number
  );
  type type_elenco_rate           is table of t_riga_rata index by binary_integer;
  t_elenco_rate                   type_elenco_rate;

begin
  --
  -- Si selezionano i dati per l'emissione delle rate
  --
  begin
    select decode(prtr.tipo_tributo,
                 'TARSU',decode(nvl(cata.flag_lordo,'N'),
                               'S',F_IMPORTI_ACC(PRTR.PRATICA,'N','LORDO'),
                                   F_IMPORTI_ACC(PRTR.PRATICA,'N','NETTO')
                               ),
                 prtr.importo_totale
                 )
         , nvl(prtr.mora,0)
         , nvl(prtr.versato_pre_rate,0)
         , prtr.data_rateazione
         , prtr.data_rateazione
         , prtr.scadenza_prima_rata
         , prtr.data_notifica
         , prtr.rate
         , to_number(decode(prtr.tipologia_rate,'M',12
                                ,'B',6
                                ,'T',4
                                ,'Q',3
                                ,'S',2
                                ,'A',1))   -- numero di rate da pagare nell'anno
         , to_number(decode(prtr.tipologia_rate,'M',1
                                ,'B',2
                                ,'T',3
                                ,'Q',4
                                ,'S',6
                                ,'A',12))  -- numero mesi da sommare alla data per determinare le scadenze
         , prtr.anno
         , prtr.tipo_tributo
         , f_inpa_valore('RATE_FIME')
         , nvl(prtr.flag_int_rate_solo_evasa,'N')
         , nvl(prtr.calcolo_rate,nvl(f_inpa_valore('RATE_CALC'),'V'))
         , prtr.flag_rate_oneri
      into w_importo
         , w_importo_mora
         , w_importo_versato
         , w_data_rateazione
         , w_data_rateazione_iniz
         , w_scadenza_prima_rata
         , w_data_notifica
         , w_numero_rate
         , w_numero_periodi
         , w_numero_mesi
         , w_anno
         , w_tipo_tributo
         , w_rate_fime
         , w_tipo_importo_base
         , w_tipo_calcolo
         , w_flag_rate_oneri
      from PRATICHE_TRIBUTO prtr
         , CARICHI_TARSU    cata
     where prtr.pratica = a_pratica
       and prtr.anno    = cata.anno (+);
  exception
    when no_data_found then
      w_errore:= 'Pratica '||a_pratica||' non presente in archivio';
      raise errore;
  end;
  --
  -- Si seleziona la percentuale di add_pro TEFA che serve dal 2021
  --
  begin
    select nvl(cata.addizionale_pro,0)
      into w_Add_Pro_perc
      from carichi_tarsu   cata
     where cata.anno = w_anno
       and cata.anno >= 2021
    ;
  exception
    when no_data_found then
         w_Add_Pro_perc  := 0;
  end;
  --
  -- Si controlla che siano presenti tutti i dati necessari al
  -- calcolo della rateazione
  --
  if nvl(w_importo,0)          = 0 or
     nvl(w_data_rateazione,to_date('01011950','ddmmyyyy')) = to_date('01011950','ddmmyyyy') or
     nvl(w_numero_rate,0)      = 0 or
     nvl(w_numero_periodi,0)   = 0 or
     nvl(w_numero_mesi,0)      = 0 then
     w_errore := 'Indicare tutti i dati necessari al calcolo della rateazione';
     raise errore;
  end if;

  if nvl(w_scadenza_prima_rata,w_data_rateazione_iniz) < w_data_rateazione_iniz then
     w_errore := 'La Data Scadenza Prima Rata non puo'' essere inferiore alla Data Rateazione';
     raise errore;
  end if;

  --
  -- Si aggiornano i parametri nella tabella PRATICHE_TRIBUTO
  --
  begin
    update pratiche_tributo
       set importo_rate = to_number(null)
         , aliquota_rate = to_number(null)
         , calcolo_rate = nvl(calcolo_rate,w_tipo_calcolo)
     where pratica = a_pratica;
  exception
    when others then
      w_errore := 'Errore in aggiornamento PRATICHE_TRIBUTO ('||sqlerrm||')';
      raise errore;
  end;
  --
  GET_INPA_SOSP_FERIE(to_number(to_char(w_data_notifica,'yyyy')),w_inizio_sosp,w_fine_sosp,w_gg_sosp);
  -- Se la data di notifica ricade nel periodo di sospensione, si considera come
  -- notifica il primo giorno successivo alla fine della sospensione
  if w_inizio_sosp is not null and w_fine_sosp is not null and w_gg_sosp is not null then
     if w_data_notifica between w_inizio_sosp and w_fine_sosp then
        w_data_notifica := w_fine_sosp + 1;
     end if;
  end if;
  w_decorrenza_aggio     := w_data_notifica + 60;
  w_decorrenza_interessi := w_data_notifica + 90;
  -- Se le date di decorrenza di aggio e interessi ricadono nel periodo di
  -- sospensione oppure lo contengono, tali date vengono incrementate dei
  -- giorni di sospensione
  if w_inizio_sosp is not null and w_fine_sosp is not null and w_gg_sosp is not null then
     if w_data_notifica < w_inizio_sosp then
        if w_decorrenza_aggio > w_inizio_sosp or w_decorrenza_aggio > w_fine_sosp then
           w_decorrenza_aggio := w_decorrenza_aggio + w_gg_sosp;
        end if;
        if w_decorrenza_interessi > w_inizio_sosp or w_decorrenza_interessi > w_fine_sosp then
           w_decorrenza_interessi := w_decorrenza_interessi + w_gg_sosp;
        end if;
     end if;
  end if;
  --dbms_output.put_line('Decorrenza aggio: '||w_decorrenza_aggio);
  --dbms_output.put_line('Decorrenza interessi: '||w_decorrenza_interessi);
  --
  -- Si impostano i codici tributo a seconda del tipo_tributo che si sta
  -- trattando e si esclude il CUNI, perchè non si fanno f24
  --
  if w_tipo_tributo = 'CUNI' then
      w_cod_tributo_int := to_number(null);
      w_cod_tributo_cap := to_number(null);
  else
      begin
        select tributo_f24
          into w_cod_tributo_int
          from codici_f24
         where tipo_tributo = w_tipo_tributo
           and descrizione_titr = f_descrizione_titr(w_tipo_tributo,w_anno)
           and tipo_codice = 'I';
      exception
        when no_data_found then
          w_errore := 'Codice tributo interessi per '||f_descrizione_titr(w_tipo_tributo,w_anno)||' non previsto - Contattare assistenza';
          raise errore;
        when others then
          w_errore := 'Errore in selezione codice tributo interessi ('||sqlerrm||')';
          raise errore;
      end;
      --dbms_output.put_line('Codice F24 interessi: '||w_cod_tributo_int);
      begin
        select tributo_f24
          into w_cod_tributo_cap
          from codici_f24
         where tipo_tributo = w_tipo_tributo
           and descrizione_titr = f_descrizione_titr(w_tipo_tributo,w_anno)
           and tipo_codice = 'S';
      exception
        when no_data_found then
          w_errore := 'Codice tributo capitale per '||f_descrizione_titr(w_tipo_tributo,w_anno)||' non previsto - Contattare assistenza';
          raise errore;
        when others then
          w_errore := 'Errore in selezione codice tributo capitale ('||sqlerrm||')';
          raise errore;
      end;
      begin
        select tributo_f24
          into w_cod_tributo_imp
          from codici_f24
         where tipo_tributo = w_tipo_tributo
           and descrizione_titr = f_descrizione_titr(w_tipo_tributo,w_anno)
           and tipo_codice = 'C'
           and flag_tributo_rif = 'S';
      exception
        when no_data_found then
          w_cod_tributo_imp := w_cod_tributo_cap;
        when others then
          w_errore := 'Errore in selezione codice tributo Imposta ('||sqlerrm||')';
          raise errore;
      end;
  end if;
  --dbms_output.put_line('Codice F24 capitale: '||w_cod_tributo_cap);
  -- Si determina l'importo dell'imposta e l'importo degli oneri
  begin
   select decode(w_tipo_tributo,
                 'TARSU',
                 F_IMPORTI_ACC(pratica, 'N', 'TASSA_EVASA') +
                 F_IMPORTI_ACC(pratica, 'N', 'MAGGIORAZIONE') +
                 F_IMPORTI_ACC(pratica, 'N', 'ADD_ECA') +
                 F_IMPORTI_ACC(pratica, 'N', 'MAG_ECA') +
                 F_IMPORTI_ACC(pratica, 'N', 'ADD_PRO') +
                 F_IMPORTI_ACC(pratica, 'N', 'IVA'),
                 sum(decode(tipo_causale, 'E', importo, 0))),
          sum(decode(tipo_causale, 'E', 0, importo))
     into w_imposta_evasa, w_importo_oneri
     from sanzioni sanz, sanzioni_pratica sapr
    where sapr.pratica      = a_pratica
      and sanz.tipo_tributo = sapr.tipo_tributo
      and sanz.cod_sanzione = sapr.cod_sanzione
      and sanz.sequenza     = sapr.sequenza_sanz
--    (select prtr.pratica,
--                  sanz.tipo_causale,
--                  prtr.tipo_tributo,
--                  sapr.importo +
--                  decode(ogpr.flag_ruolo,
--                         'S',
--                         decode(DECODE(sanz.cod_sanzione,
--                                       1,
--                                       1,
--                                       100,
--                                       1,
--                                       101,
--                                       1,
--                                       DECODE(sanz.tipo_causale ||
--                                              nvl(sanz.flag_magg_tares, 'N'),
--                                              'EN',
--                                              1,
--                                              0)),
--                                1,
--                                decode(nvl(catu.FLAG_LORDO, 'N'),
--                                       'S',
--                                       round(sapr.importo *
--                                             nvl(catu.addizionale_eca, 0) / 100,
--                                             2) +
--                                       round(sapr.importo *
--                                             nvl(catu.maggiorazione_eca, 0) / 100,
--                                             2) +
--                                       round(sapr.importo *
--                                             nvl(catu.addizionale_pro, 0) / 100,
--                                             2) +
--                                       round(sapr.importo * nvl(catu.aliquota, 0) / 100,
--                                             2),
--                                       0),
--                                0),
--                         0) importo
--             from pratiche_tributo prtr,
--                  sanzioni_pratica sapr,
--                  sanzioni sanz,
--                  carichi_tarsu catu,
--                  (select nvl(max(nvl(cotr.flag_ruolo, 'N')), 'N') flag_ruolo
--                     from codici_tributo cotr, oggetti_pratica ogpr
--                    where cotr.tributo = ogpr.tributo
--                      and ogpr.pratica = a_pratica) ogpr
--     where sapr.pratica = a_pratica
--              and prtr.pratica = sapr.pratica
--       and sapr.tipo_tributo = sanz.tipo_tributo
--       and sapr.cod_sanzione = sanz.cod_sanzione
--              and catu.anno = prtr.anno)
    group by sapr.tipo_tributo, sapr.pratica;
  exception
    when others then
      w_imposta_evasa := 0;
      w_importo_oneri := 0;
  end;
--  dbms_output.put_line('Importo: '||w_importo||', Importo Oneri: '||w_importo_oneri||', Importo Versato: '||w_importo_versato||', Oneri rata: '||w_oneri_rata);
--  dbms_output.put_line('Imposta evasa: '||w_imposta_evasa||', Importo oneri: '||w_importo_oneri);
  -- Se occorre calcolare gli interessi sulla sola imposta e esiste un versato
  -- pre-rate, si suddivide proporzionalmente tra imposta e oneri
  if w_tipo_importo_base = 'S' then
     w_importo_pratica := w_importo;
     w_importo_oneri := w_importo_oneri + w_importo_mora;
     w_importo       := w_imposta_evasa - round((w_imposta_evasa * w_importo_versato / w_importo_pratica),2);
     w_importo_oneri := w_importo_oneri - round((w_importo_oneri * w_importo_versato / w_importo_pratica),2);
     w_oneri_rata    := round(w_importo_oneri / w_numero_rate,2);
  else
     w_importo       := w_importo + w_importo_mora - w_importo_versato;
     w_importo_oneri := 0;
     w_oneri_rata    := 0;
  end if;
  w_importo_rata := round(w_importo / w_numero_rate,2);
  dbms_output.put_line('Importo: '||w_importo||', Importo Oneri: '||w_importo_oneri||' Importo Rata: '||w_importo_rata||', Oneri rata: '||w_oneri_rata);

  -- Si determinano le scadenze delle rate e si memorizzano nell'array
  --
  t_elenco_rate.delete;
  w_tot_aggio := 0;
  w_gg_iniz := to_char(w_data_rateazione_iniz,'dd');

  for w_rata in 1..w_numero_rate
  loop
    --dbms_output.put_line('Rata: '||w_rata);
    if w_rata = 1 and w_scadenza_prima_rata is not null then
       w_data_rateazione := w_scadenza_prima_rata;
       w_gg_iniz := to_char(w_data_rateazione,'dd');
    else
       w_data_rateazione := add_months(w_data_rateazione_iniz,w_numero_mesi);
       if last_day(w_data_rateazione_iniz) = w_data_rateazione_iniz and nvl(upper(w_rate_fime),'N') = 'N' then
          w_data_rateazione := to_date(least(w_gg_iniz,to_char(last_day(w_data_rateazione),'dd'))||to_char(w_data_rateazione,'mmyyyy'),'ddmmyyyy');
       end if;
    end if;
    w_flag_sosp_ferie   := null;
    -- Se la data di scadenza della rata ricade nel periodo di sospensione,
    -- tale data viene incrementata dei giorni di sospensione
    if w_inizio_sosp is not null and w_fine_sosp is not null and w_gg_sosp is not null then
dbms_output.put_line('Rata: '||w_rata||' data_rateazione iniz: '||w_data_rateazione_iniz||' data_rateazione: '||w_data_rateazione||' sosp '||w_inizio_sosp);--       if w_data_rateazione_iniz < w_inizio_sosp then
          -- AB 04/01/2024 aggiunto perchè altrimenti non considerava la sospensione per le rate degli anni successivi
          if to_number(to_char(w_data_rateazione,'yyyy')) > to_number(to_char(w_inizio_sosp,'yyyy')) then
             w_inizio_sosp := to_date(to_char(w_inizio_sosp,'dd/mm/')||to_char(w_data_rateazione,'yyyy'),'dd/mm/yyyy');
             w_fine_sosp   := to_date(to_char(w_fine_sosp,'dd/mm/')||to_char(w_data_rateazione,'yyyy'),'dd/mm/yyyy');
dbms_output.put_line('Rata interna: '||w_rata||' data_rateazione iniz: '||w_data_rateazione_iniz||' data_rateazione: '||w_data_rateazione||' sosp '||w_inizio_sosp);
          end if;
       if w_data_rateazione_iniz < w_inizio_sosp then
          if w_data_rateazione >= w_inizio_sosp or w_data_rateazione >= w_fine_sosp then
             w_data_rateazione      := w_data_rateazione + w_gg_sosp;
dbms_output.put_line('Rata interna2: '||w_rata||' data_rateazione iniz: '||w_data_rateazione_iniz||' data_rateazione: '||w_data_rateazione||' sosp '||w_inizio_sosp||' gg sosp '||w_gg_sosp);
             --AB 4/1/24 per evitare che se le reate iniziano alla fine del mese e la sosp è dal 1 al 31/8 sommando 31 gg si passi a ottobre
             if (to_number(to_char(w_data_rateazione_iniz,'mm')) + 3) = to_number(to_char(w_data_rateazione,'mm'))
             and w_gg_sosp = 31 then --nvl(upper(w_rate_fime),'N') = 'S'then
                w_data_rateazione      := w_data_rateazione - 1;
             end if;
             w_flag_sosp_ferie      := 'S';
dbms_output.put_line('Rata interna3: '||w_rata||' data_rateazione iniz: '||w_data_rateazione_iniz||' data_rateazione: '||w_data_rateazione||' sosp '||w_inizio_sosp||' gg sosp '||w_gg_sosp);
          end if;
       end if;
    end if;
    -- (VD - 24/06/2022): si aggiorna la data di rateazione iniziale
    --                    per evitare che i gg di sospensione vengano
    --                    sommati alla scadenza di tutte le rate
    --                    successive
    w_data_rateazione_iniz := w_data_rateazione;
    -- Gestione scadenza rate fine mese
    if w_rata > 1 or w_scadenza_prima_rata is null then
       if nvl(upper(w_rate_fime),'N') = 'S' then
          w_data_rateazione := last_day(w_data_rateazione);
       end if;
    end if;
    t_elenco_rate(w_rata).t_scadenza_rata   := w_data_rateazione;
    t_elenco_rate(w_rata).t_flag_sosp_ferie := w_flag_sosp_ferie;
    if w_rata < w_numero_rate then
       t_elenco_rate(w_rata).t_quota_imposta  := w_importo_rata;
       t_elenco_rate(w_rata).t_quota_tassa    := round(w_importo_rata / ((100+w_Add_Pro_perc)/100),2);
       t_elenco_rate(w_rata).t_quota_tefa     := w_importo_rata - t_elenco_rate(w_rata).t_quota_tassa;
       t_elenco_rate(w_rata).t_quota_oneri    := w_oneri_rata;
    else
       t_elenco_rate(w_rata).t_quota_imposta  := w_importo - (w_importo_rata * (w_numero_rate - 1));
       t_elenco_rate(w_rata).t_quota_tassa    := round((w_importo - (w_importo_rata * (w_numero_rate - 1))) /  ((100+w_Add_Pro_perc)/100),2);
       t_elenco_rate(w_rata).t_quota_tefa     := (w_importo - (w_importo_rata * (w_numero_rate - 1))) - t_elenco_rate(w_rata).t_quota_tassa;
       t_elenco_rate(w_rata).t_quota_oneri    := w_importo_oneri - (w_oneri_rata * (w_numero_rate - 1));
    end if;

    if nvl(w_flag_rate_oneri,'N') = 'S' then  -- indica se si vogliono trattare gli oneri di riscossione aggi
        -- Calcolo oneri di riscossione (aggio)
        t_elenco_rate(w_rata).t_giorni_aggio := w_data_rateazione - w_decorrenza_aggio + 60;
        --
        begin
          select aggi.aliquota
               , round((t_elenco_rate(w_rata).t_quota_imposta +
                        t_elenco_rate(w_rata).t_quota_oneri) *
                       aggi.aliquota / 100,2) importo_aggio
               , nvl(importo_massimo,0)
            into w_aliquota_aggio
               , w_importo_aggio
               , w_aggio_massimo
            from aggi
           where aggi.tipo_tributo = w_tipo_tributo
             and t_elenco_rate(w_rata).t_giorni_aggio between aggi.giorno_inizio
                                                          and aggi.giorno_fine
             and trunc(sysdate) between aggi.data_inizio and aggi.data_fine;
        exception
          when others then
            w_aliquota_aggio := 0;
            w_importo_aggio  := 0;
            w_aggio_massimo  := 999999999;
        end;
        --
        t_elenco_rate(w_rata).t_aliquota_aggio := w_aliquota_aggio;
        if (w_tot_aggio + w_importo_aggio) >= w_aggio_massimo then
           t_elenco_rate(w_rata).t_aggio       := greatest(0, w_aggio_massimo - w_tot_aggio);
        else
           t_elenco_rate(w_rata).t_aggio       := w_importo_aggio;
        end if;
        w_tot_aggio                            := w_tot_aggio + t_elenco_rate(w_rata).t_aggio;
    else
        t_elenco_rate(w_rata).t_aggio       := 0;
    end if;

    -- Determinazione interessi di dilazione
    if w_tipo_importo_base = 'S' then
       t_elenco_rate(w_rata).t_importo_base := t_elenco_rate(w_rata).t_quota_imposta;
    else
       t_elenco_rate(w_rata).t_importo_base := t_elenco_rate(w_rata).t_quota_imposta +
                                               t_elenco_rate(w_rata).t_quota_oneri;
    end if;
    if w_data_rateazione > w_decorrenza_interessi then
       t_elenco_rate(w_rata).t_giorni_dilazione := w_data_rateazione - w_decorrenza_interessi;
       begin
         select inte.aliquota
              , round(t_elenco_rate(w_rata).t_importo_base *
                nvl(inte.aliquota,0) / 100 *
                t_elenco_rate(w_rata).t_giorni_dilazione / w_gg_anno,2)
           into w_aliquota_dilazione
              , w_importo_dilazione
           from interessi inte
          where tipo_tributo = w_tipo_tributo
            and trunc(sysdate) between data_inizio and data_fine
            and tipo_interesse = 'D';
       exception
         when others then
           w_aliquota_dilazione := 0;
           w_importo_dilazione  := 0;
       end;
    else
       t_elenco_rate(w_rata).t_giorni_dilazione := 0;
       w_aliquota_dilazione                     := 0;
       w_importo_dilazione                      := 0;
    end if;

    t_elenco_rate(w_rata).t_aliquota_dilazione := w_aliquota_dilazione;
    t_elenco_rate(w_rata).t_dilazione          := w_importo_dilazione;

    -- Calcolo importo rata
  t_elenco_rate(w_rata).t_importo_rata := t_elenco_rate(w_rata).t_quota_imposta +
                                            t_elenco_rate(w_rata).t_quota_oneri +
                                            t_elenco_rate(w_rata).t_aggio +
                                            t_elenco_rate(w_rata).t_dilazione;
    t_elenco_rate(w_rata).t_importo_rata_arr := round(t_elenco_rate(w_rata).t_importo_rata);
--dbms_output.put_line('Imposta: '||t_elenco_rate(w_rata).t_quota_imposta||' oneri: '||
--                                            t_elenco_rate(w_rata).t_quota_oneri||' aggio: '||
--                                            t_elenco_rate(w_rata).t_aggio ||' dilazione: '||
--                                            t_elenco_rate(w_rata).t_dilazione||' importo rata: '||
--                                            t_elenco_rate(w_rata).t_importo_rata);
  end loop;
  -- Calcolo totali
  w_tot_imposta    := 0;
  w_tot_oneri      := 0;
  w_tot_aggio      := 0;
  w_tot_dilazione  := 0;
  w_tot_importo    := 0;
  w_tot_rate_arr   := 0;
  w_conta_rate_int := 0;
  for w_rata in t_elenco_rate.first..t_elenco_rate.last
  loop
    w_tot_imposta    := w_tot_imposta   + t_elenco_rate(w_rata).t_quota_imposta;
    w_tot_oneri      := w_tot_oneri     + t_elenco_rate(w_rata).t_quota_oneri;
    w_tot_aggio      := w_tot_aggio     + t_elenco_rate(w_rata).t_aggio;
    w_tot_dilazione  := w_tot_dilazione + t_elenco_rate(w_rata).t_dilazione;
    w_tot_importo    := w_tot_importo   + t_elenco_rate(w_rata).t_importo_rata;
    w_tot_rate_arr   := w_tot_rate_arr  + t_elenco_rate(w_rata).t_importo_rata_arr;
    if t_elenco_rate(w_rata).t_dilazione > 0 then
       w_conta_rate_int := w_conta_rate_int + 1;
    end if;
  end loop;
  w_tot_importo_arr  := round(w_tot_importo,0);
  -- Tipo calcolo 'V' (rate variabili): si determina l'importo della rata
  -- arrotondato
  if w_tipo_calcolo = 'V' then
     if w_tot_importo_arr <> w_tot_rate_arr then
        t_elenco_rate(w_numero_rate).t_importo_rata_arr := t_elenco_rate(w_numero_rate).t_importo_rata_arr +
                                                           (w_tot_importo_arr - w_tot_rate_arr);
     end if;
  end if;
  -- Tipo calcolo = 'C': determinazione della rata costante
  if w_tipo_calcolo = 'C' then
     --dbms_output.put_line('w_tot_importo_arr: '||w_tot_importo_arr);
     -- 23/11/2023 AB Evitato il calcolo qui ma inserito all'interno delle singole rate
--     w_importo_rata      := round(w_tot_importo / w_numero_rate,2);
--     w_importo_rata_arr  := round(w_importo_rata,0);
     w_importo_aggio     := round(w_tot_aggio / w_numero_rate,2);
     w_importo_dilazione := round(w_tot_dilazione / w_numero_rate,2);

--dbms_output.put_line('rata costante - tot_importo: '||w_tot_importo||' aggio: '||
--                                            w_importo_aggio ||' dilazione: '||
--                                            w_importo_dilazione||' importo rata: '||
--                                            w_importo_rata);
     for w_rata in 1..w_numero_rate
     loop
       --dbms_output.put_line('Rata: '||w_rata);
       if w_rata < w_numero_rate then
          w_importo_rata      := round(w_importo_aggio + w_importo_dilazione +
                                       t_elenco_rate(w_rata).t_quota_imposta +
                                       t_elenco_rate(w_rata).t_quota_oneri,2);
          w_importo_rata_arr  := round(w_importo_rata,0);
          t_elenco_rate(w_rata).t_aggio_rimodulato     := w_importo_aggio;
          t_elenco_rate(w_rata).t_dilazione_rimodulata := w_importo_dilazione;
          t_elenco_rate(w_rata).t_importo_rata         := w_importo_rata;
          t_elenco_rate(w_rata).t_importo_rata_arr     := w_importo_rata_arr;
       else
          t_elenco_rate(w_rata).t_aggio_rimodulato := w_tot_aggio -
                                                     (w_importo_aggio *
                                                     (w_numero_rate - 1));
          t_elenco_rate(w_rata).t_dilazione_rimodulata := w_tot_dilazione -
                                                         (w_importo_dilazione *
                                                         (w_numero_rate - 1));
          t_elenco_rate(w_rata).t_importo_rata := w_tot_importo -
                                                 (w_importo_rata *
                                                 (w_numero_rate -1));
          t_elenco_rate(w_rata).t_importo_rata_arr := w_tot_importo_arr -
                                                     (w_importo_rata_arr *
                                                     (w_numero_rate - 1));
       end if;
--dbms_output.put_line('Rimodulato Imposta: '||t_elenco_rate(w_rata).t_quota_imposta||' oneri: '||
--                                            t_elenco_rate(w_rata).t_quota_oneri||' aggio: '||
--                                            t_elenco_rate(w_rata).t_aggio_rimodulato ||' dilazione: '||
--                                            t_elenco_rate(w_rata).t_dilazione_rimodulata||' importo rata: '||
--                                            t_elenco_rate(w_rata).t_importo_rata);
     end loop;
     -- Quadratura rata: se l'importo della rata non coincide con la somma
     -- dei suoi componenti, si assesta l'aggio rimodulato
     if (w_aliquota_aggio > 0) then
     for w_rata in 1..w_numero_rate
     loop
       w_diff_rata := t_elenco_rate(w_rata).t_importo_rata -
                      (t_elenco_rate(w_rata).t_quota_imposta +
                       t_elenco_rate(w_rata).t_quota_oneri +
                       t_elenco_rate(w_rata).t_aggio_rimodulato +
                       t_elenco_rate(w_rata).t_dilazione_rimodulata);
       if w_diff_rata <> 0 then
          t_elenco_rate(w_rata).t_aggio_rimodulato := t_elenco_rate(w_rata).t_aggio_rimodulato +
                                                      w_diff_rata;
       end if;
     end loop;
  end if;
  end if;
  -- Inserimento righe tabella RATE_PRATICA
  for w_rata in t_elenco_rate.first..t_elenco_rate.last
  loop
    begin
      insert into RATE_PRATICA ( rata_pratica
                               , pratica
                               , rata
                               , data_scadenza
                               , anno
                               , tributo_capitale_f24
                               , importo_capitale
                               , tributo_interessi_f24
                               , importo_interessi
                               , residuo_capitale
                               , residuo_interessi
                               , utente
                               , data_variazione
                               , note
                               , giorni_aggio
                               , aliquota_aggio
                               , aggio
                               , aggio_rimodulato
                               , giorni_dilazione
                               , aliquota_dilazione
                               , dilazione
                               , dilazione_rimodulata
                               , importo
                               , importo_arr
                               , oneri
                               , flag_sosp_ferie
                               , quota_tassa
                               , quota_tefa
                               , tributo_imposta_f24
                               , tributo_tefa_f24
                               )
      values ( to_number(null)
             , a_pratica
             , w_rata
             , t_elenco_rate(w_rata).t_scadenza_rata
             , to_number(to_char(t_elenco_rate(w_rata).t_scadenza_rata,'yyyy'))
             , w_cod_tributo_cap
             , t_elenco_rate(w_rata).t_quota_imposta
             , w_cod_tributo_int
             , nvl(t_elenco_rate(w_rata).t_quota_interessi,0)
             , t_elenco_rate(w_rata).t_residuo_capitale
             , t_elenco_rate(w_rata).t_residuo_interessi
             , a_utente
             , trunc(sysdate)
             , ''
             , t_elenco_rate(w_rata).t_giorni_aggio
             , t_elenco_rate(w_rata).t_aliquota_aggio
             , t_elenco_rate(w_rata).t_aggio
             , t_elenco_rate(w_rata).t_aggio_rimodulato
             , t_elenco_rate(w_rata).t_giorni_dilazione
             , t_elenco_rate(w_rata).t_aliquota_dilazione
             , t_elenco_rate(w_rata).t_dilazione
             , t_elenco_rate(w_rata).t_dilazione_rimodulata
             , t_elenco_rate(w_rata).t_importo_rata
             , t_elenco_rate(w_rata).t_importo_rata_arr
             , t_elenco_rate(w_rata).t_quota_oneri
             , t_elenco_rate(w_rata).t_flag_sosp_ferie
             , case
                   when w_tipo_tributo = 'TARSU'
                    and w_anno >= 2021 then  -- tolto il controllo sull'anno w_anno >= 2021
                                             -- AB 20/04/2023 rimesso il controllo
                        t_elenco_rate(w_rata).t_quota_tassa
                   else
                        t_elenco_rate(w_rata).t_quota_imposta
                end
             , case
                   when w_tipo_tributo = 'TARSU'
                    and w_anno >= 2021 then  -- tolto il controllo sull'anno w_anno >= 2021
                                             -- AB 20/04/2023 rimesso il controllo
                        t_elenco_rate(w_rata).t_quota_tefa
                   else
                        to_number(null)
                end
             , w_cod_tributo_imp
             ,'TEFA'
             );
    exception
      when others then
        w_errore := 'Pratica n. '||a_pratica||' - Insert RATE_PRATICA ('||sqlerrm||')';
        raise errore;
    end;
  end loop;
  -- Determinazione della rata costante solo in presenza di interessi e aggio
  if w_tipo_calcolo = 'R' and
     w_conta_rate_int > 0 then
     -- Si ripartiscono gli interessi sulle rate in modo da avere una rata costante
     for inr in (select min(rata) rata_min
                      , max(rata) rata_max
                      , sum(dilazione) tot_dilazione
                      , sum(importo) tot_rate
                      , count(1) num_rate
                   from rate_pratica
                  where pratica = a_pratica
                  group by aliquota_aggio,aliquota_dilazione)
     loop
       --w_importo_dilazione := round(inr.tot_dilazione / inr.num_rate,2);
       w_importo_rata := round(inr.tot_rate / inr.num_rate,2);
       begin
         update rate_pratica rapr
--            set rapr.dilazione_rimodulata = decode(rapr.rata
--                                                  ,inr.rata_max,inr.tot_dilazione -
--                                                                (w_importo_dilazione * (inr.num_rate - 1))
--                                                  ,w_importo_dilazione
--                                                  )
--              , rapr.importo = rapr.importo_capitale + rapr.oneri +
--                               rapr.importo_interessi + rapr.aggio +
--                               decode(rapr.rata
--                                     ,inr.rata_max,inr.tot_dilazione -
--                                                  (w_importo_dilazione * (inr.num_rate - 1))
--                                     ,w_importo_dilazione
--                                     )
            set rapr.importo = decode(rapr.rata
                                     ,inr.rata_max,inr.tot_rate -
                                                  (w_importo_rata * (inr.num_rate - 1))
                                     ,w_importo_rata
                                     )
              , rapr.dilazione_rimodulata = decode(rapr.rata
                                                  ,inr.rata_max,inr.tot_rate -
                                                                (w_importo_rata * (inr.num_rate - 1))
                                                  ,w_importo_rata
                                                  ) -
                                           (rapr.importo_capitale + rapr.oneri + rapr.aggio)
          where rapr.pratica = a_pratica
            and rapr.rata between inr.rata_min and inr.rata_max;
       exception
         when others then
           w_errore := 'Pratica n. '||a_pratica||' - Update RATE_PRATICA ('||sqlerrm||')';
           raise errore;
       end;
     end loop;
  end if;
  --
  --commit;
  --
EXCEPTION
   WHEN errore THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,'Pratica: '||a_pratica||' '||w_errore);
   WHEN others THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR
      (-20999,'Errore in Calcolo Rateazione della Pratica '||
              a_pratica||' ('||SQLERRM||')');
end;
/* End Procedure: CALCOLO_RATEAZIONE_AGGI */
/
