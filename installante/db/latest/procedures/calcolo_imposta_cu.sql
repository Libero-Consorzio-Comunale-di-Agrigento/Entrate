--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_imposta_cu stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_IMPOSTA_CU
(a_anno                 IN number
,a_cod_fiscale          IN varchar2
,a_tipo_tributo         IN varchar2
,a_ogpr                 IN number
,a_utente               IN varchar2
,a_flag_normalizzato    IN char
,a_flag_richiamo        IN varchar2
,a_chk_rate             IN number
,a_limite               IN number
,a_pratica              IN number default null
,a_ravvedimento         IN varchar2 default null
,a_gruppo_tributo       IN varchar2 default null
,a_scadenza_rata_1      IN date default null
,a_scadenza_rata_2      IN date default null
,a_scadenza_rata_3      IN date default null
,a_scadenza_rata_4      IN date default null
)
/******************************************************************************
 NOME:        CALCOLO_IMPOSTA_CU
 DESCRIZIONE: Calcola le imposte

 ANNOTAZIONI: Personalizzazione specifica per Canone Unico
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 001   19/03/2021  RV      Prima emissione, basato su CALCOLO_IMPOSTA (VD)
 002   21/04/2021  RV      Prima release "Ufficiale" x Bellumo
 003   30/04/2021  RV      Rivisto meccanismo gestione rate
 004   27/05/2021  RV      Modificato rimozione oggetti_imposta e rate_imposta
                           esistenti per CUNI + ICP + TOSAP
 005   13/07/2021  RV      Modificato cursore sel_ogim per
                           ogva.anno : extract(year from ogva.dal)
 006   24/02/2022  VD      Aggiunto trattamento per calcolo imposta su
                           ravvedimento
 007   04/04/2022  RV      Normalizzato filtri obsoleti per includere dati
                           residui ICP e TOSAP
 008   16/05/2022  VD      #56719
                           Modificato richiamo procedure per inserimento
                           dovuti in DEPAG: ora si utilizza la funzione
                           INSERIMENTO_DOVUTI_CU del package standard
                           PAGONLINE_TR4 (e non INSERIMENTO_DOVUTI del package
                           PAGONLINE_TR4_CU).
 009   27/10/2023  RV      Personalizzazione calcolo per Provincia di Frosinone
 010   10/07/2023  RV      #54732
                           Aggiunto parametri a_gruppo_tributo e a_scadenza_rata_x
 011   07/02/2024  RV      #69834
                           Escludere sempre dal calcolo gli oggetti nati il 31/12/anno_calcolo
 012   04/04/2024  RV      #55403
                           Se calcolo globale esclude quelli nati entro l'anno di calcolo, 
                           che vanno calcolati da soli per pratica
******************************************************************************/
IS
errore                     exception;
w_errore                   varchar2(2000);
w_importo                  number;
w_importo_min              number;
--w_conta                    number; --MAI USATO
w_tariffe                  varchar2(2000) := '';
w_periodo                  number;
w_limite                   number := -0.01;
w_fase_euro                number;
w_cod_fiscale              varchar2(16);
w_tipo_occupazione         varchar2(1);
w_oggetto_imposta          number;
w_rata_imposta             number;
w_comune                   varchar2(6);
w_importo_pf               number;
w_importo_pv               number;
w_stringa_familiari        varchar2(2000);
w_dettaglio_ogim           varchar2(2000);
w_dettaglio_faog           varchar2(2000);
w_giorni_ruolo             number;
--
w_data_scadenza            date;
--
w_pagonline                varchar2(1);
w_result                   varchar2(6);
-- (RV - 21/04/2021): caso speciale per calcolo frazionamento giorni
w_tariffa_spec_fraz_giorni number := 201;
-- (VD - 18/06/2020): modifiche per Belluno
-- (RV - 29/04/2021): non usato per CU
w_cod_belluno              varchar2(6) := '999999'; --'108009'; --'025006';
w_cf_prec                  varchar2(16) := '*';
w_pratica_prec             number := 0;
w_tot_versato              number;
-- (RV - 20/10/2023): Personalizzazione Frosinone
w_cod_frosinone            varchar2(6) := '060038';
w_perc_detraz              number;
w_consistenza              number;
w_perc_possesso            number;

--
-- Cursore che viene utilizzato per memorizzare provvisoriamente nei versamenti
-- su oggetto imposta, l`oggetto pratica a cui si riferisce per dar modo di potere
-- ricalcolare l`imposta anche in presenza di versamenti.
--
cursor sel_vers_ogpr
(a_anno                    number
,a_cod_fiscale             varchar2
,a_tipo_tributo            varchar2
,a_ogpr                    number
) is
select vers.sequenza
      ,vers.cod_fiscale
      ,vers.tipo_tributo
      ,vers.oggetto_imposta
      ,vers.anno
      ,ogim.oggetto_pratica
  from oggetti_imposta ogim
      ,versamenti      vers
 where ogim.oggetto_imposta       = vers.oggetto_imposta
   and ogim.ruolo                 is null
   and ogim.flag_calcolo          = 'S'
   and vers.cod_fiscale           like a_cod_fiscale
   and vers.anno+0                = a_anno
   and vers.tipo_tributo          = a_tipo_tributo
   and ((a_pratica is null and
         ogim.oggetto_pratica     between nvl(a_ogpr,0)
                                      and decode(nvl(a_ogpr,0),0,9999999999,nvl(a_ogpr,0))) or
        (a_pratica is not null and
         ogim.oggetto_pratica in (select ogpr.oggetto_pratica
                                    from oggetti_pratica ogpr
                                   where ogpr.pratica = a_pratica)))
 union all
select vers.sequenza
      ,vers.cod_fiscale
      ,vers.tipo_tributo
      ,vers.oggetto_imposta
      ,vers.anno
      ,ogim.oggetto_pratica
  from rate_imposta    raim
      ,oggetti_imposta ogim
      ,versamenti      vers
 where ogim.oggetto_imposta       = raim.oggetto_imposta
   and raim.rata_imposta          = vers.rata_imposta
   and ogim.ruolo                 is null
   and ogim.flag_calcolo          = 'S'
   and vers.cod_fiscale           like a_cod_fiscale
   and vers.anno+0                = a_anno
   and vers.tipo_tributo          = a_tipo_tributo
   and ((a_pratica is null and
         ogim.oggetto_pratica     between nvl(a_ogpr,0)
                                      and decode(nvl(a_ogpr,0),0,9999999999,nvl(a_ogpr,0))) or
        (a_pratica is not null and
         ogim.oggetto_pratica in (select ogpr.oggetto_pratica
                                    from oggetti_pratica ogpr
                                   where ogpr.pratica = a_pratica)))
;
--
-- Cursore che permette, terminato il calcolo, di riallacciare i versamenti
-- ai nuovi oggetti imposta degli oggetti pratica memorizzati (se ancora presenti).
--
cursor sel_vers
(a_anno                    number
,a_cod_fiscale             varchar2
,a_tipo_tributo            varchar2
) is
select vers.cod_fiscale
      ,vers.anno
      ,vers.tipo_tributo
      ,vers.sequenza
      ,ogim.oggetto_imposta
      ,vers.rata
  from oggetti_imposta ogim
      ,versamenti      vers
 where ogim.oggetto_pratica (+)  = vers.ogpr_ogim
   and ogim.anno            (+)  = a_anno
   and vers.ogpr_ogim           is not null
   and vers.cod_fiscale       like a_cod_fiscale
   and vers.tipo_tributo         = a_tipo_tributo
   and vers.anno+0               = a_anno
   and ogim.oggetto_pratica (+) >= nvl(a_ogpr,0)
   and ogim.oggetto_pratica (+) <= nvl(a_ogpr,99999999999)
