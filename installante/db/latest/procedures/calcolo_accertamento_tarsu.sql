--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_accertamento_tarsu stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_ACCERTAMENTO_TARSU
/*************************************************************************
  Rev.    Date         Author      Note
  2       12/04/2019   VD          Aggiunta gestione nuovi campi di
                                   oggetti_imposta per calcolo con tariffe.
  1       10/08/2015   SC          Personalizzazione S.Lazzaro
                                   Attivita SAP
                                   CR518970 - Calcolo Accertamento a giorni
                                   (san Lazzaro)
*************************************************************************/
(a_anno                IN       number,
 a_consistenza         IN       number,
 a_data_decorrenza     IN       date,
 a_data_cessazione     IN       date,
 a_percentuale         IN       number,
 a_tributo             IN       number,
 a_categoria           IN       number,
 a_tipo_tariffa        IN       number,
 a_oggetto_pratica     IN       number,
 a_oggetto_pratica_rif IN       number,
 a_cod_fiscale         IN       varchar2,
 a_ni                  IN       number,
 a_flag_normalizzato   IN       varchar2,
 a_flag_ab_principale  IN       varchar2,
 a_tipo_occupazione    IN       varchar2,
 a_numero_familiari    IN       varchar2,
 a_imposta             IN OUT   number,
 a_imposta_lorda       IN OUT   number,
 a_flag_lordo          IN OUT   varchar2,
 a_magg_tares          IN OUT   number,
 a_dettaglio_ogim      IN OUT   varchar2,
 a_add_eca             IN OUT   number,
 a_magg_eca            IN OUT   number,
 a_add_prov            IN OUT   number,
 a_iva                 IN OUT   number,
 a_stringa_familiari   IN OUT   varchar2,
 a_importo_pf          IN OUT   number,
 a_importo_pv          IN OUT   number,
 a_tipo_tariffa_base   IN OUT   number,
 a_importo_base        IN OUT   number,
 a_add_eca_base        IN OUT   number,
 a_magg_eca_base       IN OUT   number,
 a_add_prov_base       IN OUT   number,
 a_iva_base            IN OUT   number,
 a_importo_pf_base     IN OUT   number,
 a_importo_pv_base     IN OUT   number,
 a_perc_rid_pf         IN OUT   number,
 a_perc_rid_pv         IN OUT   number,
 a_importo_pf_rid      IN OUT   number,
 a_importo_pv_rid      IN OUT   number,
 a_dettaglio_ogim_base IN OUT   varchar2,
 a_imposta_periodo     IN OUT   number)
IS
w_cod_istat                     varchar2(6);
w_flag_giorni                   varchar2(1);
w_tariffa                       number;
w_limite                        number;
w_tari_sup                      number;
w_tar_quota_fissa               number;
w_periodo                       number;
w_imposta                       number;
w_str_ogpr                      varchar2(2000);
w_str_dal                       varchar2(2000);
w_str_al                        varchar2(2000);
w_ogpr                          number;
w_dal                           date;
w_al                            date;
w_consistenza                   number;
w_percentuale                   number;
w_flag_ab_principale            varchar2(1);
w_tributo                       number;
w_categoria                     number;
w_tipo_tariffa                  number;
w_data_decorrenza               date;
w_data_cessazione               date;
w_pos                           number;
w_flag_lordo                    varchar2(1);
w_addizionale_eca               number;
w_maggiorazione_eca             number;
w_addizionale_pro               number;
w_aliquota                      number;
w_flag_ruolo                    varchar2(1);
w_importo_pf                    number;
w_importo_pv                    number;
w_stringa_familiari             varchar2(2000);
w_ret_familiari                 varchar2(2000) := rpad('1',2000, '1');
w_ret_dettaglio_ogim            varchar2(4000) := rpad('1',2000, '1');
w_dettaglio_ogim                varchar2(4000);
w_numero_familiari              number;
w_giorni_ruolo                  number;
--var per gestione magg tares
w_tariffa_magg_tares            number;
w_maggiorazione_tares           number;
w_flag_magg_anno                varchar2(1);
w_perc_riduzione                number;
w_coeff_gg                      number;
--var fine per gestione magg tares
-- variabili per totali (che probabilmente non servono...)
w_tot_imposta                   number;
w_tot_importo_pf                number;
w_tot_importo_pv                number;
w_tot_importo_base              number;
w_tot_importo_pf_base           number;
w_tot_importo_pv_base           number;
w_tot_importo_pf_rid            number;
w_tot_importo_pv_rid            number;
-- Variabili per gestione calcolo con tariffa e con tariffa base
w_flag_tariffe_ruolo        varchar2(1);
w_tipo_tariffa_base         number;
w_importo_base              number;
w_importo_pf_base           number;
w_importo_pv_base           number;
w_perc_rid_pf               number;
w_perc_rid_pv               number;
w_importo_rid               number;
w_importo_pf_rid            number;
w_importo_pv_rid            number;
w_dettaglio_ogim_base       varchar2(4000);
w_ret_dettaglio_ogim_base   varchar2(4000) := rpad('1',2000, '1');
w_imposta_periodo           number;
cursor sel_ogva(a_ogpr_dic    number
               ,a_ogpr        number
               ,a_cod_fiscale varchar2
               ,a_anno        number
               ) is
