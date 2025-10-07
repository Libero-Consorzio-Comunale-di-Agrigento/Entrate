--liquibase formatted sql 
--changeset abrandolini:20250326_152423_importi_ruolo_totale stripComments:false runOnChange:true 
 
create or replace procedure IMPORTI_RUOLO_TOTALE
/******************************************************************************
 Rev. Data       Autore Descrizione
 ---- ---------- ------ -----------------------------------------------------
 9    18/09/2018 VD     Modificata selezione importi: ora vengono riproporzionati
                        al periodo anche la quota fissa e la quota variabile.
 3    21/06/2017 VD     Calcolo importi gia' andati a ruolo: nel caso in
                        cui la data di cessazione dell'oggetto su OGCO sia
                        nulla, se il ruolo e' gestito a giorni si considera
                        come data di confronto l'ultimo giorno del mese di
                        fine ruolo; se invece il ruolo e' gestito a mesi,
                        si considera il 16 del mese di fine ruolo.
                        Aggiunto test su flag_annullamento null anche nella
                        query che ricerca l'eventuale cessazione (cfr.
                        modifica gia' effettuata su IMPORTO_RUOLO_ACCONTO)
 2    19/07/2016 AB     Nella determinazione dello sgravio ho sostituito i
                        giorni_sgravio con i giorni_ruolo, fatte diverse prove
                        nella importi_ruolo_acconto.(modifica portata anche qui
                        anche se sembra non venga mai utilizzata)
 1    06/07/2016 AB     Gestito w_gg_anno contentente i gg dell'anno
                        sulla base dell'ultimo giorno del mese di Febbraio
******************************************************************************/
(p_ruolo                 number
,p_cf                    varchar2
,p_anno                  number
,p_dal                   date
,p_al                    date
,p_titr                  varchar2
,p_calcolo_giorni_magg   number
,p_ogpr                  number
,p_norm                  varchar2
,p_importo       in out  number
,p_importo_pv    in out  number
,p_importo_pf    in out  number
,p_magg_tares_scalare in out  number)
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
w_ruolo_precedente       number;
w_conta_ruco             number;
w_conta_var              number;
w_magg_tares             number;
w_gg_anno                number;
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
         into w_data_emissione_ruolo, w_ruolo_precedente
         from ruoli           ruol
            , oggetti_imposta ogim
            , oggetti_pratica ogpr
        where ogim.cod_fiscale      = p_cf
          and ogpr.oggetto_pratica  = ogim.oggetto_pratica
          and nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
                                       = p_ogpr
          and ogim.ruolo = ruol.ruolo
          and ruol.tipo_emissione   = 'T'
          and ruol.invio_consorzio is not null
          and ruol.anno_ruolo       = p_anno
          ;
   EXCEPTION
      WHEN OTHERS THEN
         w_data_emissione_ruolo := null;
   END;
