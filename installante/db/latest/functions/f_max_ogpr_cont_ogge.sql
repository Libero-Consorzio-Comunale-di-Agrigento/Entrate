--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_max_ogpr_cont_ogge stripComments:false runOnChange:true 
 
create or replace function F_MAX_OGPR_CONT_OGGE
/*************************************************************************
 NOME:        F_MAX_OGPR_CONT_OGGE
 DESCRIZIONE: Dati oggetto, codice fiscale, tipo tributo, tipo pratica e
              anno, restituisce l'ultimo (max) oggetto_pratica che
              corrisponde ai parametri indicati
 RITORNA:     number              oggetto_pratica
 NOTE:
 Rev.    Date         Author      Note
 001     25/03/2020   VD          Per tipi tributo diversi da ICI e TASI
                                  vengono esclusi dalla ricerca i
                                  ravvedimenti
 002     04/12/2014   Betta T.    Aggiunto test su PRTR.FLAG_ANNULLAMENTO IS NULL
 000                              Prima emissione.
*************************************************************************/
(a_oggetto       IN   number
,a_cod_fiscale   IN   varchar2
,a_tipo_tributo  IN   varchar2
,a_tipo_pratica  IN   varchar2
,a_anno          IN   number
,a_flag_denuncia IN   varchar2
) RETURN number
IS
max_oggetto_pratica   NUMBER;
BEGIN
   if a_tipo_tributo <> 'ICI' and a_tipo_tributo <> 'TASI' then
      select to_number(
                 substr(
                     max(decode(nvl(prtr.tipo_evento,'U')
                               ,'C',to_char(nvl(ogco.data_cessazione,nvl(prtr.data
                                               ,to_date('3112'||
                                                        lpad(to_char(ogco.anno),4,'0')
                                                       ,'ddmmyyyy'
                                                       )
                                               )),'yyyymmdd'
                                           )
                                   ,to_char(nvl(ogco.data_decorrenza,nvl(prtr.data
                                               ,to_date('0101'||
                                                        lpad(to_char(ogco.anno),4,'0')
                                                       ,'ddmmyyyy'
                                                       )
                                               )),'yyyymmdd'
                                           )
                               )||
                         decode(prtr.tipo_evento,'C','3','V','2','U','2','1')||
                         lpad(to_char(ogpr.oggetto_pratica),10,'0')
                        ),10,10
                       )
                      )
        into max_oggetto_pratica
        from pratiche_tributo      prtr,
             oggetti_contribuente  ogco,
             oggetti_pratica       ogpr
       where ogco.cod_fiscale         = a_cod_fiscale
         and ogco.oggetto_pratica     = ogpr.oggetto_pratica
         and ogpr.oggetto             = a_oggetto
         and ogpr.pratica             = prtr.pratica
         and prtr.tipo_tributo||''    = a_tipo_tributo
         and prtr.tipo_pratica||'' like a_tipo_pratica
         -- (VD - 25/03/2020): si escludono anche i ravvedimenti
         -- (DM - 02/10/2024): si escludono i solleciti
         and prtr.tipo_pratica||'' not in ('C','V', 'S') -- <> 'C'
-- non prendiamo in considerazione le pratiche annullate
         and prtr.flag_annullamento is null
--
--  Modifica apportata per potere considerare anche gli accertamenti senza
--  flag denuncia relativamente al solo anno di pratica (per sit.contribuente).
--
         and (    decode(prtr.tipo_pratica,'A',prtr.flag_denuncia,'S')
                                       = 'S'
              or  prtr.anno           = a_anno
              and nvl(prtr.flag_denuncia,'N')
                                   like a_flag_denuncia
             )
         and decode(prtr.tipo_pratica,'A',nvl(prtr.stato_accertamento,'D'),'D')
                                      = 'D'
         and prtr.anno               <= a_anno
      ;
   else
      select to_number(substr(max(lpad(to_char(ogco.anno),4,'0')||
                                  lpad(to_char(nvl(ogco.da_mese_possesso,0)),2,'0')||
                                  ogco.tipo_rapporto||
                                  lpad(to_char(ogpr.oggetto_pratica),10,'0')
                                 ),8,10
                             )
                      )
        into max_oggetto_pratica
        from pratiche_tributo      prtr
            ,oggetti_contribuente  ogco
            ,oggetti_pratica       ogpr
       where (    (prtr.anno          <= a_anno
              and ogco.flag_possesso  = 'S')
              or  (prtr.anno           = a_anno
              and ogco.flag_possesso is null)
             )
         and prtr.tipo_tributo||''    = a_tipo_tributo
         and prtr.pratica             = ogpr.pratica
         and ogpr.oggetto_pratica     = ogco.oggetto_pratica
         and ogco.tipo_rapporto      in ('A', 'C','D','E')
         and ogco.cod_fiscale         = a_cod_fiscale
         and ogpr.oggetto             = a_oggetto
         and prtr.tipo_tributo||''    = a_tipo_tributo
         and prtr.tipo_pratica||'' like a_tipo_pratica
