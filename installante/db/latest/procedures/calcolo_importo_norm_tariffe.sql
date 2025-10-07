--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_importo_norm_tariffe stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_IMPORTO_NORM_TARIFFE
/******************************************************************************
 NOME:        CALCOLO_IMPORTO_NORM_TARIFFE
 DESCRIZIONE: Calcola importo normalizzato con tariffe.
              La presente versione calcola anche l'importo con tariffa base,
              sia in caso di calcolo con tariffe che in caso di calcolo con
              coefficienti.
              Utilizzato per ora solo in emissione ruolo TARSU, in attesa
              di verificare se deve essere utilizzato in tutti i punti
              in cui si esegue il calcolo normalizzato
 NOTE:
 Rev. Data       Autore Descrizione
 ---- ---------- ------ -----------------------------------------------------
  2   22/06/2023 AB     Valorizziamo a 0 questa variabile, perchè altrimenti il campo
                        w_dep_imp_pv_base verrbbe null e invece deve essere pieno per poter
                        riempire i dati in faog spezzando a 170 il dettaglio_ogim_base
  1   11/04/2019 VD     Aggiunta selezione flag per calcolo con tariffe nel
                        caso in cui la procedure venga utilizzata negli
                        accertamenti TARSU.
  0   21/01/2019        Prima emissione
******************************************************************************/
(a_cod_fiscale                varchar2
,a_ni                         number
,a_anno                       number
,a_tributo                    number
,a_categoria                  number
,a_tipo_tariffa               number
,a_tariffa                    number
,a_tariffa_quota_fissa        number
,b_consistenza                number
,a_perc_possesso              number
,a_dal                        date
,a_al                         date
,a_flag_ab_princ              varchar2
,a_numero_familiari           number
,a_ruolo                      number
,a_oggetto                    number   default null
,a_tipo_tariffa_base          number
,a_importo                OUT number
,a_importo_pf             OUT number
,a_importo_pv             OUT number
,a_importo_base           OUT number
,a_importo_pf_base        OUT number
,a_importo_pv_base        OUT number
,a_perc_riduzione_pf      OUT number
,a_perc_riduzione_pv      OUT number
,a_importo_pf_rid         OUT number
,a_importo_pv_rid         OUT number
,a_stringa_familiari      OUT varchar2
,a_dettaglio_ogim         OUT varchar2
,a_dettaglio_ogim_base    OUT varchar2
,a_giorni_ruolo           OUT number -- giorni a ruolo, se calcolo giornaliero
) IS
errore                    exception;
w_errore                  varchar2(2000);
w_fdom                    char;
w_max_fam_coeff           number;
w_fam_coeff               number;
w_tari                    number;
w_coeff1                  number;
w_coeff2                  number;
w_dal                     date;
w_al                      date;
w_periodo                 number;
w_giro                    number;
w_esiste_cosu             varchar2(1);
w_dep_imp                 number;
w_dep_imp_pf              number;
w_dep_imp_pv              number;
w_importo                 number := 0;
w_importo_pf              number := 0;
w_importo_pv              number := 0;
w_numero_familiari        number;
w_numero_familiari_prec   number;
w_stringa_familiari       varchar2(2000);
w_dettaglio_ogim          varchar2(32767);
w_dettaglio_pf            varchar2(2000);
w_dettaglio_pv            varchar2(2000);
w_dettaglio_tot           varchar2(20);
w_ni                      number;
w_numero_familiari_ext    number;
w_mesi_calcolo            number;
w_tipo_tributo            varchar2(5);
w_tipo_ruolo              number;
w_anno_ruolo              number;
w_anno_emissione          number;
w_progr_emissione         number;
w_rate                    number;
w_coeff_acconto_tares     number := 1;
w_cod_istat               varchar2(6);
w_tipo_calcolo            varchar2(1);
w_tipo_emissione          varchar2(1);
w_perc_acconto            number;
w_cod_sede                number(4);
w_gg_anno                 number;
--
-- S.Donato Milanese - Dati per sperimentazione Poasco
--
w_unita_terr              number;
w_suddivisione            number;
w_perc_sconto             number;
w_num_sacchi              number;
w_sconto_conf             number;
w_tot_sconto_conf         number := 0;
w_dettaglio_conf          varchar2(2000);
w_specie_ruolo            number;
--
-- Dati per calcolo ruolo con tariffa base
--
w_flag_tariffa_base       varchar2(1);
w_tariffa_qf_base         number;
w_tariffa_qv_base         number;
--
-- Dati per calcolo ruolo con tariffe
--
w_flag_ruolo_tariffa      varchar2(1);
w_tariffa_quota_fissa     number;
w_tariffa_quota_variabile number;
w_perc_rid_quota_fissa    number;
w_perc_rid_quota_var      number;
w_dep_imp_base            number;
w_dep_imp_pf_base         number;
w_dep_imp_pv_base         number;
w_dep_imp_rid             number;
w_dep_imp_pf_rid          number;
w_dep_imp_pv_rid          number;
w_importo_base            number := 0;
w_importo_pf_base         number := 0;
w_importo_pv_base         number := 0;
w_importo_rid             number := 0;
w_importo_pf_rid          number := 0;
w_importo_pv_rid          number := 0;
w_dettaglio_tot_base      varchar2(20);
w_dettaglio_pf_base       varchar2(2000);
w_dettaglio_pv_base       varchar2(2000);
w_dettaglio_ogim_base     varchar2(32767);
cursor sel_faso is
select decode(a_flag_ab_princ,'S',codo.coeff_adattamento,nvl(codo.coeff_adattamento_no_ap,codo.coeff_adattamento))  coeff_adattamento
      ,decode(a_flag_ab_princ,'S',codo.coeff_produttivita,nvl(codo.coeff_produttivita_no_ap,codo.coeff_produttivita)) coeff_produttivita
      ,to_number(null) tariffa_quota_fissa
      ,to_number(null) tariffa_quota_variabile
      ,greatest(nvl(a_dal,to_date('2222222','j')),faso.dal,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')) dal
      ,least(nvl(a_al,to_date('3333333','j')),nvl(faso.al,to_date('3333333','j'))
            ,to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')) al
            ,faso.numero_familiari numero_familiari
  from coefficienti_domestici codo
      ,familiari_soggetto     faso
 where codo.anno                  = a_anno
   and (    codo.numero_familiari = faso.numero_familiari
        or  codo.numero_familiari = w_max_fam_coeff
        and not exists
           (select 1
              from coefficienti_domestici cod3
             where cod3.anno      = a_anno
               and cod3.numero_familiari
                                  = faso.numero_familiari
           )
       )
   and faso.dal                  <= nvl(a_al,to_date('3333333','j'))
   and nvl(faso.al,to_date('3333333','j'))
                                 >= nvl(a_dal,to_date('2222222','j'))
   and faso.anno                  = a_anno
-- Riga aggiunta per non considerare dei periodi dell'anno precedente
   and nvl(to_char(faso.al,'yyyy'),9999)
                                 >= a_anno
   and faso.ni                    = w_ni
   and w_flag_ruolo_tariffa       = 'N'
 union
select to_number(null) coeff_adattamento
      ,to_number(null) coeff_produttivita
      ,decode(a_flag_ab_princ,'S',tado.tariffa_quota_fissa,nvl(tado.tariffa_quota_fissa_no_ap,tado.tariffa_quota_fissa)) tariffa_quota_fissa
      ,decode(a_flag_ab_princ,'S',tado.tariffa_quota_variabile,nvl(tado.tariffa_quota_variabile_no_ap,tado.tariffa_quota_variabile)) tariffa_quota_variabile
      ,greatest(nvl(a_dal,to_date('2222222','j')),faso.dal,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')) dal
      ,least(nvl(a_al,to_date('3333333','j')),nvl(faso.al,to_date('3333333','j'))
            ,to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')) al
            ,faso.numero_familiari numero_familiari
  from tariffe_domestiche     tado
      ,familiari_soggetto     faso
 where tado.anno                  = a_anno
   and (    tado.numero_familiari = faso.numero_familiari
        or  tado.numero_familiari = w_max_fam_coeff
        and not exists
           (select 1
              from tariffe_domestiche tad3
             where tad3.anno      = a_anno
               and tad3.numero_familiari
                                  = faso.numero_familiari
           )
       )
   and faso.dal                  <= nvl(a_al,to_date('3333333','j'))
   and nvl(faso.al,to_date('3333333','j'))
                                 >= nvl(a_dal,to_date('2222222','j'))
   and faso.anno                  = a_anno
-- Riga aggiunta per non considerare dei periodi dell'anno precedente
   and nvl(to_char(faso.al,'yyyy'),9999)
                                 >= a_anno
   and faso.ni                    = w_ni
   and w_flag_ruolo_tariffa       = 'S'
order by 3
;
BEGIN
   --dbms_output.put_line('norm a_dal '||a_dal);
   --dbms_output.put_line('norm a_al '||a_al);
   BEGIN
      select lpad(to_char(d.pro_cliente),3,'0')||
             lpad(to_char(d.com_cliente),3,'0'),
             decode(to_char(last_day(to_date('02'||a_anno,'mmyyyy')),'dd'), 28, 365, nvl(f_inpa_valore('GG_ANNO_BI'),366))
        into w_cod_istat,
             w_gg_anno
        from dati_generali           d
      ;
   EXCEPTION
      WHEN no_data_found THEN
         w_errore := 'Dati Generali non inseriti';
         RAISE errore;
      WHEN others THEN
         w_errore := 'Dati Generali';
         RAISE errore;
   END;
   if a_ruolo is not null then
      BEGIN
         select r.tipo_tributo
               ,r.tipo_ruolo
               ,r.anno_ruolo
               ,r.anno_emissione
               ,r.progr_emissione
               ,decode(r.rate,null,1,0,1,r.rate)
               ,r.tipo_emissione
               ,r.tipo_calcolo
               ,r.cod_sede
               ,r.perc_acconto
               ,r.specie_ruolo
               ,nvl(r.flag_calcolo_tariffa_base,'N')
               ,NVL(r.flag_tariffe_ruolo,'N')
           into w_tipo_tributo
               ,w_tipo_ruolo
               ,w_anno_ruolo
               ,w_anno_emissione
               ,w_progr_emissione
               ,w_rate
               ,w_tipo_emissione
               ,w_tipo_calcolo
               ,w_cod_sede
               ,w_perc_acconto
               ,w_specie_ruolo
               ,w_flag_tariffa_base
               ,w_flag_ruolo_tariffa
           from ruoli       r
          where r.ruolo   = a_ruolo
         ;
      EXCEPTION
         WHEN no_data_found THEN
            w_errore := 'Ruolo non presente in tabella';
            RAISE errore;
         WHEN others THEN
            w_errore := 'Errore in ricerca Ruoli';
            RAISE errore;
      END;
      if (   (w_tipo_ruolo = 1 and w_anno_ruolo = 2013  and w_progr_emissione = 1 and w_tipo_tributo = 'TARSU')
          or
             (w_tipo_ruolo = 1 and nvl(w_tipo_emissione,'T') = 'A'  and w_tipo_tributo = 'TARSU')
         )
         and w_cod_istat <> '017025' -- Bovezzo
               then
          if nvl(w_tipo_calcolo,'T') = 'T'  or (w_specie_ruolo = 0 and nvl(w_perc_acconto, w_cod_sede) is not null) then   -- gestiamo la percentuale di acconto per i ruoli standard non coattivi AB 27/04/2017 (Pontedera)
          --if nvl(w_tipo_calcolo,'T') = 'T' then
             if w_perc_acconto is not null then
                w_coeff_acconto_tares :=  w_perc_acconto / 100;
             else
                w_coeff_acconto_tares := (w_cod_sede / 100) / 100;  -- consideriamo di inserire nel cod_sede i valori interi comprensivi dei due decimali
             end if;
          else
             w_coeff_acconto_tares := w_rate / (w_rate + 1);
          end if;
      else
          w_coeff_acconto_tares := 1;
      end if;
   --(VD - 11/04/2019): se non si tratta di ruolo (quindi si tratta di accertamento)
   --                   si seleziona l'eventuale flag tariffe da carichi_tarsu
   else
      begin
        select nvl(flag_tariffe_ruolo,'N')
             , 'S'
          into w_flag_ruolo_tariffa
             , w_flag_tariffa_base
          from carichi_tarsu
         where anno = a_anno;
      exception
        when others then
            w_errore := 'Errore in ricerca Carichi_tarsu';
            RAISE errore;
      END;
   end if;
   if w_tipo_tributo <> 'TARSU' then
      w_mesi_calcolo := 2;
   else
      begin
         select nvl(mesi_calcolo,2)
           into w_mesi_calcolo
           from carichi_tarsu
          where anno = a_anno
         ;
      exception
         when no_data_found then
            w_mesi_calcolo := 2;
      end;
   end if;
   BEGIN
      select flag_domestica
        into w_fdom
        from categorie
       where tributo   = a_tributo
         and categoria = a_categoria
      ;
   EXCEPTION
      WHEN others THEN
         w_errore := 'Errore in ricerca Categorie per calcolo Normalizzato';
         raise errore;
   END;
   -- Calcoliamo come prima cosa il periodo totale da far ritornare alla procedure
   if w_mesi_calcolo = 0 then
      a_giorni_ruolo := least(nvl(a_al,to_date('3333333','j')),to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy'))
                        - greatest(nvl(a_dal,to_date('2222222','j')),to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy'))
                        + 1;
   else
      a_giorni_ruolo := null;
   end if;
   --dbms_output.put_line('a_giorni_ruolo '||a_giorni_ruolo);
   --
   -- Variazione effettuata il 22/06/2005 da Davide in seguito alla introduzione
   -- della tabella dei componenti per superficie che si applica solamente ai casi
   -- di abitazione NON principale in luogo della familiari soggetto.
   -- Qualora pero` per l`anno non fossero indicate registrazioni, si deduce che
   -- per quell`esercizio si e` deciso di non applicare i componenti per superficie
   -- e quindi si procede sempre mediante i familiari soggetto.
   -- Per le abitazioni principali quindi si opera come se non ci fossero i componenti
   -- per superficie, mentre per le non principali si effettua il controllo della
   -- esistenza delle registrazioni per l`anno in esame.
   --
   if a_flag_ab_princ = 'S' then
      w_esiste_cosu  := 'N';
   else
      BEGIN
         select decode(count(*),0,'N','S')
           into w_esiste_cosu
           from componenti_superficie
          where anno = a_anno
         ;
      END;
   end if;
--
-- Se e` indicata una tariffa a quota fissa nei parametri di input, questa
-- viene applicata in luogo della tariffa domestica o non domestica.
-- (VD - 04/01/2019): lo step seguente viene eseguito solo per i ruoli
--                    calcolati con coefficienti
--
   if w_flag_ruolo_tariffa = 'N' then
      --dbms_output.put_line('Ruolo a coeff. - Tariffa qf: '||a_tariffa_quota_fissa);
      if a_tariffa_quota_fissa is not null then
         w_tari := a_tariffa_quota_fissa;
         w_tariffa_qf_base := a_tariffa_quota_fissa;
      else
         BEGIN
            select decode(w_fdom
                               , 'S', tariffa_domestica
                               , tariffa_non_domestica)
                 , decode(w_fdom
                               , 'S', tariffa_domestica
                               , tariffa_non_domestica)
              into w_tari
                 , w_tariffa_qf_base
              from carichi_tarsu
             where anno = a_anno
            ;
         EXCEPTION
            WHEN others THEN
               w_errore := 'Errore in ricerca Carichi TARSU per calcolo Normalizzato';
               raise errore;
         END;
         IF w_tari is null THEN
            w_errore := 'Manca la tariffa domestica (o non domestica) in CARICHI TARSU per l''anno '||a_anno;
            raise errore;
         END IF;
      end if;
   end if;
   --
   -- (VD - 04/01/2019): se il ruolo viene calcolato a tariffa, si selezionano
   --                    le eventuali riduzioni dalla tabella TARIFFE
   --
   begin
     select nvl(riduzione_quota_fissa,0)
          , nvl(riduzione_quota_variabile,0)
       into w_perc_rid_quota_fissa
          , w_perc_rid_quota_var
       from TARIFFE
      where tributo      = a_tributo
        and anno         = a_anno
        and categoria    = a_categoria
        and tipo_tariffa = a_tipo_tariffa
        and w_flag_ruolo_tariffa = 'S';
   exception
     when others then
       w_perc_rid_quota_fissa := 0;
       w_perc_rid_quota_var   := 0;
   end;
   --
   -- Se il ruolo viene calcolato a coefficiente ed e' richiesto anche il
   -- calcolo con tariffa base, si selezionano i dati della tariffa base
   --
   w_tariffa_qv_base:= 0;  --AB (22/06/2023) Valorizziamo a 0 questa variabile, perchè altrimenti il campo
                           -- w_dep_imp_pv_base verrbbe null e invece deve essere pieno per poter
                           -- riempire i dati in faog spezzando a 170 il dettaglio_ogim_base

   if w_flag_tariffa_base = 'S' and
      a_tipo_tariffa_base is not null then
      begin
        select tari.tariffa
          into w_tariffa_qv_base
          from tariffe tari
         where tari.tributo = a_tributo
           and tari.categoria = a_categoria
           and tari.anno = a_anno
           and tari.tipo_tariffa = a_tipo_tariffa_base
           and w_flag_tariffa_base = 'S'
           and a_tipo_tariffa_base is not null;
      exception
        WHEN no_data_found THEN
             w_errore := 'Tariffa base '||a_tipo_tariffa_base||' non presente in tabella';
             RAISE errore;
        WHEN others THEN
             w_errore := 'Errore in ricerca tariffa base ('||a_tipo_tariffa_base||')';
             RAISE errore;
      end;
   end if;
   IF w_fdom = 'S' THEN
      --
      -- (VD - 18/11/2016) - Sperimentazione Poasco
      --                     Si memorizzano i dati della zona da trattare
      --                     da tabella parametri
      --
      if a_oggetto is not null and
         w_tipo_ruolo = 2 and
         w_tipo_emissione = 'T' and
         w_tipo_calcolo = 'N' and
        (w_cod_istat = '015192' or      -- San Donato Milanese
         w_cod_istat = '037006') then   -- Bologna per prove ADS
         begin
           select to_number(rtrim(substr(valore,1,instr(valore,' ')-1))),
                  to_number(rtrim(substr(valore,instr(valore,' ')+1)))
             into w_unita_terr,
                  w_suddivisione
             from installazione_parametri
            where parametro = 'GSD_UTST';
         exception
           when others then
             w_unita_terr := to_number(null);
             w_suddivisione := to_number(null);
         end;
      else
         w_unita_terr := to_number(null);
         w_suddivisione := to_number(null);
      end if;
      --
      IF w_esiste_cosu = 'N' then
      --
      -- Se non esistono componenti per superficie nell`anno si opera
      -- attraverso i familiari soggetto.
      --
         BEGIN
            select max(numero_familiari)
              into w_max_fam_coeff
              from coefficienti_domestici
             where anno   = a_anno
            ;
         EXCEPTION
            WHEN others THEN
               w_errore := 'Errore in ricerca Coefficenti Domestici per calcolo Normalizzato';
               raise errore;
         END;
         w_giro              := 0;
         w_stringa_familiari := '';
         w_numero_familiari  := -9999;
         w_al                := to_date('01011900','ddmmyyyy');
         -- Piero 17/08/2007
         -- Ho modificato il cursore sel_faso passandogli direttamente il NI,
         -- questo per permettere il calcolo normalizzato anche in caso di
         -- Soggetto non Contribuente (a_ni  è il NI del soggetto)
         BEGIN
            select ni
              into w_ni
              from contribuenti
             where cod_fiscale   = a_cod_fiscale
            ;
         EXCEPTION
            WHEN others THEN
               w_ni := a_ni;
         END;
--DBMS_OUTPUT.PUT_LINE('w_ni '||w_ni);
--DBMS_OUTPUT.PUT_LINE('a_anno '||a_anno);
--DBMS_OUTPUT.PUT_LINE('w_max_fam_coeff '||w_max_fam_coeff);
--DBMS_OUTPUT.PUT_LINE('a_dal '||a_dal);
--DBMS_OUTPUT.PUT_LINE('a_al '||a_al);
--DBMS_OUTPUT.PUT_LINE('a_flag_ab_princ '||a_flag_ab_princ);
         FOR rec_faso IN sel_faso
         LOOP
               w_giro    := w_giro + 1;
            if w_giro = 1 then
               w_dal := rec_faso.dal;
               w_al  := rec_faso.al;
            else
               if w_numero_familiari = rec_faso.numero_familiari
                         and w_al + 1 = rec_faso.dal then
                  w_al      := rec_faso.al;
               else
                  -- (VD - 03/01/2019): calcolo importi con tariffa
                  if w_flag_ruolo_tariffa = 'S' then
                     w_dep_imp_pf_base := (w_tariffa_quota_fissa * b_consistenza)
                                         * w_periodo * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
                     w_dep_imp_pf_rid := w_dep_imp_pf_base * w_perc_rid_quota_fissa / 100;
                     w_dep_imp_pf := w_dep_imp_pf_base - w_dep_imp_pf_rid;
                     w_dep_imp_pf := round(w_dep_imp_pf,2);
                     w_dep_imp_pv_base := w_tariffa_quota_variabile * w_periodo
                                        * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
                     w_dep_imp_pv_rid := w_dep_imp_pv_base * w_perc_rid_quota_var / 100;
                     w_dep_imp_pv := w_dep_imp_pv_base - w_dep_imp_pv_rid;
                     w_dep_imp_pv := round(w_dep_imp_pv,2);
                     -- (VD - 04/01/2019): composizione strighe dettaglio parte
                     --                    fissa e parte variabile
                     w_dettaglio_pf := ' Tariffa'||lpad(nvl(translate(ltrim(to_char(w_tariffa_quota_fissa,'999,990.00000')),'.,',',.'),' '),13,' ')
                                    || ' Rid.'||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pf_rid,'999,999,990.00')),'.,',',.'),' '),14,' ')
                                    || ' Imposta QF' ||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pf,'999,999,990.00')),'.,',',.'),' '),14,' ');
                     w_dettaglio_pv := ' Tariffa'||lpad(nvl(translate(ltrim(to_char(w_tariffa_quota_variabile,'999,990.00000')),'.,',',.'),' '),13,' ')
                                    || ' Rid.'||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pv_rid,'999,999,990.00')),'.,',',.'),' '),14,' ')
                                    || ' Imposta QV' ||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pv,'999,999,990.00')),'.,',',.'),' '),14,' ');
                     w_dettaglio_pf_base := lpad(' Imposta Base QF' ||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pf_base,'999,999,990.00')),'.,',',.'),' '),14,' '),75);
                     w_dettaglio_pv_base := lpad(' Imposta Base QV' ||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pv_base,'999,999,990.00')),'.,',',.'),' '),14,' '),75);
                  else
                     w_dep_imp_pf := (w_tari * b_consistenza * w_coeff1)
                                  * w_periodo * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
                     w_dep_imp_pf := round(w_dep_imp_pf,2);
                     w_dep_imp_pv := (a_tariffa * w_coeff2)
                                  * w_periodo * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
                     w_dep_imp_pv := round(w_dep_imp_pv,2);
                     w_dettaglio_pf := ' Coeff. '||lpad(nvl(translate(ltrim(to_char(w_coeff1,'90.0000')),'.,',',.'),' '),7,' ')
                                    ||' Tariffa ' ||lpad(nvl(translate(ltrim(to_char(w_tari,'999,990.00000')),'.,',',.'),' '),13,' ')
                                    ||' Imposta QF' ||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pf,'99,999,999,990.00')),'.,',',.'),' '),17,' ');
                     w_dettaglio_pv := ' Coeff. '||lpad(nvl(translate(ltrim(to_char(w_coeff2,'90.0000')),'.,',',.'),' '),7,' ')
                                    ||' Tariffa ' ||lpad(nvl(translate(ltrim(to_char(a_tariffa,'999,990.00000')),'.,',',.'),' '),13,' ')
                                    ||' Imposta QV' ||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pv,'99,999,999,990.00')),'.,',',.'),' '),17,' ');
                     if w_flag_tariffa_base = 'S' then
                        w_dep_imp_pf_base := (w_tariffa_qf_base * b_consistenza * w_coeff1)
                                     * w_periodo * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
                        w_dep_imp_pf_base := round(w_dep_imp_pf_base,2);
                        w_dep_imp_pf_rid  := w_dep_imp_pf_base - w_dep_imp_pf;
                        w_dep_imp_pv_base := (w_tariffa_qv_base * w_coeff2)
                                     * w_periodo * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
                        w_dep_imp_pv_base := round(w_dep_imp_pv_base,2);
                        w_dep_imp_pv_rid  := w_dep_imp_pv_base - w_dep_imp_pv;
                        w_dettaglio_pf_base := ' Tariffa Base' ||lpad(nvl(translate(ltrim(to_char(w_tariffa_qf_base,'999,990.00000')),'.,',',.'),' '),13,' ')
                                            || ' Rid.'||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pf_rid,'999,999,990.00')),'.,',',.'),' '),14,' ')
                                            || ' Imposta Base QF' ||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pf_base,'999,999,990.00')),'.,',',.'),' '),14,' ');
                        w_dettaglio_pv_base := ' Tariffa Base' ||lpad(nvl(translate(ltrim(to_char(w_tariffa_qv_base,'999,990.00000')),'.,',',.'),' '),13,' ')
                                            || ' Rid.'||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pv_rid,'999,999,990.00')),'.,',',.'),' '),14,' ')
                                            || ' Imposta Base QV' ||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pv_base,'999,999,990.00')),'.,',',.'),' '),14,' ');
                     else
                        w_dep_imp_pf_base := to_number(null);
                        w_dep_imp_pv_base := to_number(null);
                        w_dep_imp_pf_rid  := to_number(null);
                        w_dep_imp_pv_rid  := to_number(null);
                        w_dettaglio_pf_base  := to_char(null);
                        w_dettaglio_pv_base  := to_char(null);
                        w_dettaglio_tot_base := to_char(null);
                     end if;
                  end if;
                  --
                  -- (VD - 18/11/2016) - Sperimentazione Poasco
                  --                     Si verifica se l'utenza ha diritto agli sconti
                  --                     relativi ai sacchi conferiti.
                  --                     Se la percentuale di sconto non e nulla, si
                  --                     applica alla quota variabile
                  --
                  w_dettaglio_conf := '';
                  if w_unita_terr   is not null and
                     w_suddivisione is not null then
                     DETERMINA_SCONTO_CONF(w_unita_terr
                                          ,w_suddivisione
                                          ,a_cod_fiscale
                                          ,a_oggetto
                                          ,w_anno_ruolo
                                          ,a_tributo
                                          ,a_categoria
                                          ,w_numero_familiari
                                          ,w_perc_sconto
                                          ,w_num_sacchi
                                          );
                     if w_perc_sconto is not null then
                        w_sconto_conf := round(w_dep_imp_pv * w_perc_sconto / 100,2);
                        w_tot_sconto_conf := w_tot_sconto_conf + w_sconto_conf;
                        w_dep_imp_pv := w_dep_imp_pv - w_sconto_conf;
                        w_dep_imp_pv_base := w_dep_imp_pv_base - w_sconto_conf;
                        w_dettaglio_conf := ' Sacchi Conferiti '||lpad(ltrim(to_char(w_num_sacchi,'9990')),4)
                                         || ' Perc. sconto '||lpad(nvl(translate(ltrim(to_char(w_perc_sconto,'990.00')),'.,',',.'),' '),6,' ')
                                         || ' Sconto:'||lpad(nvl(translate(ltrim(to_char(w_sconto_conf,'99,999,990.00')),'.,',',.'),' '),13,' ');
                     end if;
                  end if;
                  --
                  w_dep_imp := w_dep_imp_pf + w_dep_imp_pv;
                  w_importo := w_importo + w_dep_imp;
                  w_importo_pf := w_importo_pf + w_dep_imp_pf;
                  w_importo_pv := w_importo_pv + w_dep_imp_pv;
                  w_dettaglio_tot := lpad(nvl(translate(ltrim(to_char(w_dep_imp,'9,999,999,999,990.00')),'.,',',.'),' '),20,' ');
                  w_dettaglio_ogim := w_dettaglio_ogim||w_dettaglio_pf||w_dettaglio_pv||w_dettaglio_tot;
                  w_stringa_familiari := w_stringa_familiari || lpad(to_char(nvl(w_numero_familiari,0)),4,'0') || to_char(w_dal,'ddmmyyyy')|| to_char(w_al,'ddmmyyyy');
--DBMS_OUTPUT.PUT_LINE(' 1 w_stringa_familiari '||w_stringa_familiari);
                  if w_flag_ruolo_tariffa = 'S' or
                     w_flag_tariffa_base  = 'S' then
                     w_dep_imp_rid := w_dep_imp_pf_rid + w_dep_imp_pv_rid;
                     w_importo_rid := w_importo_rid + w_dep_imp_rid;
                     w_importo_pf_rid := w_importo_pf_rid + w_dep_imp_pf_rid;
                     w_importo_pv_rid := w_importo_pv_rid + w_dep_imp_pv_rid;
                     w_dep_imp_base := w_dep_imp_pf_base + w_dep_imp_pv_base;
                     w_importo_base := w_importo_base + w_dep_imp_base;
                     w_importo_pf_base := w_importo_pf_base + w_dep_imp_pf_base;
                     w_importo_pv_base := w_importo_pv_base + w_dep_imp_pv_base;
                     w_dettaglio_tot_base := lpad(nvl(translate(ltrim(to_char(w_dep_imp_base,'9,999,999,999,990.00')),'.,',',.'),' '),20,' ');
                     w_dettaglio_ogim_base := w_dettaglio_ogim_base||w_dettaglio_pf_base||w_dettaglio_pv_base||w_dettaglio_tot_base;
                  end if;
                  if a_oggetto is not null then
                     w_dettaglio_ogim := w_dettaglio_ogim||rpad(nvl(w_dettaglio_conf,' '),63);
                  end if;
--dbms_output.put_line('('||to_char(w_giro)||') tariffa1 '||to_char(w_tari)||' consistenza '||to_char(b_consistenza)||
--' coeff1 '||to_char(w_coeff1)||' tariffa2 '||to_char(a_tariffa)||' coeff2 '||to_char(w_coeff2)||
--' periodo '||to_char(w_periodo)||' perc_possesso '||to_char(a_perc_possesso)||' importo '||to_char(w_dep_imp)||
--' imp.tot '||to_char(w_importo));
                  w_dal     := rec_faso.dal;
                  w_al      := rec_faso.al;
               end if;
            end if; -- w_giro = 1
            w_numero_familiari := rec_faso.numero_familiari;
            w_coeff1  := rec_faso.coeff_adattamento;
            w_coeff2  := rec_faso.coeff_produttivita;
            w_tariffa_quota_fissa     := rec_faso.tariffa_quota_fissa;
            w_tariffa_quota_variabile := rec_faso.tariffa_quota_variabile;
            if w_mesi_calcolo = 0 then -- calcolo giornaliero
               w_periodo := (w_al + 1 - w_dal) / w_gg_anno;
            else -- calcolo mensile o bimestrale
               w_periodo := round(months_between(w_al + 1,w_dal)) / 12;  -- La round al posto della ceil
            end if;
            if w_periodo < 0 then    -- metto a zero i periodi negativi
               w_periodo := 0;
            end if;
--dbms_output.put_line('(1) '||w_dettaglio_ogim_base);
         END LOOP;
         -- (VD - 03/01/2019): calcolo importi con tariffa (a fine ciclo si
         --                    trattano gli ultimi dati memorizzati)
         if w_flag_ruolo_tariffa = 'S' then
            w_dep_imp_pf_base := (w_tariffa_quota_fissa * b_consistenza)
                                * w_periodo * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
            w_dep_imp_pf_rid := w_dep_imp_pf_base * w_perc_rid_quota_fissa / 100;
            w_dep_imp_pf := w_dep_imp_pf_base - w_dep_imp_pf_rid;
            w_dep_imp_pf := round(w_dep_imp_pf,2);
            w_dep_imp_pv_base := w_tariffa_quota_variabile * w_periodo
                               * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
            w_dep_imp_pv_rid := w_dep_imp_pv_base * w_perc_rid_quota_var / 100;
            w_dep_imp_pv := w_dep_imp_pv_base - w_dep_imp_pv_rid;
            w_dep_imp_pv := round(w_dep_imp_pv,2);
            -- (VD - 04/01/2019): composizione strighe dettaglio parte
            --                    fissa e parte variabile
            w_dettaglio_pf := ' Tariffa' ||lpad(nvl(translate(ltrim(to_char(w_tariffa_quota_fissa,'999,990.00000')),'.,',',.'),' '),13,' ')
                           || ' Rid.'||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pf_rid,'999,999,990.00')),'.,',',.'),' '),14,' ')
                           || ' Imposta QF' ||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pf,'999,999,990.00')),'.,',',.'),' '),14,' ');
            w_dettaglio_pv := ' Tariffa' ||lpad(nvl(translate(ltrim(to_char(w_tariffa_quota_variabile,'999,990.00000')),'.,',',.'),' '),13,' ')
                           || ' Rid.'||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pv_rid,'999,999,990.00')),'.,',',.'),' '),14,' ')
                           || ' Imposta QV' ||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pv,'999,999,990.00')),'.,',',.'),' '),14,' ');
            w_dettaglio_pf_base := lpad(' Imposta Base QF' ||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pf_base,'999,999,990.00')),'.,',',.'),' '),14,' '),75);
            w_dettaglio_pv_base := lpad(' Imposta Base QV' ||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pv_base,'999,999,990.00')),'.,',',.'),' '),14,' '),75);
         else
            w_dep_imp_pf := (w_tari * b_consistenza * w_coeff1)
                         * w_periodo * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
            w_dep_imp_pf := round(w_dep_imp_pf,2);
            w_dep_imp_pv := (a_tariffa * w_coeff2)
                         * w_periodo * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
            w_dep_imp_pv := round(w_dep_imp_pv,2);
            w_dettaglio_pf := ' Coeff. '||lpad(nvl(translate(ltrim(to_char(w_coeff1,'90.0000')),'.,',',.'),' '),7,' ')
                           || ' Tariffa ' ||lpad(nvl(translate(ltrim(to_char(w_tari,'999,990.00000')),'.,',',.'),' '),13,' ')
                           || ' Imposta QF' ||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pf,'99,999,999,990.00')),'.,',',.'),' '),17,' ');
            w_dettaglio_pv := ' Coeff. '||lpad(nvl(translate(ltrim(to_char(w_coeff2,'90.0000')),'.,',',.'),' '),7,' ')
                           || ' Tariffa ' ||lpad(nvl(translate(ltrim(to_char(a_tariffa,'999,990.00000')),'.,',',.'),' '),13,' ')
                           || ' Imposta QV' ||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pv,'99,999,999,990.00')),'.,',',.'),' '),17,' ');
            if w_flag_tariffa_base = 'S' then
               w_dep_imp_pf_base := (w_tariffa_qf_base * b_consistenza * w_coeff1)
                            * w_periodo * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
               w_dep_imp_pf_base := round(w_dep_imp_pf_base,2);
               w_dep_imp_pf_rid  := w_dep_imp_pf_base - w_dep_imp_pf;
               w_dep_imp_pv_base := (w_tariffa_qv_base * w_coeff2)
                            * w_periodo * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
               w_dep_imp_pv_base := round(w_dep_imp_pv_base,2);
               w_dep_imp_pv_rid  := w_dep_imp_pv_base - w_dep_imp_pv;
               w_dettaglio_pf_base := ' Tariffa Base' ||lpad(nvl(translate(ltrim(to_char(w_tariffa_qf_base,'999,990.00000')),'.,',',.'),' '),13,' ')
                                   || ' Rid.'||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pf_rid,'999,999,990.00')),'.,',',.'),' '),14,' ')
                                   || ' Imposta Base QF' ||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pf_base,'999,999,990.00')),'.,',',.'),' '),14,' ');
               w_dettaglio_pv_base := ' Tariffa Base' ||lpad(nvl(translate(ltrim(to_char(w_tariffa_qv_base,'999,990.00000')),'.,',',.'),' '),13,' ')
                                   || ' Rid.'||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pv_rid,'999,999,990.00')),'.,',',.'),' '),14,' ')
                                   || ' Imposta Base QV' ||lpad(nvl(translate(ltrim(to_char(w_dep_imp_pv_base,'999,999,990.00')),'.,',',.'),' '),14,' ');
            else
               w_dep_imp_pf_base := to_number(null);
               w_dep_imp_pv_base := to_number(null);
               w_dep_imp_pf_rid  := to_number(null);
               w_dep_imp_pv_rid  := to_number(null);
               w_dettaglio_pf_base  := to_char(null);
               w_dettaglio_pv_base  := to_char(null);
               w_dettaglio_tot_base := to_char(null);
            end if;
         end if;
         --
         -- (VD - 18/11/2016) - Sperimentazione Poasco
         --                     Si verifica se l'utenza ha diritto agli sconti
         --                     relativi ai sacchi conferiti.
         --                     Se la percentuale di sconto non e nulla, si
         --                     applica alla quota variabile
         --
         w_dettaglio_conf := '';
         if w_unita_terr   is not null and
            w_suddivisione is not null then
            DETERMINA_SCONTO_CONF(w_unita_terr
                                 ,w_suddivisione
                                 ,a_cod_fiscale
                                 ,a_oggetto
                                 ,w_anno_ruolo
                                 ,a_tributo
                                 ,a_categoria
                                 ,w_numero_familiari
                                 ,w_perc_sconto
                                 ,w_num_sacchi
                                 );
            if w_perc_sconto is not null then
               w_sconto_conf := round(w_dep_imp_pv * w_perc_sconto / 100,2);
               w_tot_sconto_conf := w_tot_sconto_conf + w_sconto_conf;
               w_dep_imp_pv      := w_dep_imp_pv - w_sconto_conf;
               w_dep_imp_pv_base := w_dep_imp_pv_base - w_sconto_conf;
               w_dettaglio_conf := ' Sacchi Conferiti '||lpad(ltrim(to_char(w_num_sacchi,'9990')),4)
                                || ' Perc. sconto '||lpad(nvl(translate(ltrim(to_char(w_perc_sconto,'990.00')),'.,',',.'),' '),6,' ')
                                || ' Sconto:'||lpad(nvl(translate(ltrim(to_char(w_sconto_conf,'99,999,990.00')),'.,',',.'),' '),13,' ');
            end if;
         end if;
         --
         w_dep_imp := w_dep_imp_pf + w_dep_imp_pv;
         w_importo := w_importo + w_dep_imp;
         w_importo_pf := w_importo_pf + w_dep_imp_pf;
         w_importo_pv := w_importo_pv + w_dep_imp_pv;
         w_dettaglio_tot := lpad(nvl(translate(ltrim(to_char(w_dep_imp,'9,999,999,999,990.00')),'.,',',.'),' '),20,' ');
         w_dettaglio_ogim := w_dettaglio_ogim||w_dettaglio_pf||w_dettaglio_pv||w_dettaglio_tot;
         w_stringa_familiari := w_stringa_familiari || lpad(to_char(nvl(w_numero_familiari,0)),4,'0') || to_char(w_dal,'ddmmyyyy')|| to_char(w_al,'ddmmyyyy');
         if w_flag_ruolo_tariffa = 'S' or
            w_flag_tariffa_base = 'S' then
            w_dep_imp_base := w_dep_imp_pf_base + w_dep_imp_pv_base;
            w_importo_base := w_importo_base + w_dep_imp_base;
            w_importo_pf_base := w_importo_pf_base + w_dep_imp_pf_base;
            w_importo_pv_base := w_importo_pv_base + w_dep_imp_pv_base;
            w_dep_imp_rid := w_dep_imp_pf_rid + w_dep_imp_pv_rid;
            w_importo_rid := w_importo_rid + w_dep_imp_rid;
            w_importo_pf_rid := w_importo_pf_rid + w_dep_imp_pf_rid;
            w_importo_pv_rid := w_importo_pv_rid + w_dep_imp_pv_rid;
            w_dettaglio_tot_base := lpad(nvl(translate(ltrim(to_char(w_dep_imp_base,'9,999,999,999,990.00')),'.,',',.'),' '),20,' ');
            w_dettaglio_ogim_base := w_dettaglio_ogim_base||w_dettaglio_pf_base||w_dettaglio_pv_base||w_dettaglio_tot_base;
         end if;
         if a_oggetto is not null then
            w_dettaglio_ogim := w_dettaglio_ogim||rpad(nvl(w_dettaglio_conf,' '),63);
         end if;
--dbms_output.put_line('(2) '||w_dettaglio_ogim_base);
      ELSE
         --
         -- Caso di presenza di componenti per superficie.
         -- Analogamente a quanto fatto per i familiari soggetto, se non esiste una registrazione
         -- per componenti superficie relativa alla consistenza dell`oggetto in esame, si fa
         -- riferimento al numero massimo dei familiari previsto per l`anno.
         --
         BEGIN
            select max(cosu.numero_familiari)
              into w_max_fam_coeff
              from componenti_superficie cosu
             where cosu.anno   = a_anno
             group by 1
            ;
         -- dbms_output.put_line('Trovato Massimo '||to_char(w_max_fam_coeff));
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
         -- dbms_output.put_line('Non Trovato Nulla');
               w_max_fam_coeff := 0;
         END;
         BEGIN
            select max(cosu.numero_familiari)
              into w_fam_coeff
              from componenti_superficie cosu
             where b_consistenza between nvl(cosu.da_consistenza,0)
                                     and nvl(cosu.a_consistenza,9999999)
               and cosu.anno           = a_anno
             group by 1
            ;
-- dbms_output.put_line('Trovato '||to_char(w_max_fam_coeff));
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
-- dbms_output.put_line('Non Trovato');
                w_fam_coeff := w_max_fam_coeff;
         END;
         if nvl(a_numero_familiari,0) > w_max_fam_coeff then
            w_numero_familiari_ext := w_max_fam_coeff;
         else
            w_numero_familiari_ext := a_numero_familiari;
         end if;
         w_dal := greatest(nvl(a_dal,to_date('2222222','j')),to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy'));
         w_al  := least(nvl(a_al,to_date('3333333','j')),to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy'));
         if w_mesi_calcolo = 0 then -- calcolo giornaliero
            w_periodo := (w_al + 1 - w_dal) / w_gg_anno;
         else -- calcolo mensile o bimestrale
            w_periodo := round(months_between(w_al + 1,w_dal)) / 12;  -- La round al posto della ceil
         end if;
         --dbms_output.put_line('w_periodo '||w_periodo);
         if w_periodo < 0 then    -- metto a zero i periodi negativi
            w_periodo := 0;
         end if;
         -- (VD - 03/01/2019): calcolo importi con tariffa
         if w_flag_ruolo_tariffa = 'S' then
            begin
              select nvl(tado.tariffa_quota_fissa_no_ap,tado.tariffa_quota_fissa)
                    ,nvl(tado.tariffa_quota_variabile_no_ap,tado.tariffa_quota_variabile)
                into w_tariffa_quota_fissa
                    ,w_tariffa_quota_variabile
                from tariffe_domestiche tado
               where tado.anno                  = a_anno
                 and tado.numero_familiari      = nvl(w_numero_familiari_ext,w_fam_coeff)
               ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 w_tariffa_quota_fissa     := 0;
                 w_tariffa_quota_variabile := 0;
            END;
            w_importo_pf_base := (w_tariffa_quota_fissa * b_consistenza)
                                * w_periodo * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
            w_importo_pf_rid := w_importo_pf_base * w_perc_rid_quota_fissa / 100;
            w_importo_pf := w_importo_pf_base - w_importo_pf_rid;
            w_importo_pf := round(w_importo_pf,2);
            w_importo_pv_base := w_tariffa_quota_variabile * w_periodo
                               * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
            w_importo_pv_rid := w_importo_pv_base * w_perc_rid_quota_var / 100;
            w_importo_pv := w_importo_pv_base - w_importo_pv_rid;
            w_importo_pv := round(w_importo_pv,2);
            -- (VD - 04/01/2019): composizione strighe dettaglio parte
            --                    fissa e parte variabile
            w_dettaglio_pf := ' Tariffa' ||lpad(nvl(translate(ltrim(to_char(w_tariffa_quota_fissa,'999,990.00000')),'.,',',.'),' '),13,' ')
                           || ' Rid.'||lpad(nvl(translate(ltrim(to_char(w_importo_pf_rid,'999,999,990.00')),'.,',',.'),' '),14,' ')
                           || ' Imposta QF' ||lpad(nvl(translate(ltrim(to_char(w_importo_pf,'999,999,990.00')),'.,',',.'),' '),14,' ');
            w_dettaglio_pv := ' Tariffa' ||lpad(nvl(translate(ltrim(to_char(w_tariffa_quota_variabile,'999,990.00000')),'.,',',.'),' '),13,' ')
                           || ' Rid.'||lpad(nvl(translate(ltrim(to_char(w_importo_pv_rid,'999,999,990.00')),'.,',',.'),' '),14,' ')
                           || ' Imposta QV' ||lpad(nvl(translate(ltrim(to_char(w_importo_pv,'999,999,990.00')),'.,',',.'),' '),14,' ');
            w_dettaglio_pf_base := lpad(' Imposta Base QF' ||lpad(nvl(translate(ltrim(to_char(w_importo_pf_base,'999,999,990.00')),'.,',',.'),' '),14,' '),75);
            w_dettaglio_pv_base := lpad(' Imposta Base QV' ||lpad(nvl(translate(ltrim(to_char(w_importo_pv_base,'999,999,990.00')),'.,',',.'),' '),14,' '),75);
         else
            --
            -- Contrariamente ai familiari soggetto, non ci si trova in presenza
            -- di un archivio storico, per cui la query per determinare i
            -- coefficienti ha come risultato una unica registrazione.
            --
            BEGIN
               select nvl(codo.coeff_adattamento_no_ap,codo.coeff_adattamento)
                     ,nvl(codo.coeff_produttivita_no_ap,codo.coeff_produttivita)
                 into w_coeff1
                     ,w_coeff2
                 from coefficienti_domestici codo
                where codo.anno                  = a_anno
                  and codo.numero_familiari      = nvl(w_numero_familiari_ext,w_fam_coeff)
                ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 w_coeff1 := 0;
                 w_coeff2 := 0;
            END;
            w_importo_pf := (w_tari * b_consistenza * w_coeff1)
                         * w_periodo * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
            w_importo_pf := round(w_importo_pf,2);
            w_importo_pv := (a_tariffa * w_coeff2)
                         * w_periodo * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
            w_importo_pv := round(w_importo_pv,2);
            w_dettaglio_pf := ' Coeff. '||lpad(nvl(translate(ltrim(to_char(w_coeff1,'90.0000')),'.,',',.'),' '),7,' ')
                           || ' Tariffa ' ||lpad(nvl(translate(ltrim(to_char(w_tari,'999,990.00000')),'.,',',.'),' '),13,' ')
                           || ' Imposta QF' ||lpad(nvl(translate(ltrim(to_char(w_importo_pf,'99,999,999,990.00')),'.,',',.'),' '),17,' ');
            w_dettaglio_pv := ' Coeff. '||lpad(nvl(translate(ltrim(to_char(w_coeff2,'90.0000')),'.,',',.'),' '),7,' ')
                           || ' Tariffa ' ||lpad(nvl(translate(ltrim(to_char(a_tariffa,'999,990.00000')),'.,',',.'),' '),13,' ')
                           || ' Imposta QV' ||lpad(nvl(translate(ltrim(to_char(w_importo_pv,'99,999,999,990.00')),'.,',',.'),' '),17,' ');
            if w_flag_tariffa_base = 'S' then
               w_importo_pf_base := (w_tariffa_qf_base * b_consistenza * w_coeff1)
                            * w_periodo * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
               w_importo_pf_base := round(w_importo_pf_base,2);
               w_importo_pf_rid  := w_importo_pf_base - w_importo_pf;
               w_importo_pv_base := (w_tariffa_qv_base * w_coeff2)
                            * w_periodo * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
               w_importo_pv_base := round(w_importo_pv_base,2);
               w_importo_pv_rid  := w_importo_pv_base - w_importo_pv;
               w_dettaglio_pf_base := ' Tariffa Base' ||lpad(nvl(translate(ltrim(to_char(w_tariffa_qf_base,'999,990.00000')),'.,',',.'),' '),13,' ')
                                   || ' Rid.'||lpad(nvl(translate(ltrim(to_char(w_importo_pf_rid,'999,999,990.00')),'.,',',.'),' '),14,' ')
                                   || ' Imposta Base QF' ||lpad(nvl(translate(ltrim(to_char(w_importo_pf_base,'999,999,990.00')),'.,',',.'),' '),14,' ');
               w_dettaglio_pv_base := ' Tariffa Base' ||lpad(nvl(translate(ltrim(to_char(w_tariffa_qv_base,'999,990.00000')),'.,',',.'),' '),13,' ')
                                   || ' Rid.'||lpad(nvl(translate(ltrim(to_char(w_importo_pv_rid,'999,999,990.00')),'.,',',.'),' '),14,' ')
                                   || ' Imposta Base QV' ||lpad(nvl(translate(ltrim(to_char(w_importo_pv_base,'999,999,990.00')),'.,',',.'),' '),14,' ');
            else
               w_importo_pf_base := to_number(null);
               w_importo_pv_base := to_number(null);
               w_importo_pf_rid  := to_number(null);
               w_importo_pv_rid  := to_number(null);
               w_dettaglio_pf_base  := to_char(null);
               w_dettaglio_pv_base  := to_char(null);
               w_dettaglio_tot_base := to_char(null);
            end if;
         end if;
         --
         -- (VD - 18/11/2016) - Sperimentazione Poasco
         --                     Si verifica se l'utenza ha diritto agli sconti
         --                     relativi ai sacchi conferiti.
         --                     Se la percentuale di sconto non e nulla, si
         --                     applica alla quota variabile
         --
         w_dettaglio_conf := '';
         if w_unita_terr   is not null and
            w_suddivisione is not null then
            DETERMINA_SCONTO_CONF(w_unita_terr
                                 ,w_suddivisione
                                 ,a_cod_fiscale
                                 ,a_oggetto
                                 ,w_anno_ruolo
                                 ,a_tributo
                                 ,a_categoria
                                 ,nvl(w_numero_familiari_ext,w_fam_coeff)
                                 ,w_perc_sconto
                                 ,w_num_sacchi
                                 );
            if w_perc_sconto is not null then
               w_sconto_conf := round(w_importo_pv * w_perc_sconto / 100,2);
               w_tot_sconto_conf := w_tot_sconto_conf + w_sconto_conf;
               w_importo_pv      := w_importo_pv - w_sconto_conf;
               w_importo_pv_base := w_importo_pv_base - w_sconto_conf;
               w_dettaglio_conf := ' Sacchi Conferiti '||lpad(ltrim(to_char(w_num_sacchi,'9990')),4)
                                || ' Perc. sconto '||lpad(nvl(translate(ltrim(to_char(w_perc_sconto,'990.00')),'.,',',.'),' '),6,' ')
                                || ' Sconto:'||lpad(nvl(translate(ltrim(to_char(w_sconto_conf,'99,999,990.00')),'.,',',.'),' '),13,' ');
            end if;
         end if;
         w_importo           := w_importo_pf + w_importo_pv;
         w_dettaglio_tot     := lpad(nvl(translate(ltrim(to_char(w_importo,'9,999,999,999,990.00')),'.,',',.'),' '),20,' ');
         w_dettaglio_ogim    := w_dettaglio_ogim||w_dettaglio_pf||w_dettaglio_pv||w_dettaglio_tot;
         w_stringa_familiari := w_stringa_familiari || lpad(to_char(nvl(nvl(w_numero_familiari_ext,w_fam_coeff),0)),4,'0') || to_char(w_dal,'ddmmyyyy')|| to_char(w_al,'ddmmyyyy');
--DBMS_OUTPUT.PUT_LINE('3 w_stringa_familiari'||w_stringa_familiari);
         if w_flag_ruolo_tariffa = 'S' or
            w_flag_tariffa_base  = 'S' then
            w_importo_base        := w_importo_pf_base + w_importo_pv_base;
            w_dettaglio_tot_base  := lpad(nvl(translate(ltrim(to_char(w_importo_base,'9,999,999,999,990.00')),'.,',',.'),' '),20,' ');
            w_dettaglio_ogim_base := w_dettaglio_ogim_base||w_dettaglio_pf_base||w_dettaglio_pv_base||w_dettaglio_tot_base;
         end if;
         if a_oggetto is not null then
            w_dettaglio_ogim := w_dettaglio_ogim||rpad(nvl(w_dettaglio_conf,' '),63);
         end if;
         -- dbms_output.put_line('tariffa1 '||to_char(w_tari)||' consistenza '||to_char(b_consistenza)||
         -- ' coeff1 '||to_char(w_coeff1)||' tariffa2 '||to_char(a_tariffa)||' coeff2 '||to_char(w_coeff2)||
         -- ' periodo '||to_char(w_periodo)||' perc_possesso '||to_char(a_perc_possesso)||' importo '||to_char(w_importo));
      END IF;
--dbms_output.put_line('(3) '||w_dettaglio_ogim_base);
   ELSE
      -- Utenze non domestiche
      w_dal     := greatest(nvl(a_dal,to_date('2222222','j')),to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy'));
      w_al      := least(nvl(a_al,to_date('3333333','j'))
                        ,to_date('3112'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy'));
      if w_mesi_calcolo = 0 then -- calcolo giornaliero
         w_periodo := (w_al + 1 - w_dal) / w_gg_anno;
      else -- calcolo mensile o bimestrale
         w_periodo := round(months_between(w_al + 1,w_dal)) / 12;  -- Utilizzata la round anzich la ceil
      end if;
      if w_periodo < 0 then    -- metto a zero i periodi negativi
         w_periodo := 0;
      end if;
      -- (VD - 03/01/2019): calcolo importi con tariffa
      if w_flag_ruolo_tariffa = 'S' then
         BEGIN
            select tariffa_quota_fissa
                 , tariffa_quota_variabile
              into w_tariffa_quota_fissa
                 , w_tariffa_quota_variabile
              from tariffe_non_domestiche
             where anno      = a_anno
               and tributo   = a_tributo
               and categoria = a_categoria
            ;
         EXCEPTION
            WHEN others THEN
               w_errore := 'Errore in ricerca Tariffe Non Domestiche per calcolo Normalizzato ['
               ||to_char( a_tributo)||'-'||to_char(a_categoria)||']';
               raise errore;
         END;
         w_importo_pf_base := w_tariffa_quota_fissa * b_consistenza * w_periodo
                            * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
         w_importo_pf_rid  := w_importo_pf_base * w_perc_rid_quota_fissa / 100;
         w_importo_pf      := w_importo_pf_base - w_importo_pf_rid;
         w_importo_pf      := round(w_importo_pf,2);
         w_importo_pv_base := w_tariffa_quota_variabile * b_consistenza * w_periodo
                            * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
         w_importo_pv_rid  := w_importo_pv_base * w_perc_rid_quota_var / 100;
         w_importo_pv      := w_importo_pv_base - w_importo_pv_rid;
         w_importo_pv      := round(w_importo_pv,2);
         -- (VD - 04/01/2019): composizione strighe dettaglio parte
         --                    fissa e parte variabile
         w_dettaglio_pf := ' Tariffa' ||lpad(nvl(translate(ltrim(to_char(w_tariffa_quota_fissa,'999,990.00000')),'.,',',.'),' '),13,' ')
                         ||' Rid.'||lpad(nvl(translate(ltrim(to_char(w_importo_pf_rid,'999,999,990.00')),'.,',',.'),' '),14,' ')
                         ||' Imposta QF' ||lpad(nvl(translate(ltrim(to_char(w_importo_pf,'999,999,990.00')),'.,',',.'),' '),14,' ');
         w_dettaglio_pv := ' Tariffa' ||lpad(nvl(translate(ltrim(to_char(w_tariffa_quota_variabile,'999,990.00000')),'.,',',.'),' '),13,' ')
                         ||' Rid.'||lpad(nvl(translate(ltrim(to_char(w_importo_pv_rid,'999,999,990.00')),'.,',',.'),' '),14,' ')
                         ||' Imposta QV' ||lpad(nvl(translate(ltrim(to_char(w_importo_pv,'999,999,990.00')),'.,',',.'),' '),14,' ');
         w_dettaglio_pf_base := lpad(' Imposta Base QF' ||lpad(nvl(translate(ltrim(to_char(w_importo_pf_base,'999,999,990.00')),'.,',',.'),' '),14,' '),75);
         w_dettaglio_pv_base := lpad(' Imposta Base QV' ||lpad(nvl(translate(ltrim(to_char(w_importo_pv_base,'999,999,990.00')),'.,',',.'),' '),14,' '),75);
      else
         BEGIN
            select coeff_potenziale
                 , coeff_produzione
              into w_coeff1
                 , w_coeff2
              from coefficienti_non_domestici
             where anno      = a_anno
               and tributo   = a_tributo
               and categoria = a_categoria
            ;
         EXCEPTION
            WHEN others THEN
               w_errore := 'Errore in ricerca Coefficienti Non Domestici per calcolo Normalizzato ['
               ||to_char( a_tributo)||'-'||to_char(a_categoria)||']';
               raise errore;
         END;
         w_importo_pf := (w_tari * b_consistenza * w_coeff1)
                      * w_periodo * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
         w_importo_pf := round(w_importo_pf,2);
         w_importo_pv := (a_tariffa * b_consistenza * w_coeff2)
                      * w_periodo * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
         w_importo_pv := round(w_importo_pv,2);
         w_dettaglio_pf := ' Coeff. '||lpad(nvl(translate(ltrim(to_char(w_coeff1,'90.0000')),'.,',',.'),' '),7,' ')
                         ||' Tariffa ' ||lpad(nvl(translate(ltrim(to_char(w_tari,'999,990.00000')),'.,',',.'),' '),13,' ')
                         ||' Imposta QF' ||lpad(nvl(translate(ltrim(to_char(w_importo_pf,'99,999,999,990.00')),'.,',',.'),' '),17,' ');
         w_dettaglio_pv := ' Coeff. '||lpad(nvl(translate(ltrim(to_char(w_coeff2,'90.0000')),'.,',',.'),' '),7,' ')
                         ||' Tariffa ' ||lpad(nvl(translate(ltrim(to_char(a_tariffa,'999,990.00000')),'.,',',.'),' '),13,' ')
                         ||' Imposta QV' ||lpad(nvl(translate(ltrim(to_char(w_importo_pv,'99,999,999,990.00')),'.,',',.'),' '),17,' ');
         if w_flag_tariffa_base = 'S' then
            w_importo_pf_base := (w_tariffa_qf_base * b_consistenza * w_coeff1)
                         * w_periodo * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
            w_importo_pf_base := round(w_importo_pf_base,2);
            w_importo_pf_rid  := w_importo_pf_base - w_importo_pf;
            w_importo_pv_base := (w_tariffa_qv_base* b_consistenza * w_coeff2)
                         * w_periodo * nvl(a_perc_possesso,100) / 100 * w_coeff_acconto_tares;
            w_importo_pv_base := round(w_importo_pv_base,2);
            w_importo_pv_rid  := w_importo_pv_base - w_importo_pv;
            w_dettaglio_pf_base := ' Tariffa Base' ||lpad(nvl(translate(ltrim(to_char(w_tariffa_qf_base,'999,990.00000')),'.,',',.'),' '),13,' ')
                                || ' Rid.'||lpad(nvl(translate(ltrim(to_char(w_importo_pf_rid,'999,999,990.00')),'.,',',.'),' '),14,' ')
                                || ' Imposta Base QF' ||lpad(nvl(translate(ltrim(to_char(w_importo_pf_base,'999,999,990.00')),'.,',',.'),' '),14,' ');
            w_dettaglio_pv_base := ' Tariffa Base' ||lpad(nvl(translate(ltrim(to_char(w_tariffa_qv_base,'999,990.00000')),'.,',',.'),' '),13,' ')
                                || ' Rid.'||lpad(nvl(translate(ltrim(to_char(w_importo_pv_rid,'999,999,990.00')),'.,',',.'),' '),14,' ')
                                || ' Imposta Base QV' ||lpad(nvl(translate(ltrim(to_char(w_importo_pv_base,'999,999,990.00')),'.,',',.'),' '),14,' ');
         else
            w_importo_pf_base := to_number(null);
            w_importo_pv_base := to_number(null);
            w_importo_pf_rid  := to_number(null);
            w_importo_pv_rid  := to_number(null);
            w_dettaglio_pf_base  := to_char(null);
            w_dettaglio_pv_base  := to_char(null);
            w_dettaglio_tot_base := to_char(null);
         end if;
      end if;
      w_dettaglio_conf    := '';
      w_importo           := w_importo_pf + w_importo_pv;
      w_dettaglio_tot     := lpad(nvl(translate(ltrim(to_char(w_importo,'9,999,999,999,990.00')),'.,',',.'),' '),20,' ');
      w_dettaglio_ogim    := w_dettaglio_ogim||w_dettaglio_pf||w_dettaglio_pv||w_dettaglio_tot;
      w_stringa_familiari := w_stringa_familiari || lpad(to_char(nvl(nvl(w_numero_familiari_ext,w_fam_coeff),0)),4,'0') || to_char(w_dal,'ddmmyyyy')|| to_char(w_al,'ddmmyyyy');
      if w_flag_ruolo_tariffa = 'S' or
         w_flag_tariffa_base  = 'S' then
         w_importo_base        := w_importo_pf_base + w_importo_pv_base;
         w_dettaglio_tot_base  := lpad(nvl(translate(ltrim(to_char(w_importo_base,'9,999,999,999,990.00')),'.,',',.'),' '),20,' ');
         w_dettaglio_ogim_base := w_dettaglio_ogim_base||w_dettaglio_pf_base||w_dettaglio_pv_base||w_dettaglio_tot_base;
      end if;
      if a_oggetto is not null then
         w_dettaglio_ogim := w_dettaglio_ogim||rpad(nvl(w_dettaglio_conf,' '),63);
      end if;
--dbms_output.put_line('(4) '||w_dettaglio_ogim_base);
   END IF;
   --
   -- (VD - 18/11/2016): Sperimentazione Poasco
   --                    In presenza di sconti per conferimento sacchi
   --                    si aggiorna la tabella conferimenti con i dati
   --                    del ruolo
   --
   if a_oggetto is not null and
      w_tot_sconto_conf <> 0 then
      BEGIN
        update CONFERIMENTI
           set ruolo = a_ruolo
             , importo_scalato = nvl(importo_scalato,0) + w_tot_sconto_conf
         where cod_fiscale = a_cod_fiscale
           and anno = w_anno_ruolo;
      EXCEPTION
        WHEN OTHERS THEN
          w_errore := 'Errore in Aggiornamento CONFERIMENTI '||
                      'per '||a_cod_fiscale||' - ('||SQLERRM||')';
          RAISE errore;
      END;
   end if;
   a_importo           := f_round(w_importo,1);
   a_importo_pf        := f_round(w_importo_pf,1);
   a_importo_pv        := f_round(w_importo_pv,1);
   a_stringa_familiari := substr(w_stringa_familiari,1,2000);
   a_dettaglio_ogim    := rtrim(w_dettaglio_ogim);
   if w_flag_ruolo_tariffa = 'S' or
      w_flag_tariffa_base  = 'S' then
      a_importo_base        := f_round(w_importo_base,1);
      a_importo_pf_base     := f_round(w_importo_pf_base,1);
      a_importo_pv_base     := f_round(w_importo_pv_base,1);
      a_perc_riduzione_pf   := w_perc_rid_quota_fissa;
      a_perc_riduzione_pv   := w_perc_rid_quota_var;
      a_importo_pf_rid      := f_round(w_importo_pf_rid,1);
      a_importo_pv_rid      := f_round(w_importo_pv_rid,1);
      a_dettaglio_ogim_base := rtrim(w_dettaglio_ogim_base);
   else
      a_importo_base        := to_number(null);
      a_importo_pf_base     := to_number(null);
      a_importo_pv_base     := to_number(null);
      a_perc_riduzione_pf   := to_number(null);
      a_perc_riduzione_pv   := to_number(null);
      a_importo_pf_rid      := to_number(null);
      a_importo_pv_rid      := to_number(null);
      a_dettaglio_ogim_base := to_char(null);
   end if;
EXCEPTION
   WHEN errore THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,w_errore,TRUE);
   WHEN others THEN
      RAISE_APPLICATION_ERROR(-20999,'Errore in Importo Normalizzato '||'('||SQLERRM||')');
END;
/* End Procedure: CALCOLO_IMPORTO_NORM_TARIFFE */
/

