--liquibase formatted sql 
--changeset abrandolini:20250326_152429_pagonline_tr4_cu stripComments:false runOnChange:true context:DEPAG
 
create or replace package PAGONLINE_TR4_CU is
  /******************************************************************************
   NOME:        PAGONLINE_TR4_CU
   DESCRIZIONE: Procedure e Funzioni per integrazione con PAGONLINE
   ANNOTAZIONI: Personalizzazione specifica per Canone Unico
   REVISIONI:
   Rev.  Data        Autore  Descrizione
   ----  ----------  ------  ----------------------------------------------------
   004   19/03/2021  RV      Prima emissione, basato su package PAGONLINE_TR4 Revsione 003 (VD)
  ******************************************************************************/
  s_versione  varchar2(20) := 'V1.0';
  s_revisione varchar2(30) := '4    19/03/2021';
  type dovuti_table is table of depag_dovuti%rowtype;
  p_tab_dovuti              dovuti_table := dovuti_table();
  function versione
  return varchar2;
  --Generali
  function inserimento_dovuti
  ( p_tipo_tributo            in varchar2
  , p_cod_fiscale             in varchar2
  , p_anno                    in number
  , p_pratica                 in number
  , p_chk_rate                in number
  )
  return number;
  function aggiornamento_pagamenti
  ( p_ente                    in varchar2 default null
  , p_idback                  in varchar2 default null
  , p_iuv                     in varchar2
  , p_importo_versato         in varchar2
  , p_data_pagamento          in varchar2
  , p_utente                  in varchar2
  , p_servizio                in varchar2 default null
  ) return number;
  function j_aggiornamento_pagamenti
  ( p_ente                     in varchar2 default null
  , p_idback                   in varchar2 default null
  ) return number;
end PAGONLINE_TR4_CU;
/

create or replace package body PAGONLINE_TR4_CU is
  /******************************************************************************
   NOME:        PAGONLINE_TR4_CU
   DESCRIZIONE: Procedure e Funzioni per integrazione con PAGONLINE
   ANNOTAZIONI: Personalizzazione specifica per Canone Unico
   REVISIONI:
   Rev.  Data        Autore  Descrizione
   ----  ----------  ------  ----------------------------------------------------
   004   23/03/2021  RV      Prima emissione, basato su package PAGONLINE_TR4 Revsione 003 (VD)
   005   03/05/2021  RV      Revisione per implementazione separazione CUNI/CUME
  ******************************************************************************/
   function versione return varchar2
   is
   begin
      return s_versione||'.'||s_revisione;
   end versione;
--------------------------------------------------------------------------------------------------------
function inserimento_dovuti
( p_tipo_tributo            in varchar2
, p_cod_fiscale             in varchar2
, p_anno                    in number
, p_pratica                 in number
, p_chk_rate                in number
) return number is
/******************************************************************************
 NOME:        INSERIMENTO_DOVUTI
 DESCRIZIONE: Carica l'elenco degli importi dovuti per PAGONLINE.
              Tributi: Solo CUNI
 PARAMETRI:   p_tipo_tributo        Tipo tributo da elaborare
              p_cod_fiscale         Codice fiscale del contribuente
                                    (% = tutti i contribuenti)
              p_anno                Anno di riferimento
              p_pratica             Eventuale pratica su cui calcolare
                                    l'imposta
              p_chk_rate            0 - calcolo senza rateizzazione
                                    > 0 - calcolo con rateizzazione
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 004   19/03/2021  RV      Prima emissione, basato su medesima funzione di PAGONLINE_TR4
                           Revisione 003 (VD)
 005   03/05/2021  RV      Rivisto selezione IDBack da eliminare su calcolo totale,
                           integrato per gestione separata CUNI/CUME
 006   02/05/2022  VD      Corretta selezione Idback da eliminare su calcolo totale:
                           occorre trattare le denunce con anno <= anno imposta
                           Aggiunto inserimento dati contabili per integrazione
                           con CFA
******************************************************************************/
RetVal                      VARCHAR2(8);
w_des_cliente               varchar2(60);
--w_servizio                  varchar(40) := 'TOSAP';  -- DA DEFINIRE
w_utente_ultimo_agg         varchar(8)  := 'TRIBUTI';
w_idback_ann                depag_dovuti.idback%TYPE;
--w_iud                       depag_dovuti.iud%TYPE;
w_iud_prec                  depag_dovuti.iud%TYPE;
w_importo_vers              number;
w_conta_vers                number;
w_return                    number:= 0;
w_operazione_log            varchar2(100) := 'Inserimento dovuti CU';
w_ordinamento               varchar2(1);
w_cf_prec                   varchar2(16);
w_pratica_prec              number;
w_errore                    varchar2(4000);
errore                      exception;
-- (VD - 06/05/2022): Dati per contabilita' finanziaria
w_int_cfa                   varchar2(1);
w_dati_riscossione          depag_dovuti.dati_riscossione%type;
w_accertamento              depag_dovuti.accertamento%type;
w_bilancio                  depag_dovuti.bilancio%type;
-- Cursore per annullare i dovuti di tutte le denunce dell'anno
-- (in questo modo vengono eliminati anche i dovuti relativi
-- a pratiche da non trattare più)
cursor sel_pratiche_ann is
  select prtr.cod_fiscale
        ,prtr.pratica
        ,ogpr.tipo_occupazione
        ,nvl(cotr.descrizione_cc,p_tipo_tributo) cotr_tributo
    from pratiche_tributo prtr
        ,oggetti_pratica  ogpr
        ,codici_tributo   cotr
   where (
       ((p_tipo_tributo <> 'CUNI') and (prtr.tipo_tributo = p_tipo_tributo)) or
       ((p_tipo_tributo = 'CUNI') and (prtr.tipo_tributo in ('ICP','TOSAP','CUNI')))
     )
     and prtr.anno                   = p_anno
     and prtr.cod_fiscale         like p_cod_fiscale
     and prtr.tipo_pratica           = 'D'
     and prtr.pratica                = ogpr.pratica
     and ogpr.tipo_occupazione       = 'P'
     and cotr.tributo                = ogpr.tributo
     and cotr.flag_ruolo is null
     and p_pratica is null
   group by
         prtr.cod_fiscale
        ,prtr.pratica
        ,ogpr.tipo_occupazione
        ,nvl(cotr.descrizione_cc,p_tipo_tributo)
  union
  select p_cod_fiscale
        ,p_pratica
        ,ogpr.tipo_occupazione
        ,nvl(cotr.descrizione_cc,p_tipo_tributo) cotr_tributo
    from oggetti_pratica  ogpr
        ,codici_tributo   cotr
   where ogpr.pratica                = p_pratica
     and cotr.tributo                = ogpr.tributo
     and cotr.flag_ruolo is null
     and p_pratica is not null
   group by
         p_cod_fiscale
        ,p_pratica
        ,ogpr.tipo_occupazione
        ,nvl(cotr.descrizione_cc,p_tipo_tributo)
   order by 1,2;
