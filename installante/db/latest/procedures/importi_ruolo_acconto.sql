--liquibase formatted sql 
--changeset abrandolini:20250326_152423_importi_ruolo_acconto stripComments:false runOnChange:true 
 
create or replace procedure IMPORTI_RUOLO_ACCONTO
/*******************************************************************************
 Rev. Data       Autore     Descrizione
 ---- ---------- ------     -----------------------------------------------------
 13   29/06/2020 VD         Roccastrada - La determinazione degli importi con
                            la procedure IMPORTI_RUOLO_ACCONTO fallisce con
                            l'errore "Divisor is equal to zero", di conseguenza
                            tali importi vengono considerati pari a zero.
                            Il problema è dovuto dalla solita vista implicita
                            sugli sgravi che, considerando tutti gli sgravi del
                            contribuente, include anche record vecchi su cui
                            non sono memorizzati i mesi ruolo o i giorno ruolo.
                            Modificata subquery per includere solo gli eventuali
                            sgravi relativi al ruolo in acconto che deve essere
                            trattato.
 12   23/10/2018 VD         Aggiunta gestione campi calcolati con tariffa base
 11   18/09/2018 VD         Modificata selezione importi: ora vengono riproporzionati
                            al periodo anche la quota fissa e la quota variabile.
 10   21/02/2018 VD         Aggiunto parametro p_oggetto.
                            Modificata query per selezionare dati ruolo acconto:
                            viene effettuata prima la ricerca per oggetto_pratica,
                            se questa fallisce si ricerca per oggetto_pratica_rif
                            e periodo indicato.
 9    24/01/2018 VD         Aggiunto parametro p_ogpr_rif per passare
                            separatamente l'oggetto_pratica_rif.
                            Per verificare variazioni e cessazioni si utilizza
                            oggetto_pratica_rif, mentre per calcolare l'importo
                            in acconto si utilizza oggetto_pratica.
 8    22/01/2018 VD         Modificato controllo date in query principale:
                            ora si verifica che la variabile w_al sia minore
                            della data di cessazione di OGCO (con gli opportuni
                            nvl).
 7    21/06/2017 VD         Calcolo importi gia' andati a ruolo: nel caso in
                            cui la data di cessazione dell'oggetto su OGCO sia
                            nulla, se il ruolo e' gestito a giorni si considera
                            come data di confronto l'ultimo giorno del mese di
                            fine ruolo; se invece il ruolo e' gestito a mesi,
                            si considera il 16 del mese di fine ruolo.
 6    24/02/2017 VD         Aggiunto test su flag_annullamento null anche nella
                            query che ricerca l'eventuale cessazione
 5    19/07/2016 AB         Nella determinazione dello sgravio ho sostituito i
                            giorni_sgravio con i giorni_ruolo, fatte diverse prove
                            e funziona bene.
 4    06/07/2016 AB         Gestito w_gg_anno contentente i gg dell'anno
                            sulla base dell'ultimo giorno del mese di Febbraio
 3    27/01/2016 VD         Modificata vista implicita su sgravi per gestire il caso
                            di mesi_sgravio = 0 (considerati = 12) ed evitare l'errore
                            "divide by zero"
 2    15/01/2015 ET         Modificata nuovamente vista implicita sugli sgravi
                            per gestire il caso di più sgravi sullo stesso oggetto
                            con mesi o giorni sgravio diversi
 1    14/01/2015 ET         Corretta subquery sugli sgravi: estraeva mesi_sgravio
                            e giorni_sgravio dagli sgravi con un nvl a 0
                            questo generava un divide by 0 che, intercettato da
                            una when others faceva sì che non ci fossero errori
                            ma il ruolo in acconto per degli sgravi manuali non
                            veniva estratto.
*******************************************************************************/
(p_cf                         varchar2
,p_anno                       number
,p_dal                        date
,p_al                         date
,p_titr                       varchar2
,p_oggetto                    number
,p_ogpr                       number
,p_ogpr_rif                   number
,p_norm                       varchar2
,p_flag_tariffa_base          varchar2 default null
,p_importo            in out  number
,p_importo_pv         in out  number
,p_importo_pf         in out  number
,p_importo_base       in out  number
,p_importo_pv_base    in out  number
,p_importo_pf_base    in out  number
,p_tipo_calcolo       in out  varchar2
,p_ruolo_acconto      in out  number)
IS
w_importo                number;
w_sgravi                 number;
w_importo_pv             number;
w_importo_pf             number;
w_tiev                   varchar2(1) := '';
w_dal                    date;
w_al                     date;
w_mesi_calcolo           number;
w_tipo_calcolo           varchar2(1)  := '';
w_data_emissione_ruolo   date;
w_data_cess              date;
w_se_cessato             number;
w_ruolo_acconto          number;
w_conta_ruco             number;
w_conta_var              number;
w_gg_anno                number;
--
-- (VD - 23/10/2018): Variabili per importi calcolati con tariffa base
--
w_importo_base           number;
w_sgravi_base            number;
w_importo_pv_base        number;
w_importo_pf_base        number;
BEGIN
   BEGIN
      select decode(to_char(last_day(to_date('02'||p_anno,'mmyyyy')),'dd'), 28, 365, nvl(f_inpa_valore('GG_ANNO_BI'),366))
        into w_gg_anno
        from dual
      ;
   EXCEPTION
      WHEN others THEN
           w_gg_anno := 365;
   END;
   BEGIN
      select nvl(mesi_calcolo,2)
        into w_mesi_calcolo
        from carichi_tarsu
       where anno              = p_anno
      ;
   EXCEPTION
      WHEN others THEN
         w_mesi_calcolo := 2;
   END;
   BEGIN
       select max(ruol.data_emissione),max(ruol.ruolo)
         into w_data_emissione_ruolo, w_ruolo_acconto
         from ruoli           ruol
            , oggetti_imposta ogim
            , oggetti_pratica ogpr
        where ogim.cod_fiscale      = p_cf
          and ogpr.oggetto_pratica  = ogim.oggetto_pratica
       --
       -- (VD - 24/01/2018); test su oggetto_pratica_rif
       --
          and nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
       --                           = p_ogpr
                                    = p_ogpr_rif
          and ogim.ruolo = ruol.ruolo
          and nvl(ruol.tipo_emissione,'T')   = 'A'
          and ruol.tipo_ruolo       = 1
          and ruol.invio_consorzio is not null
          and ruol.anno_ruolo       = p_anno
          ;
      EXCEPTION
      WHEN OTHERS THEN
         w_data_emissione_ruolo := null;
   END;
   --dbms_output.put_line('Ruolo acconto: '||w_ruolo_acconto);
   BEGIN
     --
     -- (VD - 24/02/2017): aggiunta condizione di where per escludere
     --                    pratiche annullate
     --
     select prtr.tipo_evento, prtr.data
       into w_tiev, w_data_cess
       from pratiche_tributo prtr
          , oggetti_pratica ogpr
          , oggetti_contribuente ogco
      where ogpr.pratica = prtr.pratica
     --
     -- (VD - 24/01/2018); test su oggetto_pratica_rif
     --
     --        and ogpr.oggetto_pratica_rif = p_ogpr
        and ogpr.oggetto_pratica_rif = p_ogpr_rif
        and ogpr.oggetto_pratica = ogco.oggetto_pratica
        and ogco.data_cessazione = p_al
        and prtr.tipo_evento     ='C'
        and prtr.flag_annullamento is null
        ;
   EXCEPTION
      WHEN OTHERS THEN
         w_tiev := '';
         w_data_cess := null;
   END;
   --dbms_output.put_Line('Tipo evento: '||w_tiev||', data cess.: '||w_data_cess);
   w_dal := nvl(p_dal,to_date('0101'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'));
   --
   -- (VD - 22/01/2018): se la data di cessazione e' nulla, si considera il
   --                    31/12 per determinare correttamente i periodi delle
   --                    variazioni
   -- w_al  := p_al;
   w_al  := nvl(p_al,to_date('3112'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'));
   --if w_dal != to_date('01012016','ddmmyyyy') then
   --   RAISE_APPLICATION_ERROR(-20099,'CF '|| p_cf||' anno '||p_anno||' dal '||to_char(w_dal,'dd/mm/yyyy')||' al '||to_char(w_al,'dd/mm/yyyy')||' ogpr '||p_ogpr||' norm '||p_norm||' tiev '||w_tiev||' data_cess '||w_data_cess);
   --end if;
   --dbms_output.put_line('IRA - Periodo: dal '||to_char(w_dal,'dd/mm/yyyy')||' al '||to_char(w_al,'dd/mm/yyyy'));
   --
   -- (VD - 05/12/2014): Modificata gestione date periodo per calcolo acconti:
   -- Se l'oggetto è cessato e non ci sono variazioni in corso d'anno, si
   -- considera in detrazione l'intero ruolo emesso in acconto;
   -- Se l'oggetto è cessato e ci sono state variazioni in corso d'anno, si
   -- riproporziona l'acconto per il periodo che intercorre dall'inizio validità
   -- dell'oggetto e il 31/12 dell'anno in trattamento
   --
   w_se_cessato := 0;
   if w_tiev = 'C' then  -- controllo se un record a ruolo e nessuna variazione
      begin
        select count(*)
          into w_conta_ruco
          from oggetti_imposta ogim
             , oggetti_pratica ogpr
         where ogim.cod_fiscale      = p_cf
           and ogpr.oggetto_pratica  = ogim.oggetto_pratica
           and nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
        --
        -- (VD - 24/01/2018); test su oggetto_pratica_rif
        --
        --                           = p_ogpr
                                     = p_ogpr_rif
           and ogim.ruolo            = w_ruolo_acconto
           ;
      EXCEPTION
           WHEN OTHERS THEN
              w_conta_ruco := 0;
      END;
      if w_conta_ruco >= 1 then
         begin
          select count(*)
            into w_conta_var
            from pratiche_tributo prtr
               , oggetti_pratica ogpr
               , oggetti_contribuente ogco
           where ogpr.pratica = prtr.pratica
          --
          -- (VD - 24/01/2018); test su oggetto_pratica_rif
          --
          -- and ogpr.oggetto_pratica_rif = p_ogpr
             and ogpr.oggetto_pratica_rif = p_ogpr_rif
             and ogpr.oggetto_pratica = ogco.oggetto_pratica
             and prtr.tipo_evento      = 'V'
             and ogco.data_decorrenza > to_date('01/01/'||p_anno,'dd/mm/yyyy')
             and prtr.flag_annullamento is null
             ;
         EXCEPTION
           WHEN OTHERS THEN
              w_conta_var := 0;
         END;
         if w_conta_var = 0 then  -- non ci sono altre variazioni nell'anno andate a ruolo acconto
            w_se_cessato := 1;
         else
            w_al := to_date('31/12/'||p_anno,'dd/mm/yyyy');
         end if;
      end if;
   end if;
   --dbms_output.put_line('w_se_cessato: '||w_se_cessato);
   --dbms_output.put_line('GG: '||f_periodo(p_anno,w_dal,w_al,'P',p_titr,p_norm));
   --dbms_output.put_line('Dal: '||w_dal||', al: '||w_al);
   --
   -- (VD - 23/12/2014): Modificata selezione sgravi. Si trattano solo gli sgravi
   --                    manuali (motivo_sgravio <> 99) e si utilizza una vista
   --                    implicita per evitare prodotti cartesiani generati dalla
   --                    join diretta con la tabella SGRAVI
   --
/*   BEGIN
      select sum(decode(ruol.importo_lordo,'S',ruco.importo - nvl(ogim.addizionale_eca,0)
                                                            - nvl(ogim.maggiorazione_eca,0)
                                                            - nvl(ogim.maggiorazione_tares,0)
                                                            - nvl(ogim.addizionale_pro,0)
                                                            - nvl(ogim.iva,0)
                                              ,ruco.importo
                       ) * least(1,
                            decode(w_se_cessato
                                 ,1,1
                                 ,f_periodo(p_anno,w_dal,w_al,'P',p_titr,p_norm)
                                  * decode(w_mesi_calcolo
                                          ,0,w_gg_anno / decode(ruco.giorni_ruolo
                                                         ,null, decode(nvl(ruco.mesi_ruolo,12)
                                                                      ,12,w_gg_anno
                                                                      ,ruco.mesi_ruolo * 30
                                                                      )
                                                         ,ruco.giorni_ruolo
                                                         )
                                          ,12 / decode(nvl(ruco.mesi_ruolo,12),0,12,ruco.mesi_ruolo)
                                          )
                                 )
                )
               )
            ,sum(sgra.sgravio)
            ,sum(ogim.importo_pv)
            ,sum(ogim.importo_pf)
            ,max(ruol.tipo_calcolo)
        into w_importo
            ,w_sgravi
            ,w_importo_pv
            ,w_importo_pf
            ,w_tipo_calcolo
        from oggetti_pratica       ogpr
            ,oggetti_imposta       ogim
            ,oggetti_contribuente  ogco
            ,(select sgra2.ruolo, sgra2.cod_fiscale, sgra2.sequenza,
                     sum(decode(ruol2.importo_lordo,'S',nvl(sgra2.importo,0) - nvl(sgra2.addizionale_eca,0)
                                                                           - nvl(sgra2.maggiorazione_eca,0)
                                                                           - nvl(sgra2.maggiorazione_tares,0)
                                                                           - nvl(sgra2.addizionale_pro,0)
                                                                           - nvl(sgra2.iva,0)
                                                      ,nvl(sgra2.importo,0)
                               ) * least(1,
                                         decode(w_se_cessato
                                               ,1,1
                                               ,f_periodo(p_anno,w_dal,w_al,'P',p_titr,p_norm)
                     --    * 12 / nvl(sgra2.mesi_sgravio,12)
                                                * decode(w_mesi_calcolo
                                                        ,0,w_gg_anno / decode(ruco2.giorni_ruolo  --sgra2.giorni_sgravio AB 19/07/16
                                                                       ,null, decode(nvl(ltrim(sgra2.mesi_sgravio,'0'),nvl(ruco2.mesi_ruolo,12))
                                                                                    ,12,w_gg_anno
                                                                                    ,nvl(ltrim(sgra2.mesi_sgravio,'0'),nvl(ruco2.mesi_ruolo,12)) * 30
                                                                                    )
                                                                       ,ruco2.giorni_ruolo -- sgra2.giorni_sgravio AB 19/07/16
                                                                       )
                                                        ,12 / nvl(ltrim(sgra2.mesi_sgravio,'0'),nvl(ruco2.mesi_ruolo,12))
                                                        )
                                               )
                                        )
                        ) sgravio
                from sgravi sgra2, ruoli_contribuente ruco2
                     ,ruoli                 ruol2
               where sgra2.cod_fiscale = p_cf
                 and sgra2.motivo_sgravio <> 99
                 and ruol2.ruolo        = ruco2.ruolo
                 and sgra2.ruolo        = ruco2.ruolo
                 and sgra2.cod_fiscale  = ruco2.cod_fiscale
                 and sgra2.sequenza     = ruco2.sequenza
               group by sgra2.ruolo, sgra2.cod_fiscale, sgra2.sequenza) sgra
            ,ruoli_contribuente    ruco
            ,ruoli                 ruol
         --   ,oggetti_validita      ogva
       where ruol.ruolo            = ruco.ruolo
         and ogim.oggetto_imposta  = ruco.oggetto_imposta
         and ogim.cod_fiscale      = p_cf
         and ogpr.oggetto_pratica  = ogim.oggetto_pratica
--
-- (VD - 24/01/2018); test su oggetto_pratica
--
--         and nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
         and ogpr.oggetto_pratica
                                   = p_ogpr
--       and ogva.oggetto_pratica  = ogpr.oggetto_pratica
--       and ogva.cod_fiscale      = ogco.cod_fiscale
--      --   and ogva.dal              = ogco.data_decorrenza
--       and nvl(ogva.dal,to_date('0101'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'))
--           = nvl(ogco.data_decorrenza,to_date('0101'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'))
         and ogco.cod_fiscale      = ogim.cod_fiscale
         and ogco.oggetto_pratica  = ogim.oggetto_pratica
--
--       (VD - 24/01/2018): eseguendo la query per oggetto_pratica si eliminano
--                          i test sulle date
--
--         and w_dal                >= nvl(ogco.data_decorrenza,to_date('01011900','ddmmyyyy'))
--
--       (VD - 22/01/2018): modificato test date di validità per gestire
--                          correttamente le variazioni in corso d'anno
--
--         and w_dal                 <=
--         and nvl(w_al,
--                 decode(w_mesi_calcolo
--                       ,0,last_day(to_date(lpad(nvl(ruco.a_mese,12),2,'0')||lpad(p_anno,4,'0'),'mmyyyy'))
--                         ,to_date(to_char('16'||lpad(nvl(ruco.a_mese,12),2,'0')||lpad(p_anno,4,'0')),'ddmmyyyy')
--                       )
--                ) <=
         --
         -- (VD - 21/06/2017): nel caso in cui la data cessazione sia nulla, se il ruolo è gestito a giorni,
         --                    si considera come data di fine l'ultimo giorno del mese di fine ruolo;
         --                    se il ruolo è gestito a mesi, si considera il 16 del mese di fine ruolo.
         --
--                nvl(ogco.data_cessazione
--                   ,decode(w_mesi_calcolo
--                          ,0,last_day(to_date(lpad(nvl(ruco.a_mese,12),2,'0')||lpad(p_anno,4,'0'),'mmyyyy'))
--                            ,to_date(to_char('16'||lpad(nvl(ruco.a_mese,12),2,'0')||lpad(p_anno,4,'0')),'ddmmyyyy')
--                          )
--                   )
--                nvl(ogco.data_cessazione,to_date('16'||lpad(nvl(ruco.a_mese,12),2,'0')||lpad(p_anno,4,'0'),'ddmmyyyy'))
--                nvl(ogco.data_cessazione,to_date(to_char('16'||lpad(nvl(ruco.a_mese,12),2,'0')||lpad(p_anno,4,'0')),'ddmmyyyy'))
--                nvl(ogco.data_cessazione,to_date(to_char(last_day(to_date(lpad(nvl(ruco.a_mese,12),2,'0')||lpad(p_anno,4,'0'),'mmyyyy')),'dd')||lpad(nvl(ruco.a_mese,12),2,'0')||lpad(p_anno,4,'0'),'ddmmyyyy'))
--                nvl(ogco.data_cessazione,to_date('31'||lpad(to_char(nvl(ruco.da_mese,12)),2,'0')||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'))
--                nvl(nvl(ogco.data_cessazione,w_al),to_date('3112'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'))
--                nvl(ogva.al,to_date('3112'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'))
         and ruco.ruolo            = ogim.ruolo
         and nvl(ruol.tipo_emissione,'T')   = 'A'
         and ruol.tipo_ruolo       = 1
         and ruol.invio_consorzio is not null
         and ruol.anno_ruolo       = p_anno
         and ruco.cod_fiscale      = p_cf
         and ruol.tipo_tributo||'' = p_titr
         and sgra.ruolo        (+) = ruco.ruolo
         and sgra.cod_fiscale  (+) = ruco.cod_fiscale
         and sgra.sequenza     (+) = ruco.sequenza
--         and sgra.FLAG_AUTOMATICO  (+) = 'S'  -- tolto il 21/10/2013 per evitare di non trattare quelli manuali a Rivoli
      ;
   EXCEPTION
      WHEN OTHERS THEN
         w_importo := 0;
         w_sgravi  := 0;
         w_importo_pv := 0;
         w_importo_pf := 0;
         w_tipo_calcolo := '';
   END; */
   --
   -- (VD - 21/02/2018): Modificata ricerca dati ruolo acconto.
   --                    Viene effettuata prima la ricerca per oggetto_pratica:
   --                    se tale ricerca fallisce, si ricerca nuovamente per
   --                    oggetto_pratica_rif e periodo indicato.
   --
   BEGIN
      select sum(decode(ruol.importo_lordo,'S',ruco.importo - nvl(ogim.addizionale_eca,0)
                                                            - nvl(ogim.maggiorazione_eca,0)
                                                            - nvl(ogim.maggiorazione_tares,0)
                                                            - nvl(ogim.addizionale_pro,0)
                                                            - nvl(ogim.iva,0)
                                              ,ruco.importo
                       ) * least(1,
                            decode(w_se_cessato
                                 ,1,1
                                 ,f_periodo(p_anno,w_dal,w_al,'P',p_titr,p_norm)
                                  * decode(w_mesi_calcolo
                                          ,0,w_gg_anno / decode(ruco.giorni_ruolo
                                                         ,null, decode(nvl(ruco.mesi_ruolo,12)
                                                                      ,12,w_gg_anno
                                                                      ,ruco.mesi_ruolo * 30
                                                                      )
                                                         ,ruco.giorni_ruolo
                                                         )
                                          ,12 / decode(nvl(ruco.mesi_ruolo,12),0,12,ruco.mesi_ruolo)
                                          )
                                  )
                                )
                )
            ,sum(sgra.sgravio)
            ,sum(ogim.importo_pv *
                 least(1, decode(w_se_cessato
                                ,1,1
                                ,f_periodo(p_anno,w_dal,w_al,'P',p_titr,p_norm)
                                 * decode(w_mesi_calcolo
                                         ,0,w_gg_anno / decode(ruco.giorni_ruolo
                                                         ,null, decode(nvl(ruco.mesi_ruolo,12)
                                                                      ,12,w_gg_anno
                                                                      ,ruco.mesi_ruolo * 30
                                                                      )
                                                         ,ruco.giorni_ruolo
                                                         )
                                          ,12 / decode(nvl(ruco.mesi_ruolo,12),0,12,ruco.mesi_ruolo)
                                         )
                                )
                      )
                )
            ,sum(ogim.importo_pf *
                 least(1, decode(w_se_cessato
                                ,1,1
                                ,f_periodo(p_anno,w_dal,w_al,'P',p_titr,p_norm)
                                 * decode(w_mesi_calcolo
                                         ,0,w_gg_anno / decode(ruco.giorni_ruolo
                                                         ,null, decode(nvl(ruco.mesi_ruolo,12)
                                                                      ,12,w_gg_anno
                                                                      ,ruco.mesi_ruolo * 30
                                                                      )
                                                         ,ruco.giorni_ruolo
                                                         )
                                          ,12 / decode(nvl(ruco.mesi_ruolo,12),0,12,ruco.mesi_ruolo)
                                          )
                                  )
                                ))
            ,max(ruol.tipo_calcolo)
            ,sum(decode(ruol.importo_lordo,'S',ruco.importo_base - nvl(ogim.addizionale_eca_base,0)
                                                            - nvl(ogim.maggiorazione_eca_base,0)
                                                            - nvl(ogim.addizionale_pro_base,0)
                                                            - nvl(ogim.iva_base,0)
                                              ,ruco.importo_base
                       ) * least(1,
                            decode(w_se_cessato
                                 ,1,1
                                 ,f_periodo(p_anno,w_dal,w_al,'P',p_titr,p_norm)
                                  * decode(w_mesi_calcolo
                                          ,0,w_gg_anno / decode(ruco.giorni_ruolo
                                                         ,null, decode(nvl(ruco.mesi_ruolo,12)
                                                                      ,12,w_gg_anno
                                                                      ,ruco.mesi_ruolo * 30
                                                                      )
                                                         ,ruco.giorni_ruolo
                                                         )
                                          ,12 / decode(nvl(ruco.mesi_ruolo,12),0,12,ruco.mesi_ruolo)
                                          )
                                  )
                                )
                )
            ,sum(sgra.sgravio_base)
            ,sum(ogim.importo_pv_base *
                 least(1, decode(w_se_cessato
                                ,1,1
                                ,f_periodo(p_anno,w_dal,w_al,'P',p_titr,p_norm)
                                 * decode(w_mesi_calcolo
                                         ,0,w_gg_anno / decode(ruco.giorni_ruolo
                                                         ,null, decode(nvl(ruco.mesi_ruolo,12)
                                                                      ,12,w_gg_anno
                                                                      ,ruco.mesi_ruolo * 30
                                                                      )
                                                         ,ruco.giorni_ruolo
                                                         )
                                          ,12 / decode(nvl(ruco.mesi_ruolo,12),0,12,ruco.mesi_ruolo)
                                         )
                                )
                      )
                )
            ,sum(ogim.importo_pf_base *
                 least(1, decode(w_se_cessato
                                ,1,1
                                ,f_periodo(p_anno,w_dal,w_al,'P',p_titr,p_norm)
                                 * decode(w_mesi_calcolo
                                         ,0,w_gg_anno / decode(ruco.giorni_ruolo
                                                         ,null, decode(nvl(ruco.mesi_ruolo,12)
                                                                      ,12,w_gg_anno
                                                                      ,ruco.mesi_ruolo * 30
                                                                      )
                                                         ,ruco.giorni_ruolo
                                                         )
                                          ,12 / decode(nvl(ruco.mesi_ruolo,12),0,12,ruco.mesi_ruolo)
                                          )
                                  )
                                ))
        into w_importo
            ,w_sgravi
            ,w_importo_pv
            ,w_importo_pf
            ,w_tipo_calcolo
            ,w_importo_base
            ,w_sgravi_base
            ,w_importo_pv_base
            ,w_importo_pf_base
        from oggetti_pratica       ogpr
            ,oggetti_imposta       ogim
            ,(select sgra2.ruolo, sgra2.cod_fiscale, sgra2.sequenza,
                     sum(decode(ruol2.importo_lordo,'S',nvl(sgra2.importo,0) - nvl(sgra2.addizionale_eca,0)
                                                                           - nvl(sgra2.maggiorazione_eca,0)
                                                                           - nvl(sgra2.maggiorazione_tares,0)
                                                                           - nvl(sgra2.addizionale_pro,0)
                                                                           - nvl(sgra2.iva,0)
                                                      ,nvl(sgra2.importo,0)
                               ) * least(1,
                                         decode(w_se_cessato
                                               ,1,1
                                               ,f_periodo(p_anno,w_dal,w_al,'P',p_titr,p_norm)
                     --    * 12 / nvl(sgra2.mesi_sgravio,12)
                                                * decode(w_mesi_calcolo
                                                        ,0,w_gg_anno / decode(ruco2.giorni_ruolo  --sgra2.giorni_sgravio AB 19/07/16
                                                                       ,null, decode(nvl(ltrim(sgra2.mesi_sgravio,'0'),nvl(ruco2.mesi_ruolo,12))
                                                                                    ,12,w_gg_anno
                                                                                    ,nvl(ltrim(sgra2.mesi_sgravio,'0'),nvl(ruco2.mesi_ruolo,12)) * 30
                                                                                    )
                                                                       ,ruco2.giorni_ruolo -- sgra2.giorni_sgravio AB 19/07/16
                                                                       )
                                                        ,12 / nvl(ltrim(sgra2.mesi_sgravio,'0'),nvl(ruco2.mesi_ruolo,12))
                                                        )
                                               )
                                        )
                        ) sgravio,
                     sum(decode(ruol2.importo_lordo,'S',nvl(sgra2.importo_base,0) - nvl(sgra2.addizionale_eca_base,0)
                                                                           - nvl(sgra2.maggiorazione_eca_base,0)
                                                                           - nvl(sgra2.addizionale_pro_base,0)
                                                                           - nvl(sgra2.iva_base,0)
                                                      ,nvl(sgra2.importo_base,0)
                               ) * least(1,
                                         decode(w_se_cessato
                                               ,1,1
                                               ,f_periodo(p_anno,w_dal,w_al,'P',p_titr,p_norm)
                     --    * 12 / nvl(sgra2.mesi_sgravio,12)
                                                * decode(w_mesi_calcolo
                                                        ,0,w_gg_anno / decode(ruco2.giorni_ruolo  --sgra2.giorni_sgravio AB 19/07/16
                                                                       ,null, decode(nvl(ltrim(sgra2.mesi_sgravio,'0'),nvl(ruco2.mesi_ruolo,12))
                                                                                    ,12,w_gg_anno
                                                                                    ,nvl(ltrim(sgra2.mesi_sgravio,'0'),nvl(ruco2.mesi_ruolo,12)) * 30
                                                                                    )
                                                                       ,ruco2.giorni_ruolo -- sgra2.giorni_sgravio AB 19/07/16
                                                                       )
                                                        ,12 / nvl(ltrim(sgra2.mesi_sgravio,'0'),nvl(ruco2.mesi_ruolo,12))
                                                        )
                                               )
                                        )
                        ) sgravio_base
                from sgravi sgra2, ruoli_contribuente ruco2
                     ,ruoli                 ruol2
               where sgra2.cod_fiscale = p_cf
                 and sgra2.motivo_sgravio <> 99
                 --- (VD - 29/06/2020): aggiunte condizioni di where per
                 --                     limitare la possibilita di errore
                 --                     "divide by zero"
                 and nvl(ruol2.tipo_emissione,'T')   = 'A'
                 and ruol2.tipo_ruolo   = 1
                 and ruol2.invio_consorzio is not null
                 and ruol2.anno_ruolo   = p_anno
                 and ruol2.tipo_tributo||'' = p_titr
                 and ruol2.ruolo        = ruco2.ruolo
                 and sgra2.ruolo        = ruco2.ruolo
                 and sgra2.cod_fiscale  = ruco2.cod_fiscale
                 and sgra2.sequenza     = ruco2.sequenza
               group by sgra2.ruolo, sgra2.cod_fiscale, sgra2.sequenza) sgra
            ,ruoli_contribuente    ruco
            ,ruoli                 ruol
       where ruol.ruolo            = ruco.ruolo
         and ogim.oggetto_imposta  = ruco.oggetto_imposta
         and ogim.cod_fiscale      = p_cf
         and ogpr.oggetto_pratica  = ogim.oggetto_pratica
         and ogpr.oggetto          = p_oggetto
         and ogpr.oggetto_pratica  = p_ogpr
         and w_dal <= decode(w_mesi_calcolo
                            ,0,last_day(to_date(lpad(least(nvl(ruco.a_mese,12),12),2,'0')||lpad(p_anno,4,'0'),'mmyyyy'))
                              ,to_date(to_char('16'||lpad(least(nvl(ruco.a_mese,12),12),2,'0')||lpad(p_anno,4,'0')),'ddmmyyyy')
                            )
         and w_al >= to_date('01'||lpad(least(nvl(ruco.da_mese,12),12),2,'0')||lpad(p_anno,4,'0'),'ddmmyyyy')
         and ruco.ruolo            = ogim.ruolo
         and nvl(ruol.tipo_emissione,'T')   = 'A'
         and ruol.tipo_ruolo       = 1
         and ruol.invio_consorzio is not null
         and ruol.anno_ruolo       = p_anno
         and ruco.cod_fiscale      = p_cf
         and ruol.tipo_tributo||'' = p_titr
         and sgra.ruolo        (+) = ruco.ruolo
         and sgra.cod_fiscale  (+) = ruco.cod_fiscale
         and sgra.sequenza     (+) = ruco.sequenza
      ;
   EXCEPTION
      WHEN OTHERS THEN
         w_importo := 0;
         w_sgravi  := 0;
         w_importo_pv := 0;
         w_importo_pf := 0;
         w_tipo_calcolo := '';
         w_importo_base := 0;
         w_sgravi_base  := 0;
         w_importo_pv_base := 0;
         w_importo_pf_base := 0;
   END;
   --dbms_output.put_line('IRA - Importo acconto per ogpr: '||w_importo);
   if w_tipo_calcolo is null then
      BEGIN
         select sum(decode(ruol.importo_lordo,'S',ruco.importo - nvl(ogim.addizionale_eca,0)
                                                               - nvl(ogim.maggiorazione_eca,0)
                                                               - nvl(ogim.maggiorazione_tares,0)
                                                               - nvl(ogim.addizionale_pro,0)
                                                               - nvl(ogim.iva,0)
                                                 ,ruco.importo
                          ) * least(1,
                               decode(w_se_cessato
                                    ,1,1
                                    ,f_periodo(p_anno,w_dal,w_al,'P',p_titr,p_norm)
                                     * decode(w_mesi_calcolo
                                             ,0,w_gg_anno / decode(ruco.giorni_ruolo
                                                            ,null, decode(nvl(ruco.mesi_ruolo,12)
                                                                         ,12,w_gg_anno
                                                                         ,ruco.mesi_ruolo * 30
                                                                         )
                                                            ,ruco.giorni_ruolo
                                                            )
                                             ,12 / decode(nvl(ruco.mesi_ruolo,12),0,12,ruco.mesi_ruolo)
                                             )
                                     )
                                   )
                   )
               ,sum(sgra.sgravio)
               ,sum(ogim.importo_pv * least(1,
                               decode(w_se_cessato
                                    ,1,1
                                    ,f_periodo(p_anno,w_dal,w_al,'P',p_titr,p_norm)
                                     * decode(w_mesi_calcolo
                                             ,0,w_gg_anno / decode(ruco.giorni_ruolo
                                                            ,null, decode(nvl(ruco.mesi_ruolo,12)
                                                                         ,12,w_gg_anno
                                                                         ,ruco.mesi_ruolo * 30
                                                                         )
                                                            ,ruco.giorni_ruolo
                                                            )
                                             ,12 / decode(nvl(ruco.mesi_ruolo,12),0,12,ruco.mesi_ruolo)
                                             )
                                     )
                                   ))
               ,sum(ogim.importo_pf * least(1,
                               decode(w_se_cessato
                                    ,1,1
                                    ,f_periodo(p_anno,w_dal,w_al,'P',p_titr,p_norm)
                                     * decode(w_mesi_calcolo
                                             ,0,w_gg_anno / decode(ruco.giorni_ruolo
                                                            ,null, decode(nvl(ruco.mesi_ruolo,12)
                                                                         ,12,w_gg_anno
                                                                         ,ruco.mesi_ruolo * 30
                                                                         )
                                                            ,ruco.giorni_ruolo
                                                            )
                                             ,12 / decode(nvl(ruco.mesi_ruolo,12),0,12,ruco.mesi_ruolo)
                                             )
                                     )
                                   ))
               ,max(ruol.tipo_calcolo)
               ,sum(decode(ruol.importo_lordo,'S',ruco.importo_base - nvl(ogim.addizionale_eca_base,0)
                                                               - nvl(ogim.maggiorazione_eca_base,0)
                                                               - nvl(ogim.addizionale_pro_base,0)
                                                               - nvl(ogim.iva_base,0)
                                                 ,ruco.importo_base
                          ) * least(1,
                               decode(w_se_cessato
                                    ,1,1
                                    ,f_periodo(p_anno,w_dal,w_al,'P',p_titr,p_norm)
                                     * decode(w_mesi_calcolo
                                             ,0,w_gg_anno / decode(ruco.giorni_ruolo
                                                            ,null, decode(nvl(ruco.mesi_ruolo,12)
                                                                         ,12,w_gg_anno
                                                                         ,ruco.mesi_ruolo * 30
                                                                         )
                                                            ,ruco.giorni_ruolo
                                                            )
                                             ,12 / decode(nvl(ruco.mesi_ruolo,12),0,12,ruco.mesi_ruolo)
                                             )
                                     )
                                   )
                   )
               ,sum(sgra.sgravio_base)
               ,sum(ogim.importo_pv_base *
                    least(1, decode(w_se_cessato
                                   ,1,1
                                   ,f_periodo(p_anno,w_dal,w_al,'P',p_titr,p_norm)
                                    * decode(w_mesi_calcolo
                                            ,0,w_gg_anno / decode(ruco.giorni_ruolo
                                                            ,null, decode(nvl(ruco.mesi_ruolo,12)
                                                                         ,12,w_gg_anno
                                                                         ,ruco.mesi_ruolo * 30
                                                                         )
                                                            ,ruco.giorni_ruolo
                                                            )
                                             ,12 / decode(nvl(ruco.mesi_ruolo,12),0,12,ruco.mesi_ruolo)
                                            )
                                   )
                         )
                   )
               ,sum(ogim.importo_pf_base *
                    least(1, decode(w_se_cessato
                                   ,1,1
                                   ,f_periodo(p_anno,w_dal,w_al,'P',p_titr,p_norm)
                                    * decode(w_mesi_calcolo
                                            ,0,w_gg_anno / decode(ruco.giorni_ruolo
                                                            ,null, decode(nvl(ruco.mesi_ruolo,12)
                                                                         ,12,w_gg_anno
                                                                         ,ruco.mesi_ruolo * 30
                                                                         )
                                                            ,ruco.giorni_ruolo
                                                            )
                                             ,12 / decode(nvl(ruco.mesi_ruolo,12),0,12,ruco.mesi_ruolo)
                                             )
                                     )
                                   ))
           into w_importo
               ,w_sgravi
               ,w_importo_pv
               ,w_importo_pf
               ,w_tipo_calcolo
               ,w_importo_base
               ,w_sgravi_base
               ,w_importo_pv_base
               ,w_importo_pf_base
           from oggetti_pratica       ogpr
               ,oggetti_imposta       ogim
               ,oggetti_contribuente  ogco
               ,(select sgra2.ruolo, sgra2.cod_fiscale, sgra2.sequenza,
                        sum(decode(ruol2.importo_lordo,'S',nvl(sgra2.importo,0) - nvl(sgra2.addizionale_eca,0)
                                                                              - nvl(sgra2.maggiorazione_eca,0)
                                                                              - nvl(sgra2.maggiorazione_tares,0)
                                                                              - nvl(sgra2.addizionale_pro,0)
                                                                              - nvl(sgra2.iva,0)
                                                         ,nvl(sgra2.importo,0)
                                  ) * least(1,
                                            decode(w_se_cessato
                                                  ,1,1
                                                  ,f_periodo(p_anno,w_dal,w_al,'P',p_titr,p_norm)
                                                   * decode(w_mesi_calcolo
                                                           ,0,w_gg_anno / decode(ruco2.giorni_ruolo  --sgra2.giorni_sgravio AB 19/07/16
                                                                          ,null, decode(nvl(ltrim(sgra2.mesi_sgravio,'0'),nvl(ruco2.mesi_ruolo,12))
                                                                                       ,12,w_gg_anno
                                                                                       ,nvl(ltrim(sgra2.mesi_sgravio,'0'),nvl(ruco2.mesi_ruolo,12)) * 30
                                                                                       )
                                                                          ,ruco2.giorni_ruolo -- sgra2.giorni_sgravio AB 19/07/16
                                                                          )
                                                           ,12 / nvl(ltrim(sgra2.mesi_sgravio,'0'),nvl(ruco2.mesi_ruolo,12))
                                                           )
                                                  )
                                           )
                           ) sgravio,
                        sum(decode(ruol2.importo_lordo,'S',nvl(sgra2.importo_base,0) - nvl(sgra2.addizionale_eca_base,0)
                                                                              - nvl(sgra2.maggiorazione_eca_base,0)
                                                                              - nvl(sgra2.addizionale_pro_base,0)
                                                                              - nvl(sgra2.iva_base,0)
                                                         ,nvl(sgra2.importo_base,0)
                                  ) * least(1,
                                            decode(w_se_cessato
                                                  ,1,1
                                                  ,f_periodo(p_anno,w_dal,w_al,'P',p_titr,p_norm)
                                                   * decode(w_mesi_calcolo
                                                           ,0,w_gg_anno / decode(ruco2.giorni_ruolo  --sgra2.giorni_sgravio AB 19/07/16
                                                                          ,null, decode(nvl(ltrim(sgra2.mesi_sgravio,'0'),nvl(ruco2.mesi_ruolo,12))
                                                                                       ,12,w_gg_anno
                                                                                       ,nvl(ltrim(sgra2.mesi_sgravio,'0'),nvl(ruco2.mesi_ruolo,12)) * 30
                                                                                       )
                                                                          ,ruco2.giorni_ruolo -- sgra2.giorni_sgravio AB 19/07/16
                                                                          )
                                                           ,12 / nvl(ltrim(sgra2.mesi_sgravio,'0'),nvl(ruco2.mesi_ruolo,12))
                                                           )
                                                  )
                                           )
                           ) sgravio_base
                   from sgravi sgra2, ruoli_contribuente ruco2
                        ,ruoli                 ruol2
                  where sgra2.cod_fiscale = p_cf
                    and sgra2.motivo_sgravio <> 99
                    and ruol2.ruolo        = ruco2.ruolo
                    and sgra2.ruolo        = ruco2.ruolo
                    and sgra2.cod_fiscale  = ruco2.cod_fiscale
                    and sgra2.sequenza     = ruco2.sequenza
                  group by sgra2.ruolo, sgra2.cod_fiscale, sgra2.sequenza) sgra
               ,ruoli_contribuente    ruco
               ,ruoli                 ruol
          where ruol.ruolo            = ruco.ruolo
            and ogim.oggetto_imposta  = ruco.oggetto_imposta
            and ogim.cod_fiscale      = p_cf
            and ogpr.oggetto_pratica  = ogim.oggetto_pratica
            and ogpr.oggetto          = p_oggetto
            and nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica) = p_ogpr_rif
            and w_dal <= decode(w_mesi_calcolo
                               ,0,last_day(to_date(lpad(least(nvl(ruco.a_mese,12),12),2,'0')||lpad(p_anno,4,'0'),'mmyyyy'))
                                 ,to_date(to_char('16'||lpad(least(nvl(ruco.a_mese,12),12),2,'0')||lpad(p_anno,4,'0')),'ddmmyyyy')
                               )
            and w_al >= to_date('01'||lpad(least(nvl(ruco.da_mese,12),12),2,'0')||lpad(p_anno,4,'0'),'ddmmyyyy')
            and ogco.cod_fiscale      = ogim.cod_fiscale
            and ogco.oggetto_pratica  = ogim.oggetto_pratica
            and ruco.ruolo            = ogim.ruolo
            and nvl(ruol.tipo_emissione,'T')   = 'A'
            and ruol.tipo_ruolo       = 1
            and ruol.invio_consorzio is not null
            and ruol.anno_ruolo       = p_anno
            and ruco.cod_fiscale      = p_cf
            and ruol.tipo_tributo||'' = p_titr
            and sgra.ruolo        (+) = ruco.ruolo
            and sgra.cod_fiscale  (+) = ruco.cod_fiscale
            and sgra.sequenza     (+) = ruco.sequenza
         ;
      EXCEPTION
         WHEN OTHERS THEN
            w_importo := 0;
            w_sgravi  := 0;
            w_importo_pv := 0;
            w_importo_pf := 0;
            w_tipo_calcolo := '';
            w_importo_base := 0;
            w_sgravi_base  := 0;
            w_importo_pv_base := 0;
            w_importo_pf_base := 0;
      END;
   end if;
   dbms_output.put_line('IRA - Importo: '||to_char(w_importo)||' Sgravi: '||w_sgravi||' Importo_pv: '||w_importo_pv||' Importo pf: '||w_importo_pf);
   --if w_dal != to_date('01012016','ddmmyyyy') then
   --    raise_application_error(-20099,'IRA - Importo: '||to_char(w_importo)||' Sgravi: '||w_sgravi||' Importo_pv: '||w_importo_pv||' Importo pf: '||w_importo_pf||' cessato '||w_se_cessato);
   --end if;
   IF w_tipo_calcolo is null THEN
      w_importo := 0;
      w_sgravi  := 0;
      w_importo_pv := 0;
      w_importo_pf := 0;
      w_importo_base := 0;
      w_sgravi_base  := 0;
      w_importo_pv_base := 0;
      w_importo_pf_base := 0;
      BEGIN  -- Determino il tipo_calcolo anche per soggetti che non sono andati a ruolo nell'acconto (segnalato da Pontassieve - 29/10/13) AB
         select max(ruol.tipo_calcolo),max(ruol.ruolo)
           into w_tipo_calcolo,w_ruolo_acconto
           from ruoli ruol
          where nvl(ruol.tipo_emissione,'T')   = 'A'
            and ruol.tipo_ruolo       = 1
            and ruol.invio_consorzio is not null
            and ruol.anno_ruolo       = p_anno
            and ruol.tipo_tributo||'' = p_titr
        ;
      EXCEPTION
         WHEN OTHERS THEN
             w_tipo_calcolo := '';
      END;
   END IF;
   --dbms_output.put_line('Ogpr: '||p_ogpr||', Importo '|| w_importo||' sgravi '||w_sgravi);
   w_importo       := round(nvl(w_importo,0) - nvl(w_sgravi,0),2);
   p_importo       := w_importo;
   p_importo_pv    := round(w_importo_pv,2);
   p_importo_pf    := round(w_importo_pf,2);
   p_tipo_calcolo  := w_tipo_calcolo;
   p_ruolo_acconto := w_ruolo_acconto;
--
   if nvl(p_flag_tariffa_base,'N') = 'S' then
      w_importo_base       := round(nvl(w_importo_base,0) - nvl(w_sgravi_base,0),2);
      p_importo_base       := w_importo_base;
      p_importo_pv_base    := round(w_importo_pv_base,2);
      p_importo_pf_base    := round(w_importo_pf_base,2);
   else
      p_importo_base       := to_number(null);
      p_importo_pv_base    := to_number(null);
      p_importo_pf_base    := to_number(null);
   end if;
END;
/* End Procedure: IMPORTI_RUOLO_ACCONTO */
/