;
--
-- Cursore di selezione dei contribuenti e oggetti soggetti al calcolo imposta.
-- (VD - 24/02/2022): gestione calcolo imposta per ravvedimento.
--                    Aggiunta union per selezionare gli oggetti della
--                    pratica di ravvedimento emessa
--
CURSOR sel_ogpr
(a_anno              number
,a_cod_fiscale       varchar2
,a_tipo_tributo      varchar2
,a_tipo_occupazione  varchar2
,a_data_emissione    date
,a_ogpr              number
,a_pratica           number
,a_ravvedimento      varchar2
,a_gruppo_tributo     varchar2
) IS
-- Calcolo di imposta standard
select ogva.cod_fiscale
      ,ogpr.oggetto_pratica
      ,ogva.dal data_decorrenza
      ,ogva.al data_cessazione
      ,ogpr.oggetto
      ,ogpr.tributo
      ,ogpr.categoria
      ,ogpr.consistenza
      ,ogpr.quantita
      ,ogpr.tipo_tariffa
      ,ogpr.numero_familiari
      ,tari.tariffa_quota_fissa
      ,tari.perc_riduzione
      ,tari.tariffa
      ,tari.limite
      ,tari.tariffa_superiore
      ,case when nvl(instr(tari.descrizione,'(mq.)'),0) > 0 then 1 else 0 end as tariffa_al_mq
      ,cast(round(nvl(tari.riduzione_quota_fissa,0),0) as integer) as tariffa_secondaria
      ,cast(round(nvl(tari.riduzione_quota_variabile,0),0) as integer) as tariffa_speciale
      ,nvl(cotr.conto_corrente,titr.conto_corrente) conto_corrente
      ,ogco.perc_possesso
      ,ogco.perc_detrazione
      ,ogco.flag_ab_principale
      ,cotr.flag_ruolo
      ,cate.flag_giorni
      ,ogva.tipo_occupazione
      ,ogva.tipo_tributo
      ,decode(ogva.anno,a_anno,ogpr.data_concessione,null) data_concessione
      ,prtr.anno
  from tariffe              tari
      ,tipi_tributo         titr
      ,codici_tributo       cotr
      ,categorie            cate
      ,pratiche_tributo     prtr
      ,oggetti_pratica      ogpr
      ,oggetti_contribuente ogco
      ,oggetti_validita     ogva
 where decode(cotr.flag_ruolo
             ,'S', nvl(to_number(to_char(ogva.data,'yyyy')),a_anno)
                 , a_anno
             )                <= a_anno
   and nvl(to_number(to_char(ogva.dal,'yyyy')),a_anno)
                              <= a_anno
   and nvl(to_number(to_char(ogva.al,'yyyy')),a_anno)
                               >= a_anno
   and nvl(ogva.data,nvl(a_data_emissione
                        ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
                        )
          )                    <=
       nvl(a_data_emissione,nvl(ogva.data
                               ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
                               )
          )
-- RV (07/02/2024) : #69834 escludere sempre dal calcolo gli oggetti nati il 31/12/anno_calcolo
   and nvl(to_char(ogva.dal,'yyyymmdd'),'19000101') <> lpad(to_char(a_anno),4,'0')||'1231'
-- RV (04/04/2024) : #54732 esclude i 'P' nati entro l'anno di calcolo (da fare per pratica)
   and ((a_pratica is not null) or 
        (nvl(to_char(ogva.dal,'yyyymmdd'),'19000101') < lpad(to_char(a_anno),4,'0')||'0101'))
   and not exists
      (select 'x'
         from pratiche_tributo prtr
        where prtr.tipo_pratica||''    = 'A'
          and prtr.anno               <= a_anno
          and prtr.pratica             = ogpr.pratica
          and (    trunc(sysdate) - nvl(prtr.data_notifica,trunc(sysdate))
                                       < 60
               and flag_adesione      is NULL
               or  prtr.anno           = a_anno
              )
          and prtr.flag_denuncia       = 'S'
      )
   and tari.tipo_tariffa         = ogpr.tipo_tariffa
   and tari.categoria+0          = ogpr.categoria
   and tari.tributo              = ogpr.tributo
   and nvl(tari.anno,0)          = a_anno
   and titr.tipo_tributo         = cotr.tipo_tributo
   and cotr.tributo              = ogpr.tributo
   and cotr.flag_ruolo          is null
   and ((a_gruppo_tributo is null) or
        ((a_gruppo_tributo is not null) and (cotr.gruppo_tributo = a_gruppo_tributo))
   )
   and cate.tributo              = ogpr.tributo
   and cate.categoria            = ogpr.categoria
   and ogpr.flag_contenzioso    is null
   and ogpr.oggetto_pratica      = ogva.oggetto_pratica
   and ogva.tipo_occupazione  like a_tipo_occupazione
   and ogva.cod_fiscale       like a_cod_fiscale
   and ogva.tipo_tributo||''     = a_tipo_tributo
   and ogco.oggetto_pratica      = ogva.oggetto_pratica
   and ogco.cod_fiscale          = ogva.cod_fiscale
   and prtr.pratica              = ogpr.pratica
   and nvl(prtr.stato_accertamento,'D')
                                 = 'D'
   and (    ogva.tipo_occupazione
                                 = 'T'
        or  a_tipo_tributo      in ('TARSU','ICIAP','ICI')
        or  ogva.tipo_occupazione
                                 = 'P'
        and a_tipo_tributo      in ('TOSAP','ICP','CUNI')
        and not exists
           (select 1
              from oggetti_validita   ogv2
             where ogv2.cod_fiscale   = ogva.cod_fiscale
               and ogv2.oggetto_pratica_rif
                                 = ogva.oggetto_pratica_rif
               and ogv2.tipo_tributo||''
                                 = ogva.tipo_tributo
               and ogv2.tipo_occupazione
                                 = 'P'
               and nvl(to_number(to_char(ogv2.data,'yyyy'))
                      ,decode(ogv2.tipo_pratica,'A',a_anno - 1,a_anno)
                      )         <= decode(ogv2.tipo_pratica,'A',a_anno - 1,a_anno)
               and nvl(to_number(to_char(ogv2.dal,'yyyy'))
                      ,decode(ogv2.tipo_pratica,'A',a_anno - 1,a_anno)
                      )         <= decode(ogv2.tipo_pratica,'A',a_anno - 1,a_anno)
               and nvl(to_number(to_char(ogv2.al,'yyyy'))
                      ,decode(ogv2.tipo_pratica,'A',a_anno - 1,a_anno)
                      )         >= decode(ogv2.tipo_pratica,'A',a_anno - 1,a_anno)
               and nvl(ogv2.data
                      ,nvl(a_data_emissione
                          ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
                          )
                      )         <=
                   nvl(a_data_emissione
                      ,nvl(ogv2.data
                          ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
                          )
                      )
               and ogv2.dal      > ogva.dal
           )
       )
   and ((a_pratica is null and
         ogpr.oggetto_pratica     between nvl(a_ogpr,0)
                                      and decode(nvl(a_ogpr,0),0,9999999999,a_ogpr)) or
        (a_pratica is not null and
         ogpr.oggetto_pratica in (select oggetto_pratica
                                    from oggetti_pratica
                                   where pratica = a_pratica)))
   and nvl(a_ravvedimento,'N') <> 'S'
 union