-- dbms_output.put_line('tipo_calcolo Inizio '||w_tipo_calcolo);
   BEGIN
     --
     -- (VD - 21/06/2017): aggiunta condizione di where per escludere
     --                    pratiche annullate
     --
     select prtr.tipo_evento, prtr.data
       into w_tiev, w_data_cess
       from pratiche_tributo prtr
          , oggetti_pratica ogpr
          , oggetti_contribuente ogco
      where ogpr.pratica = prtr.pratica
        and ogpr.oggetto_pratica_rif = p_ogpr
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
   w_al := p_al;
   w_dal := nvl(p_dal,to_date('0101'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'));
--
-- (VD - 05/12/2014: Modificata gestione date periodo per calcolo acconti:
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
                                            = p_ogpr
               and ogim.ruolo = w_ruolo_precedente
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
             and ogpr.oggetto_pratica_rif = p_ogpr
             and ogpr.oggetto_pratica = ogco.oggetto_pratica
             and prtr.tipo_evento      = 'V'
             and ogco.data_decorrenza > to_date('01/01/'||p_anno,'dd/mm/yyyy')
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
            ,sum(decode(ruol.importo_lordo,'S',nvl(sgra.importo,0) - nvl(sgra.addizionale_eca,0)
                                                                   - nvl(sgra.maggiorazione_eca,0)
                                                                   - nvl(sgra.maggiorazione_tares,0)
                                                                   - nvl(sgra.addizionale_pro,0)
                                                                   - nvl(sgra.iva,0)
                                              ,nvl(sgra.importo,0)
                       ) * least(1,
                            decode(w_se_cessato
                                 ,1,1
                                 ,f_periodo(p_anno,w_dal,w_al,'P',p_titr,p_norm)
                     --    * 12 / nvl(sgra.mesi_sgravio,12)
                                  * decode(w_mesi_calcolo
                                          ,0,w_gg_anno / decode(ruco.giorni_ruolo  --sgra.giorni_sgravio AB 19/07/16
                                                         ,null, decode(nvl(sgra.mesi_sgravio,nvl(ruco.mesi_ruolo,12))
                                                                      ,12,w_gg_anno
                                                                      ,nvl(sgra.mesi_sgravio,nvl(ruco.mesi_ruolo,12)) * 30
                                                                      )
                                                                       ,ruco.giorni_ruolo -- sgra.giorni_sgravio AB 19/07/16
                                                         )
                                          ,12 / nvl(sgra.mesi_sgravio,nvl(ruco.mesi_ruolo,12))
                                          )
                                 )
                  )
                )
            ,sum(ogim.importo_pv  * least(1,
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
                                )
                )
            ,max(ruol.tipo_calcolo)
            ,decode(p_calcolo_giorni_magg
                                 ,null,decode(nvl(w_se_cessato,0),1,1,F_COEFF_GG(p_anno,w_dal,w_al)),1)*
                                 sum(nvl(ogim.maggiorazione_tares,0)) - sum(nvl(sgra.maggiorazione_tares,0))
        into w_importo
            ,w_sgravi
            ,w_importo_pv
            ,w_importo_pf
            ,w_tipo_calcolo
            ,w_magg_tares
        from oggetti_pratica       ogpr
            ,oggetti_imposta       ogim
            ,oggetti_contribuente  ogco
            ,(select ruolo, cod_fiscale, sequenza,
                 max (nvl (mesi_sgravio,0))         mesi_sgravio,
                 max (nvl (giorni_sgravio,0))       giorni_sgravio,
                 sum (nvl (importo, 0))             importo,
                 sum (nvl (maggiorazione_tares, 0)) maggiorazione_tares,
                 sum (nvl (maggiorazione_eca, 0))   maggiorazione_eca,
                 sum (nvl (addizionale_eca, 0))     addizionale_eca,
                 sum (nvl (addizionale_pro, 0))     addizionale_pro,
                 sum (nvl (iva, 0))                 iva
                from sgravi
               where cod_fiscale = p_cf
                 and motivo_sgravio <> 99
               group by ruolo, cod_fiscale, sequenza) sgra
            ,ruoli_contribuente    ruco
            ,ruoli                 ruol
         --   ,oggetti_validita      ogva
       where ruol.ruolo            = ruco.ruolo
         and ogim.oggetto_imposta  = ruco.oggetto_imposta
         and ogim.cod_fiscale      = p_cf
         and ogpr.oggetto_pratica  = ogim.oggetto_pratica
         and nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
                                   = p_ogpr
--         and ogva.oggetto_pratica  = ogpr.oggetto_pratica
--         and ogva.cod_fiscale      = ogco.cod_fiscale
--         and ogva.dal              = ogco.data_decorrenza
--         and nvl(ogva.dal,to_date('0101'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'))
--           = nvl(ogco.data_decorrenza,to_date('0101'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'))
         and ogco.cod_fiscale      = ogim.cod_fiscale
         and ogco.oggetto_pratica  = ogim.oggetto_pratica
         and w_dal                >= nvl(ogco.data_decorrenza,to_date('01011900','ddmmyyyy'))
         and w_dal                <
         --
         -- (VD - 21/06/2017): nel caso in cui la data cessazione sia nulla, se il ruolo è gestito a giorni,
         --                    si considera come data di fine l'ultimo giorno del mese di fine ruolo;
         --                    se il ruolo è gestito a mesi, si considera il 16 del mese di fine ruolo.
         --
                nvl(ogco.data_cessazione
                   ,decode(w_mesi_calcolo
                          ,0,last_day(to_date(lpad(nvl(ruco.a_mese,12),2,'0')||lpad(p_anno,4,'0'),'mmyyyy'))
                            ,to_date(to_char('16'||lpad(nvl(ruco.a_mese,12),2,'0')||lpad(p_anno,4,'0')),'ddmmyyyy')
                          )
                   )
--                nvl(ogco.data_cessazione,to_date('16'||lpad(nvl(ruco.a_mese,12),2,'0')||lpad(p_anno,4,'0'),'ddmmyyyy'))
--                nvl(ogco.data_cessazione,to_date(to_char('16'||lpad(nvl(ruco.a_mese,12),2,'0')||lpad(p_anno,4,'0')),'ddmmyyyy'))
--                nvl(ogco.data_cessazione,to_date(to_char(last_day(to_date(lpad(nvl(ruco.a_mese,12),2,'0')||lpad(p_anno,4,'0'),'mmyyyy')),'dd')||lpad(nvl(ruco.a_mese,12),2,'0')||lpad(p_anno,4,'0'),'ddmmyyyy'))
--                nvl(ogco.data_cessazione,to_date('31'||lpad(to_char(nvl(ruco.da_mese,12)),2,'0')||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'))
--                nvl(nvl(ogco.data_cessazione,w_al),to_date('3112'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'))
--                nvl(ogva.al,to_date('3112'||lpad(to_char(p_anno),4,'0'),'ddmmyyyy'))
         and ruco.ruolo            = ogim.ruolo
         and ruol.tipo_emissione   = 'T'
         and ruol.ruolo            <> p_ruolo
         and ruol.invio_consorzio is not null
         and ruol.anno_ruolo       = p_anno
         and ruco.cod_fiscale      = p_cf
         and ruol.tipo_tributo||'' = p_titr
         and sgra.ruolo        (+) = ruco.ruolo
         and sgra.cod_fiscale  (+) = ruco.cod_fiscale
         and sgra.sequenza     (+) = ruco.sequenza
--         and sgra.motivo_sgravio(+) <> 99
--         and sgra.FLAG_AUTOMATICO  (+) = 'S'  -- tolto il 21/10/2013 per evitare di non trattare quelli manuali a Rivoli
      ;
   EXCEPTION
      WHEN OTHERS THEN
         w_importo := 0;
         w_sgravi  := 0;
         w_importo_pv := 0;
         w_importo_pf := 0;
         w_tipo_calcolo := '';
   END;
--RAISE_APPLICATION_ERROR(-20099,'Importo '|| w_importo||' sgravi '||w_sgravi);
   w_importo := round(nvl(w_importo,0) - nvl(w_sgravi,0),2);
   p_importo       := w_importo;
   p_importo_pv    := round(w_importo_pv,2);
   p_importo_pf    := round(w_importo_pf,2);
   p_magg_tares_scalare := w_magg_tares;
END;
/* End Procedure: IMPORTI_RUOLO_TOTALE */
/