-- non prendiamo in considerazione le pratiche annullate
         and prtr.flag_annullamento is null
         and prtr.tipo_pratica||'' <> 'K'
--
--  Modifica apportata per potere considerare anche gli accertamenti senza
--  flag denuncia relativamente al solo anno di pratica (per sit.contribuente).
--
         and (    decode(prtr.tipo_pratica,'A',prtr.flag_denuncia,'S')
                                       = 'S'
              or  prtr.anno           = a_anno
              and nvl(prtr.flag_denuncia,'N')
                                   like a_flag_denuncia
             )
         and decode(prtr.tipo_pratica,'A',nvl(prtr.stato_accertamento,'D'),'D')
                                      = 'D'
         and a_anno                  <> 9999
--
--  Modifica apportata per potere escludere le denunce, per gli oggetti dove vi sia stato un accertamento
--  con flag denuncia attivo e possesso null, per gli anni successivi all'accertamneto.
--
         and (prtr.tipo_pratica||'' <> 'D'
             or
                prtr.tipo_pratica||'' = 'D'
                   and not exists
                        (select 1
                           from pratiche_tributo      prt2
                              , oggetti_contribuente  ogc2
                              , oggetti_pratica       ogp2
                          where prt2.tipo_tributo||''    = a_tipo_tributo
                           and prt2.pratica             = ogp2.pratica
                           and ogp2.oggetto_pratica     = ogc2.oggetto_pratica
                           and ogc2.tipo_rapporto      in ('A', 'C','D','E')
                           and ogc2.cod_fiscale         = a_cod_fiscale
                           and ogp2.oggetto             = a_oggetto
-- non prendiamo in considerazione le pratiche annullate
                           and prt2.flag_annullamento is null
                           and prt2.tipo_tributo||''    = a_tipo_tributo
                           and prt2.tipo_pratica||''    = 'A'
                           and prt2.flag_denuncia       = 'S'
                --      and nvl(ogc2.flag_possesso,'N') = 'N'
                           and prtr.tipo_pratica||''    = 'D'
                           and ogc2.anno                >= ogco.anno
                           and ogc2.anno                < a_anno
                        )
             )
-- 09/06/2004 Modifica che permette di visualizzare solo gli oggetti attivi anche per l'anno
-- scelto e non solo per l'anno 9999 (Tutti)  come fa nella seconda parte della union
         and not exists
            (select 1
               from pratiche_tributo      prt2
                   ,oggetti_contribuente  ogc2
                   ,oggetti_pratica       ogp2
              where prt2.tipo_tributo||''    = a_tipo_tributo
                and prt2.pratica             = ogp2.pratica
                and ogp2.oggetto_pratica     = ogc2.oggetto_pratica
                and ogc2.tipo_rapporto      in ('A', 'C','D','E')
                and ogc2.cod_fiscale         = a_cod_fiscale
                and ogp2.oggetto             = a_oggetto
                and prt2.tipo_tributo||''    = a_tipo_tributo
                and prt2.tipo_pratica||'' like a_tipo_pratica
-- non prendiamo in considerazione le pratiche annullate
                and prt2.flag_annullamento is null
                        and prt2.tipo_pratica||''   <> 'K'
--
--  Modifica apportata per potere considerare anche gli accertamenti senza
--  flag denuncia relativamente al solo anno di pratica (per sit.contribuente).
--
                and (    decode(prt2.tipo_pratica,'A',prt2.flag_denuncia,'S')
                                             = 'S'
                     or  prt2.anno           = a_anno
                     and nvl(prt2.flag_denuncia,'N')
                                          like a_flag_denuncia
                    )
                and decode(prt2.tipo_pratica,'A',nvl(prt2.stato_accertamento,'D'),'D')
                                             = 'D'
                and ogc2.anno                > ogco.anno
                        and ogc2.anno                < a_anno
            )
       group by a_tipo_tributo
       union all
      select to_number(substr(max(lpad(to_char(ogco.anno),4,'0')||
                                  lpad(to_char(nvl(ogco.da_mese_possesso,0)),2,'0')||
                                  ogco.tipo_rapporto||
                                  lpad(to_char(ogpr.oggetto_pratica),10,'0')
                                 ),8,10
                             )
                      )
        from pratiche_tributo      prtr
            ,oggetti_contribuente  ogco
            ,oggetti_pratica       ogpr
       where prtr.tipo_tributo||''    = a_tipo_tributo
         and prtr.pratica             = ogpr.pratica
         and ogpr.oggetto_pratica     = ogco.oggetto_pratica
         and ogco.tipo_rapporto      in ('A', 'C','D','E')
         and ogco.cod_fiscale         = a_cod_fiscale
         and ogpr.oggetto             = a_oggetto
         and prtr.tipo_tributo||''    = a_tipo_tributo
         and prtr.tipo_pratica||'' like a_tipo_pratica