-- Calcolo di imposta per ravvedimento
select ogco.cod_fiscale
      ,ogpr.oggetto_pratica
      ,ogco.data_decorrenza
      ,ogco.data_cessazione
      ,ogpr.oggetto
      ,ogpr.tributo
      ,ogpr.categoria
      ,ogpr.consistenza
      ,ogpr.quantita
      ,ogpr.tipo_tariffa
      ,ogpr.numero_familiari
      ,tari.tariffa_quota_fissa
      ,tari.perc_riduzione
      ,tari.tariffa
      ,tari.limite
      ,tari.tariffa_superiore
      ,case when nvl(instr(tari.descrizione,'(mq.)'),0) > 0 then 1 else 0 end as tariffa_al_mq
      ,cast(round(nvl(tari.riduzione_quota_fissa,0),0) as integer) as tariffa_secondaria
      ,cast(round(nvl(tari.riduzione_quota_variabile,0),0) as integer) as tariffa_speciale
      ,nvl(cotr.conto_corrente,titr.conto_corrente) conto_corrente
      ,ogco.perc_possesso
      ,ogco.perc_detrazione
      ,ogco.flag_ab_principale
      ,cotr.flag_ruolo
      ,cate.flag_giorni
      ,ogpr.tipo_occupazione
      ,prtr.tipo_tributo
      ,decode(ogco.anno,a_anno,ogpr.data_concessione,null) data_concessione
      ,prtr.anno
  from tariffe              tari
      ,tipi_tributo         titr
      ,codici_tributo       cotr
      ,categorie            cate
      ,pratiche_tributo     prtr
      ,oggetti_pratica      ogpr
      ,oggetti_contribuente ogco
 where tari.tipo_tariffa         = ogpr.tipo_tariffa
   and tari.categoria+0          = ogpr.categoria
   and tari.tributo              = ogpr.tributo
   and nvl(tari.anno,0)          = a_anno
   and titr.tipo_tributo         = cotr.tipo_tributo
   and cotr.tributo              = ogpr.tributo
   -- (VD - 03/03/2022): in caso di ravvedimento non interessa se il calcolo
   --                    massivo e' disattivato oppure no
   --and cotr.flag_ruolo          is null
   and cate.tributo              = ogpr.tributo
   and cate.categoria            = ogpr.categoria
   and ogpr.flag_contenzioso    is null
   and ogpr.oggetto_pratica      = ogco.oggetto_pratica
   and ogpr.tipo_occupazione  like a_tipo_occupazione
   and ogco.cod_fiscale       like a_cod_fiscale
   and prtr.tipo_tributo||''     = a_tipo_tributo
   and prtr.pratica              = ogpr.pratica
   and prtr.pratica              = a_pratica
   and nvl(a_ravvedimento,'N')   = 'S'
 order by 1,2,3
;
--
-- Cursore per effettuare le eventuali rateizzazioni.
-- Le imposte vengono Raggruppate o per Contribuente o per Utenza secondo quanto
-- memorizzato nei parametri di input. Se pero` un oggetto imposta ha l`anno
-- uguale a quello della pratica, la rateizzazione e` sempre per utenza.
-- Nell`ambito poi delle singole situazioni, ulteriori raggruppamenti vengono
-- fatti per Conto Corrente e Decorrenza al fine di ottenere, per uno stesso
-- raggruppamento, lo stesso numero di rate e la stessa destinazione.
-- (VD - 24/02/2022): gestione calcolo imposta su ravvedimento.
--                    La rateizzazione viene eseguita sempre per oggetto_imposta.
--
cursor sel_ogim
(a_anno               number
,a_tipo_tributo       varchar2
,a_gruppo_tributo     varchar2
,a_chk_rate           number
,a_importo_min        number
,a_ravvedimento       varchar2
) is
select ogim.cod_fiscale
      ,greatest(nvl(ogva.dal,to_date('2222222','j'))
               ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
               ) data_decorrenza
      ,nvl(cotr.conto_corrente,titr.conto_corrente) conto_corrente
      --L'oggetto imposta ci serve sempre per gestione delle rate per gruppo_tributo
      ,decode(nvl(a_ravvedimento,'N')
             ,'S',ogim.oggetto_imposta
             ,decode(extract(year from ogva.dal)
                    ,a_anno,ogim.oggetto_imposta
                           ,decode(a_chk_rate
                                  ,TR4PACKAGE.RATE_SINGOLO_OGIM,ogim.oggetto_imposta
                                                               ,to_number(null)
                                  )
                    )
             ) oggetto_imposta
      ,decode(extract(year from ogva.dal),a_anno,ogpr.data_concessione,null) data_concessione
      ,nvl(sum(nvl(ogim.imposta,0)),0) imposta
      ,nvl(tari.flag_no_depag,cate.flag_no_depag) flag_no_depag
  from oggetti_validita ogva
      ,oggetti_pratica  ogpr
      ,codici_tributo   cotr
      ,tipi_tributo     titr
      ,oggetti_imposta  ogim
      ,categorie        cate
      ,tariffe          tari
 where ogva.oggetto_pratica        = ogim.oggetto_pratica
   and ogva.cod_fiscale            = ogim.cod_fiscale
   and ogpr.oggetto_pratica        = ogim.oggetto_pratica
   and cotr.tributo                = ogpr.tributo
   and ((a_gruppo_tributo is null) or
       ((a_gruppo_tributo is not null) and (cotr.gruppo_tributo = a_gruppo_tributo))
   )
   and ogpr.tributo                = cate.tributo
   and ogpr.categoria              = cate.categoria
   and ogpr.tributo                = tari.tributo
   and ogpr.categoria              = tari.categoria
   and ogpr.tipo_tariffa           = tari.tipo_tariffa
   and tari.anno                   = a_anno
   and titr.tipo_tributo           = a_tipo_tributo
   and ogim.utente                 = '###'
 group by
       ogim.cod_fiscale
      ,greatest(nvl(ogva.dal,to_date('2222222','j'))
               ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
               )
      ,decode(extract(year from ogva.dal),a_anno,ogpr.data_concessione,null)
      ,nvl(cotr.conto_corrente,titr.conto_corrente)
      ,decode(nvl(a_ravvedimento,'N')
             ,'S',ogim.oggetto_imposta
             ,decode(extract(year from ogva.dal)
                    ,a_anno,ogim.oggetto_imposta
                           ,decode(a_chk_rate
                                  ,TR4PACKAGE.RATE_SINGOLO_OGIM,ogim.oggetto_imposta
                                                               ,to_number(null)
                                  )
                    )
             )
      ,nvl(tari.flag_no_depag,cate.flag_no_depag)
having nvl(sum(nvl(ogim.imposta,0)),0)
                                 >= a_importo_min
 order by 1,2,3,4
;
-------------------------------------------------------------------------------
-- PERSONALIZZAZIONI BELLUNO: SELEZIONE OGGETTI IMPOSTA PER RATEAZIONE
-- PER PRATICA E PER CONTRIBUENTE SEPARATAMENTE AI FINI DEL PASSAGGIO
-- A DEPAG
-------------------------------------------------------------------------------
cursor sel_ogim_contribuente
(a_anno              number
,a_tipo_tributo      varchar2
,a_gruppo_tributo    varchar2
,a_chk_rate          number
,a_importo_min       number
) is
select ogim.cod_fiscale
      ,greatest(nvl(ogva.dal,to_date('2222222','j'))
               ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
               ) data_decorrenza
      ,nvl(cotr.conto_corrente,titr.conto_corrente) conto_corrente
      ,decode(a_chk_rate
             ,TR4PACKAGE.RATE_SINGOLO_OGIM,ogim.oggetto_imposta
                                          ,to_number(null)
             ) oggetto_imposta
      ,to_date(null) data_concessione
      ,nvl(sum(nvl(ogim.imposta,0)),0) imposta
      ,nvl(tari.flag_no_depag,cate.flag_no_depag) flag_no_depag
  from oggetti_validita ogva
      ,oggetti_pratica  ogpr
      ,codici_tributo   cotr
      ,tipi_tributo     titr
      ,oggetti_imposta  ogim
      ,categorie        cate
      ,tariffe          tari
 where ogva.oggetto_pratica        = ogim.oggetto_pratica
   and ogva.cod_fiscale            = ogim.cod_fiscale
   and ogpr.oggetto_pratica        = ogim.oggetto_pratica
   and cotr.tributo                = ogpr.tributo
   and ((a_gruppo_tributo is null) or
        ((a_gruppo_tributo is not null) and (cotr.gruppo_tributo = a_gruppo_tributo))
   )
   and ogpr.tributo                = cate.tributo
   and ogpr.categoria              = cate.categoria
   and ogpr.tributo                = tari.tributo
   and ogpr.categoria              = tari.categoria
   and ogpr.tipo_tariffa           = tari.tipo_tariffa
   and tari.anno                   = a_anno
   and titr.tipo_tributo           = a_tipo_tributo
   and ogva.anno                   < a_anno
   and ogim.utente                 = '###'
 group by
       ogim.cod_fiscale
      ,greatest(nvl(ogva.dal,to_date('2222222','j'))
               ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
               )
      ,nvl(cotr.conto_corrente,titr.conto_corrente)
      ,decode(a_chk_rate
             ,TR4PACKAGE.RATE_SINGOLO_OGIM,ogim.oggetto_imposta
                                          ,to_number(null)
             )
      ,nvl(tari.flag_no_depag,cate.flag_no_depag)