-- Cursore per annullare i dovuti totali dell'anno relativi a denunce degli anni precedenti
cursor sel_pratiche_totali_ann is
  select prtr.cod_fiscale
        ,ogpr.tipo_occupazione
        ,nvl(cotr.descrizione_cc,p_tipo_tributo) cotr_tributo
    from pratiche_tributo prtr
        ,oggetti_pratica  ogpr
        ,codici_tributo   cotr
   where (
       ((p_tipo_tributo <> 'CUNI') and (prtr.tipo_tributo = p_tipo_tributo)) or
       ((p_tipo_tributo = 'CUNI') and (prtr.tipo_tributo in ('ICP','TOSAP','CUNI')))
     )
     -- (VD - 02/05/2022): corretta selezione pratiche. L'anno deve essere
     --                    <= dell'anno di imposta, altrimenti si annullano solo i
     --                    dovuti relativi alle denunce dell'anno
     --and prtr.anno                   = p_anno
     and prtr.anno                   <= p_anno
     and prtr.cod_fiscale         like p_cod_fiscale
     and prtr.tipo_pratica           = 'D'
     and prtr.pratica                = ogpr.pratica
     and ogpr.tipo_occupazione       = 'P'
     and cotr.tributo                = ogpr.tributo
     and cotr.flag_ruolo is null
     and p_pratica is null
   group by
         prtr.cod_fiscale
        ,ogpr.tipo_occupazione
        ,nvl(cotr.descrizione_cc,p_tipo_tributo);