select ogva.oggetto_pratica ogpr
      ,greatest(nvl(ogva.dal,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy'))
               ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')) dal
      ,least(nvl(ogva.al,to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy'))
            ,to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')) al
  from oggetti_validita ogva
 where ogva.cod_fiscale         = a_cod_fiscale
   and ogva.tipo_tributo||''    = 'TARSU'
   and ogva.oggetto_pratica     = a_ogpr_dic
  -- and ogva.oggetto_pratica    <> nvl(a_ogpr,0)
   and nvl(ogva.dal,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy'))
                               <=
          to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
   and nvl(ogva.al ,to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy'))
                               >=
          to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
 order by 2,3,1
;
-- Ho modificato il cursore per gestire solo l' OGVA che si va ad accertare e non tutto l'anno
-- questo perchè le sanzioni dell'accertamento vengono calcolate sulla differenza d'imposta tra
-- l'imposta dell'accertamento e l'imposta dell' OGVA scelto .
-- Piero (26-11-2009)
BEGIN
--raise_application_error(-20999, 'anno '||a_anno||
-- ' cons '||a_consistenza||
-- ' data dec '||a_data_decorrenza||
-- ' data ces '||a_data_cessazione||
-- ' perc '||a_percentuale||
-- ' trib '||a_tributo||
-- ' cat '||a_categoria||
-- ' tipo tar '||a_tipo_tariffa||
-- ' ogpr '||a_oggetto_pratica||
-- ' ogpr rif '||a_oggetto_pratica_rif||
-- ' cf '||a_cod_fiscale||
-- ' ni '||a_ni||
-- ' norm '||a_flag_normalizzato||
-- ' a p '||a_flag_ab_principale||
-- ' tipo oc '||a_tipo_occupazione||
-- ' num fam '||a_numero_familiari);
  BEGIN
     select nvl(cotr.flag_ruolo,'N')
       into w_flag_ruolo
       from codici_tributo    cotr
      where cotr.tributo      = a_tributo
     ;
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
        w_flag_ruolo := 'N';
  END;
  BEGIN
     select nvl(cate.flag_giorni,'N')
       into w_flag_giorni
       from categorie    cate
      where cate.tributo      = a_tributo
        and cate.categoria    = a_categoria
     ;
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
        w_flag_giorni := 'N';
  END;
  BEGIN
     select nvl(cata.addizionale_eca,0)
           ,nvl(cata.maggiorazione_eca,0)
           ,nvl(cata.addizionale_pro,0)
           ,nvl(cata.aliquota,0)
           ,nvl(w_flag_lordo,nvl(flag_lordo,'N'))
           ,maggiorazione_tares
           ,flag_magg_anno
           ,flag_tariffe_ruolo
       into w_addizionale_eca
           ,w_maggiorazione_eca
           ,w_addizionale_pro
           ,w_aliquota
           ,w_flag_lordo
           ,w_tariffa_magg_tares
           ,w_flag_magg_anno
           ,w_flag_tariffe_ruolo
       from carichi_tarsu cata
      where cata.anno = a_anno
     ;
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
        w_flag_lordo        := 'N';
        w_addizionale_eca   := 0;
        w_maggiorazione_eca := 0;
        w_addizionale_pro   := 0;
        w_aliquota          := 0;
  END;
  BEGIN
      select lpad(to_char(pro_cliente),3,'0')||
             lpad(to_char(com_cliente),3,'0')
        into w_cod_istat
        from dati_generali
      ;
  EXCEPTION
  WHEN OTHERS THEN
      RAISE_APPLICATION_ERROR
              (-20999,'Errore in ricerca Dati Generali');
  END;
  BEGIN
   -- Si inizializzano 3 stringhe contenenti oggetto pratica, dal, al
   -- dei periodi di oggetti validita` dell`anno.
   -- Le date Dal e Al sono portate al 1/1 e 31/12 dell`anno se nulle
   -- o inferiori all`inizio e fine anno.
   -- La stessa cosa viene fatta per l`accertamento in esame sulle
   -- date di decorrenza (dal) e cessazione (al).
     w_str_ogpr := null;
     w_str_dal  := null;
     w_str_al   := null;
     w_data_decorrenza := greatest(nvl(a_data_decorrenza
                                      ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
                                      )
                                  ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
                                  );
     w_data_cessazione := least(nvl(a_data_cessazione
                                   ,to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
                                   )
                               ,to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
                               );
   --dbms_output.put_line('calcolo acc data dec '||w_data_decorrenza);
   --dbms_output.put_line('calcolo acc data ces '||w_data_cessazione);
   -- Si riempono le stringhe con gli oggetti pratica dell`anno valorizzando
   -- le date Dal e Al in rapporto al periodo dell`accertamento in esame.
   -- I periodi sono estratti ordinati per Dal e Al.
   -- Se il periodo di validita` e` completamente compreso nel periodo di
   -- validita` dell`accertamento, non si considera.
   -- Se il Dal e` compreso nel periodo di accertamento e Al superiore alla
   -- sua data di cessazione, il periodo cambia il dal = alla data di
   -- cessazione dell`accertamento + 1.
   -- Se il Dal e` inferiore alla data di decorrenza dell`accertamento e Al
   -- e` compreso nel periodo di accertamento l`al = alla data di decorrenza
   -- dell`accertamento - 1.
   -- Se il Dal e` inferiore alla data di decorrenza dell`accertamento e
   -- l`Al e` superiore alla data di cessazione dell`accertamento si hanno due
   -- periodi che sono l`unione dei due casi esposti in precedenza.
   -- Se il periodo non si interseca col periodo di validita` dell`accertamento,
   -- si considera nella sua interezza.
   for rec_ogva in sel_ogva(a_oggetto_pratica_rif,a_oggetto_pratica
                           ,a_cod_fiscale,a_anno
                           )
     loop
         dbms_output.put_line('rec_ogva.dal '||rec_ogva.dal);
         dbms_output.put_line('rec_ogva.al '||rec_ogva.al);
         dbms_output.put_line('w_data_decorrenza '||w_data_decorrenza);
         dbms_output.put_line('w_data_cessazione '||w_data_cessazione);
        if  rec_ogva.dal between w_data_decorrenza and w_data_cessazione
        and rec_ogva.al  between w_data_decorrenza and w_data_cessazione then
        DBMS_OUTPUT.PUT_LINE('Null');
           null;
        else
           if  rec_ogva.al  < w_data_decorrenza
           or  rec_ogva.dal > w_data_cessazione then
         DBMS_OUTPUT.PUT_LINE('Caso 1');
              w_str_ogpr := w_str_ogpr||lpad(to_char(rec_ogva.ogpr),10,'0');
               w_str_dal  := w_str_dal ||to_char(rec_ogva.dal,'dd/mm/yyyy');
               w_str_al   := w_str_al  ||to_char(rec_ogva.al,'dd/mm/yyyy');
           end if;
           if  rec_ogva.dal < w_data_decorrenza
           and rec_ogva.al  between w_data_decorrenza and w_data_cessazione then
         DBMS_OUTPUT.PUT_LINE('Caso 2');
               w_str_ogpr := w_str_ogpr||lpad(to_char(rec_ogva.ogpr),10,'0');
               w_str_dal  := w_str_dal ||to_char(rec_ogva.dal,'dd/mm/yyyy');
               w_str_al   := w_str_al  ||to_char(w_data_decorrenza - 1,'dd/mm/yyyy');
           end if;
           if  rec_ogva.dal between w_data_decorrenza and w_data_cessazione
           and rec_ogva.al  > w_data_cessazione then
         DBMS_OUTPUT.PUT_LINE('Caso 3');
               w_str_ogpr := w_str_ogpr||lpad(to_char(rec_ogva.ogpr),10,'0');
               w_str_dal  := w_str_dal ||to_char(w_data_cessazione + 1,'dd/mm/yyyy');
               w_str_al   := w_str_al  ||to_char(rec_ogva.al,'dd/mm/yyyy');
           end if;
           if  rec_ogva.dal < w_data_decorrenza
           and rec_ogva.al  > w_data_cessazione then
         DBMS_OUTPUT.PUT_LINE('Caso 4');
               w_str_ogpr := w_str_ogpr||lpad(to_char(rec_ogva.ogpr),10,'0');
               w_str_dal  := w_str_dal ||to_char(rec_ogva.dal,'dd/mm/yyyy');
               w_str_al   := w_str_al  ||to_char(w_data_decorrenza - 1,'dd/mm/yyyy');
               w_str_ogpr := w_str_ogpr||lpad(to_char(rec_ogva.ogpr),10,'0');
               w_str_dal  := w_str_dal ||to_char(w_data_cessazione + 1,'dd/mm/yyyy');
               w_str_al   := w_str_al  ||to_char(rec_ogva.al,'dd/mm/yyyy');
           end if;
        end if;
        dbms_output.put_line('rec ogva Stringa Ogpr '||w_str_ogpr);
        dbms_output.put_line('Stringa Dal '||w_str_dal);
        dbms_output.put_line('Stringa Al '||w_str_al);
     end loop;
   -- Ora si esaminano le stringhe costruite che sono ordinate per date da e al e
   -- si va ad inserire al posto giusto l`accertamento in esame.
     w_pos := 1;
     loop
      -- Se si e` arrivati a fine stringa significa che non esistono periodi o che
      -- la validita` e` superiore agli altri periodi per cui si accoda l`accertamento.
        if w_pos > nvl(length(w_str_ogpr),0) then
           w_str_ogpr := w_str_ogpr||lpad(to_char(nvl(a_oggetto_pratica,0)),10,'0');
           w_str_dal  := w_str_dal ||to_char(w_data_decorrenza,'dd/mm/yyyy');
           w_str_al   := w_str_al  ||to_char(w_data_cessazione,'dd/mm/yyyy');
           exit;
        end if;
      -- Se la data Dal e` > alla data di cessazione dell`Accertamento, si inserisce
      -- l`accertamento nelle stringhe.
        if to_date(substr(w_str_Dal,w_pos,10),'dd/mm/yyyy') > w_data_cessazione then
           if w_pos = 1 then
              w_str_ogpr := lpad(to_char(nvl(a_oggetto_pratica,0)),10,'0')||w_str_ogpr;
              w_str_dal  := to_char(w_data_decorrenza,'dd/mm/yyyy')||w_str_dal;
              w_str_al   := to_char(w_data_cessazione,'dd/mm/yyyy')||w_str_al;
           else
              w_str_ogpr := substr(w_str_ogpr,1,w_pos - 1)||
                            lpad(to_char(nvl(a_oggetto_pratica,0)),10,'0')||
                            substr(w_str_ogpr,w_pos);
              w_str_dal  := substr(w_str_dal,1,w_pos - 1)||
                            to_char(w_data_decorrenza,'dd/mm/yyyy')||
                            substr(w_str_dal,w_pos);
              w_str_al   := substr(w_str_al,1,w_pos - 1)||
                            to_char(w_data_cessazione,'dd/mm/yyyy')||
                            substr(w_str_al,w_pos);
           end if;
           exit;
        end if;
        w_pos := w_Pos + 10;
     end loop;
  END;
 dbms_output.put_line('Stringa Ogpr '||w_str_ogpr);
 dbms_output.put_line('Stringa Dal '||w_str_dal);
 dbms_output.put_line('Stringa Al '||w_str_al);
-- Analisi degli oggetti pratica memorizzati nelle stringhe
-- e determinazione delle singole imposte che vanno totalizzate
-- nella imposta annuale.
  w_tot_imposta := 0;
  w_tot_importo_pf := 0;
  w_tot_importo_pv := 0;
  w_tot_importo_base := 0;
  w_tot_importo_pf_base := 0;
  w_tot_importo_pv_base := 0;
  w_tot_importo_pf_rid := 0;
  w_tot_importo_pv_rid := 0;
  w_imposta_periodo    := to_number(null);
  w_Pos := 1;
  loop
     if w_pos > nvl(length(w_str_ogpr),0) then
        exit;
     end if;
     w_ogpr := to_number(substr(w_str_ogpr,w_pos,10));
     w_dal  := to_date(substr(w_str_dal,w_Pos,10),'dd/mm/yyyy');
     w_al   := to_date(substr(w_str_al,w_pos,10),'dd/mm/yyyy');
     if w_ogpr = nvl(a_oggetto_pratica,0) then
        w_consistenza        := a_consistenza;
        w_tipo_tariffa       := a_tipo_tariffa;
        w_categoria          := a_categoria;
        w_tributo            := a_tributo;
        w_percentuale        := a_percentuale;
        w_flag_ab_principale := a_flag_ab_principale;
        w_numero_familiari   := a_numero_familiari;
        w_tipo_tariffa_base  := f_get_tariffa_base(w_tributo,w_categoria,a_anno);
     else
        BEGIN
           select ogpr.consistenza
                 ,ogco.perc_possesso
                 ,ogco.flag_ab_principale
                 ,ogpr.tributo
                 ,ogpr.categoria
                 ,ogpr.tipo_tariffa
                 ,ogpr.numero_familiari
                 ,f_get_tariffa_base(ogpr.tributo,ogpr.categoria,a_anno) tipo_tariffa_base
             into w_consistenza
                 ,w_percentuale
                 ,w_flag_ab_principale
                 ,w_tributo
                 ,w_categoria
                 ,w_tipo_tariffa
                 ,w_numero_familiari
                 ,w_tipo_tariffa_base
             from oggetti_contribuente ogco
                 ,oggetti_pratica      ogpr
            where ogpr.oggetto_pratica    = ogco.oggetto_pratica
              and ogco.cod_fiscale        = a_cod_fiscale
              and ogco.oggetto_pratica    = w_ogpr
           ;
        EXCEPTION
           WHEN OTHERS THEN
              RAISE_APPLICATION_ERROR
              (-20999,'Errore in Ricerca Oggetto Pratica '||to_char(w_ogpr));
        END;
     end if;
     BEGIN
       select tari.tariffa
             ,tari.limite
             ,tari.tariffa_superiore
             ,tari.tariffa_quota_fissa
             ,nvl(tari.perc_riduzione,0)
         into w_tariffa
             ,w_limite
             ,w_tari_sup
             ,w_tar_quota_fissa
             ,w_perc_riduzione
         from tariffe tari
        where tari.tipo_tariffa         = w_tipo_tariffa
          and tari.categoria            = w_categoria
          and tari.tributo              = w_tributo
          and tari.anno                 = a_anno
       ;
     EXCEPTION
        WHEN no_data_found THEN
           RAISE_APPLICATION_ERROR
           (-20999,'Manca la tariffa per Tipo Tariffa '||
                   to_char(w_tipo_tariffa)||' Categoria '||to_char(w_categoria)||
                   ' Tributo '||to_char(w_tributo)||' Anno '||to_char(a_anno));
        WHEN others THEN
           RAISE_APPLICATION_ERROR
           (-20999,'Errore in ricerca Tariffe per Tipo Tariffa '||
                   to_char(w_tipo_tariffa)||' Categoria '||to_char(w_categoria)||
                   ' Tributo '||to_char(w_tributo)||' Anno '||to_char(a_anno));
     END;
     if a_flag_normalizzato = 'S' then
--raise_application_error(-20999,
--'a_oggetto_pratica_rif '||a_oggetto_pratica_rif||' ,a_oggetto_pratica '||a_oggetto_pratica||
--' cod f '||a_cod_fiscale||
--' NI '||to_char(a_ni)||
--' anno '||a_anno||
--' w_tributo '||w_tributo||
--' w_categoria '||w_categoria||
--' w_tipo_tariffa '||w_tipo_tariffa||
--' w_tariffa '||w_tariffa||
--' w_tar_quota_fissa '||w_tar_quota_fissa||
--' Consistenza '||to_char(w_consistenza)||
--' % '||to_char(w_percentuale)||
--' Dal '||to_char(w_dal,'dd/mm/yyyy')||
--' Al '||to_char(w_al,'dd/mm/yyyy')||
--' ab prin '||w_flag_ab_principale||
--' w_numero_familiari '||w_numero_familiari);
        calcolo_importo_norm_tariffe(a_cod_fiscale
                                    ,a_ni
                                    ,a_anno
                                    ,w_tributo
                                    ,w_categoria
                                    ,w_tipo_tariffa
                                    ,w_tariffa
                                    ,w_tar_quota_fissa
                                    ,w_consistenza
                                    ,w_percentuale
                                    ,w_dal
                                    ,w_al
                                    ,w_flag_ab_principale
                                    ,w_numero_familiari
                                    ,null  -- ruolo
                                    ,to_number(null)      -- oggetto
                                    ,w_tipo_tariffa_base
                                    ,w_imposta
                                    ,w_importo_pf
                                    ,w_importo_pv
                                    ,w_importo_base
                                    ,w_importo_pf_base
                                    ,w_importo_pv_base
                                    ,w_perc_rid_pf
                                    ,w_perc_rid_pv
                                    ,w_importo_pf_rid
                                    ,w_importo_pv_rid
                                    ,w_stringa_familiari
                                    ,w_dettaglio_ogim
                                    ,w_dettaglio_ogim_base
                                    ,w_giorni_ruolo
                                    );
--raise_application_error(-20999,
--' w_imposta '||w_imposta||
--' w_importo_pf '||w_importo_pf||
--' w_importo_pv '||w_importo_pv);
         if w_ret_familiari = rpad('1',2000, '1') then
            w_ret_familiari := w_stringa_familiari;
         else
            w_ret_familiari := w_ret_familiari||w_stringa_familiari;
         end if;
         if w_ret_dettaglio_ogim = rpad('1',2000, '1') then
            w_ret_dettaglio_ogim := w_dettaglio_ogim;
         else
            w_ret_dettaglio_ogim := w_ret_dettaglio_ogim||w_dettaglio_ogim;
         end if;
         if w_ret_dettaglio_ogim_base = rpad('1',2000, '1') then
            w_ret_dettaglio_ogim_base := w_dettaglio_ogim_base;
         else
            w_ret_dettaglio_ogim_base := w_ret_dettaglio_ogim_base||w_dettaglio_ogim_base;
         end if;
          dbms_output.put_line('NI '||to_char(a_ni)||' Dal '||to_char(w_dal,'dd/mm/yyyy'));
          dbms_output.put_line('Consistenza '||to_char(w_consistenza)||' % '||to_char(w_percentuale));
          dbms_output.put_line('Importo_pf '||to_char(w_importo_pf)||' Importo_pv '||to_char(w_importo_pv));
          dbms_output.put_line('Imposta '||to_char(w_imposta));
     else
        if a_tipo_occupazione = 'T' and w_flag_giorni <> 'S' then
           w_periodo := 1;
        else
           if  w_cod_istat ='037054' then  --san lazzaro sempre normalizzato, cioe sempre a giorni
               w_periodo := f_periodo(a_anno,w_dal,w_al,a_tipo_occupazione,'TARSU','S');
           else
               w_periodo := f_periodo(a_anno,w_dal,w_al,a_tipo_occupazione,'TARSU',a_flag_normalizzato);
           end if;
        end if;
--        dbms_output.put_line('Periodo '||to_char(w_periodo * 12)||' Coeff. '||to_char(w_periodo));
--        dbms_output.put_line('Consistenza '||to_char(w_consistenza)||' % '||to_char(w_percentuale));
--        dbms_output.put_line('Limite '||to_char(w_limite)||' Tariffa '||to_char(w_tariffa));
        w_imposta := 0;
        -- w_periodo := 12;
        -- IF nvl(to_char(w_al,'yyyy'),0) = a_anno THEN
        --    w_periodo := to_char(w_al,'mm');
        -- END IF;
        -- IF nvl(to_char(w_dal,'yyyy'),0) = a_anno THEN
        --    w_periodo := w_periodo - to_char(w_dal,'mm');
        --    w_periodo := w_periodo + 1;
        -- END IF;
        IF (w_consistenza < w_limite) or (w_limite is NULL) THEN
           w_imposta := w_consistenza * w_tariffa;
        ELSE
           w_imposta := w_limite * w_tariffa + (w_consistenza - w_limite) * w_tari_sup;
        END IF;
        w_imposta := w_imposta * (nvl(w_percentuale,100) / 100) * w_periodo;
     end if;
     w_tot_imposta := w_tot_imposta + w_imposta;
     w_tot_importo_pf := w_tot_importo_pf + w_importo_pf;
     w_tot_importo_pv := w_tot_importo_pv + w_importo_pv;
     w_tot_importo_base := w_tot_importo_base + w_importo_base;
     w_tot_importo_pf_base := w_tot_importo_pf_base + w_importo_pf_base;
     w_tot_importo_pv_base := w_tot_importo_pv_base + w_importo_pv_base;
     w_tot_importo_pf_rid := w_tot_importo_pf_rid + w_importo_pf_rid;
     w_tot_importo_pv_rid := w_tot_importo_pv_rid + w_importo_pv_rid;
     --SC 14/11/2014 Aggiungiamo gestione magg tares
     --copiata da Emissione_ruolo
     if w_flag_magg_anno is null then
        w_coeff_gg := F_COEFF_GG(a_anno,w_dal,w_al);
        w_maggiorazione_tares := nvl(w_maggiorazione_tares,0) + round(w_consistenza * w_tariffa_magg_tares * (100 - w_perc_riduzione) / 100 * w_coeff_gg,2);
     else
        --SC 12/12/2014 si calcola la magg tares un'unica volta per tutto l'anno
        -- prendendo i valori della prima denuncia (che sia dichiarata o accertamento)
        if w_maggiorazione_tares is null then
           w_maggiorazione_tares := round(w_consistenza * w_tariffa_magg_tares,2);
        end if;
     end if;
     -- (VD - 04/07/2022): nuovo accertamento tributiweb
     --                    Se l'imposta calcolata è relativa al periodo che si
     --                    sta accertando, si valorizza l'imposta del periodo
     --                    (nuovo campo di OGGETTI_IMPOSTA).
     if w_ogpr = nvl(a_oggetto_pratica,0) then
        w_imposta_periodo := w_imposta;
     end if;
     w_pos := w_pos + 10;
  end loop;
  w_tot_imposta := f_round(w_tot_imposta,1);
  a_imposta := w_tot_imposta;
  --dbms_output.put_line('a_oggetto_pratica_rif '||a_oggetto_pratica_rif);
  --dbms_output.put_line('a_anno '||a_anno);
  BEGIN
     select nvl(ruol.importo_lordo,'N')
       into w_flag_lordo
       from oggetti_imposta       ogim
           ,ruoli                 ruol
      where ruol.ruolo            = ogim.ruolo
        and ogim.oggetto_pratica  = a_oggetto_pratica_rif
        and ogim.anno             = a_anno
        and invio_consorzio is not null
   group by ruol.importo_lordo
     ;
   --dbms_output.put_line('w_flag_lordo '||w_flag_lordo);
  EXCEPTION
     WHEN NO_DATA_FOUND THEN
        w_flag_lordo := null;
     WHEN OTHERS THEN
       RAISE_APPLICATION_ERROR
       (-20999,'Errore in Ruoli. Esistono Ruoli sia Lordi che Netti sull'' oggetto pratica rif '||a_oggetto_pratica_rif||' per l''anno '||a_anno);
  END;
  if w_flag_lordo = 'S' and w_flag_ruolo = 'S' then
     a_add_eca       := round(w_tot_imposta * w_addizionale_eca / 100,2);
     a_magg_eca      := round(w_tot_imposta * w_maggiorazione_eca / 100,2);
     a_add_prov      := round(w_tot_imposta * w_addizionale_pro / 100,2);
     a_iva           := round(w_tot_imposta * w_aliquota / 100,2);
     a_imposta_lorda := a_add_eca    +
                        a_magg_eca   +
                        a_add_prov   +
                        a_iva        +
                        w_tot_imposta;
     if w_importo_base is not null then
        a_add_eca_base  := round(w_tot_importo_base * w_addizionale_eca / 100,2);
        a_magg_eca_base := round(w_tot_importo_base * w_maggiorazione_eca / 100,2);
        a_add_prov_base := round(w_tot_importo_base * w_addizionale_pro / 100,2);
        a_iva_base      := round(w_tot_importo_base * w_aliquota / 100,2);
     else
        a_add_eca_base  := to_number(null);
        a_magg_eca_base := to_number(null);
        a_add_prov_base := to_number(null);
        a_iva_base      := to_number(null);
     end if;
  else
     a_imposta_lorda := w_tot_imposta;
  end if;
  a_flag_lordo      := w_flag_lordo;
  a_magg_tares      := w_maggiorazione_tares;
  if w_ret_dettaglio_ogim = rpad('1',2000, '1') then
    a_dettaglio_ogim  := null;
  else
    a_dettaglio_ogim  := '*'||substr(w_ret_dettaglio_ogim,2) ;
  end if;
  if w_ret_familiari = rpad('1',2000, '1') then
    a_stringa_familiari  := null;
  else
    a_stringa_familiari  := w_ret_familiari ;
  end if;
--
-- (VD - 12/04/2019): valorizzazione in uscita dei parametri
--                    relativi al calcolo con tariffa e con
--                    tariffa base
  a_importo_pf        := w_tot_importo_pf;
  a_importo_pv        := w_tot_importo_pv;
  a_tipo_tariffa_base := w_tipo_tariffa_base;
  a_importo_base      := w_tot_importo_base;
  a_importo_pf_base   := w_tot_importo_pf_base;
  a_importo_pv_base   := w_tot_importo_pv_base;
  a_perc_rid_pf       := w_perc_rid_pf;
  a_perc_rid_pv       := w_perc_rid_pv;
  a_importo_pf_rid    := w_tot_importo_pf_rid;
  a_importo_pv_rid    := w_tot_importo_pv_rid;
  if w_ret_dettaglio_ogim_base = rpad('1',2000, '1') then
     a_dettaglio_ogim_base  := null;
  else
     a_dettaglio_ogim_base  := '*'||substr(w_ret_dettaglio_ogim_base,2) ;
  end if;
--
-- (VD - 04/07/2022): valorizzazione in uscita del parametro
--                    relativo all'imposta del periodo da
--                    accertare
  a_imposta_periodo := w_imposta_periodo;
--EXCEPTION
--  WHEN others THEN
--       RAISE_APPLICATION_ERROR
--    (-20999,'Errore in calcolo Accertamento TARSU '||
--       '('||SQLERRM||')');
END;
/* End Procedure: CALCOLO_ACCERTAMENTO_TARSU */
/