having nvl(sum(nvl(ogim.imposta,0)),0)
                                 >= a_importo_min
 order by 1,2,3,4
;
cursor sel_pratiche_da_rateizz
(a_anno              number
,a_tipo_tributo      varchar2
,a_gruppo_tributo    varchar2
,a_chk_rate          number
,a_importo_min       number
) is
select ogva.cod_fiscale
     , ogva.pratica
     , sum(ogim.imposta)
  from oggetti_validita ogva
     , oggetti_pratica  ogpr
     , oggetti_imposta  ogim
 where ogva.oggetto_pratica        = ogim.oggetto_pratica
   and ogva.cod_fiscale            = ogim.cod_fiscale
   and ogva.tipo_tributo||''       = a_tipo_tributo
   and ogpr.oggetto_pratica        = ogim.oggetto_pratica
   and ogva.anno                   = a_anno
   and ogim.utente                 = '###'
   and a_chk_rate                  > TR4PACKAGE.NO_RATE
 group by ogva.cod_fiscale, ogva.pratica
 having sum(imposta) > a_importo_min
;
cursor sel_ogim_pratica
(a_cod_fiscale  varchar2
,a_pratica      number
,a_anno         number
,a_tipo_tributo varchar2
,a_chk_rate     number
) is
select ogim.cod_fiscale
      ,ogpr.pratica
      ,greatest(nvl(ogva.dal,to_date('2222222','j'))
               ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
               ) data_decorrenza
      ,nvl(cotr.conto_corrente,titr.conto_corrente) conto_corrente
      ,ogim.oggetto_imposta
      ,ogpr.data_concessione
      ,nvl(sum(nvl(ogim.imposta,0)),0) imposta
      ,cate.flag_no_depag
  from oggetti_validita ogva
      ,oggetti_pratica  ogpr
      ,codici_tributo   cotr
      ,tipi_tributo     titr
      ,oggetti_imposta  ogim
      ,categorie        cate
 where ogva.cod_fiscale            = a_cod_fiscale
   and ogva.pratica                = a_pratica
   and ogva.anno                   = a_anno
   and ogva.oggetto_pratica        = ogim.oggetto_pratica
   and ogva.cod_fiscale            = ogim.cod_fiscale
   and ogpr.oggetto_pratica        = ogim.oggetto_pratica
   and cotr.tributo                = ogpr.tributo
   and ogpr.tributo                = cate.tributo
   and ogpr.categoria              = cate.categoria
   and titr.tipo_tributo           = a_tipo_tributo
   and ogim.utente                 = '###'
 group by
       ogim.cod_fiscale
      ,ogpr.pratica
      ,greatest(nvl(ogva.dal,to_date('2222222','j'))
               ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
               )
      ,ogpr.data_concessione
      ,nvl(cotr.conto_corrente,titr.conto_corrente)
      ,ogim.oggetto_imposta
      ,cate.flag_no_depag
 order by 1,2,3,4
;
-- (VD - 02/03/2022): cursore per rateizzazione pratica ravvedimento
cursor sel_ogim_pratica_ravv
(a_cod_fiscale  varchar2
,a_pratica      number
,a_anno         number
,a_tipo_tributo varchar2
,a_chk_rate     number
) is
select ogim.cod_fiscale
      ,ogpr.pratica
      ,greatest(nvl(ogco.data_decorrenza,to_date('2222222','j'))
               ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
               ) data_decorrenza
      ,nvl(cotr.conto_corrente,titr.conto_corrente) conto_corrente
      ,ogim.oggetto_imposta
      ,ogpr.data_concessione
      ,nvl(sum(nvl(ogim.imposta,0)),0) imposta
  from oggetti_contribuente ogco
      ,oggetti_pratica      ogpr
      ,codici_tributo       cotr
      ,tipi_tributo         titr
      ,oggetti_imposta      ogim
 where ogco.cod_fiscale            = a_cod_fiscale
   and ogpr.pratica                = a_pratica
   and ogpr.oggetto_pratica        = ogco.oggetto_pratica
   and ogco.cod_fiscale            = ogim.cod_fiscale
   and ogpr.oggetto_pratica        = ogim.oggetto_pratica
   and cotr.tributo                = ogpr.tributo
   and titr.tipo_tributo           = a_tipo_tributo
   and ogim.utente                 = '###'
 group by
       ogim.cod_fiscale
      ,ogpr.pratica
      ,greatest(nvl(ogco.data_decorrenza,to_date('2222222','j'))
               ,to_date('0101'||lpad(to_char(a_anno),4,'0'),'ddmmyyyy')
               )
      ,ogpr.data_concessione
      ,nvl(cotr.conto_corrente,titr.conto_corrente)
      ,ogim.oggetto_imposta
 order by 1,2,3,4
;
--
--    +--------------------------------------------------------------+
--    |                 C A L C O L O   I M P O S T A                |
--    +--------------------------------------------------------------+
--
BEGIN
   w_cod_fiscale := ' ';
   BEGIN
      select fase_euro
           , lpad(to_char(pro_cliente),3,'0')||lpad(to_char(com_cliente),3,'0')
        into w_fase_euro
           , w_comune
        from dati_generali
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         RAISE_APPLICATION_ERROR(-20999,'Mancano i Dati Generali');
   END;
   IF a_tipo_tributo = 'ICI' THEN
-- L`ultimo parametro che indica se si trattano o no i Ravvedimenti
-- viene posto = N in quanto i ravvedimenti chiamano direttamente
-- il calcolo imposta ICI e quindi non esiste il caso di richiamo
-- di detta procedura da questa per i ravvedimenti.
      CALCOLO_IMPOSTA_ICI(a_anno,a_cod_fiscale,a_utente,'N');
   ELSIF a_tipo_tributo = 'TASI' THEN
      CALCOLO_IMPOSTA_TASI(a_anno,a_cod_fiscale,a_utente,'N');
   ELSE
-- a_limite e` il limite minimo di rateizzazione se diverso dallo standard
-- e viene gestito solo da ICP, TARSU e TOSAP. Se non indicato, si applica lo standard.
      IF a_tipo_tributo = 'ICP' THEN
         if w_fase_euro = 1 then
            w_importo_min := nvl(a_limite,3000000);
         else
            w_importo_min := nvl(a_limite,1549);
         end if;
      ELSIF a_tipo_tributo = 'TOSAP' THEN
         if w_fase_euro = 1 then
            w_importo_min := nvl(a_limite,500000);
         else
            w_importo_min := nvl(a_limite,258);
         end if;
      ELSIF a_tipo_tributo = 'CUNI' THEN
         if w_fase_euro = 1 then
            w_importo_min := nvl(a_limite,500000);
         else
            w_importo_min := nvl(a_limite,258);
         end if;
      ELSIF a_tipo_tributo = 'TARSU' THEN
         if w_fase_euro = 1 then
            w_importo_min := nvl(a_limite,3000000);
         else
            w_importo_min := nvl(a_limite,1549);
         end if;
      END IF;