-- Cursore per selezionare l'imposta da passare a DEPAG
cursor sel_mov is
   -- Selezione per calcolo imposta senza rateizzazione (o imposta non rateizzata perche'
   -- inferiore al limite indicato)
   select decode(w_ordinamento,'A',replace(sogg.cognome_nome,'/',' ')  -- anag_pagatore (cognome e nome)
                              ,'C',cont.cod_fiscale                    -- codice_ident (codice fiscale)
                              ,'I',decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                                         ,null,decode(sogg.cod_via
                                                     ,null,sogg.denominazione_via
                                                          ,arvi.denom_uff)
                                              ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                                         )||
                                   decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                                         ,null,to_char(sogg.num_civ)||
                                               decode(sogg.suffisso,null,'','/'||sogg.suffisso)||
                                               decode(sogg.interno,null,'', ' Int.'||to_char(sogg.interno))
                                              ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'NC')||
                                               decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF')
                                                     ,null,''
                                                          ,'/'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF'))||
                                               decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN')
                                                     ,null,''
                                                     ,' Int.'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN'))
                                          ) -- indirizzo_pagatore
                                  ,impo.cotr_tributo||impo.tipo_occupazione||
                                                           p_anno||lpad(nvl(impo.pratica,0),10,'0')||
                                                                            rpad(cont.cod_fiscale,16)||0 -- id_back
                   ) ordinamento
        , cont.cod_fiscale cod_fiscale
        , impo.pratica
        , w_des_cliente ente
        , null iud
        , f_depag_servizio(impo.cotr_tributo,impo.tipo_occupazione) servizio
        , impo.cotr_tributo||impo.tipo_occupazione||p_anno||lpad(nvl(impo.pratica,0),10,'0')||
          rpad(cont.cod_fiscale,16)||0 idback
        , null backend
        , null cod_iuv
        , decode(sogg.tipo_residente
                ,0,'F'
                  ,decode(sogg.tipo
                         ,0,'F'
                         ,1,'G'
                           ,decode(instr(sogg.cognome_nome,'/'),0,'G','F'))) tipo_ident
        , cont.cod_fiscale codice_ident
        , replace(replace(replace(sogg.cognome_nome,'/',' '),'&','e'),'''','''''') anag_pagatore
        , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                ,null,decode(sogg.cod_via
                            ,null,sogg.denominazione_via
                                 ,arvi.denom_uff)
                     ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')) indirizzo_pagatore
        , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                ,null,to_char(sogg.num_civ)||
                      decode(sogg.suffisso,null,'','/'||sogg.suffisso)||
                      decode(sogg.interno,null,'', ' Int.'||to_char(sogg.interno))
                     ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'NC')||
                      decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF')
                            ,null,'','/'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF'))||
                      decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN')
                            ,null,'',' Int.'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN'))
                ) civico_pagatore
        , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                ,null,lpad(sogg.cap,5,'0')
                     ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'CAP')) cap_pagatore
        , substr(nvl(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'CO')
                    ,ad4_comune.get_denominazione(sogg.cod_pro_res,sogg.cod_com_res))
                ,1,35) localita_pagatore
        , nvl(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SPS')
             ,pagonline_tr4.f_get_sigla_provincia(sogg.cod_pro_res)) prov_pagatore
        , 'IT'                                           naz_pagatore
        , nvl(f_recapito(sogg.ni,p_tipo_tributo,3),
              f_recapito(sogg.ni,p_tipo_tributo,2))      email_pagatore
        , f_scadenza_rata (p_tipo_tributo, p_anno, 0)    data_scadenza
        , decode(titr.flag_canone,'S',nvl(impo.imposta,0)
                                     ,round(nvl(impo.imposta, 0))) importo_dovuto
        , null commissione_carico_pa
        ,'TRIBUTO' tipo_dovuto
        , null tipo_versamento
        , f_descrizione_titr(impo.cotr_tributo,p_anno)||
          decode(impo.tipo_occupazione,
                 'P',' PERMANENTE, ANNO: '||p_anno,
                     ' TEMPORANEA, '|| --f_descrizione_oggetto(max(ogpr.oggetto))||
                     ' DAL: '||to_char(impo.inizio_occupazione,'dd/mm/yyyy')||
                     ' AL: '||to_char(impo.fine_occupazione,'dd/mm/yyyy'))||
                     ', RATA: UNICA'     causale_versamento
        , null dati_riscossione
        , w_utente_ultimo_agg utente_ultimo_agg
        , 0 rata
     from contribuenti     cont
        , soggetti         sogg
        , archivio_vie     arvi
        , tipi_tributo     titr
        , (select ogim.tipo_tributo,
                  ogim.anno,
                  ogim.cod_fiscale,
                  decode(prtr.tipo_pratica||decode(ogco.data_decorrenza,null,prtr.anno,extract(year from ogco.data_decorrenza)),
                         'D'||p_anno,prtr.pratica,to_number(null)) pratica,
                  min(ogpr.tipo_occupazione) tipo_occupazione,
                  0 rata,
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.inizio_occupazione) inizio_occupazione,
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.fine_occupazione) fine_occupazione,
                  nvl(cotr.conto_corrente,99999900) as cc_riferimento,
                  nvl(cotr.descrizione_cc,p_tipo_tributo) as cotr_tributo,
                  sum(ogim.imposta) imposta
             from oggetti_imposta ogim,
                  oggetti_pratica ogpr,
                  oggetti_contribuente ogco,
                  pratiche_tributo prtr,
                  codici_tributo cotr
            where ogpr.pratica  = prtr.pratica
              --and prtr.tipo_pratica = 'D'
              --and prtr.pratica > 0
              and ogim.utente = '###'
              and ogim.oggetto_pratica = ogpr.oggetto_pratica
              and ogim.oggetto_pratica = ogco.oggetto_pratica
              and ogim.cod_fiscale = ogco.cod_fiscale
              and cotr.tributo = ogpr.tributo
            group by ogim.tipo_tributo,ogim.anno,ogim.cod_fiscale,
                  decode(prtr.tipo_pratica||decode(ogco.data_decorrenza,null,prtr.anno,extract(year from ogco.data_decorrenza)),
                         'D'||p_anno,prtr.pratica,to_number(null)),
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.inizio_occupazione),
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.fine_occupazione),
                  nvl(cotr.conto_corrente,99999900),
                  cotr.descrizione_cc
                  ) impo
    where cont.cod_fiscale like p_cod_fiscale
      and cont.ni = sogg.ni
      and sogg.cod_via = arvi.cod_via (+)
      and titr.tipo_tributo = p_tipo_tributo
      and impo.tipo_tributo = p_tipo_tributo
      and impo.cod_fiscale = cont.cod_fiscale
      and impo.anno = p_anno
      and (p_chk_rate = 0 or
          (p_chk_rate > 0 and not exists (select 'x' from rate_imposta raim
                                           where raim.tipo_tributo = p_tipo_tributo
                                             and raim.cod_fiscale = cont.cod_fiscale
                                             and raim.anno = p_anno
                                             and ((impo.pratica is null and raim.oggetto_imposta is null) or
                                                  (impo.pratica is not null and raim.oggetto_imposta in
                                                 (select ogim.oggetto_imposta
                                                    from oggetti_imposta ogim
                                                       , oggetti_pratica ogpr
                                                   where ogpr.pratica = impo.pratica
                                                     and ogpr.oggetto_pratica = ogim.oggetto_pratica)))
                                          )
          ))
   union
   -- Selezione per calcolo imposta con rateizzazione
   select decode(w_ordinamento,'A',replace(sogg.cognome_nome,'/',' ')  -- anag_pagatore (cognome e nome)
                              ,'C',cont.cod_fiscale                    -- codice_ident (codice fiscale)
                              ,'I',decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                                        ,null,decode(sogg.cod_via
                                                     ,null,sogg.denominazione_via
                                                          ,arvi.denom_uff)
                                              ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                                         )||
                                   decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                                         ,null,to_char(sogg.num_civ)||
                                               decode(sogg.suffisso,null,'','/'||sogg.suffisso)||
                                               decode(sogg.interno,null,'', ' Int.'||to_char(sogg.interno))
                                              ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'NC')||
                                               decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF')
                                                     ,null,''
                                                          ,'/'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF'))||
                                               decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN')
                                                     ,null,''
                                                     ,' Int.'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN'))
                                          ) -- indirizzo_pagatore
                                  ,impo.cotr_tributo||impo.tipo_occupazione||
                                                                p_anno||lpad(nvl(impo.pratica,0),10,'0')||
                                                                             rpad(cont.cod_fiscale,16)||raim.rata -- id_back
                   ) ordinamento
        , cont.cod_fiscale cod_fiscale
        , impo.pratica
        , w_des_cliente ente
        , null iud
        , f_depag_servizio(impo.cotr_tributo,impo.tipo_occupazione) servizio
        , impo.cotr_tributo||impo.tipo_occupazione||p_anno||lpad(nvl(impo.pratica,0),10,'0')||
          rpad(cont.cod_fiscale,16)||raim.rata idback
        , null backend
        , null cod_iuv
        , decode(sogg.tipo_residente
                ,0,'F'
                  ,decode(sogg.tipo
                         ,0,'F'
                         ,1,'G'
                           ,decode(instr(sogg.cognome_nome,'/'),0,'G','F'))) tipo_ident
        , cont.cod_fiscale codice_ident
        , replace(replace(replace(sogg.cognome_nome,'/',' '),'&','e'),'''','''''') anag_pagatore
        , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                ,null,decode(sogg.cod_via
                            ,null,sogg.denominazione_via
                                 ,arvi.denom_uff)
                     ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')) indirizzo_pagatore
        , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                ,null,to_char(sogg.num_civ)||
                      decode(sogg.suffisso,null,'','/'||sogg.suffisso)||
                      decode(sogg.interno,null,'', ' Int.'||to_char(sogg.interno))
                     ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'NC')||
                      decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF')
                            ,null,'','/'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SF'))||
                      decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN')
                            ,null,'',' Int.'||f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'IN'))
                ) civico_pagatore
        , decode(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'DV')
                ,null,lpad(sogg.cap,5,'0')
                     ,f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'CAP')) cap_pagatore
        , nvl(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'CO')
             ,ad4_comune.get_denominazione(sogg.cod_pro_res,sogg.cod_com_res))
              localita_pagatore
        , nvl(ltrim(replace(replace(f_recapito(sogg.ni,p_tipo_tributo,1,trunc(sysdate),'SP'),'(',''),')',''))
             ,ad4_provincia.get_sigla(sogg.cod_pro_res)) prov_pagatore
        , 'IT'                                           naz_pagatore
        , nvl(f_recapito(sogg.ni,p_tipo_tributo,3),
              f_recapito(sogg.ni,p_tipo_tributo,2))      email_pagatore
        , f_scadenza_rata (p_tipo_tributo, p_anno, raim.rata) data_scadenza
        , decode(titr.flag_canone,'S',sum(nvl(raim.imposta,0))
                                     ,sum(nvl(raim.imposta_round, 0))) importo_dovuto
        , null commissione_carico_pa
        ,'TRIBUTO' tipo_dovuto
        , null tipo_versamento
        , f_descrizione_titr(impo.cotr_tributo,p_anno)||
          decode(impo.tipo_occupazione,
                 'P',' PERMANENTE, ANNO: '||p_anno,
                     ' TEMPORANEA, '|| --f_descrizione_oggetto(max(ogpr.oggetto))||
                     ' DAL: '||to_char(impo.inizio_occupazione,'dd/mm/yyyy')||
                     ' AL: '||to_char(impo.fine_occupazione,'dd/mm/yyyy'))||
                     ', RATA: '||raim.rata     causale_versamento
        , null dati_riscossione
        , w_utente_ultimo_agg utente_ultimo_agg
        , raim.rata
     from contribuenti     cont
        , soggetti         sogg
        , archivio_vie     arvi
        , rate_imposta     raim
        , tipi_tributo     titr
        , (select ogim.tipo_tributo,
                  ogim.anno,
                  ogim.cod_fiscale,
                  decode(prtr.tipo_pratica||decode(ogco.data_decorrenza,null,prtr.anno,extract(year from ogco.data_decorrenza)),
                         'D'||p_anno,prtr.pratica,to_number(null)) pratica,
                  min(ogpr.tipo_occupazione) tipo_occupazione,
                  0 rata,
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.inizio_occupazione) inizio_occupazione,
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.fine_occupazione) fine_occupazione,
                  nvl(cotr.conto_corrente,99999900) as cc_riferimento,
                  nvl(cotr.descrizione_cc,p_tipo_tributo) as cotr_tributo,
                  sum(ogim.imposta) imposta
             from oggetti_imposta ogim,
                  oggetti_pratica ogpr,
                  oggetti_contribuente ogco,
                  pratiche_tributo prtr,
                  codici_tributo cotr
            where ogpr.pratica  = prtr.pratica
              and prtr.tipo_pratica = 'D'
              --and prtr.pratica > 0
              and ogim.utente = '###'
              and ogim.oggetto_pratica = ogpr.oggetto_pratica
              and ogim.oggetto_pratica = ogco.oggetto_pratica
              and ogim.cod_fiscale = ogco.cod_fiscale
              and cotr.tributo = ogpr.tributo
            group by ogim.tipo_tributo,ogim.anno,ogim.cod_fiscale,
                  decode(prtr.tipo_pratica||decode(ogco.data_decorrenza,null,prtr.anno,extract(year from ogco.data_decorrenza)),
                         'D'||p_anno,prtr.pratica,to_number(null)),
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.inizio_occupazione),
                  decode(ogpr.tipo_occupazione,'P',to_date(null),ogco.fine_occupazione),
                  nvl(cotr.conto_corrente,99999900),
                  cotr.descrizione_cc
                  ) impo
    where cont.cod_fiscale like p_cod_fiscale
      and cont.ni = sogg.ni
      and sogg.cod_via = arvi.cod_via (+)
      and titr.tipo_tributo = p_tipo_tributo
      and impo.tipo_tributo = p_tipo_tributo
      and impo.anno = p_anno
      and impo.cod_fiscale = cont.cod_fiscale
      and raim.tipo_tributo = p_tipo_tributo
      and raim.cod_fiscale = cont.cod_fiscale
      and raim.anno = p_anno
      and nvl(raim.conto_corrente,99999900) = cc_riferimento
      and ((impo.pratica is null and raim.oggetto_imposta is null) or
           (impo.pratica is not null and raim.oggetto_imposta in
           (select ogim.oggetto_imposta
              from oggetti_imposta ogim
                 , oggetti_pratica ogpr
             where ogpr.pratica = impo.pratica
               and ogpr.oggetto_pratica = ogim.oggetto_pratica)))
      and p_chk_rate > 0
    group by cont.cod_fiscale,sogg.ni,sogg.cognome_nome,sogg.tipo_residente,sogg.tipo,
             sogg.cod_via,sogg.denominazione_via,sogg.num_civ,sogg.suffisso,sogg.interno,
             sogg.cod_pro_res,sogg.cod_com_res,arvi.denom_uff,sogg.cap,
             impo.cc_riferimento,
             impo.cotr_tributo,
             impo.tipo_occupazione,impo.pratica,
             impo.inizio_occupazione,impo.fine_occupazione,
             raim.rata,titr.flag_canone
    order by 1,2,3;
---------------------------------------------------------------------------------------------------
  begin
    /*w_des_cliente := pagonline_tr4.descrizione_ente;
    -- Si memorizza il tipo di ordinamento da utilizzare nella emissione dei dovuti
    w_ordinamento := nvl(f_inpa_valore('PAGONL_ORD'),'A');
    pagonline_tr4.inserimento_log(w_operazione_log||' - Inizio', w_des_cliente);
    -- (VD - 06/05/2022): nuovi dati per integrazione con contabilita' finanziaria
    -- Si seleziona il flag per verificare l'integrazione con CFA
    w_int_cfa     := nvl(f_inpa_valore('CFA_INT'),'N');
    -- Determinazione accertamento contabile abbinato all'imposta
    -- (da memorizzare nel campo "accertamento" di depag_dovuti)
    w_accertamento := null;
    w_dati_riscossione := null;
    if w_int_cfa = 'S' then
       w_accertamento := dati_contabili_pkg.f_get_acc_contabile( p_tipo_tributo
                                                               , p_anno
                                                               , 'O'               -- tipo_imposta
                                                               , to_char(null)     -- tipo_pratica
                                                               , trunc(sysdate)    -- data_emissione
                                                               , to_char(null)     -- cod_tributo_f24
                                                               , to_char(null)     -- stato_pratica
                                                               );
       -- Determinazione capitolo abbinato all'accertamento contabile
       -- (da memorizzare nel campo "dati_riscossione" di depag_dovuti)
       if w_accertamento is not null then
          w_dati_riscossione := dati_contabili_pkg.f_get_capitolo( p_anno
                                                                 , to_number(substr(w_accertamento,1,4))
                                                                 , to_number(substr(w_accertamento,6))
                                                                 );
       end if;
    end if;
    -- Se si sta eseguendo un calcolo imposta generale o per contribuente, si selezionano le denunce
    -- dell'anno e per ognuna si annullano gli eventuali dovuti;
    -- se si sta eseguendo un calcolo per pratica, il risultato della select e' costituito dalla
    -- pratica stessa
    for rec_ann in sel_pratiche_ann
    loop
      --dbms_output.put_line('Pratica: '||rec_ann.pratica);
      w_idback_ann := rec_ann.cotr_tributo||rec_ann.tipo_occupazione||p_anno||lpad(rec_ann.pratica,10,'0')||
                      rec_ann.cod_fiscale||'%';
      pagonline_tr4.inserimento_log(w_operazione_log||' - annulladovutilike pratica', w_idback_ann);
      --dbms_output.put_line('Prima di annulladovutilike - Retval: '||RetVal);
      RetVal := DEPAG_SERVICE_PKG.ANNULLADOVUTILIKE  (w_des_cliente, w_idback_ann , w_utente_ultimo_agg);
      --dbms_output.put_line('Dopo annulladovutilike - Retval: '||RetVal);
    end loop;
    -- Prima di elaborare, si cancellano tutti i dovuti per tributo, tipo_occupazione
    -- anno e codice fiscale indicato. Se il calcolo imposta è generale, il codice
    -- fiscale sarà '%', per cui si cancellano tutte le righe per tributo e anno.
    if p_cod_fiscale = '%' or p_pratica is null then
      for rec_ann in sel_pratiche_totali_ann
      loop
        --dbms_output.put_line('Tributo: '||rec_ann.cotr_tributo);
        w_idback_ann := rec_ann.cotr_tributo||rec_ann.tipo_occupazione||p_anno||lpad('0',10,'0')||
                        rec_ann.cod_fiscale||'%';
        pagonline_tr4.inserimento_log(w_operazione_log||' - annulladovutilike totale', w_idback_ann);
        --dbms_output.put_line('Prima di annulladovutilike - Retval: '||RetVal);
        RetVal := DEPAG_SERVICE_PKG.ANNULLADOVUTILIKE  (w_des_cliente, w_idback_ann , w_utente_ultimo_agg);
        --dbms_output.put_line('Dopo annulladovutilike - Retval: '||RetVal);
      end loop;
       w_idback_ann := ' ';
    end if;
    --
    -- RetVal > 0 indica che è stato trovato almeno un record in DEPAG_DOVUTI
    -- ed è stato trattato dalla for .. loop
    -- Creazione dovuti per imposta calcolata
    pagonline_tr4.inserimento_log(w_operazione_log||' - prima del loop', w_des_cliente||' ' ||p_tipo_tributo||' ' ||p_anno);
    w_cf_prec      := '*';
    w_pratica_prec := -1;
    for rec_mov in sel_mov
    loop
      --DBMS_OUTPUT.PUT_LINE('CF: '||REC_MOV.cod_fiscale||', IMPORTO: '||REC_MOV.IMPORTO_dovuto);
      -- Gestione del versato: ora si verifica se esistono dei versamenti per contribuente
      -- e se esistono si attribuiscono alle varie rate a scalare
      if rec_mov.cod_fiscale <> w_cf_prec or
         nvl(rec_mov.pratica,0) <> nvl(w_pratica_prec,0) then
         w_cf_prec      := rec_mov.cod_fiscale;
         w_pratica_prec := rec_mov.pratica;
         if rec_mov.pratica is not null then
            -- Gestione del versato: si verifica se esistono dei versamenti per pratica
            -- e se esistono si attribuiscono alle varie rate a scalare
            begin
              select nvl(sum(vers.importo_versato),0),
                     count(*)
                into w_importo_vers,
                     w_conta_vers
                from versamenti vers
               where vers.tipo_tributo||''   = p_tipo_tributo
               --and nvl(vers.rata,0)        = rec_mov.rata
                 and vers.cod_fiscale        = rec_mov.cod_fiscale
                 and vers.anno               = p_anno
                 and vers.pratica            = rec_mov.pratica
               group by vers.cod_fiscale;
            exception
              when others then
                w_importo_vers := 0;
                w_conta_vers := 0;
            end;
         else
            -- Si controlla l'esistenza di eventuali versamenti
            begin
              select nvl(sum(vers.importo_versato),0),
                     count(*)
                into w_importo_vers,
                     w_conta_vers
                from versamenti vers
               where vers.tipo_tributo||''   = p_tipo_tributo
                 and vers.cod_fiscale        = rec_mov.CODICE_IDENT
                 and vers.anno               = p_anno
                 and vers.pratica            is null
                 --and nvl(vers.rata,0)        = rec_mov.rata
               group by vers.cod_fiscale;
            exception
              when others then
                w_importo_vers := 0;
                w_conta_vers := 0;
            end;
         end if;
       end if;
       --DBMS_OUTPUT.PUT_LINE('CF: '||REC_MOV.cod_fiscale||', versato: '||w_importo_vers);
       if nvl(rec_mov.importo_dovuto,0) > 0 then
          if w_importo_vers < rec_mov.IMPORTO_DOVUTO then
             --dbms_output.put_line('Prima di depag_service');
             pagonline_tr4.inserimento_log(w_operazione_log||' - aggiornadovuto', rec_mov.idback);
             -- (VD - 06/05/2022): Dati per contabilita' finanziaria
             -- Composizione del campo "bilancio"
             if w_int_cfa = 'S' and
                w_dati_riscossione is not null and
                w_accertamento is not null then
                w_bilancio := dati_contabili_pkg.f_get_bilancio ( w_dati_riscossione
                                                                , w_accertamento
                                                                , rec_mov.IMPORTO_DOVUTO - w_importo_vers
                                                                );
             else
                w_bilancio := null;
             end if;
             RetVal:=DEPAG_SERVICE_PKG.AGGIORNADOVUTO(rec_mov.ENTE,
                                                      rec_mov.IUD, --iud
                                                      rec_mov.SERVIZIO,
                                                      --rec_mov.idback,
                                                      case
                                                        when w_conta_vers > 0 then
                                                          rec_mov.idback||'-'||w_conta_vers
                                                        else
                                                          rec_mov.idback
                                                      end,--idback
                                                      rec_mov.BACKEND,
                                                      rec_mov.COD_IUV,
                                                      rec_mov.TIPO_IDENT,
                                                      rec_mov.CODICE_IDENT,
                                                      rec_mov.ANAG_PAGATORE,
                                                      rec_mov.INDIRIZZO_PAGATORE,
                                                      substr(rec_mov.CIVICO_PAGATORE,1,16),
                                                      rec_mov.CAP_PAGATORE,
                                                      rec_mov.LOCALITA_PAGATORE,
                                                      rec_mov.PROV_PAGATORE,
                                                      rec_mov.NAZ_PAGATORE,
                                                      rec_mov.EMAIL_PAGATORE,
                                                      rec_mov.DATA_SCADENZA,
                                                      --rec_mov.IMPORTO_DOVUTO,
                                                      case
                                                        when w_conta_vers > 0 then
                                                          rec_mov.IMPORTO_DOVUTO - w_importo_vers
                                                        else
                                                          rec_mov.IMPORTO_DOVUTO
                                                      end, -- importo dovuto
                                                      rec_mov.COMMISSIONE_CARICO_PA,
                                                      rec_mov.TIPO_DOVUTO,
                                                      rec_mov.TIPO_VERSAMENTO,
                                                      rec_mov.CAUSALE_VERSAMENTO,
                                                      rec_mov.DATI_RISCOSSIONE,
                                                      rec_mov.UTENTE_ULTIMO_AGG,
             -- (VD - 06/05/2022): Nuovi campi per integrazione con contabilita' finanziaria
                                                      to_char(null),  -- note
                                                      to_char(null),  -- dati_extra
                                                      w_accertamento, -- accertamento
                                                      w_bilancio      -- bilancio
                                                     );
             --dbms_output.put_line('Dopo depag_service - retval: '||retval);
             if retval in ('PO0100','PO0099') then
                w_errore := 'Errore in inserimento DEPAG_DOVUTI 1 '||rec_mov.idback||' '||Retval;
                pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
                w_errore := null;
             else
                w_return := w_return +1;
             end if;
          end if;
          if w_importo_vers < rec_mov.importo_dovuto then
             w_importo_vers := 0;
          else
             w_importo_vers := w_importo_vers - rec_mov.importo_dovuto;
          end if;
       end if;
       w_iud_prec := rec_mov.iud;
   end loop;
   pagonline_tr4.inserimento_log(w_operazione_log||' - Fine', w_des_cliente);*/
   -- (VD - 16/05/2022): si richiama la funzione del package standard PAGONLINE_TR4
   w_return := pagonline_tr4.inserimento_dovuti_cu ( p_tipo_tributo
                                                   , p_cod_fiscale
                                                   , p_anno
                                                   , p_pratica
                                                   , p_chk_rate
                                                   );
   return w_return;
/*exception
  when errore then
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       ROLLBACK;
       w_return := -1;
       return w_return;
  when others then
       w_errore := 'errore '||SQLERRM;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       ROLLBACK;
       w_return := -1;
       return w_return;*/
end inserimento_dovuti;
--------------------------------------------------------------------------------------------------------
function aggiornamento_pagamenti
( p_ente                    in varchar2 default null
, p_idback                  in varchar2 default null
, p_iuv                     in varchar2
, p_importo_versato         in varchar2
, p_data_pagamento          in varchar2
, p_utente                  in varchar2
, p_servizio                in varchar2 default null
) return number is
/*************************************************************************
 NOME:         AGGIORNAMENTO_PAGAMENTI
 DESCRIZIONE:
 PARAMETRI:
 ANNOTAZIONI: -
 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 004   19/03/2021  RV      Prima emissione, basato su medesima funzione di PAGONLINE_TR4 Revsione 003 (VD)
*************************************************************************/
  RetVal                    varchar2(8);
  w_utente_ultimo_agg       varchar(8)  := 'TRIBUTI';
  w_servizio                depag_dovuti.servizio%type;
  w_insert_pag              number;
  w_importo_pag             number;
  w_titolo_log              varchar2(100) := 'aggiornamento_pagamenti';
  w_operazione_log          varchar2(100);
  w_errore                  varchar2(4000);
  errore                    exception;
  w_dep_record              depag_dovuti%rowtype;
  w_fonte                   number;
  w_tipo_tributo            varchar2(5);
  w_anno                    number;
  w_pratica                 number;
  w_cod_fiscale             varchar2(16);
  w_rata                    number;
  w_sequenza                number;
  w_data_pagamento          date;
  w_ruolo                   number;
  -- Variabili per gestione separatore decimali
  -- a seconda dell'impostazione NLS_NUMERIC
  -- di Oracle
  w_da_sostituire            varchar2(1);
  w_sostituto                varchar2(1);
begin
  -- (VD - 16/05/2022): commentato codice perche' si lancia l'analoga funzione
  --                    del package PAGONLINE_TR4 opportunamente modificata
  --
  /*pagonline_tr4.inserimento_log(w_operazione_log, 'Gestione movimenti per ente '||p_ente||' idback:'||p_idback||' IUV:'||p_iuv||' Importo:'||p_importo_versato||' Data:'||p_data_pagamento);
  --
  -- Selezione del parametro NLS_NUMERIC_CHARACTERS
  --
  begin
    select decode(substr(value,1,1)
                 ,'.',',','.')
         , substr(value,1,1)
      into w_da_sostituire
         , w_sostituto
      from nls_session_parameters
     where parameter = 'NLS_NUMERIC_CHARACTERS';
  exception
    when others then
      w_da_sostituire := ',';
      w_sostituto := '.';
  end;
  -- (VD - 17/12/2020): se il servizio è null, si ricerca il valore su depag_dovuti
  if p_servizio is null then
     w_dep_record := depag_service_pkg.dovuto_per_idback(p_ente,p_idback,null);
     if w_dep_record.servizio is not null then
        w_servizio := w_dep_record.servizio;
     else
        w_errore:= 'Impossibile determinare il servizio - IUV: '||p_iuv||', id.Back: '||p_idback;
        pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
        return 0;
     end if;
  else
     w_servizio := p_servizio;
  end if;
  --
  w_fonte          := f_inpa_valore('FONT_DEPAG');
  w_data_pagamento := trunc(to_date(p_data_pagamento,'dd/mm/yyyy hh24.mi.ss'));
  w_ruolo          := to_number(null);
  w_pratica        := to_number(null);
  -- (VD - 09/03/2022): se i quattro caratteri a partire dalla posizione 7
  --                    dell'idback sono numerici, significa che si sta
  --                    trattando un versamento d'imposta.
  --                    In caso contrario si tratta di versamento su
  --                    violazione (LIQ%, ACC%, RAV%) quindi la pratica
  --                    inizia alla posizione 15.
  if rtrim(substr(p_idback,1,5)) in('CUNIP','CUNIT','CUMEP','CUMET') then
     w_tipo_tributo   := rtrim(substr(p_idback,1,4));
     w_anno           := to_number(substr(p_idback,6,4));
     w_pratica        := to_number(substr(p_idback,10,10));
     w_cod_fiscale    := rtrim(substr(p_idback,20,16));
     w_rata           := to_number(substr(p_idback,36,1));
  elsif
  -- (VD - 09/03/2022): gestione idback per violazioni e ravvedimenti
     substr(p_idback,1,6) in ('CUNI P','CUNI T','CUME P','CUME T') then
     w_tipo_tributo   := rtrim(substr(p_idback,1,4));
     w_anno           := to_number(substr(p_idback,11,4));
     w_pratica        := to_number(substr(p_idback,15,10));
     w_cod_fiscale    := rtrim(substr(p_idback,25,16));
     w_rata           := to_number(substr(p_idback,41,2));
  else
     w_errore := 'Tipo tributo non previsto'||rtrim(substr(p_idback,1,5))||
                 ', idback '||p_idback;
     RAISE errore;
  end if;
  if w_tipo_tributo = 'CUME' then
     w_tipo_tributo := 'CUNI';
  end if;
  --
  -- Conversione importo a seconda del parametro NLS_NUMERIC di Oracle
  w_importo_pag := to_number(translate(p_importo_versato,w_da_sostituire,w_sostituto));
  --dbms_output.put_line('Importo: '||p_importo_versato||', '||w_importo_pag);
  BEGIN -- Assegnazione Numero Progressivo
    select nvl(max(vers.sequenza),0)+1
      into w_sequenza
      from versamenti vers
     where vers.cod_fiscale     = w_cod_fiscale
       and vers.anno            = w_anno
       and vers.tipo_tributo    = w_tipo_tributo
    ;
  END;
  BEGIN
    insert into versamenti
           (cod_fiscale
           ,anno
           ,pratica
           ,tipo_tributo
           ,sequenza
           ,descrizione
           ,ufficio_pt
           ,data_pagamento
           ,importo_versato
           ,fonte
           ,utente
           ,data_variazione
           ,data_reg
           ,ruolo
           ,rata
           ,note
           ,servizio
           ,idback)
     select w_cod_fiscale
           ,w_anno
           ,decode(w_pratica,0,to_number(null),w_pratica)
           ,w_tipo_tributo
           ,w_sequenza
           ,'VERSAMENTO IMPORTATO DA PAGONLINE'
           ,'' --rec_vers.ufficio_pt
           ,w_data_pagamento
           ,w_importo_pag
           ,w_fonte
           ,p_utente
           ,trunc(sysdate)
           ,sysdate
           ,w_ruolo
           ,w_rata
           ,'IUV: '||p_iuv
           , w_servizio
           , p_idback
       from dual
     ;
  EXCEPTION
    WHEN others THEN
      w_errore := 'Errore in inserimento versamento'||
                  ' di '||w_cod_fiscale||' progressivo '||
                  to_char(w_sequenza)||' ('||sqlerrm||')';
      RAISE errore;
  END;*/
  --
  -- (VD - 16/05/2022): si lancia l'analoga funzione del package PAGONLINE_TR4
  --
  RetVal := pagonline_tr4.aggiornamento_pagamenti ( p_ente
                                                  , p_idback
                                                  , p_iuv
                                                  , p_importo_versato
                                                  , p_data_pagamento
                                                  , p_utente
                                                  , p_servizio
                                                  );
  return RetVal;
/*exception
  when errore then
       ROLLBACK;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       return 0;
  when others then
       ROLLBACK;
       w_errore := 'errore '||SQLERRM;
       pagonline_tr4.inserimento_log(w_operazione_log, w_errore);
       return 0;*/
end aggiornamento_pagamenti;
--------------------------------------------------------------------------------------------------------
function j_aggiornamento_pagamenti
( p_ente                    in varchar2 default null
, p_idback                  in varchar2 default null
) return number
is
/******************************************************************************
 NOME:        J_AGGIORNAMENTO_PAGAMENTI
 DESCRIZIONE: Caricamento job.
 PARAMETRI:   p_operazione         Descrizione operazione eseguita.
              p_note               Dati dell'operazione eseguita.
 NOTE:
******************************************************************************/  job_number  number;
begin
  dbms_job.submit(job_number
                 ,'declare dummy number; BEGIN dummy := pagonline_tr4_cu.aggiornamento_pagamenti(''' || p_ente ||
                  ''','''||p_idback||'''); END;'
                 ,sysdate + 1 / 5760);
  commit;
  return job_number;
end;
end PAGONLINE_TR4_CU;
/

