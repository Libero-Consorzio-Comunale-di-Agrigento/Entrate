--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_solleciti stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_SOLLECITI
/*************************************************************************
  Rev.    Date         Author      Note
  006     20/05/2025   RV          #77609
                                   Adeguamento nuovo DL regime sanzionatorio
  005     20/09/2023   VM          #66699 - sostituito filtro ricerca sogg.cognome_nome
                                   con sogg.cognome_nome_ric
  004     03/03/2023   DM          Non si genera il sollecito se per lo stesso anno
                                   ne esiste un altro già notificato o numerato
  003     10/02/2023   DM          Aggiunta gestione data scadenza
  002     09/02/2023   RV          Tolto flag a_escludi_acc_not
  001     30/01/2023   AB          Tolto il controllo di sol_prec x utente #
  000     17/01/2023   RV          #Issue61561
                                   Versione iniziale pertendo da CALCOLO_ACC_AUTOMATICO
*************************************************************************/
(a_tipo_tributo        in  varchar2
,a_anno                in  number
,a_cod_fiscale         in  varchar2
,a_cognome_nome        in  varchar2
,a_tributo             in  number
,a_limite_inf          in  number
,a_limite_sup          in  number
,a_categoria_da        in  number
,a_categoria_a         in  number
,a_se_spese_notifica   in  varchar2
,a_data_scadenza       in  date
,a_utente              in  varchar2
,a_pratica             out number
) IS
--
-- a_limite_rimborsi e` un indicatore che se = S applica l`eventuale limite
-- introdotto anche agli accertamenti a rimborso in valore assoluto.
--
errore                  exception;
w_errore                varchar2(2000);
w_cf                    varchar2(16);
w_gt                    varchar2(10);
w_pr                    number;
w_ins_pratica           varchar2(2);
--w_err                   number; --MAI USATO
w_ind                   number;
w_tot                   number;
w_dep                   number;
w_dep_r1                number;
w_dep_r2                number;
w_dep_r3                number;
w_dep_r4                number;
w_dep_rt                number;
--w_cod_sanzione          number; --MAI USATO
w_imposta               number;
w_imposta_r1            number;
w_imposta_r2            number;
w_imposta_r3            number;
w_imposta_r4            number;
w_imposta_rt            number;
w_scad                  date;
w_scad_r1               date;
w_scad_r2               date;
w_scad_r3               date;
w_scad_r4               date;
w_scadenza_r1           date;
w_scadenza_r2           date;
w_scadenza_r3           date;
w_scadenza_r4           date;
w_scadenza_invalid      date;
w_omesso_r1             number;
w_omesso_r2             number;
w_omesso_r3             number;
w_omesso_r4             number;
w_eccedenza_r1          number;
w_eccedenza_r2          number;
w_eccedenza_r3          number;
w_eccedenza_r4          number;
w_versato_r1            number;
w_versato_r1_da_r2      number;
w_versato_r1_da_r3      number;
w_versato_r1_da_r4      number;
w_versato_r2            number;
w_versato_r2_da_r1      number;
w_versato_r2_da_r3      number;
w_versato_r2_da_r4      number;
w_versato_r3            number;
w_versato_r3_da_r1      number;
w_versato_r3_da_r2      number;
w_versato_r3_da_r4      number;
w_versato_r4            number;
w_versato_r4_da_r1      number;
w_versato_r4_da_r2      number;
w_versato_r4_da_r3      number;
w_tot_versato           number;
w_tot_versato_r1        number;
w_tot_versato_r2        number;
w_tot_versato_r3        number;
w_tot_versato_r4        number;
w_versato_ravv          number;
w_versato_ravv_r1       number;
w_versato_ravv_r2       number;
w_versato_ravv_r3       number;
w_versato_ravv_r4       number;
w_data_versamento_r1    date;
w_data_versamento_r2    date;
w_data_versamento_r3    date;
w_data_versamento_r4    date;
w_cod_fiscale_prec      varchar2(16);
w_cod_fiscale           varchar2(16);
w_gruppo_tributo_prec   varchar2(10);
w_gruppo_tributo        varchar2(10);
w_oggetto_pratica       number;
w_oggetto_pratica_rif   number;
w_oggetto               number;
w_pratica_da_sol_prec   number;
w_pratica_da_sol        number;
w_pratica               number;
w_data_pratica          date;
w_numero_pratica        varchar2(15);
w_tipo_pratica          varchar2(1);
w_tipo_evento           varchar2(1);
w_tipo_occupazione      varchar2(1);
w_tipo_tributo_gruppo   varchar2(100);
w_dal                   date;
w_al                    date;
w_anno                  number;
--w_min_ogim              number; --MAI USATO
--w_max_ogim              number; --MAI USATO
--w_conta                 number; --MAI USATO
w_max_rata              number;
w_stringa_vers_r1       varchar2(2300);
w_stringa_vers_r2       varchar2(2300);
w_stringa_vers_r3       varchar2(2300);
w_stringa_vers_r4       varchar2(2300);
w_stringa_eccedenze_r1  varchar2(2300);
w_stringa_eccedenze_r2  varchar2(2300);
w_stringa_eccedenze_r3  varchar2(2300);
w_stringa_eccedenze_r4  varchar2(2300);
w_ind_stringa           number;
--w_ind_stringa_2         number; --MAI USATO
w_imp_confronto         number;
w_round                 varchar2(1);
--
-- Pratiche generate da precedenti calcoli di sollecito.
--
CURSOR sel_sol_prec ( p_tipo_trib    varchar2
                    , p_anno         number
                    , p_cod_fiscale  varchar2
                    , p_cognome_nome varchar2
                    , p_tributo      number
                    , p_categoria_da number
                    , p_categoria_a  number
                    ) IS
select prtr.pratica
  from pratiche_tributo     prtr
      ,contribuenti         cont
      ,soggetti             sogg
      ,oggetti_pratica      ogpr
 where prtr.tipo_tributo||''   = p_tipo_trib
   and prtr.anno               = p_anno
   and prtr.tipo_pratica       = 'S'
   and prtr.tipo_evento        = 'A'
   and prtr.data_notifica     is null
   and prtr.numero            is null