-- Questo controllo serve per verificare se si viene da PB (Power Buider) oppure da SQL.
-- Se si viene da PB significa che e" gia" stata eseguita con successo la procedure
-- TARIFFE_CHK, mentre se si viene da SQL si esegue il loop per verificare se esistono
-- o meno tariffe non caricate per l"anno richiesto
      IF nvl(a_flag_richiamo,'XX') != 'PB' THEN --Se nn è stato chiamato da PowerBuilder (PB)
         --Controlla che esistano le tariffe degli oggetti del contribuente
         FOR rec_tari IN TR4PACKAGE.sel_tari(a_tipo_tributo, a_anno, a_cod_fiscale)
         LOOP
            w_tariffe := nvl(w_tariffe,' ')
                         || ' '
                         || rec_tari.tributo --Codice tributo
                         || ' '
                         || rec_tari.categoria
                         || ' '
                         || rec_tari.tipo_tariffa
                         || ' ';
         END LOOP;
         --w_tariffe serve solo in questo punto
         IF rtrim(w_tariffe,' ') is not null THEN
            w_errore := 'Errore in ricerca Tariffe per l''anno: '||a_anno;
            RAISE errore;
         END IF;
      END IF;
--

-- Il parametro a_ogpr viene sempre passato null,
-- non esiste più il calcolo imposta sulla pratica
-- ma viene fatto sempre su tutto il contribuente (Piero 24/03/2010)
--
    --  if nvl(a_ogpr,0) = 0 then
    --     w_tipo_occupazione := 'P'; --Permanente
    --  else
         w_tipo_occupazione := '%';
    --  end if;
      if nvl(a_pratica,0) = 0 then
         w_tipo_occupazione := 'P'; --Permanente
      else
         w_tipo_occupazione := '%';
      end if;
--
-- La seguente fase memorizza gli oggetti pratica sui versamenti con oggetto imposta.
-- (VD - 24/02/2022): il seguente trattamento viene eseguito solo se il calcolo
--                    non e' relativo ad un ravvedimento
--
      if nvl(a_ravvedimento,'N') <> 'S' then
         FOR rec_vers_ogpr in sel_vers_ogpr (a_anno
                                            ,a_cod_fiscale
                                            ,a_tipo_tributo
                                            ,a_ogpr
                                            )
         LOOP
            BEGIN
               update versamenti vers
                  set vers.ogpr_ogim       = rec_vers_ogpr.oggetto_pratica
                     ,vers.oggetto_imposta = null
                     ,vers.rata_imposta    = null
                where vers.cod_fiscale     = rec_vers_ogpr.cod_fiscale
                  and vers.anno            = rec_vers_ogpr.anno
                  and vers.tipo_tributo    = rec_vers_ogpr.tipo_tributo
                  and vers.sequenza        = rec_vers_ogpr.sequenza
               ;
            EXCEPTION
              WHEN others THEN
                 w_errore := 'Errore in Aggiornamento Versamenti (Memorizzazione Oggetto Pratica)'
                             ||' di '||rec_vers_ogpr.cod_fiscale||' '||'('||SQLERRM||')';
                 RAISE ERRORE;
            END;
         END LOOP;
      end if;
--
-- Si eliminano gli oggetti imposta e le eventuali rate imposta
-- che si vanno a ricalcolare.
-- (VD - 24/02/2022): gestione calcolo imposta su ravvedimento.
--                    Aggiunta condizione di where su parametro a_ravvedimento
--                    e flag_calcolo
--
      BEGIN
         --a_ogpr è nullo se la procedura è chiamata da PowerBuilder
         if nvl(a_ogpr,0) = 0 then
            --
            -- Elimina dati imposte esistenti :
            -- - Se per pratica elimina tutto
            -- - Se specificato gruppo tributo solo di quel gruppo
            -- - Se non specificato gruppo di tutto il tributo
            --
            delete from familiari_ogim       faog
             where faog.oggetto_imposta   in
                  (select ogim.oggetto_imposta
                     from oggetti_imposta    ogim
                    where ogim.cod_fiscale     like a_cod_fiscale
                      and ogim.anno               = a_anno
                      and ogim.tipo_tributo||'' = a_tipo_tributo
                      -- (VD - 24/02/2022): gestione calcolo su ravvedimento
                      --and ogim.flag_calcolo       = 'S'
                      and ((nvl(a_ravvedimento,'N') <> 'S' and ogim.flag_calcolo = 'S') or
                           (nvl(a_ravvedimento,'N') = 'S'  and ogim.flag_calcolo is null))
                      and ogim.ruolo             is NULL
                      and ogim.oggetto_pratica   in
                         (select ogpr.oggetto_pratica
                            from oggetti_pratica  ogpr
                                ,pratiche_tributo prtr
                                ,codici_tributo   cotr
                           where prtr.pratica     = nvl(a_pratica,ogpr.pratica)
                             and prtr.pratica     = ogpr.pratica
                             and ogpr.tributo     = cotr.tributo
                             and cotr.flag_ruolo  is null
                             and ((a_pratica is not null) or
                                  (a_gruppo_tributo is null) or
                                  ((a_gruppo_tributo is not null) and (cotr.gruppo_tributo = a_gruppo_tributo))
                             )
                             and prtr.tipo_tributo||'' = a_tipo_tributo
                             and nvl(ogpr.tipo_occupazione,'P')
                                                   like w_tipo_occupazione
                         )
                  )
            ;
            delete from rate_imposta       raim
             where raim.cod_fiscale     like a_cod_fiscale
               and raim.anno               = a_anno
               and raim.tipo_tributo||'' = a_tipo_tributo
               and nvl(raim.conto_corrente,99990000) in (
                  select distinct nvl(cotr.conto_corrente,99990000) conto_corrente
                  from codici_tributo cotr
                  where cotr.flag_ruolo is null
                    and ((a_pratica is not null) or
                         (a_gruppo_tributo is null) or
                         ((a_gruppo_tributo is not null) and (cotr.gruppo_tributo = a_gruppo_tributo))
                    )
               )
               and ((a_pratica is null and raim.oggetto_imposta is null) or
                    (a_pratica is not null and raim.oggetto_imposta in
                              (select ogim.oggetto_imposta
                                 from oggetti_pratica  ogpr
                                     ,oggetti_imposta  ogim
                                     ,pratiche_tributo prtr
                                where prtr.pratica     = a_pratica
                                  and prtr.pratica     = ogpr.pratica
                                  and ogpr.oggetto_pratica = ogim.oggetto_pratica
                                  -- (VD - 24/02/2022): gestione calcolo su ravvedimento
                                  --and ogim.flag_calcolo = 'S'
                                  and ((nvl(a_ravvedimento,'N') <> 'S' and ogim.flag_calcolo = 'S') or
                                       (nvl(a_ravvedimento,'N') = 'S'  and ogim.flag_calcolo is null))
                              )))
            ;
            delete from oggetti_imposta    ogim
             where ogim.cod_fiscale     like a_cod_fiscale
               and ogim.anno               = a_anno
               -- (VD - 24/02/2022): gestione calcolo su ravvedimento
               --and ogim.flag_calcolo       = 'S'
               and ((nvl(a_ravvedimento,'N') <> 'S' and ogim.flag_calcolo = 'S') or
                    (nvl(a_ravvedimento,'N') = 'S'  and ogim.flag_calcolo is null))
               and ogim.tipo_tributo||''   = a_tipo_tributo
               and ogim.ruolo             is NULL
               and ogim.oggetto_pratica   in
                  (select ogpr.oggetto_pratica
                     from oggetti_pratica  ogpr
                         ,pratiche_tributo prtr
                         ,codici_tributo   cotr
                    where prtr.pratica     = nvl(a_pratica,ogpr.pratica)
                      and prtr.pratica     = ogpr.pratica
                      and ogpr.tributo     = cotr.tributo
                      and cotr.flag_ruolo  is null
                      and ((a_pratica is not null) or
                           (a_gruppo_tributo is null) or
                           ((a_gruppo_tributo is not null) and (cotr.gruppo_tributo = a_gruppo_tributo))
                      )
                      and prtr.tipo_tributo||'' = a_tipo_tributo
                      and nvl(ogpr.tipo_occupazione,'P')
                                           like w_tipo_occupazione
                  )
            ;
         else
         --a_ogpr nn è nullo
            delete from familiari_ogim       faog
             where faog.oggetto_imposta   in
                  (select ogim.oggetto_imposta
                     from oggetti_imposta  ogim
                    where ogim.oggetto_pratica
                                            = a_ogpr
                      and ogim.anno         = a_anno
                      and ogim.tipo_tributo||'' = a_tipo_tributo
                      and ogim.flag_calcolo = 'S'
                  )
            ;
            delete from rate_imposta       raim
             where raim.cod_fiscale     like a_cod_fiscale
               and raim.anno               = a_anno
               and raim.tipo_tributo||''   = a_tipo_tributo
               and raim.oggetto_imposta   in
                  (select ogim.oggetto_imposta
                     from oggetti_imposta  ogim
                    where ogim.oggetto_pratica
                                           = a_ogpr
                      and ogim.anno        = a_anno
                      and ogim.flag_calcolo = 'S'
                  )
            ;
            delete from oggetti_imposta    ogim
             where ogim.cod_fiscale     like a_cod_fiscale
               and ogim.anno               = a_anno
               and ogim.oggetto_pratica    = a_ogpr
               and ogim.flag_calcolo       = 'S'
               and ogim.ruolo             is NULL
               and ogim.tipo_tributo||''   = a_tipo_tributo
            ;
         end if;
      EXCEPTION
         WHEN others THEN
            w_errore := 'Errore in Eliminazione Oggetti Imposta o Rate Imposta'
                        ||' '||'('||SQLERRM||')';
        RAISE ERRORE;
      END;