-- non prendiamo in considerazione le pratiche annullate
         and prtr.flag_annullamento is null
           and prtr.tipo_pratica||'' <> 'K'
--
--  Modifica apportata per potere considerare anche gli accertamenti senza
--  flag denuncia relativamente al solo anno di pratica (per sit.contribuente).
--
         and (    decode(prtr.tipo_pratica,'A',prtr.flag_denuncia,'S')
                                       = 'S'
              or  prtr.anno           = a_anno
              and nvl(prtr.flag_denuncia,'N')
                                   like a_flag_denuncia
             )
         and decode(prtr.tipo_pratica,'A',nvl(prtr.stato_accertamento,'D'),'D')
                                      = 'D'
         and ogco.flag_possesso       = 'S'
         and a_anno                   = 9999
--
--  Modifica apportata per potere escludere le denuncie per gli oggetti dove vi sia stato un accertamento
--  con flag denuncia attivo e possesso null per gli anni successivi all'accertamneto.
--
       and   (prtr.tipo_pratica||'' <> 'D'
             or
                prtr.tipo_pratica||'' = 'D'
                   and not exists
                        (select 1
                     from pratiche_tributo      prt2
                            ,oggetti_contribuente  ogc2
                          ,oggetti_pratica       ogp2
                   where prt2.tipo_tributo||''    = a_tipo_tributo
                       and prt2.pratica             = ogp2.pratica
                      and ogp2.oggetto_pratica     = ogc2.oggetto_pratica
                      and ogc2.tipo_rapporto      in ('A', 'C','D','E')
                      and ogc2.cod_fiscale         = a_cod_fiscale
                      and ogp2.oggetto             = a_oggetto
                      and prt2.tipo_tributo||''    = a_tipo_tributo
                      and prt2.tipo_pratica||''    = 'A'
                      and prt2.flag_denuncia       = 'S'
-- non prendiamo in considerazione le pratiche annullate
                      and prt2.flag_annullamento is null
                --      and nvl(ogc2.flag_possesso,'N') = 'N'
                      and prtr.tipo_pratica||''    = 'D'
                              and ogc2.anno                >= ogco.anno
                      and ogc2.anno                < a_anno
               )
            )
         and not exists
            (select 1
               from pratiche_tributo      prt2
                   ,oggetti_contribuente  ogc2
                   ,oggetti_pratica       ogp2
              where prt2.tipo_tributo||''    = a_tipo_tributo
                and prt2.pratica             = ogp2.pratica
                and ogp2.oggetto_pratica     = ogc2.oggetto_pratica
                and ogc2.tipo_rapporto      in ('A', 'C','D','E')
                and ogc2.cod_fiscale         = a_cod_fiscale
                and ogp2.oggetto             = a_oggetto
                and prt2.tipo_tributo||''    = a_tipo_tributo
                and prt2.tipo_pratica||'' like a_tipo_pratica
-- non prendiamo in considerazione le pratiche annullate
                and prt2.flag_annullamento is null
                    and prt2.tipo_pratica||''   <> 'K'
--
--  Modifica apportata per potere considerare anche gli accertamenti senza
--  flag denuncia relativamente al solo anno di pratica (per sit.contribuente).
--
                and (    decode(prt2.tipo_pratica,'A',prt2.flag_denuncia,'S')
                                             = 'S'
                     or  prt2.anno           = a_anno
                     and nvl(prt2.flag_denuncia,'N')
                                          like a_flag_denuncia
                    )
                and decode(prt2.tipo_pratica,'A',nvl(prt2.stato_accertamento,'D'),'D')
                                             = 'D'
                and ogc2.anno                > ogco.anno
            )
       group by a_tipo_tributo
      ;
   end if;
   RETURN max_oggetto_pratica;
EXCEPTION
   WHEN OTHERS THEN
        RETURN -1;
END;
/* End Function: F_MAX_OGPR_CONT_OGGE */
/