--   and substr(prtr.utente,1,1) = '#'    AB (30/01/2023 tolto il controllo d'accordo coi servizi
   and prtr.cod_fiscale       like p_cod_fiscale
   and cont.cod_fiscale        = prtr.cod_fiscale
   and ogpr.pratica            = prtr.pratica
   and sogg.ni                 = cont.ni
   and sogg.cognome_nome_ric like p_cognome_nome
   and not exists
               ( select ogva5.oggetto_pratica
                   from oggetti_validita ogva5
                  where ogva5.cod_fiscale = cont.cod_fiscale
                    and ogva5.tipo_tributo||''   = p_tipo_trib
                    and nvl(to_number(to_char(ogva5.dal,'yyyy')),0)
                                                       <= p_anno
                    and nvl(to_number(to_char(ogva5.al,'yyyy')),9999)
                                                       >= p_anno
                  minus
                 select ogva4.oggetto_pratica
                   from oggetti_pratica  ogpr4
                      , oggetti_validita ogva4
                  where ogva4.cod_fiscale = cont.cod_fiscale
                    and ogpr4.oggetto_pratica    = ogva4.oggetto_pratica
                    and ogva4.tipo_tributo||''   = p_tipo_trib
                    and nvl(to_number(to_char(ogva4.dal,'yyyy')),0)
                                                       <= p_anno
                    and nvl(to_number(to_char(ogva4.al,'yyyy')),9999)
                                                       >= p_anno
                    and ogpr4.tributo            = decode(a_tributo,-1,ogpr4.tributo,p_tributo)
                    and ogpr4.categoria    between p_categoria_da
                                               and p_categoria_a
               )
 group by prtr.pratica
 order by 1
;
--
--   Selezione delle pratiche scadute.
--   Non vengono considerate le Pratiche TOSAP relative all`anno
--   se hanno Data di Concessione ed eventuale rateizzazione su Oggetto.
--
cursor sel_sol (p_tipo_trib    varchar2
              , p_anno         number
              , p_cod_fiscale  varchar2
              , p_cognome_nome varchar2
              , p_tributo      number
              , p_categoria_da number
              , p_categoria_a  number) is
select ogac.cod_fiscale
      ,ogac.gruppo_tributo
      ,ogac.oggetto_pratica
      ,ogac.oggetto_pratica_rif
      ,ogac.oggetto
      ,ogac.pratica
      ,ogac.pratica_sol
      ,ogac.data
      ,ogac.numero
      ,ogac.anno
      ,ogac.tipo_pratica
      ,ogac.tipo_evento
      ,ogac.tipo_occupazione
      ,ogac.dal
      ,ogac.al
from (
--
select ogva.cod_fiscale
      ,cotr.gruppo_tributo gruppo_tributo
      ,ogva.oggetto_pratica
      ,ogva.oggetto_pratica_rif
      ,ogva.oggetto
      ,ogva.pratica
      ,case when (p_tipo_trib = 'CUNI') and
                 ((ogva.tipo_occupazione = 'T') or
                  (nvl(to_char(ogva.dal,'yyyymmdd'),'19000101') >= lpad(to_char(p_anno),4,'0')||'0101')
                 ) then
        ogva.pratica
      else
        null
      end pratica_sol
      ,ogva.data
      ,ogva.numero
      ,ogva.anno
      ,ogva.tipo_pratica
      ,ogva.tipo_evento
      ,ogva.tipo_occupazione
      ,ogva.dal
      ,ogva.al
  from oggetti_pratica     ogpr
      ,codici_tributo      cotr
      ,oggetti_validita    ogva
      ,contribuenti        cont
      ,soggetti            sogg
 where cont.cod_fiscale                like p_cod_fiscale
   and sogg.ni                            = cont.ni
   and sogg.cognome_nome_ric like p_cognome_nome
   and ogpr.oggetto_pratica               = ogva.oggetto_pratica
   and ogva.tipo_tributo||''              = p_tipo_trib
   and ogva.cod_fiscale                   = cont.cod_fiscale
   and nvl(to_number(to_char(ogva.dal,'yyyy')),0)
                                         <= p_anno
   and nvl(to_number(to_char(ogva.al,'yyyy')),9999)
                                         >= p_anno
   and decode(ogva.tipo_pratica,'S',ogva.anno,p_anno - 1)
                                         <> p_anno
   and decode(ogva.tipo_pratica,'S',ogva.flag_denuncia,'S')
                                          = 'S'
   and nvl(ogva.stato_accertamento,'D')   = 'D'
   and ogpr.tributo = cotr.tributo(+)
-- RV (19/02/2024) : #69834 Solo per CUNI escludere sempre dal calcolo gli oggetti nati il 31/12/anno_calcolo
   and ((p_tipo_trib != 'CUNI') or
        (nvl(to_char(ogva.dal,'yyyymmdd'),'19000101') <> lpad(to_char(p_anno),4,'0')||'1231'))
   and not exists
               ( select ogva5.oggetto_pratica
                   from oggetti_validita ogva5
                  where ogva5.cod_fiscale = ogva.cod_fiscale
                    and ogva5.tipo_tributo||''   = p_tipo_trib
                    and nvl(to_number(to_char(ogva5.dal,'yyyy')),0)
                                                       <= p_anno
                    and nvl(to_number(to_char(ogva5.al,'yyyy')),9999)
                                                       >= p_anno
                  minus
                 select ogva4.oggetto_pratica
                   from oggetti_pratica  ogpr4
                      , oggetti_validita ogva4
                  where ogva4.cod_fiscale = ogva.cod_fiscale
                    and ogpr4.oggetto_pratica    = ogva4.oggetto_pratica
                    and ogva4.tipo_tributo||''   = p_tipo_trib
                    and nvl(to_number(to_char(ogva4.dal,'yyyy')),0)
                                                       <= p_anno
                    and nvl(to_number(to_char(ogva4.al,'yyyy')),9999)
                                                       >= p_anno
                    and ogpr4.tributo            = decode(p_tributo,-1,ogpr4.tributo,p_tributo)
                    and ogpr4.categoria    between p_categoria_da
                                               and p_categoria_a
               )
   and F_CONCESSIONE_ATTIVA(ogva.cod_fiscale,p_tipo_trib,p_anno
                           ,ogva.pratica,null,null
                           )              = 'NO'
   and (    ogva.tipo_occupazione||''     = 'T'
        or  ogva.tipo_occupazione||''     = 'P'
        and not exists
           (select 1
              from oggetti_validita ogv2
             where ogv2.cod_fiscale       = ogva.cod_fiscale
               and ogv2.tipo_tributo||''  = ogva.tipo_tributo
               and ogv2.oggetto_pratica_rif
                                          = ogva.oggetto_pratica_rif
               and decode(ogv2.tipo_pratica,'S',ogv2.anno,p_anno - 1)
                                         <> p_anno
               and decode(ogv2.tipo_pratica,'S',ogv2.flag_denuncia,'S')
                                          = 'S'
               and nvl(ogv2.stato_accertamento,'D')
                                          = 'D'
               and nvl(to_number(to_char(ogv2.dal,'yyyy')),0)
                                         <= p_anno
               and nvl(to_number(to_char(ogv2.al ,'yyyy')),9999)
                                         >= p_anno
               and (    nvl(ogv2.dal,to_date('01011900','ddmmyyyy'))
                                          >
                        nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                    or  nvl(ogv2.dal,to_date('01011900','ddmmyyyy'))
                                          =
                        nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                    and nvl(ogv2.data,to_date('01011900','ddmmyyyy'))
                                          >
                        nvl(ogva.data,to_date('01011900','ddmmyyyy'))
                    or  nvl(ogv2.dal,to_date('01011900','ddmmyyyy'))
                                          =
                        nvl(ogva.dal,to_date('01011900','ddmmyyyy'))
                    and nvl(ogv2.data,to_date('01011900','ddmmyyyy'))
                                          =
                        nvl(ogva.data,to_date('01011900','ddmmyyyy'))
                    and ogv2.pratica      > ogva.pratica
                   )
           )
       )
   and not exists
      (select 1
        from pratiche_tributo prt3
       where prt3.tipo_tributo = p_tipo_trib
         and prt3.anno = p_anno
         and prt3.cod_fiscale = ogva.cod_fiscale
         and prt3.tipo_pratica in ('A', 'S')
         and prt3.tipo_evento = 'A'
         and nvl(prt3.stato_accertamento,'D') = 'D'
         and (prt3.data_notifica is not null
              or prt3.numero is not null))
) ogac
--
 order by
       cod_fiscale,
       gruppo_tributo,
       pratica_sol
;
--
-- Determinazione delle Scadenze delle Rate per Anno e Tipo Tributo.
--
cursor sel_scad (
  p_tipo_tributo in varchar2
, p_gruppo_tributo in varchar2
, p_anno in number
) is
select scad.data_scadenza
      ,scad.rata
  from scadenze scad
 where scad.tipo_tributo  = p_tipo_tributo
   and scad.anno          = p_anno
   and scad.rata         is not null
   and scad.tipo_scadenza = 'V'
   and nvl(scad.tipo_occupazione,'P') = 'P'
   and p_gruppo_tributo is not null
   and scad.gruppo_tributo = p_gruppo_tributo
union
select scad.data_scadenza
      ,scad.rata
  from scadenze scad
 where scad.tipo_tributo  = p_tipo_tributo
   and scad.anno          = p_anno
   and scad.rata         is not null
   and scad.tipo_scadenza = 'V'
   and scad.gruppo_tributo is null
   and not exists (select 1
                     from scadenze scad1
                    where scad1.tipo_tributo  = p_tipo_tributo
                      and scad1.anno          = p_anno
                      and scad1.rata         = scad.rata
                      and scad1.tipo_scadenza = 'V'
                      and nvl(scad1.tipo_occupazione,'P') = 'P'
                      and p_gruppo_tributo is not null
                      and scad1.gruppo_tributo = p_gruppo_tributo)
;
--
-- Determinazione dei Versamenti.
-- (VD - 08/04/2021): Modificate condizioni di where
--
cursor sel_vers (p_cod_fiscale  in varchar2
                ,p_tipo_tributo in varchar2
                ,p_tipo_tributo_gruppo in varchar2
                ,p_pratica_da_sol in number
                ,p_anno         in number
                ,p_scadenza_r1  in date
                ,p_scadenza_r2  in date
                ,p_scadenza_r3  in date
                ,p_scadenza_r4  in date
                ) is
select decode(p_scadenza_r1
             ,to_date('31122999','ddmmyyyy'),0
                  ,decode(nvl(vers.rata,0)
                         ,0,vers.importo_versato
                         ,1,vers.importo_versato
                           ,0
                         )
             ) versato_r1
      ,decode(p_scadenza_r1
             ,to_date('31122999','ddmmyyyy'),to_date('31122999','ddmmyyyy')
                  ,decode(nvl(vers.rata,0)
                         ,0,nvl(vers.data_pagamento,to_date('01011900','ddmmyyyy'))
                         ,1,nvl(vers.data_pagamento,to_date('01011900','ddmmyyyy'))
                           ,to_date('31122999','ddmmyyyy')
                         )
             ) data_pagamento_r1
      ,decode(p_scadenza_r2
             ,to_date('31122999','ddmmyyyy'),0
                  ,decode(nvl(vers.rata,0)
                         ,2,vers.importo_versato
                           ,0
                         )
             ) versato_r2
      ,decode(p_scadenza_r2
             ,to_date('31122999','ddmmyyyy'),to_date('31122999','ddmmyyyy')
                  ,decode(nvl(vers.rata,0)
                         ,2,nvl(vers.data_pagamento,to_date('01011900','ddmmyyyy'))
                           ,to_date('31122999','ddmmyyyy')
                         )
             ) data_pagamento_r2
      ,decode(p_scadenza_r3
             ,to_date('31122999','ddmmyyyy'),0
                  ,decode(nvl(vers.rata,0)
                         ,3,vers.importo_versato
                           ,0
                         )
             ) versato_r3
      ,decode(p_scadenza_r3
             ,to_date('31122999','ddmmyyyy'),to_date('31122999','ddmmyyyy')
                  ,decode(nvl(vers.rata,0)
                         ,3,nvl(vers.data_pagamento,to_date('01011900','ddmmyyyy'))
                           ,to_date('31122999','ddmmyyyy')
                         )
             ) data_pagamento_r3
      ,decode(p_scadenza_r4
             ,to_date('31122999','ddmmyyyy'),0
                  ,decode(nvl(vers.rata,0)
                         ,4,vers.importo_versato
                           ,0
                         )
             ) versato_r4
      ,decode(p_scadenza_r4
             ,to_date('31122999','ddmmyyyy'),to_date('31122999','ddmmyyyy')
                  ,decode(nvl(vers.rata,0)
                         ,4,nvl(vers.data_pagamento,to_date('01011900','ddmmyyyy'))
                           ,to_date('31122999','ddmmyyyy')
                         )
             ) data_pagamento_r4
      ,vers.importo_versato versato
      ,vers.data_pagamento
  from versamenti                         vers
    --  ,pratiche_tributo                   prtr
 where vers.cod_fiscale                      = p_cod_fiscale
   and vers.tipo_tributo                     = p_tipo_tributo
   and vers.anno                             = p_anno
   and ((vers.servizio is null) or
        (p_tipo_tributo_gruppo is null) or
        (vers.servizio in (select distinct servizio
                           from (select F_DEPAG_SERVIZIO(p_tipo_tributo_gruppo,'P','N','N') as servizio from dual
                                  union
                                 select F_DEPAG_SERVIZIO(p_tipo_tributo_gruppo,'P','N','S') as servizio from dual
                                  union
                                 select F_DEPAG_SERVIZIO(p_tipo_tributo_gruppo,'T','N','N') as servizio from dual
                                  union
                                 select F_DEPAG_SERVIZIO(p_tipo_tributo_gruppo,'T','N','S') as servizio from dual)))
   )
   -- (VD - 08/04/2021): modificata selezione versamenti. Ora si
   --                    trattano solo i versamenti senza pratica
   --                    oppure quelli relativi a denunce dell'anno
   --                    con occupazione permanente
   -- (RV - 10/04/2024): caso speciale CUNI - si prendono i versamenti:
   --                    - senza pratica per il calcolo anni precedenti (p_pratica_da_sol = null)
   --                    - solo quelli collegati alla pratica per gli altri casi
   and (
        ((p_tipo_tributo = 'CUNI') and
         (((p_pratica_da_sol is null) and (vers.pratica is null))
         or
         (vers.pratica = p_pratica_da_sol)
         )
        )
       or
        ((p_tipo_tributo != 'CUNI') and
         (vers.pratica is null or
       (vers.pratica is not null
        and exists (select 'x'
                      from pratiche_tributo prtr
                         , oggetti_pratica  ogpr
                     where prtr.pratica          = vers.pratica
                       and prtr.tipo_pratica     = 'D'
                       and prtr.anno             = p_anno
                       and prtr.pratica          = ogpr.pratica
                       and ogpr.tipo_occupazione = 'P'
                   )
        and F_CONCESSIONE_ATTIVA(p_cod_fiscale,p_tipo_tributo,p_anno
                                ,vers.pratica,null,vers.oggetto_imposta
                                )              = 'NO'
          )
         )
        )
       )
 order by
       vers.data_pagamento
;
--
-- Determinazione dei Solleciti che devono essere eliminati
-- per non avere raggiunto il limite.
--
cursor sel_prat_elim (p_limite_inf      number
                     ,p_limite_sup      number
                     ,p_tipo_trib       varchar2
                     ,p_anno            number
                     ,p_cod_fiscale     varchar2
                     ,p_cognome_nome    varchar2
                     ) is
select prtr.pratica
  from pratiche_tributo  prtr
      ,contribuenti      cont
      ,soggetti          sogg
-- (VD - 13/03/2019): aggiunto nvl su importo totale per trattare
--                    anche pratiche prive di sanzioni
 where nvl(prtr.importo_totale,0) not between nvl(p_limite_inf,-999999999.99) and nvl(p_limite_sup,999999999.99)
   and prtr.tipo_tributo||''   = p_tipo_trib
   and prtr.anno               = p_anno
   and prtr.tipo_pratica       = 'S'
   and prtr.tipo_evento        = 'A'
   and prtr.data_notifica     is null
   and prtr.numero            is null
   and substr(prtr.utente,1,1) = '#'
   and prtr.cod_fiscale       like p_cod_fiscale
   and cont.cod_fiscale        = prtr.cod_fiscale
   and sogg.ni                 = cont.ni
   and sogg.cognome_nome_ric like p_cognome_nome
 order by 1
;
--
-- Sistema eccedenze
--
PROCEDURE SISTEMA_ECCEDENZE (p_importo   in     number
                           , p_stringa_1 in out varchar2
                           , p_stringa_2 in out varchar2
                              )
IS
w_importo                  number;
w_stringa_1                varchar2(2300);
w_stringa_2                varchar2(2300);
w_imp_confronto            number;
w_ind                      number;
w_ind_2                    number;
BEGIN
   w_importo         := p_importo;
   w_stringa_1       := p_stringa_1;
   w_stringa_2       := p_stringa_2;
   w_ind             := nvl(length(w_stringa_1),0) / 23;
   w_imp_confronto   := 0;
   if w_importo > 0 then
      loop
         if w_ind = 0 then
            exit;
         end if;
--
-- Caso di raggiungimento del valore; la parte di valore si riporta
-- nella stringa 2 e si aggiorna la stringa 1 con la quota
-- rimasta dopo avere sottratto la quota spostata nella stringa 2.
--
         if w_imp_confronto + to_number(substr(w_stringa_1,w_ind * 23 - 14,15)) / 100
                            > w_importo then
            w_ind_2 := 0;
            loop
--
-- La data di scadenza non esiste tra gli elementi memorizzati
-- nella stringa 2 per cui viene accodato un nuovo elemento.
--
               if nvl(length(w_stringa_2),0) < w_ind_2 * 23 + 1 then
                  w_stringa_2 := w_stringa_2||
                                 substr(w_stringa_1,w_ind * 23 - 22,8)||
                                 lpad(to_char((w_importo - w_imp_confronto) * 100),15,'0');
                  w_stringa_1 := substr(w_stringa_1,1,w_ind * 23 - 15)||
                                 lpad(to_char(to_number(substr(w_stringa_1,w_ind * 23 - 14,15)) -
                                 to_number(substr(w_stringa_2,w_ind_2 * 23 + 9,15))),15,'0')||
                                 substr(w_stringa_1,w_ind * 23 + 1);
                  exit;
               end if;
--
-- La data di scadenza esiste nella stringa 2 per cui
-- si incrementa la quota a quella esistente.
--
               if substr(w_stringa_1,w_ind * 23 - 22,8) =
                  substr(w_stringa_2,w_ind_2 * 23 + 1,8) then
                  w_stringa_2 := substr(w_stringa_2,1,w_ind_2 * 23 + 8)||
                                 lpad(to_char(to_number(substr(w_stringa_2,w_ind_2 * 23 + 9,15)) +
                                              (w_importo - w_imp_confronto) * 100),15,'0')||
                                 substr(w_stringa_2,w_ind_2 * 23 + 24);
                  w_stringa_1 := substr(w_stringa_1,1,w_ind * 23 - 15)||
                                 lpad(to_char(to_number(substr(w_stringa_1,w_ind * 23 - 14,15)) -
                                              (w_importo - w_imp_confronto) * 100),15,'0')||
                                 substr(w_stringa_1,w_ind * 23 + 1);
                  exit;
               end if;
--
-- Elemento non trovato: si continua ad esaminare la stringa eccedenze.
--
               w_ind_2 := w_ind_2 + 1;
            end loop;
         else
--
-- Caso di Importo non raggiunto: tutta la quota della stringa 1 va
-- nella stringa 2 e si incrementa il valore di confronto per
-- il raggiungimento del valore  (w_imp_confronto).
--
            w_ind_2 := 0;
            loop
--
-- La data di scadenza non esiste tra gli elementi memorizzati
-- nella stringa 2 per cui viene accodato un nuovo elemento.
--
               if nvl(length(w_stringa_2),0) < w_ind_2 * 23 + 1 then
                  w_stringa_2     := w_stringa_2||
                                     substr(w_stringa_1,w_ind * 23 - 22,23);
                  w_imp_confronto := w_imp_confronto +
                                     to_number(substr(w_stringa_1,w_ind * 23 - 14,15)) / 100;
                  w_stringa_1     := substr(w_stringa_1,1,w_ind * 23 - 15)||
                                     lpad('0',15,'0')||
                                     substr(w_stringa_1,w_ind * 23 + 1);
                  exit;
               end if;
--
-- La data di scadenza esiste nella stringa 2 per cui
-- si incrementa la quota a quella esistente.
--
               if substr(w_stringa_1,w_ind * 23 - 22,8) =
                  substr(w_stringa_2,w_ind_2 * 23 + 1,8) then
                  w_stringa_2     := substr(w_stringa_2,1,w_ind_2 * 23 + 8)||
                                     substr(w_stringa_1,w_ind * 23 - 14,15)||
                                     substr(w_stringa_2,w_ind_2 * 23 + 24);
                  w_imp_confronto := w_imp_confronto +
                                     to_number(substr(w_stringa_1,w_ind * 23 - 14,15)) / 100;
                  w_stringa_1     := substr(w_stringa_1,1,w_ind * 23 - 15)||
                                     lpad('0',15,'0')||
                                     substr(w_stringa_1,w_ind * 23 + 1);
                  exit;
               end if;
--
-- Elemento non trovato: si continua ad esaminare la stringa eccedenze.
--
               w_ind_2 := w_ind_2 + 1;
            end loop;
         end if;
--
-- Si continua a scorrere a ritroso la stringa dei versamenti.
--
         w_ind := w_ind - 1;
      end loop;
   end if;
   p_stringa_1 := w_stringa_1;
   p_stringa_2 := w_stringa_2;
END SISTEMA_ECCEDENZE;
--
-- Compensa eccedenze
--
PROCEDURE COMPENSA_ECCEDENZE (p_a         in     number
                             ,p_da        in     number
                             ,p_importo   in     number
                             ,p_stringa_1 in out varchar2
                             ,p_stringa_2 in out varchar2
                             )
IS
-- p_a, p_da MAI USATI
w_importo                  number;
w_stringa_1                varchar2(2300);
w_stringa_2                varchar2(2300);
w_imp_confronto            number;
w_ind                      number;
w_ind_2                    number;
BEGIN
   w_importo         := p_importo;
   w_stringa_1       := p_stringa_1;
   w_stringa_2       := p_stringa_2;
   w_ind             := 0;
   w_imp_confronto   := 0;
   if w_importo > 0 then
      loop
         if w_ind = nvl(length(w_stringa_1),0) / 23 then
            exit;
         end if;
--
-- Caso di raggiungimento del valore; la parte di valore si riporta
-- nella stringa 2 e si aggiorna la stringa 1 con la quota
-- rimasta dopo avere sottratto la quota spostata nella stringa 2.
--
         if w_imp_confronto + to_number(substr(w_stringa_1,w_ind * 23 + 9,15)) / 100
                            > w_importo then
            w_ind_2 := 0;
            loop
--
-- La data di scadenza non esiste tra gli elementi memorizzati
-- nella stringa 2 per cui viene accodato un nuovo elemento.
--
               if nvl(length(w_stringa_2),0) < w_ind_2 * 23 + 1 then
                  w_stringa_2 := w_stringa_2||
                                 substr(w_stringa_1,w_ind * 23 + 1,8)||
                                 lpad(to_char((w_importo - w_imp_confronto) * 100),15,'0');
                  w_stringa_1 := substr(w_stringa_1,1,w_ind * 23 + 8)||
                                 lpad(to_char(to_number(substr(w_stringa_1,w_ind * 23 + 9,15)) -
                                 to_number(substr(w_stringa_2,w_ind_2 * 23 + 9,15))),15,'0')||
                                 substr(w_stringa_1,w_ind * 23 + 24);
                  exit;
               end if;
--
-- La data di scadenza esiste nella stringa 2 per cui
-- si incrementa la quota a quella esistente.
--
               if substr(w_stringa_1,w_ind * 23 + 1,8) =
                  substr(w_stringa_2,w_ind_2 * 23 + 1,8) then
                  w_stringa_2 := substr(w_stringa_2,1,w_ind_2 * 23 + 8)||
                                 lpad(to_char(to_number(substr(w_stringa_2,w_ind_2 * 23 + 9,15)) +
                                              (w_importo - w_imp_confronto) * 100),15,'0')||
                                 substr(w_stringa_2,w_ind_2 * 23 + 24);
                  w_stringa_1 := substr(w_stringa_1,1,w_ind * 23 + 8)||
                                 lpad(to_char(to_number(substr(w_stringa_1,w_ind * 23 + 9,15)) -
                                              (w_importo - w_imp_confronto) * 100),15,'0')||
                                 substr(w_stringa_1,w_ind * 23 + 24);
                  exit;
               end if;
--
-- Elemento non trovato: si continua ad esaminare la stringa eccedenze.
--
               w_ind_2 := w_ind_2 + 1;
            end loop;
         else
--
-- Caso di Importo non raggiunto: tutta la quota della stringa 1 va
-- nella stringa 2 e si incrementa il valore di confronto per
-- il raggiungimento del valore  (w_imp_confronto).
--
            w_ind_2 := 0;
            loop
--
-- La data di scadenza non esiste tra gli elementi memorizzati
-- nella stringa 2 per cui viene accodato un nuovo elemento.
--
               if nvl(length(w_stringa_2),0) < w_ind_2 * 23 + 1 then
                  w_stringa_2     := w_stringa_2||
                                     substr(w_stringa_1,w_ind * 23 + 1,23);
                  w_imp_confronto := w_imp_confronto +
                                     to_number(substr(w_stringa_1,w_ind * 23 + 9,15)) / 100;
                  w_stringa_1     := substr(w_stringa_1,1,w_ind * 23 + 8)||
                                     lpad('0',15,'0')||
                                     substr(w_stringa_1,w_ind * 23 + 24);
                  exit;
               end if;
--
-- La data di scadenza esiste nella stringa 2 per cui
-- si incrementa la quota a quella esistente.
--
               if substr(w_stringa_1,w_ind * 23 + 1,8) =
                  substr(w_stringa_2,w_ind_2 * 23 + 1,8) then
                  w_stringa_2     := substr(w_stringa_2,1,w_ind_2 * 23 + 8)||
                                     substr(w_stringa_1,w_ind * 23 + 9,15)||
                                     substr(w_stringa_2,w_ind_2 * 23 + 24);
                  w_imp_confronto := w_imp_confronto +
                                     to_number(substr(w_stringa_1,w_ind * 23 + 9,15)) / 100;
                  w_stringa_1     := substr(w_stringa_1,1,w_ind * 23 + 8)||
                                     lpad('0',15,'0')||
                                     substr(w_stringa_1,w_ind * 23 + 24);
                  exit;
               end if;
--
-- Elemento non trovato: si continua ad esaminare la stringa eccedenze.
--
               w_ind_2 := w_ind_2 + 1;
            end loop;
         end if;
--
-- Si continua a scorrere la stringa dei versamenti.
--
         w_ind := w_ind + 1;
      end loop;
   end if;
   p_stringa_1 := w_stringa_1;
   p_stringa_2 := w_stringa_2;
END COMPENSA_ECCEDENZE;
--
-- Bonifica gli elementi che non hanno importo
--
PROCEDURE BONIFICA_STRINGA (p_stringa in out varchar2)
IS
w_stringa                 varchar2(2300);
w_stringa_2               varchar2(2300);
w_elem_stringa            varchar2(23);
w_ind                     number;
BEGIN
   w_stringa := p_stringa;
   w_stringa_2 := '';
   w_ind := 0;
   loop
      if nvl(length(w_stringa),0) < w_ind * 23 + 1 then
         exit;
      end if;
      w_elem_stringa := substr(w_stringa,w_ind * 23 + 1,23);
      if substr(w_elem_stringa,9,15) <> '000000000000000' then
         w_stringa_2 := w_stringa_2||w_elem_stringa;
      end if;
      w_ind := w_ind + 1;
   end loop;
   w_stringa := w_stringa_2;
   p_stringa := w_stringa;
END BONIFICA_STRINGA;
--------------------------------------------
-- CALCOLO_SOLLECITI -----------------------
--------------------------------------------
BEGIN
    begin
        select decode(a_tipo_tributo
                      ,'TARSU',flag_tariffa
                      ,'ICP',flag_canone
                      ,'TOSAP',flag_canone
                      ,'CUNI',flag_canone
                      ,null)
          into w_round
          from tipi_tributo
         where tipo_tributo = a_tipo_tributo
            ;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
         w_round := null;
      WHEN OTHERS THEN
         w_round := null;
    end;
   --
   w_cf := '';
   w_gt := '';
   w_pr := null;
   w_scadenza_invalid := to_date('31122999','ddmmyyyy');
   --
   for rec_sol_prec in sel_sol_prec ( a_tipo_tributo
                               , a_anno
                               , a_cod_fiscale
                               , a_cognome_nome
                               , a_tributo
                               , a_categoria_da
                               , a_categoria_a)
   loop
      begin
       --dbms_output.put_line('Eliminazione sollecito precedente: '||rec_sol_prec.pratica);
         delete from pratiche_tributo prtr
          where prtr.pratica = rec_sol_prec.pratica
         ;
      end;
   end loop;
   --
   open sel_sol (a_tipo_tributo
               , a_anno
               , a_cod_fiscale
               , a_cognome_nome
               , a_tributo
               , a_categoria_da
               , a_categoria_a);
   fetch sel_sol into w_cod_fiscale
                    , w_gruppo_tributo
                    , w_oggetto_pratica
                    , w_oggetto_pratica_rif
                    , w_oggetto
                    , w_pratica
                    , w_pratica_da_sol
                    , w_data_pratica
                    , w_numero_pratica
                    , w_anno
                    , w_tipo_pratica
                    , w_tipo_evento
                    , w_tipo_occupazione
                    , w_dal
                    , w_al
   ;
   if sel_sol%FOUND then
    --dbms_output.put_line('*** Sollecito per: '||w_cod_fiscale||', gruppo: '||nvl(w_gruppo_tributo,'NULL')||', pratica: '||w_pratica_da_sol);
      w_cod_fiscale_prec   := w_cod_fiscale;
      w_gruppo_tributo_prec := w_gruppo_tributo;
      w_pratica_da_sol_prec := w_pratica_da_sol;
      w_imposta_r1         := 0;
      w_imposta_r2         := 0;
      w_imposta_r3         := 0;
      w_imposta_r4         := 0;
      w_imposta_rt         := 0;
      w_imposta            := 0;
      w_max_rata           := 0;
      w_stringa_vers_r1    := '';
      w_stringa_vers_r2    := '';
      w_stringa_vers_r3    := '';
      w_stringa_vers_r4    := '';
      w_ind_stringa        := 0;
      loop
        w_cf := w_cod_fiscale;
        w_gt := w_gruppo_tributo;
        w_pr := w_pratica_da_sol;
        --
        w_scadenza_r1 := w_scadenza_invalid;
        w_scadenza_r2 := w_scadenza_invalid;
        w_scadenza_r3 := w_scadenza_invalid;
        w_scadenza_r4 := w_scadenza_invalid;
        for rec_scad in sel_scad (a_tipo_tributo,w_gruppo_tributo,a_anno)
        loop
          if    rec_scad.rata = 1 then
             w_scadenza_r1 := rec_scad.data_scadenza;
          elsif rec_scad.rata = 2 then
             w_scadenza_r2 := rec_scad.data_scadenza;
          elsif rec_scad.rata = 3 then
             w_scadenza_r3 := rec_scad.data_scadenza;
          elsif rec_scad.rata = 4 then
             w_scadenza_r4 := rec_scad.data_scadenza;
          end if;
        end loop;
        --
--
-- Per esigenze di stampa dei bollettini, si e` operato sul calcolo imposta
-- distinguendo le pratiche dell`anno di imposta che si pagano al momento della
-- dichiarazione. Se l`imposta viene determinata senza rateizzazione non cambia
-- niente rispetto a prima; se invece si desidera rateizzare, allora per le pratiche
-- dell`anno di imposta la rateizzazione e` solo per utenza, mentre per le pratiche
-- relative agli anni precedenti la rateizzazione puo` essere anche per contribuente.
-- In questa sede si fanno dei controlli sulla data di presentazione della denuncia
-- soltanto per le pratiche dell`anno. Come si e` detto prima, queste pratiche sono
-- eventualmente rateizzate solo per utenza (rate con oggetto imposta); per evitare
-- di ripetere successivamente gli stessi controlli, le imposte e la rateizzazione su
-- utenza sono determinate ora sulla base dell`oggetto imposta. Le restanti rateizzazioni
-- eventuali da sommare saranno tutte quelle senza oggetto imposta che, come si e` gia`
-- detto, provengono da rateizzazione per contribuente che pero` e` possibile solo per
-- pratiche di anni precedenti sulle quali non c`e` il controllo di data di presentazione
-- scaduta e quindi sono da considerarsi tutte valide. Vengono trattate a cambio contribuente.
-- Quando si sono trattate tutte le imposte e tutte le rateizzazioni, puo` verificarsi
-- che i totali non tornino. I casi sono due: o non c`e` stata rateizzazione, o non c`e`
-- stata parziale rateizzazione (perche` si e` operato volutamente in questo modo o
-- perche` non e` stato raggiunto il limite per la rateizzazione). La differenza
-- va gestita sulla scadenza della prima rata (o della rata 0 in assenza di rate vere).
--
         BEGIN
            select nvl(max(nvl(ogim.imposta,0)),0)
                  ,nvl(sum(decode(nvl(raim.rata,0),0,nvl(nvl(raim.imposta_round,raim.imposta),0)
                                                  ,1,nvl(nvl(raim.imposta_round,raim.imposta),0)
                                                    ,0
                                 )
                          ),0
                      )
                  ,nvl(sum(decode(nvl(raim.rata,0),2,nvl(nvl(raim.imposta_round,raim.imposta),0)
                                                    ,0
                                 )
                          ),0
                      )
                  ,nvl(sum(decode(nvl(raim.rata,0),3,nvl(nvl(raim.imposta_round,raim.imposta),0)
                                                    ,0
                                 )
                          ),0
                      )
                  ,nvl(sum(decode(nvl(raim.rata,0),4,nvl(nvl(raim.imposta_round,raim.imposta),0)
                                                    ,0
                                 )
                          ),0
                      )
                  ,nvl(sum(nvl(nvl(raim.imposta_round,raim.imposta),0)),0)
                  ,nvl(max(nvl(raim.rata,0)),0)
                  ,min(ogim.data_scadenza)
              into w_dep
                  ,w_dep_r1
                  ,w_dep_r2
                  ,w_dep_r3
                  ,w_dep_r4
                  ,w_dep_rt
                  ,w_max_rata
                  ,w_scad
              from oggetti_imposta        ogim
                  ,rate_imposta           raim
                  ,oggetti_pratica        ogpr
                  ,pratiche_tributo       prtr
             where ogim.oggetto_pratica     = w_oggetto_pratica
               and ogpr.oggetto_pratica     = w_oggetto_pratica
               and prtr.pratica             = ogpr.pratica
               and prtr.tipo_tributo||''    = a_tipo_tributo
               and ogim.anno                = a_anno
               and ogim.oggetto_imposta     = raim.oggetto_imposta (+)
               and substr(nvl(prtr.utente,'?'),1,1)
                                           <> '#'
            ;
         EXCEPTION
            WHEN NO_DATA_FOUND THEN
               w_dep          := 0;
               w_dep_r1       := 0;
               w_dep_r2       := 0;
               w_dep_r3       := 0;
               w_dep_r4       := 0;
               w_dep_rt       := 0;
               w_max_rata     := 0;
               w_scad         := null;
         END;
         -- Gestione Arrotondamenti pratiche dell'anno di sollecito
         if w_round is null and  a_anno >= 2007 then
            if a_anno = w_anno then
               w_dep := round(w_dep);
            end if;
         end if;
         --
       --dbms_output.put_line('C.F.: '||w_cod_fiscale||', gruppo: '||nvl(w_gruppo_tributo,'NULL')||', pratica: '||w_pratica_da_sol);
       --dbms_output.put_line('Oggetto pratica: '||w_oggetto_pratica);
       --dbms_output.put_line('Oggetto pratica rif.: '||w_oggetto_pratica_rif);
       --dbms_output.put_line('Imposta: '||w_dep);
       --dbms_output.put_line('Scadenza: '||w_scad);
         --
         if w_scad is not null then
           w_scadenza_r1 := w_scad;
         end if;
         --
         w_imposta            := w_imposta + w_dep;
    --   w_imposta_r1         := w_imposta_r1 + w_dep_r1;
    --   w_imposta_r2         := w_imposta_r2 + w_dep_r2;
    --   w_imposta_r3         := w_imposta_r3 + w_dep_r3;
    --   w_imposta_r4         := w_imposta_r4 + w_dep_r4;
    --   w_imposta_rt         := w_imposta_rt + w_dep_rt;
         --
         fetch sel_sol into w_cod_fiscale
                          , w_gruppo_tributo
                          , w_oggetto_pratica
                          , w_oggetto_pratica_rif
                          , w_oggetto
                          , w_pratica
                          , w_pratica_da_sol
                          , w_data_pratica
                          , w_numero_pratica
                          , w_anno
                          , w_tipo_pratica
                          , w_tipo_evento
                          , w_tipo_occupazione
                          , w_dal
                          , w_al
         ;
         if sel_sol%NOTFOUND
         or w_cod_fiscale <> w_cod_fiscale_prec
         or w_gruppo_tributo <> w_gruppo_tributo_prec
         or nvl(w_pratica_da_sol,0) <> nvl(w_pratica_da_sol_prec,0) then
          --dbms_output.put_line('*** Genera pratica: '||w_cod_fiscale_prec||', gruppo: '||nvl(w_gruppo_tributo_prec,'NULL')||', pratica: '||w_pratica_da_sol_prec);
            w_cf := w_cod_fiscale_prec;
            w_gt := w_gruppo_tributo_prec;
            w_pr := w_pratica_da_sol_prec;
            --
            -- Si gestiscono le rate imposta rateizzate per contribuente.
            --
            BEGIN
               select nvl(sum(decode(raim.rata,0,nvl(raim.imposta_round,raim.imposta)
                                              ,1,nvl(raim.imposta_round,raim.imposta)
                                                ,0
                                   )
                             ),0
                         )
                     ,nvl(sum(decode(raim.rata,2,nvl(raim.imposta_round,raim.imposta)
                                                ,0
                                    )
                             ),0
                         )
                     ,nvl(sum(decode(raim.rata,3,nvl(raim.imposta_round,raim.imposta)
                                                ,0
                                    )
                             ),0
                         )
                     ,nvl(sum(decode(raim.rata,4,nvl(raim.imposta_round,raim.imposta)
                                                ,0
                                    )
                             ),0
                         )
                     ,nvl(sum(nvl(nvl(raim.imposta_round,raim.imposta),0)),0)
                     ,min(decode(raim.rata,1,data_scadenza,null))
                     ,min(decode(raim.rata,2,data_scadenza,null))
                     ,min(decode(raim.rata,3,data_scadenza,null))
                     ,min(decode(raim.rata,4,data_scadenza,null))
                 into w_dep_r1
                     ,w_dep_r2
                     ,w_dep_r3
                     ,w_dep_r4
                     ,w_dep_rt
                     ,w_scad_r1
                     ,w_scad_r2
                     ,w_scad_r3
                     ,w_scad_r4
                 from rate_imposta         raim
                where raim.cod_fiscale        = w_cod_fiscale_prec
                  and raim.anno               = a_anno
                  and raim.tipo_tributo       = a_tipo_tributo
                  and nvl(raim.conto_corrente,99990000) in (
                     select distinct nvl(cotr.conto_corrente,99990000) conto_corrente
                     from codici_tributo cotr
                     where cotr.flag_ruolo is null
                       and ((w_gruppo_tributo_prec is null) or
                            ((w_gruppo_tributo_prec is not null) and (cotr.gruppo_tributo = w_gruppo_tributo_prec))
                       )
                  )
                  and F_CONCESSIONE_ATTIVA(w_cod_fiscale_prec,a_tipo_tributo,a_anno
                                          ,null,null,raim.oggetto_imposta
                                          )   = 'NO'
--                and (raim.oggetto_imposta is null)
                  and (
                       ((w_pratica_da_sol_prec is null) and (raim.oggetto_imposta is null)
                       )
                      or
                       ((w_pratica_da_sol_prec is not null) and
                        (raim.oggetto_imposta in
                          (select ogim.oggetto_imposta
                             from oggetti_imposta ogim,
                                  oggetti_pratica ogpr
                            where ogim.oggetto_pratica = ogpr.oggetto_pratica
                              and ogim.anno = a_anno
                              and ogpr.pratica = w_pratica_da_sol_prec)
                        )
                       )
                  )
               ;
            EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  w_dep_r1 := 0;
                  w_dep_r2 := 0;
                  w_dep_r3 := 0;
                  w_dep_r4 := 0;
                  w_dep_rt := 0;
                  w_scad_r1 := null;
                  w_scad_r2 := null;
                  w_scad_r3 := null;
                  w_scad_r4 := null;
            END;
            --
          --dbms_output.put_line('Imposta R1: '||w_dep_r1);
          --dbms_output.put_line('Imposta R2: '||w_dep_r2);
          --dbms_output.put_line('Imposta R3: '||w_dep_r3);
          --dbms_output.put_line('Imposta R4: '||w_dep_r4);
          --dbms_output.put_line('Imposta RT: '||w_dep_rt);
            --
          --dbms_output.put_line('Scadenza R1: '||w_scad_r1);
          --dbms_output.put_line('Scadenza R2: '||w_scad_r2);
          --dbms_output.put_line('Scadenza R3: '||w_scad_r3);
          --dbms_output.put_line('Scadenza R4: '||w_scad_r4);
            --
            if w_scad_r1 is not null then
              w_scadenza_r1 := w_scad_r1;
              w_scadenza_r2 := nvl(w_scad_r2,w_scadenza_invalid);
              w_scadenza_r3 := nvl(w_scad_r3,w_scadenza_invalid);
              w_scadenza_r4 := nvl(w_scad_r4,w_scadenza_invalid);
            end if;
            --
            w_imposta_r1 := w_imposta_r1 + w_dep_r1;
            w_imposta_r2 := w_imposta_r2 + w_dep_r2;
            w_imposta_r3 := w_imposta_r3 + w_dep_r3;
            w_imposta_r4 := w_imposta_r4 + w_dep_r4;
            w_imposta_rt := w_imposta_rt + w_dep_rt;
            --
            -- Eventuali differenze tra il totale imposta di oggetti imposta e
            -- il totale imposta di rate imposta e` imputabile a utenze che non sono
            -- state soggette a rateizzazione per cui detta differenza va
            -- ad incrementarsi sulla prima rata.
            --
            -- Gestione Arrotondamenti
            if w_round is null and  a_anno >= 2007 then
               w_imposta := round(w_imposta);
            end if;
            if w_imposta > w_imposta_rt then
               w_imposta_r1 := w_imposta - w_imposta_rt + w_imposta_r1;
            end if;
            w_versato_r1          := 0;
            w_versato_r1_da_r2    := 0;
            w_versato_r1_da_r3    := 0;
            w_versato_r1_da_r4    := 0;
            w_versato_r2          := 0;
            w_versato_r2_da_r1    := 0;
            w_versato_r2_da_r3    := 0;
            w_versato_r2_da_r4    := 0;
            w_versato_r3          := 0;
            w_versato_r3_da_r1    := 0;
            w_versato_r3_da_r2    := 0;
            w_versato_r3_da_r4    := 0;
            w_versato_r4          := 0;
            w_versato_r4_da_r1    := 0;
            w_versato_r4_da_r2    := 0;
            w_versato_r4_da_r3    := 0;
            w_tot_versato         := 0;
            w_tot_versato_r1      := 0;
            w_tot_versato_r2      := 0;
            w_tot_versato_r3      := 0;
            w_tot_versato_r4      := 0;
            w_data_versamento_r1  := to_date('31122999','ddmmyyyy');
            w_data_versamento_r2  := to_date('31122999','ddmmyyyy');
            w_data_versamento_r3  := to_date('31122999','ddmmyyyy');
            w_data_versamento_r4  := to_date('31122999','ddmmyyyy');
            w_omesso_r1           := 0;
            w_omesso_r2           := 0;
            w_omesso_r3           := 0;
            w_omesso_r4           := 0;
            w_eccedenza_r1        := 0;
            w_eccedenza_r2        := 0;
            w_eccedenza_r3        := 0;
            w_eccedenza_r4        := 0;
            w_ins_pratica         := 'NO';
            -- (VD - 22/03/2022): si determina l'eventuale versato su
            --                    ravvedimento, sia totale sia per rata,
            --                    e si somma ai relativi totalizzatori
            w_versato_ravv       := F_IMPORTO_VERS_RAVV(w_cod_fiscale_prec,a_tipo_tributo,a_anno,'U');
            w_versato_ravv_r1    := F_IMPORTO_VERS_RAVV(w_cod_fiscale_prec,a_tipo_tributo,a_anno,'1');
            w_versato_ravv_r2    := F_IMPORTO_VERS_RAVV(w_cod_fiscale_prec,a_tipo_tributo,a_anno,'2');
            w_versato_ravv_r3    := F_IMPORTO_VERS_RAVV(w_cod_fiscale_prec,a_tipo_tributo,a_anno,'3');
            w_versato_ravv_r4    := F_IMPORTO_VERS_RAVV(w_cod_fiscale_prec,a_tipo_tributo,a_anno,'4');
            w_tot_versato        := w_tot_versato    + nvl(w_versato_ravv,0);
            w_tot_versato_r1     := w_tot_versato_r1 + nvl(w_versato_ravv_r1,0);
            w_tot_versato_r2     := w_tot_versato_r2 + nvl(w_versato_ravv_r2,0);
            w_tot_versato_r3     := w_tot_versato_r3 + nvl(w_versato_ravv_r3,0);
            w_tot_versato_r4     := w_tot_versato_r4 + nvl(w_versato_ravv_r4,0);
--
-- Per filtrare i versamenti determina l'eventuale tipo_tributo per depag
-- Da questo ricaviamo poi i servizi compatibili, quindi filtriamo i versamenti
--
            w_tipo_tributo_gruppo := null;
            if w_gruppo_tributo is not null then
              begin
                select nvl(max(nvl(grtr.descrizione,a_tipo_tributo)),a_tipo_tributo)
                  into w_tipo_tributo_gruppo
                  from gruppi_tributo grtr
                 where grtr.tipo_tributo = a_tipo_tributo
                   and grtr.gruppo_tributo = w_gruppo_tributo_prec
                      ;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                   w_tipo_tributo_gruppo := null;
                WHEN OTHERS THEN
                   w_tipo_tributo_gruppo := null;
              end;
            end if;
--
-- Totalizzazione del Versato del Contribuente.
--
            for rec_vers in sel_vers (w_cod_fiscale_prec
                                    , a_tipo_tributo
                                    , w_tipo_tributo_gruppo
                                    , w_pratica_da_sol_prec
                                    , a_anno
                                    , w_scadenza_r1
                                    , w_scadenza_r2
                                    , w_scadenza_r3
                                    , w_scadenza_r4
                                     )
            loop
             --dbms_output.put_line('Versato 1: '||w_gruppo_tributo_prec||', Gruppo: '||w_tipo_tributo_gruppo||', Imp: '||rec_vers.versato);
               w_tot_versato        := w_tot_versato + nvl(rec_vers.versato,0);
               w_tot_versato_r1     := w_tot_versato_r1                +
                                       nvl(rec_vers.versato_r1,0);
               if  rec_vers.data_pagamento_r1 < w_data_versamento_r1 then
                  w_data_versamento_r1 := rec_vers.data_pagamento_r1;
               end if;
               w_tot_versato_r2     := w_tot_versato_r2                +
                                       nvl(rec_vers.versato_r2,0);
               if  rec_vers.data_pagamento_r2 < w_data_versamento_r2 then
                  w_data_versamento_r2 := rec_vers.data_pagamento_r2;
               end if;
               w_tot_versato_r3     := w_tot_versato_r3                +
                                       nvl(rec_vers.versato_r3,0);
               if  rec_vers.data_pagamento_r3 < w_data_versamento_r3 then
                  w_data_versamento_r3 := rec_vers.data_pagamento_r3;
               end if;
               w_tot_versato_r4     := w_tot_versato_r4                +
                                       nvl(rec_vers.versato_r4,0);
               if  rec_vers.data_pagamento_r4 < w_data_versamento_r4 then
                  w_data_versamento_r4 := rec_vers.data_pagamento_r4;
               end if;
--
-- Si compongono le stringhe dei versamenti per le 4 rate in cui vengono memorizzati tanti
-- elementi a lunghezza fissa con data (ggmmyyyy) e importo in centesimi di 15 chr (tot=23).
-- Per data uguale si totalizzano gli importi relativi.
-- (VD - 23/03/2022): i versamenti su ravvedimento vengono sempre sommati alla
--                    prima data
--
               --Rata 1
               if  rec_vers.data_pagamento_r1 <> to_date('31122999','ddmmyyyy') then
                   w_ind_stringa := 0;
                   loop
                      if nvl(length(w_stringa_vers_r1),0) < w_ind_stringa * 23 + 1 then
                         w_stringa_vers_r1 := w_stringa_vers_r1
                                           || to_char(rec_vers.data_pagamento_r1,'ddmmyyyy')
                                           || lpad(to_char((nvl(rec_vers.versato_r1,0) + nvl(w_versato_ravv_r1,0)) * 100),15,'0');
                         w_versato_ravv_r1 := 0;
                         exit;
                      end if;
                      if to_char(rec_vers.data_pagamento_r1,'ddmmyyyy') =
                         substr(w_stringa_vers_r1,w_ind_stringa * 23 + 1,8)
                                                         then
                         w_stringa_vers_r1 :=
                            substr(w_stringa_vers_r1,1,w_ind_stringa * 23 + 8)
                         || lpad(to_char((to_number(substr(w_stringa_vers_r1,w_ind_stringa * 23 + 9,15)) / 100 +
                                          nvl(rec_vers.versato_r1,0)) * 100),15,'0')
                         || substr(w_stringa_vers_r1,w_ind_stringa * 23 + 24);
                         exit;
                      end if;
                      w_ind_stringa := w_ind_stringa + 1;
                   end loop;
               end if;
               --Rata 2
               if  rec_vers.data_pagamento_r2 <> to_date('31122999','ddmmyyyy') then
                   w_ind_stringa := 0;
                   loop
                      if nvl(length(w_stringa_vers_r2),0) < w_ind_stringa * 23 + 1 then
                         w_stringa_vers_r2 := w_stringa_vers_r2
                                           || to_char(rec_vers.data_pagamento_r2,'ddmmyyyy')
                                           || lpad(to_char((nvl(rec_vers.versato_r2,0) + nvl(w_versato_ravv_r2,0)) * 100),15,'0');
                         w_versato_ravv_r2 := 0;
                         exit;
                      end if;
                      if to_char(rec_vers.data_pagamento_r2,'ddmmyyyy') =
                         substr(w_stringa_vers_r2,w_ind_stringa * 23 + 1,8)
                                                         then
                         w_stringa_vers_r2 :=
                            substr(w_stringa_vers_r2,1,w_ind_stringa * 23 + 8)
                         || lpad(to_char((to_number(substr(w_stringa_vers_r2,w_ind_stringa * 23 + 9,15)) / 100 +
                                          nvl(rec_vers.versato_r2,0)) * 100),15,'0')
                         || substr(w_stringa_vers_r2,w_ind_stringa * 23 + 24);
                         exit;
                      end if;
                      w_ind_stringa := w_ind_stringa + 1;
                   end loop;
               end if;
               --Rata 3
               if  rec_vers.data_pagamento_r3 <> to_date('31122999','ddmmyyyy') then
                   w_ind_stringa := 0;
                   loop
                      if nvl(length(w_stringa_vers_r3),0) < w_ind_stringa * 23 + 1 then
                         w_stringa_vers_r3 := w_stringa_vers_r3
                                           || to_char(rec_vers.data_pagamento_r3,'ddmmyyyy')
                                           || lpad(to_char((nvl(rec_vers.versato_r3,0) + nvl(w_versato_ravv_r3,0)) * 100),15,'0');
                         w_versato_ravv_r3 := 0;
                         exit;
                      end if;
                      if to_char(rec_vers.data_pagamento_r3,'ddmmyyyy') =
                         substr(w_stringa_vers_r3,w_ind_stringa * 23 + 1,8)
                                                         then
                         w_stringa_vers_r3 :=
                            substr(w_stringa_vers_r3,1,w_ind_stringa * 23 + 8)
                         || lpad(to_char((to_number(substr(w_stringa_vers_r3,w_ind_stringa * 23 + 9,15)) / 100 +
                                          nvl(rec_vers.versato_r3,0)) * 100),15,'0')
                         || substr(w_stringa_vers_r3,w_ind_stringa * 23 + 24);
                         exit;
                      end if;
                      w_ind_stringa := w_ind_stringa + 1;
                  end loop;
               end if;
               --Rata 4
               if  rec_vers.data_pagamento_r4 <> to_date('31122999','ddmmyyyy') then
                   w_ind_stringa := 0;
                   loop
                      if nvl(length(w_stringa_vers_r4),0) < w_ind_stringa * 23 + 1 then
                         w_stringa_vers_r4 := w_stringa_vers_r4
                                           || to_char(rec_vers.data_pagamento_r4,'ddmmyyyy')
                                           || lpad(to_char((nvl(rec_vers.versato_r4,0) + nvl(w_versato_ravv_r4,0)) * 100),15,'0');
                         w_versato_ravv_r4 := 0;
                         exit;
                      end if;
                      if to_char(rec_vers.data_pagamento_r4,'ddmmyyyy') =
                         substr(w_stringa_vers_r4,w_ind_stringa * 23 + 1,8)
                                                         then
                         w_stringa_vers_r4 :=
                            substr(w_stringa_vers_r4,1,w_ind_stringa * 23 + 8)
                         || lpad(to_char((to_number(substr(w_stringa_vers_r4,w_ind_stringa * 23 + 9,15)) / 100 +
                                          nvl(rec_vers.versato_r4,0)) * 100),15,'0')
                         || substr(w_stringa_vers_r4,w_ind_stringa * 23 + 24);
                         exit;
                      end if;
                      w_ind_stringa := w_ind_stringa + 1;
                  end loop;
               end if;
            end loop;
--
-- Determinazione del Numero di Scadenze.
--
            w_tot := 1;
            if  w_scadenza_r2 <> to_date('31122999','ddmmyyyy')
            and w_scadenza_r3  = to_date('31122999','ddmmyyyy')
            and w_scadenza_r4  = to_date('31122999','ddmmyyyy') then
                w_tot := 2;
            end if;
            if  w_scadenza_r3 <> to_date('31122999','ddmmyyyy')
            and w_scadenza_r4  = to_date('31122999','ddmmyyyy') then
                w_tot := 3;
            end if;
            if  w_scadenza_r4 <> to_date('31122999','ddmmyyyy') then
                w_tot := 4;
            end if;
--
-- Determinazione di Eccedenze di Versamento e del Versato non in eccedenza.
-- Per la gestione delle stringhe dei versamenti e delle eccedenze viene richiamata
-- la procedura relativa.
--
            w_stringa_eccedenze_r1 := '';
            if w_scadenza_r1 <> to_date('31122999','ddmmyyyy') then
               if w_tot_versato_r1 > w_imposta_r1 then
                  w_eccedenza_r1 := w_tot_versato_r1 - w_imposta_r1;
                  w_versato_r1   := w_imposta_r1;
               else
                  w_versato_r1   := w_tot_versato_r1;
               end if;
            end if;
            SISTEMA_ECCEDENZE(w_eccedenza_r1,w_stringa_vers_r1,w_stringa_eccedenze_r1);
            w_stringa_eccedenze_r2 := '';
            if w_scadenza_r2 <> to_date('31122999','ddmmyyyy') then
               if w_tot_versato_r2 > w_imposta_r2 then
                  w_eccedenza_r2 := w_tot_versato_r2 - w_imposta_r2;
                  w_versato_r2   := w_imposta_r2;
               else
                  w_versato_r2   := w_tot_versato_r2;
               end if;
            end if;
            SISTEMA_ECCEDENZE(w_eccedenza_r2,w_stringa_vers_r2,w_stringa_eccedenze_r2);
            w_stringa_eccedenze_r3 := '';
            if w_scadenza_r3 <> to_date('31122999','ddmmyyyy') then
               if w_tot_versato_r3 > w_imposta_r3 then
                  w_eccedenza_r3 := w_tot_versato_r3 - w_imposta_r3;
                  w_versato_r3   := w_imposta_r3;
               else
                  w_versato_r3   := w_tot_versato_r3;
               end if;
            end if;
            SISTEMA_ECCEDENZE(w_eccedenza_r3,w_stringa_vers_r3,w_stringa_eccedenze_r3);
            w_stringa_eccedenze_r4 := '';
            if w_scadenza_r4 <> to_date('31122999','ddmmyyyy') then
               if w_tot_versato_r4 > w_imposta_r4 then
                  w_eccedenza_r4 := w_tot_versato_r4 - w_imposta_r4;
                  w_versato_r4   := w_imposta_r4;
               else
                  w_versato_r4   := w_tot_versato_r4;
               end if;
            end if;
            SISTEMA_ECCEDENZE(w_eccedenza_r4,w_stringa_vers_r4,w_stringa_eccedenze_r4);
--
-- Determinazione delle Compensazioni tra Rate.
-- Per la gestione delle stringhe dei versamenti e delle eccedenze viene richiamata
-- la procedura relativa.
--
            if w_scadenza_r1 <> to_date('31122999','ddmmyyyy') then
               if w_versato_r1 < w_imposta_r1 then
                  if w_eccedenza_r2 > 0 then
                     w_versato_r1_da_r2 := least(w_eccedenza_r2
                                                ,w_imposta_r1 - w_versato_r1
                                                );
                     COMPENSA_ECCEDENZE(1,2,w_versato_r1_da_r2,w_stringa_eccedenze_r2,w_stringa_vers_r1);
                     w_eccedenza_r2 := w_eccedenza_r2 - w_versato_r1_da_r2;
                  end if;
               end if;
               if w_versato_r1 < (w_imposta_r1 + w_versato_r1_da_r2) then
                  if w_eccedenza_r3 > 0 then
                     w_versato_r1_da_r3 := least(w_eccedenza_r3
                                                ,w_imposta_r1 - w_versato_r1
                                                              - w_versato_r1_da_r2
                                                );
                     COMPENSA_ECCEDENZE(1,3,w_versato_r1_da_r3,w_stringa_eccedenze_r3,w_stringa_vers_r1);
                     w_eccedenza_r3 := w_eccedenza_r3 - w_versato_r1_da_r3;
                  end if;
               end if;
               if w_versato_r1 < (w_imposta_r1 + w_versato_r1_da_r2
                                               + w_versato_r1_da_r3) then
                  if w_eccedenza_r4 > 0 then
                     w_versato_r1_da_r4 := least(w_eccedenza_r4
                                                ,w_imposta_r1 - w_versato_r1
                                                              - w_versato_r1_da_r2
                                                              - w_versato_r1_da_r3
                                                );
                     COMPENSA_ECCEDENZE(1,4,w_versato_r1_da_r4,w_stringa_eccedenze_r4,w_stringa_vers_r1);
                     w_eccedenza_r4 := w_eccedenza_r4 - w_versato_r1_da_r4;
                  end if;
               end if;
            end if;
            if w_scadenza_r2 <> to_date('31122999','ddmmyyyy') then
               if w_versato_r2 < w_imposta_r2 then
                  if w_eccedenza_r1 > 0 then
                     w_versato_r2_da_r1 := least(w_eccedenza_r1
                                                ,w_imposta_r2 - w_versato_r2
                                                );
                     COMPENSA_ECCEDENZE(2,1,w_versato_r2_da_r1,w_stringa_eccedenze_r1,w_stringa_vers_r2);
                     w_eccedenza_r1 := w_eccedenza_r1 - w_versato_r2_da_r1;
                  end if;
               end if;
               if w_versato_r2 < (w_imposta_r2 + w_versato_r2_da_r1) then
                  if w_eccedenza_r3 > 0 then
                     w_versato_r2_da_r3 := least(w_eccedenza_r3
                                                ,w_imposta_r2 - w_versato_r2
                                                              - w_versato_r2_da_r1
                                                );
                     COMPENSA_ECCEDENZE(2,3,w_versato_r2_da_r3,w_stringa_eccedenze_r3,w_stringa_vers_r2);
                     w_eccedenza_r3 := w_eccedenza_r3 - w_versato_r2_da_r3;
                  end if;
               end if;
               if w_versato_r2 < (w_imposta_r2 + w_versato_r2_da_r1
                                               + w_versato_r2_da_r3) then
                  if w_eccedenza_r4 > 0 then
                     w_versato_r2_da_r4 := least(w_eccedenza_r4
                                                ,w_imposta_r2 - w_versato_r2
                                                              - w_versato_r2_da_r1
                                                              - w_versato_r2_da_r3
                                                );
                     COMPENSA_ECCEDENZE(2,4,w_versato_r2_da_r4,w_stringa_eccedenze_r4,w_stringa_vers_r2);
                     w_eccedenza_r4 := w_eccedenza_r4 - w_versato_r2_da_r4;
                  end if;
               end if;
            end if;
            if w_scadenza_r3 <> to_date('31122999','ddmmyyyy') then
               if w_versato_r3 < w_imposta_r3 then
                  if w_eccedenza_r1 > 0 then
                     w_versato_r3_da_r1 := least(w_eccedenza_r1
                                                ,w_imposta_r3 - w_versato_r3
                                                );
                     COMPENSA_ECCEDENZE(3,1,w_versato_r3_da_r1,w_stringa_eccedenze_r1,w_stringa_vers_r3);
                     w_eccedenza_r1 := w_eccedenza_r1 - w_versato_r3_da_r1;
                  end if;
               end if;
               if w_versato_r3 < (w_imposta_r3 + w_versato_r3_da_r1) then
                  if w_eccedenza_r2 > 0 then
                     w_versato_r3_da_r2 := least(w_eccedenza_r2
                                                ,w_imposta_r3 - w_versato_r3
                                                              - w_versato_r3_da_r1
                                                );
                     COMPENSA_ECCEDENZE(3,2,w_versato_r3_da_r2,w_stringa_eccedenze_r2,w_stringa_vers_r3);
                     w_eccedenza_r2 := w_eccedenza_r2 - w_versato_r3_da_r2;
                  end if;
               end if;
               if w_versato_r3 < (w_imposta_r3 + w_versato_r3_da_r1
                                               + w_versato_r3_da_r2) then
                  if w_eccedenza_r4 > 0 then
                     w_versato_r3_da_r4 := least(w_eccedenza_r4
                                                ,w_imposta_r3 - w_versato_r3
                                                              - w_versato_r3_da_r1
                                                              - w_versato_r3_da_r2
                                                );
                     COMPENSA_ECCEDENZE(3,4,w_versato_r3_da_r4,w_stringa_eccedenze_r4,w_stringa_vers_r3);
                     w_eccedenza_r4 := w_eccedenza_r4 - w_versato_r3_da_r4;
                  end if;
               end if;
            end if;
            if w_scadenza_r4 <> to_date('31122999','ddmmyyyy') then
               if w_versato_r4 < w_imposta_r4 then
                  if w_eccedenza_r1 > 0 then
                     w_versato_r4_da_r1 := least(w_eccedenza_r1
                                                ,w_imposta_r4 - w_versato_r4
                                                );
                     COMPENSA_ECCEDENZE(4,1,w_versato_r4_da_r1,w_stringa_eccedenze_r1,w_stringa_vers_r4);
                     w_eccedenza_r1 := w_eccedenza_r1 - w_versato_r4_da_r1;
                  end if;
               end if;
               if w_versato_r4 < (w_imposta_r4 + w_versato_r4_da_r1) then
                  if w_eccedenza_r2 > 0 then
                     w_versato_r4_da_r2 := least(w_eccedenza_r2
                                                ,w_imposta_r4 - w_versato_r4
                                                              - w_versato_r4_da_r1
                                                );
                     COMPENSA_ECCEDENZE(4,2,w_versato_r4_da_r2,w_stringa_eccedenze_r2,w_stringa_vers_r4);
                     w_eccedenza_r2 := w_eccedenza_r2 - w_versato_r4_da_r2;
                  end if;
               end if;
               if w_versato_r4 < (w_imposta_r4 + w_versato_r4_da_r1
                                               + w_versato_r4_da_r2) then
                  if w_eccedenza_r3 > 0 then
                     w_versato_r4_da_r3 := least(w_eccedenza_r3
                                                ,w_imposta_r4 - w_versato_r4
                                                              - w_versato_r4_da_r1
                                                              - w_versato_r4_da_r2
                                                );
                     COMPENSA_ECCEDENZE(4,3,w_versato_r4_da_r3,w_stringa_eccedenze_r3,w_stringa_vers_r4);
                     w_eccedenza_r3 := w_eccedenza_r3 - w_versato_r4_da_r3;
                  end if;
               end if;
            end if;
--
-- Determinazione dell`omesso.
--
            if w_imposta_r1 > (w_versato_r1 + w_versato_r1_da_r2
                                            + w_versato_r1_da_r3
                                            + w_versato_r1_da_r4
                              ) then
               w_omesso_r1 := w_imposta_r1 - w_versato_r1
                                           - w_versato_r1_da_r2
                                           - w_versato_r1_da_r3
                                           - w_versato_r1_da_r4;
            end if;
            if w_imposta_r2 > (w_versato_r2 + w_versato_r2_da_r1
                                            + w_versato_r2_da_r3
                                            + w_versato_r2_da_r4
                              ) then
               w_omesso_r2 := w_imposta_r2 - w_versato_r2
                                           - w_versato_r2_da_r1
                                           - w_versato_r2_da_r3
                                           - w_versato_r2_da_r4;
            end if;
            if w_imposta_r3 > (w_versato_r3 + w_versato_r3_da_r1
                                            + w_versato_r3_da_r2
                                            + w_versato_r3_da_r4
                              ) then
               w_omesso_r3 := w_imposta_r3 - w_versato_r3
                                           - w_versato_r3_da_r1
                                           - w_versato_r3_da_r2
                                           - w_versato_r3_da_r4;
            end if;
            if w_imposta_r4 > (w_versato_r4 + w_versato_r4_da_r1
                                            + w_versato_r4_da_r2
                                            + w_versato_r4_da_r3
                              ) then
               w_omesso_r4 := w_imposta_r4 - w_versato_r4
                                           - w_versato_r4_da_r1
                                           - w_versato_r4_da_r2
                                           - w_versato_r4_da_r3;
            end if;
--
-- Si tolgono dalle stringhe gli elementi che hanno importo a zero.
--
            BONIFICA_STRINGA(w_stringa_vers_r1);
            BONIFICA_STRINGA(w_stringa_vers_r2);
            BONIFICA_STRINGA(w_stringa_vers_r3);
            BONIFICA_STRINGA(w_stringa_vers_r4);
            BONIFICA_STRINGA(w_stringa_eccedenze_r1);
            BONIFICA_STRINGA(w_stringa_eccedenze_r2);
            BONIFICA_STRINGA(w_stringa_eccedenze_r3);
            BONIFICA_STRINGA(w_stringa_eccedenze_r4);
--dbms_output.put_line('SOLLECITO - Anno '||a_anno);
--dbms_output.put_line('1^ RATA');
--dbms_output.put_line('Scadenza '||to_char(w_scadenza_r1,'dd/mm/yyyy')||
--                     ' Imposta '||to_char(w_imposta_r1)||
--                     ' Data Pagamento '||to_char(w_data_versamento_r1,'dd/mm/yyyy')||
--                     ' Tot. Versato '||to_char(w_tot_versato_r1)
--                    );
--dbms_output.put_line('Versato '||to_char(w_versato_r1)||
--                     ' da rata2 '||to_char(w_versato_r1_da_r2)||
--                     ' da rata3 '||to_char(w_versato_r1_da_r3)||
--                     ' da rata4 '||to_char(w_versato_r1_da_r4)||
--                     ' Omesso '||to_char(w_omesso_r1)||
--                     ' Eccedenza '||to_char(w_eccedenza_r1)
--                    );
--dbms_output.put_line('Stringa Versamenti '||w_stringa_vers_r1);
--dbms_output.put_line('Stringa Eccedenze '||w_stringa_eccedenze_r1);
--dbms_output.put_line('2^ RATA');
--dbms_output.put_line('Scadenza '||to_char(w_scadenza_r2,'dd/mm/yyyy')||
--                     ' Imposta '||to_char(w_imposta_r2)||
--                     ' Data Pagamento '||to_char(w_data_versamento_r2,'dd/mm/yyyy')||
--                     ' Tot. Versato '||to_char(w_tot_versato_r2)
--                    );
--dbms_output.put_line('Versato '||to_char(w_versato_r2)||
--                     ' da rata1 '||to_char(w_versato_r2_da_r1)||
--                     ' da rata3 '||to_char(w_versato_r2_da_r3)||
--                     ' da rata4 '||to_char(w_versato_r2_da_r4)||
--                     ' Omesso '||to_char(w_omesso_r2)||
--                     ' Eccedenza '||to_char(w_eccedenza_r2)
--                    );
--dbms_output.put_line('Stringa Versamenti '||w_stringa_vers_r2);
--dbms_output.put_line('Stringa Eccedenze '||w_stringa_eccedenze_r2);
--dbms_output.put_line('3^ RATA');
--dbms_output.put_line('Scadenza '||to_char(w_scadenza_r3,'dd/mm/yyyy')||
--                     ' Imposta '||to_char(w_imposta_r3)||
--                     ' Data Pagamento '||to_char(w_data_versamento_r3,'dd/mm/yyyy')||
--                     ' Tot. Versato '||to_char(w_tot_versato_r3)
--                    );
--dbms_output.put_line('Versato '||to_char(w_versato_r3)||
--                     ' da rata1 '||to_char(w_versato_r3_da_r1)||
--                     ' da rata2 '||to_char(w_versato_r3_da_r2)||
--                     ' da rata4 '||to_char(w_versato_r3_da_r4)||
--                     ' Omesso '||to_char(w_omesso_r3)||
--                     ' Eccedenza '||to_char(w_eccedenza_r3)
--                    );
--dbms_output.put_line('Stringa Versamenti '||w_stringa_vers_r3);
--dbms_output.put_line('Stringa Eccedenze '||w_stringa_eccedenze_r3);
--dbms_output.put_line('4^ RATA');
--dbms_output.put_line('Scadenza '||to_char(w_scadenza_r4,'dd/mm/yyyy')||
--                     ' Imposta '||to_char(w_imposta_r4)||
--                     ' Data Pagamento '||to_char(w_data_versamento_r4,'dd/mm/yyyy')||
--                     ' Tot. Versato '||to_char(w_tot_versato_r4)
--                    );
--dbms_output.put_line('Versato '||to_char(w_versato_r4)||
--                     ' da rata1 '||to_char(w_versato_r4_da_r1)||
--                     ' da rata2 '||to_char(w_versato_r4_da_r2)||
--                     ' da rata3 '||to_char(w_versato_r4_da_r3)||
--                     ' Omesso '||to_char(w_omesso_r4)||
--                     ' Eccedenza '||to_char(w_eccedenza_r4)
--                    );
--dbms_output.put_line('Stringa Versamenti '||w_stringa_vers_r4);
--dbms_output.put_line('Stringa Eccedenze '||w_stringa_eccedenze_r4);
            CALCOLO_SOL_SANZIONI(w_cod_fiscale_prec
                               , a_tipo_tributo
                               , a_anno
                               , a_utente
                               , w_imposta_r1
                               , w_scadenza_r1
                               , w_stringa_vers_r1
                               , w_stringa_eccedenze_r1
                               , w_imposta_r2
                               , w_scadenza_r2
                               , w_stringa_vers_r2
                               , w_stringa_eccedenze_r2
                               , w_imposta_r3
                               , w_scadenza_r3
                               , w_stringa_vers_r3
                               , w_stringa_eccedenze_r3
                               , w_imposta_r4
                               , w_scadenza_r4
                               , w_stringa_vers_r4
                               , w_stringa_eccedenze_r4
                               , 'NO'
                               , a_se_spese_notifica
                               , a_data_scadenza
                               , w_gruppo_tributo_prec
                               , w_pratica_da_sol_prec
                               );
         end if;
         if sel_sol%NOTFOUND then
            exit;
         elsif (w_cod_fiscale_prec <> w_cod_fiscale or
                nvl(w_gruppo_tributo_prec,'') <> w_gruppo_tributo or
                nvl(w_pratica_da_sol_prec,0) <> nvl(w_pratica_da_sol,0)) then
          --dbms_output.put_line('*** Sollecito per: '||w_cod_fiscale||', gruppo: '||nvl(w_gruppo_tributo,'NULL')||', pratica: '||w_pratica_da_sol);
            w_cod_fiscale_prec := w_cod_fiscale;
            w_gruppo_tributo_prec := w_gruppo_tributo;
            w_pratica_da_sol_prec := w_pratica_da_sol;
            w_imposta_r1       := 0;
            w_imposta_r2       := 0;
            w_imposta_r3       := 0;
            w_imposta_r4       := 0;
            w_imposta_rt       := 0;
            w_imposta          := 0;
            w_stringa_vers_r1  := '';
            w_stringa_vers_r2  := '';
            w_stringa_vers_r3  := '';
            w_stringa_vers_r4  := '';
            w_ind_stringa      := 0;
         end if;
      end loop;
   end if;
   close sel_sol;
--
-- Eliminazione dei Solleciti emessi nel caso di non raggiungimento del Limite.
--
   for rec_prat_elim in sel_prat_elim (a_limite_inf
                                     , a_limite_sup
                                     , a_tipo_tributo
                                     , a_anno
                                     , a_cod_fiscale
                                     , a_cognome_nome
                                      )
   loop
    --dbms_output.put_line('Eliminazione pratica: '||rec_prat_elim.pratica);
      delete from pratiche_tributo prtr
       where prtr.pratica = rec_prat_elim.pratica
      ;
   end loop;
  if instr(a_cod_fiscale,'%') = 0 then
     a_pratica := w_pratica;
  else
     a_pratica := to_number(null);
  end if;
EXCEPTION
   WHEN errore THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,'CF = '||w_cf||' Acc. '||w_errore);
   WHEN others THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR
      (-20999,'Errore in Calcolo Automatico Solleciti di '||w_cf||' ('||SQLERRM||')');
END;
/* End Procedure: CALCOLO_SOLLECITI */
/