--
-- Calcolo Imposta ed emissione degli Oggetti Imposta.
--
      FOR rec_ogpr in sel_ogpr (a_anno
                               ,a_cod_fiscale
                               ,a_tipo_tributo
                               ,w_tipo_occupazione
                               ,null
                               ,a_ogpr
                               ,a_pratica
                               ,a_ravvedimento
                               ,a_gruppo_tributo
                               )
      LOOP
       --dbms_output.put_line('Calcolo imposta - OGPR: '||rec_ogpr.oggetto_pratica);
       --dbms_output.put_line('Tipo Occupazione: '||rec_ogpr.tipo_occupazione||', dal: '||rec_ogpr.data_decorrenza||', al: '||rec_ogpr.data_cessazione);
         --
         w_stringa_familiari := '';
         w_dettaglio_faog    := '';
         w_dettaglio_ogim    := '';

         if rec_ogpr.cod_fiscale <> w_cod_fiscale then
         --
         -- Si attualizza il Codice Fiscale.
         --
            w_cod_fiscale := rec_ogpr.cod_fiscale;
         end if;

         if rec_ogpr.tipo_occupazione = 'T' then
            if rec_ogpr.flag_giorni = 'S' then
                w_periodo := rec_ogpr.data_cessazione - rec_ogpr.data_decorrenza + 1;
            else
                if a_tipo_tributo in ('ICP', 'CUNI') then
                   --ceil: Returns smallest integer greater than or equal to n
                   w_periodo := ceil(months_between(rec_ogpr.data_cessazione + 1,rec_ogpr.data_decorrenza));
                else
                   w_periodo := 1;
                end if;
            end if;
         else
            if a_tipo_tributo = 'TARSU'
            -- Particolarita` per Pontassieve che calcola la TOSAP a bimestri.
                   or a_tipo_tributo = 'TOSAP' and rec_ogpr.tipo_occupazione = 'P' and w_comune = '048033' and a_anno >= 2006 then
                   --Pontassieve
                  w_periodo :=
                  f_periodo(a_anno
                          , rec_ogpr.data_decorrenza
                          , rec_ogpr.data_cessazione
                          , rec_ogpr.tipo_occupazione
                          , a_tipo_tributo
                          , a_flag_normalizzato
                           );
            elsif (a_tipo_tributo = 'ICP' and w_comune = '017025') or (a_tipo_tributo = 'TOSAP' and w_comune = '047014')  then  -- Bovezzo --Provincia di Pistoia
               -- Le variazioni dovranno sempre essere indicate con decorrenza 1/1 dell'anno,
               -- mentre le cessazioni in corso d'anno non determineranno una diminuzione del canone
               -- che resterà sempre annuale. (da preventivo Piero 01/06/2010)
               if rec_ogpr.data_decorrenza > to_date('0101'||to_char(a_anno),'ddmmyyyy') then
                  w_periodo := ceil(months_between(to_date('3112'||to_char(a_anno),'ddmmyyyy') + 1
                                                   ,rec_ogpr.data_decorrenza)
                                   ) / 12;
               else
                  w_periodo := 1;
               end if;
            else
                  w_periodo := 1;
            end if;
         end if;

         IF a_flag_normalizzato is NULL THEN
            --
            w_perc_detraz   := rec_ogpr.perc_detrazione;
            w_consistenza   := rec_ogpr.consistenza;
            w_perc_possesso := rec_ogpr.perc_possesso;
            --
            -- 20/10/2023 (RV) : Presonalizzazione Frosinone
            --
            IF (w_comune = w_cod_frosinone) and (a_tipo_tributo = 'CUNI') THEN
              --
              if w_perc_possesso > 0 and w_perc_possesso < 100 then
                if w_consistenza <= 1 then
                  w_consistenza := 0;
                else
                  w_consistenza := Round(w_consistenza * w_perc_possesso / 100,2);
                  w_consistenza := greatest(w_consistenza, 2);
                end if;
              else
                if w_consistenza <= 1 then
                  w_consistenza := 0;
                else
                  w_consistenza := Round(w_consistenza, 2);
                end if;
                --
                if w_consistenza > 1000 and rec_ogpr.tariffa_al_mq > 0 then
                  w_consistenza := 1000 + trunc((w_consistenza - 1000) / 10);
                end if;
                --
              end if;
              w_perc_possesso := null;
            END IF;
            --
            IF (a_tipo_tributo = 'CUNI') and (rec_ogpr.tariffa_speciale = w_tariffa_spec_fraz_giorni) THEN
               IF (w_periodo < rec_ogpr.limite) or (rec_ogpr.limite is null) THEN
                  w_importo := w_consistenza * rec_ogpr.tariffa;
               ELSE
                  w_importo := ( rec_ogpr.limite * rec_ogpr.tariffa +
                                 (w_periodo - rec_ogpr.limite) * rec_ogpr.tariffa_superiore );
                  w_importo := w_importo * w_consistenza;
                  w_periodo := 1;
               END IF;
            ELSE
               IF (w_consistenza < rec_ogpr.limite) or (rec_ogpr.limite is null) THEN
                  w_importo := w_consistenza * rec_ogpr.tariffa;
               ELSE
                  w_importo := ( rec_ogpr.limite * rec_ogpr.tariffa +
                                 (w_consistenza - rec_ogpr.limite) * rec_ogpr.tariffa_superiore );
               END IF;
            END IF;
            --
            IF a_tipo_tributo = 'CUNI' THEN
              w_importo := w_importo * nvl(rec_ogpr.tariffa_quota_fissa,1) ;
              w_importo := w_importo * ((100 - nvl(rec_ogpr.perc_riduzione,0)) / 100) ;
              if nvl(w_perc_detraz,0) <> 0 then
                 w_importo := w_importo * ((100 - w_perc_detraz) / 100);
              end if;
            END IF ;
            w_importo := f_round(w_importo * (nvl(w_perc_possesso,100) / 100) * w_periodo , 1);
         ELSE
            calcolo_importo_normalizzato(rec_ogpr.cod_fiscale,
                                         null,   -- ni
                                         a_anno,
                                         rec_ogpr.tributo,
                                         rec_ogpr.categoria,
                                         rec_ogpr.tipo_tariffa,
                                         rec_ogpr.tariffa,
                                         rec_ogpr.tariffa_quota_fissa,
                                         rec_ogpr.consistenza,
                                         rec_ogpr.perc_possesso,
                                         rec_ogpr.data_decorrenza,
                                         rec_ogpr.data_cessazione,
                                         rec_ogpr.flag_ab_principale,
                                         rec_ogpr.numero_familiari,
                                         null, -- ruolo
                                         w_importo,
                                         w_importo_pf,
                                         w_importo_pv,
                                         w_stringa_familiari,
                                         w_dettaglio_ogim,
                                         w_giorni_ruolo);
            --Se sono più righe estistono cambiamenti nel numero di familiari
            --all'interno dell'anno d'imposta
            if length(w_dettaglio_ogim) > 151 then
               w_dettaglio_faog := w_dettaglio_ogim;
               w_dettaglio_ogim := '';
            end if;
         END IF;
--
-- Inserimento Oggetto Imposta. Nell`utente viene messa una costante strana
-- per poter individuare, in sede di rateizzazione, quali oggetti imposta
-- da considerare senza dover effettuare tanti controlli.
--
         IF w_importo > w_limite THEN
            w_oggetto_imposta := NULL;
            oggetti_imposta_nr(w_oggetto_imposta);
            -- Se calcolo NON rateizzato e se specificato si tiene la data di scadenza per DePag e Stampe
            if a_chk_rate = TR4PACKAGE.NO_RATE and a_scadenza_rata_1 is not null then
              w_data_scadenza := a_scadenza_rata_1;
            else
              w_data_scadenza := null;
            end if;
            BEGIN
               insert into oggetti_imposta(oggetto_imposta
                                         , cod_fiscale
                                         , anno
                                         , oggetto_pratica
                                         , imposta
                                         , flag_calcolo
                                         , utente
                                         , importo_pf
                                         , importo_pv
                                         , dettaglio_ogim
                                         , tipo_tributo
                                         , data_scadenza
                                         )
               values(w_oggetto_imposta
                    , rec_ogpr.cod_fiscale
                    , a_anno
                    , rec_ogpr.oggetto_pratica
                    , w_importo
                    -- (VD - 07/03/2022): se si tratta di ravvedimento, il
                    --                    flag calcolo deve essere null
                    , decode(a_ravvedimento,'S','','S')
                    , '###'
                    , w_importo_pf
                    , w_importo_pv
                    , w_dettaglio_ogim
                    , a_tipo_tributo
                    , w_data_scadenza
                    )
               ;
            EXCEPTION
               WHEN others THEN
                  w_errore := 'Errore in inserimento Oggetti Imposta di '
                              ||rec_ogpr.cod_fiscale||' ('||SQLERRM||')';
                  RAISE ERRORE;
            END;

            --Gestisce i cambiamenti nel numero di familiari all'interno dell'anno d'imposta
            WHILE length(w_stringa_familiari) > 19  LOOP
                 BEGIN
                     insert into familiari_ogim(oggetto_imposta
                                              , numero_familiari
                                              , dal
                                              , al
                                              , data_variazione
                                              , dettaglio_faog)
                          values(w_oggetto_imposta
                               , to_number(substr(w_stringa_familiari,1,4))
                                      , to_date(substr(w_stringa_familiari,5,8),'ddmmyyyy')
                               , to_date(substr(w_stringa_familiari,13,8),'ddmmyyyy')
                                       , trunc(sysdate)
                               , substr(w_dettaglio_faog,1,150)
                                 )
                               ;
                  EXCEPTION
                     WHEN others THEN
                          w_errore := 'Errore in inserimento Familiari_ogim di '
                                      ||rec_ogpr.cod_fiscale||' ('||SQLERRM||')';
                             RAISE ERRORE;
                 END;
                 w_stringa_familiari := substr(w_stringa_familiari,21);
                 w_dettaglio_faog    := substr(w_dettaglio_faog,151);
            END LOOP;
         END IF;
      END LOOP;
--
-- Se da parametri di input e` stata indicata la rateizzazione, si procede.
--
      IF a_chk_rate <> TR4PACKAGE.NO_RATE then
      --Se si effettua la rateizzazione
         if nvl(a_ravvedimento,'N') = 'S' then
         -- (VD - 24/02/2022): gestione calcolo imposta su ravvedimento
         -- Se si tratta di ravvedimento, si rateizza per pratica
            FOR rec_ogim in sel_ogim_pratica_ravv ( a_cod_fiscale
                                                  , a_pratica
                                                  , a_anno
                                                  , a_tipo_tributo
                                                  , a_chk_rate
                                                  )
            loop
              BEGIN
                 INSERIMENTO_RAIM_CU(rec_ogim.cod_fiscale
                                , rec_ogim.oggetto_imposta
                                , rec_ogim.data_decorrenza
                                , rec_ogim.imposta
                                , a_tipo_tributo
                                , rec_ogim.conto_corrente
                                , rec_ogim.data_concessione
                                , a_anno
                                , a_utente
                                , w_tot_versato
                                , a_gruppo_tributo
                                , a_scadenza_rata_1
                                , a_scadenza_rata_2
                                , a_scadenza_rata_3
                                , a_scadenza_rata_4
                                 );
                --dbms_output.put_line('C.F. '||rec_ogim.cod_fiscale||', Importo versato dopo: '||w_tot_versato);
              EXCEPTION
                 WHEN others THEN
                    w_errore := 'Errore in Emissione Rate Imposta'
                                ||' di '||rec_ogim.cod_fiscale||' '||'('||SQLERRM||')';
                RAISE ERRORE;
              END;
            end loop;
         else
            if w_comune = w_cod_belluno and
               a_tipo_tributo in ('ICP', 'TOSAP', 'CUNI') then
               w_cf_prec := '*';
               -- Belluno: si trattano le imposte calcolate che devono essere
               -- rateizzate per contribuente
               FOR rec_ogim in sel_ogim_contribuente ( a_anno
                                                     , a_tipo_tributo
                                                     , a_gruppo_tributo
                                                     , a_chk_rate
                                                     , w_importo_min
                                                     )
               LOOP
                 --dbms_output.put_line('C.F. '||rec_ogim.cod_fiscale||', OGIM: '||rec_ogim.oggetto_imposta||', Imposta: '||rec_ogim.imposta);
                 if rec_ogim.cod_fiscale <> w_cf_prec then
                    --dbms_output.put_line('C.F. '||rec_ogim.cod_fiscale||', sono qui 2');
                    w_cf_prec := rec_ogim.cod_fiscale;
                    -- Si selezionano eventuali versamenti
                    begin
                      select nvl(sum(vers.importo_versato),0)
                        into w_tot_versato
                        from versamenti vers
                       where vers.tipo_tributo||'' = a_tipo_tributo
                         and vers.cod_fiscale        = rec_ogim.cod_fiscale
                         and vers.anno               = a_anno
                         and vers.pratica is null
                       group by vers.cod_fiscale;
                    exception
                      when others then
                        w_tot_versato := 0;
                    end;
                 end if;
                 --dbms_output.put_line('C.F. '||rec_ogim.cod_fiscale||', Importo versato prima: '||w_tot_versato);
                 BEGIN
                    INSERIMENTO_RAIM_CU(rec_ogim.cod_fiscale
                                   , rec_ogim.oggetto_imposta
                                   , rec_ogim.data_decorrenza
                                   , rec_ogim.imposta
                                   , a_tipo_tributo
                                   , rec_ogim.conto_corrente
                                   , rec_ogim.data_concessione
                                   , a_anno
                                   , a_utente
                                   , w_tot_versato
                                   , a_gruppo_tributo
                                   , a_scadenza_rata_1
                                   , a_scadenza_rata_2
                                   , a_scadenza_rata_3
                                   , a_scadenza_rata_4
                                   , rec_ogim.flag_no_depag
                                    );
                    --dbms_output.put_line('C.F. '||rec_ogim.cod_fiscale||', Importo versato dopo: '||w_tot_versato);
                 EXCEPTION
                    WHEN others THEN
                       w_errore := 'Errore in Emissione Rate Imposta'
                                   ||' di '||rec_ogim.cod_fiscale||' '||'('||SQLERRM||')';
                    RAISE ERRORE;
                 END;
               END LOOP;
               -- Belluno: si trattano le imposte calcolate che devono essere
               -- rateizzate per pratica
               w_cf_prec := '*';
               w_pratica_prec := 0;
               for rec_prat in sel_pratiche_da_rateizz ( a_anno
                                                       , a_tipo_tributo
                                                       , a_gruppo_tributo
                                                       , a_chk_rate
                                                       , w_importo_min
                                                       )
               loop
                 if rec_prat.cod_fiscale <> w_cf_prec or
                    rec_prat.pratica <> w_pratica_prec then
                    -- Si selezionano eventuali versamenti
                    begin
                      select nvl(sum(vers.importo_versato),0)
                        into w_tot_versato
                        from versamenti vers
                       where vers.tipo_tributo||'' = a_tipo_tributo
                         and vers.cod_fiscale        = rec_prat.cod_fiscale
                         and vers.anno               = a_anno
                         and vers.pratica            = rec_prat.pratica
                       group by vers.cod_fiscale;
                    exception
                      when others then
                        w_tot_versato := 0;
                    end;
                 end if;
                 FOR rec_ogim in sel_ogim_pratica ( rec_prat.cod_fiscale
                                                  , rec_prat.pratica
                                                  , a_anno
                                                  , a_tipo_tributo
                                                  , a_chk_rate
                                                  )
                 loop
                   BEGIN
                      INSERIMENTO_RAIM_CU(rec_ogim.cod_fiscale
                                     , rec_ogim.oggetto_imposta
                                     , rec_ogim.data_decorrenza
                                     , rec_ogim.imposta
                                     , a_tipo_tributo
                                     , rec_ogim.conto_corrente
                                     , rec_ogim.data_concessione
                                     , a_anno
                                     , a_utente
                                     , w_tot_versato
                                     , a_gruppo_tributo
                                     , a_scadenza_rata_1
                                     , a_scadenza_rata_2
                                     , a_scadenza_rata_3
                                     , a_scadenza_rata_4
                                     , rec_ogim.flag_no_depag
                                      );
                     --dbms_output.put_line('C.F. '||rec_ogim.cod_fiscale||', Importo versato dopo: '||w_tot_versato);
                   EXCEPTION
                      WHEN others THEN
                         w_errore := 'Errore in Emissione Rate Imposta'
                                     ||' di '||rec_ogim.cod_fiscale||' '||'('||SQLERRM||')';
                     RAISE ERRORE;
                   END;
                 end loop;
               end loop;
            else
               -- Trattamento standard
               FOR rec_ogim in sel_ogim (a_anno
                                        , a_tipo_tributo
                                        , a_gruppo_tributo
                                        , a_chk_rate
                                        , w_importo_min
                                        , a_ravvedimento
                                        )
               LOOP
                 BEGIN
                    INSERIMENTO_RAIM_CU(rec_ogim.cod_fiscale
                                   , rec_ogim.oggetto_imposta
                                   , rec_ogim.data_decorrenza
                                   , rec_ogim.imposta
                                   , a_tipo_tributo
                                   , rec_ogim.conto_corrente
                                   , rec_ogim.data_concessione
                                   , a_anno
                                   , a_utente
                                   , w_tot_versato
                                   , a_gruppo_tributo
                                   , a_scadenza_rata_1
                                   , a_scadenza_rata_2
                                   , a_scadenza_rata_3
                                   , a_scadenza_rata_4
                                   , rec_ogim.flag_no_depag
                                    );
                    --dbms_output.put_line('C.F. '||rec_ogim.cod_fiscale||', Importo versato dopo: '||w_tot_versato);
                 EXCEPTION
                    WHEN others THEN
                       w_errore := 'Errore in Emissione Rate Imposta'
                                   ||' di '||rec_ogim.cod_fiscale||' '||'('||SQLERRM||')';
                   RAISE ERRORE;
                 END;
               END LOOP;
            end if;
         end if;
      END IF;
--
-- La seguente fase assegna ai versamenti su oggetto imposta il nuovo oggetto imposta.
--
      IF nvl(a_ravvedimento,'N') <> 'S' then
         FOR rec_vers in sel_vers (a_anno
                                 , a_cod_fiscale
                                 , a_tipo_tributo
                                  )
         LOOP
            if rec_vers.rata is null then
               BEGIN
                  update versamenti vers
                     set vers.ogpr_ogim       = null
                       , vers.oggetto_imposta = rec_vers.oggetto_imposta
                   where vers.cod_fiscale     = rec_vers.cod_fiscale
                     and vers.anno            = rec_vers.anno
                     and vers.tipo_tributo    = rec_vers.tipo_tributo
                     and vers.sequenza        = rec_vers.sequenza
                  ;
               EXCEPTION
                 WHEN others THEN
                    w_errore := 'Errore in Aggiornamento Versamenti (Riassegnazione Oggetto Imposta)'
                                ||' di '||rec_vers.cod_fiscale||' '||'('||SQLERRM||')';
                    RAISE ERRORE;
               END;
            else
               BEGIN
                  select raim.rata_imposta
                    into w_rata_imposta
                    from rate_imposta   raim
                   where raim.oggetto_imposta = rec_vers.oggetto_imposta
                     and raim.rata            = rec_vers.rata
                  ;
               EXCEPTION
                  WHEN NO_DATA_FOUND THEN
                     w_rata_imposta := null;
               END;
               BEGIN
                  update versamenti vers
                     set vers.ogpr_ogim       = null
                       , vers.rata_imposta    = w_rata_imposta
                   where vers.cod_fiscale     = rec_vers.cod_fiscale
                     and vers.anno            = rec_vers.anno
                     and vers.tipo_tributo    = rec_vers.tipo_tributo
                     and vers.sequenza        = rec_vers.sequenza
                  ;
               EXCEPTION
                 WHEN others THEN
                    w_errore := 'Errore in Aggiornamento Versamenti (Riassegnazione Rata Imposta)'
                                ||' di '||rec_vers.cod_fiscale||' '||'('||SQLERRM||')';
                    RAISE ERRORE;
               END;
            end if;
         END LOOP;
      end if;
      --
      -- (VD - 11/11/2019): Passaggio a PAGONLINE solo per tipi tributo
      --                    TOSAP e ICP e se attivo flag su
      --                    installazione_parametri
      -- (RV - 19/03/2021): Aggiunto tributo CUNI
      --
      w_pagonline := F_INPA_VALORE('PAGONLINE');
      --
      if w_pagonline = 'S' and nvl(a_ravvedimento,'N') <> 'S' then
        w_result := 0;
        if a_tipo_tributo in ('CUNI') then
          w_result := pagonline_tr4.inserimento_dovuti_cu ( a_tipo_tributo, a_cod_fiscale, a_anno, a_pratica, a_chk_rate, a_gruppo_tributo );
        end if;
        if a_tipo_tributo in ('ICP', 'TOSAP') then
          w_result := pagonline_tr4.inserimento_dovuti ( a_tipo_tributo, a_cod_fiscale, a_anno, a_pratica, a_chk_rate );
        end if;
        if w_result = -1 then
          w_errore:= 'Si e'' verificato un errore in fase di preparazione dati per PAGONLINE - Verificare log';
          raise errore;
        end if;
      end if;
--
-- Aggiornamento dell`utente provvisorio in oggetti imposta col definitivo.
--
      BEGIN
         update oggetti_imposta
            set utente = a_utente
         where utente = '###'
         ;
      EXCEPTION
         WHEN others THEN
            w_errore := 'Errore in Aggiornamento finale di Oggetti Imposta '
                        ||'('||SQLERRM||')';
            RAISE ERRORE;
      END;
   END IF; --Nn ICI
EXCEPTION
  WHEN errore THEN
     ROLLBACK;
     RAISE_APPLICATION_ERROR(-20999,w_errore);
  WHEN others THEN
     ROLLBACK;
     RAISE_APPLICATION_ERROR
     (-20999,'Errore in Calcolo Imposta di '||w_cod_fiscale||' '||'('||SQLERRM||')');
END;
/* End Procedure: CALCOLO_IMPOSTA_CU */
/
