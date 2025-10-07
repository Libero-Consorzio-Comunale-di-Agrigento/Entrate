--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importo_vers_ravv stripComments:false runOnChange:true 
 
CREATE OR REPLACE function     F_IMPORTO_VERS_RAVV
/*************************************************************************
 NOME:        F_IMPORTO_VERS_RAVV
 DESCRIZIONE: Restituisce l'importo versato su ravvedimento relativo
              alla sola imposta.
 PARAMETRI:   p_tipo_tributo      Tipo tributo da controllare
 RITORNA:     number              Importo versato
 NOTE:
 Rev.    Date         Author      Note
 005     10/12/2024   AB          #76942
                                  Sistemato controllo su sanz con sequenza
 004     06/06/2024   RV          #72967
                                  Rivisto selezione versamenti e sanzioni per tributi
                                  non ICI e TASI con codice rata nullo e 1
                                  Sistemato logica importo reale per sanz.tipo_causale = 'E'
                                  con sanz.rata nullo (TARSU) o 0 (CUNI)
                                  Sistemato caso TARSU per calcolo ripartizione su lordo e non su netto
 003     22/03/2022   VD          Aggiunta gestione versamenti su rate
                                  per tipi tributo diversi da ICI e TASI.
 002     07/05/2020   VD          Revisionato test su codici sanzione:
                                  per evitare di doverlo modificare ogni
                                  volta che si inserisce un nuovo codice,
                                  ora il test viene eseguito utilizzando
                                  altri attributi della tabella, come il
                                  tipo_causale e i vari flag.
 001     18/08/2016   VD          Aggiunta gestione liquidazione mini IMU
                                  per il 2013: nella determinazione degli
                                  importi di imposta e sanzioni dalla pratica
                                  si trattano i nuovi codici sanzione relativi
                                  alla mini IMU
                                  NOTA: Allo stato attuale, la mini IMU viene
                                  trattata correttamente SOLO SE IL VERSAMENTO
                                  VIENE FATTO CON TIPO = 'U'
 000     XX/XX/XXXX    XX         Prima emissione.
*************************************************************************/
(a_cod_fiscale          in varchar2
,a_tipo_tributo         in varchar2
,a_anno                 in number
,a_tipo_versamento      in varchar2
) Return number is
nImporto_versato           number;
nImporto_sapr              number;
nImporto_reale             number;
nImporto                   number := 0;
CURSOR sel_prtr(p_cf varchar2, p_anno number, p_titr varchar2) IS
select pratica
  from pratiche_tributo prtr
 where prtr.tipo_tributo||''  = p_titr
   and prtr.anno              = p_anno
   and prtr.tipo_pratica      = 'V'
   and prtr.cod_fiscale       = p_cf
   and prtr.numero            is not null
   and nvl(prtr.stato_accertamento,'D') = 'D'
 order by 1
     ;
BEGIN
   FOR rec_prtr IN sel_prtr(a_cod_fiscale, a_anno, a_tipo_tributo)
   LOOP
      BEGIN
         select sum(importo_versato)       importo_versato
           into nImporto_versato
           from versamenti vers
          where vers.pratica = rec_prtr.pratica
            and ((a_tipo_tributo in ('ICI','TASI')
                  and (a_tipo_versamento = 'U'
                      or (    a_tipo_versamento = 'A'
                          and nvl(vers.tipo_versamento,'U') in ('A','U')
                         )
                      or (    a_tipo_versamento = 'S'
                          and nvl(vers.tipo_versamento,'U') = 'S'
                         )
                      )
                 )
               or
                 (a_tipo_tributo in ('TARSU') and
                  -- #72967 per Caso 'U', ovvero totale :
                  --          Siccome i versamenti da F24 su Ravvedimento arrivano sempre con rata = 1
                  --          ci serve contabilizzare pure quelli
                  --          Non è il massimo ma senno tocca rivedere tutta la procedura di importazione
                  --          ed assegnare numero rata = '0' o null nei casi di rateazione F24 '0101'
                  decode(a_tipo_versamento
                        ,'U',decode(vers.rata,null,'U',0,'U',1,'U',to_char(vers.rata))
                        ,a_tipo_versamento) = decode(vers.rata,null,'U',0,'U',1,'U',to_char(vers.rata))
                 )
               or
                 (a_tipo_tributo not in ('ICI','TASI','TARSU') and
                  decode(a_tipo_versamento
                        ,'U',decode(vers.rata,null,'U',0,'U',to_char(vers.rata))
                        ,a_tipo_versamento) = decode(vers.rata,null,'U',0,'U',to_char(vers.rata))
                 )
         )
              ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            nImporto_versato := 0;
         WHEN others THEN
            nImporto_versato := 0;
      END;
      nImporto_versato := nvl(nImporto_versato,0);
      --
    --dbms_output.put_line('Ver : '||nImporto_versato);
      --
      BEGIN
         select case
                  when a_tipo_tributo in ('ICI','TASI')
                    then decode(a_tipo_versamento
                               ,'U',sum(importo)
                               ,'A',sum(decode(sanz.tipo_versamento
                                              ,'A',sapr.importo
                                              ,0
                                              )
                                       )
                               ,'S',sum(decode(sanz.tipo_versamento
                                              ,'S',sapr.importo
                                              ,0
                                              )
                                       )
                               )
                    when a_tipo_tributo in ('TARSU')
                      then
                       sum(decode(a_tipo_versamento
                                 ,decode(sanz.rata,null,'U',0,'U',to_char(sanz.rata))
                                 ,sapr.importo +          -- Serve il lordo, senno sbaglia la proporzione
                                   case when sanz.tipo_causale = 'E' and sanz.flag_magg_tares is null then
                                          f_round(cata.addizionale_eca * nvl(sapr.importo,sanz.sanzione)/100,1)
                                        + f_round(cata.maggiorazione_eca * nvl(sapr.importo,sanz.sanzione)/100,1)
                                        + f_round(cata.addizionale_pro * nvl(sapr.importo,sanz.sanzione)/100,1)
                                        + f_round(cata.aliquota * nvl(sapr.importo,sanz.sanzione)/100,1)
                                   else
                                       0
                                   end
                                 ,0
                                 )
                          )
                  else
                       sum(decode(a_tipo_versamento
                                 ,'U'                           -- Se voglio il totale prende tutto, senno solo
                                 ,sapr.importo                  -- le sanzioni specifiche per il tipo_versamento
                                 ,decode(sanz.rata,null,'U',0,'U',to_char(sanz.rata))
                                 ,sapr.importo
                                 ,0
                                 )
                          )
                end importo_sapr
              , case
                  when a_tipo_tributo in ('ICI','TASI')
                    then decode(a_tipo_versamento
                               ,'U',sum(decode(sanz.tipo_causale
                                              ,'E',sapr.importo
                                              ,0
                                              )
                                       )
                               ,'A',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                              ,'EA',sapr.importo
                                              ,0
                                              )
                                       )
                               ,'S',sum(decode(sanz.tipo_causale||sanz.tipo_versamento
                                              ,'ES',sapr.importo
                                              ,0
                                              )
                                       )
                               )
                    when a_tipo_tributo in ('TARSU')
                      then
                         sum(decode(sanz.tipo_causale||
                                      decode(sanz.rata,null,'U',0,'U',to_char(sanz.rata))
                                   ,'E'||a_tipo_versamento
                                   ,sapr.importo +          -- Serve il lordo, senno sbaglia la proporzione
                                     decode(sanz.flag_magg_tares,'S',0,
                                            f_round(cata.addizionale_eca * nvl(sapr.importo,sanz.sanzione)/100,1)
                                          + f_round(cata.maggiorazione_eca * nvl(sapr.importo,sanz.sanzione)/100,1)
                                          + f_round(cata.addizionale_pro * nvl(sapr.importo,sanz.sanzione)/100,1)
                                          + f_round(cata.aliquota * nvl(sapr.importo,sanz.sanzione)/100,1))
                                   ,0
                                   )
                             )
                    else
                         sum(decode(sanz.tipo_causale||
                                      decode(a_tipo_versamento    -- Se voglio il totale prende tutto, senno solo
                                              ,'U','U'            -- le sanzioni specifiche per il tipo_versamento
                                              ,decode(sanz.rata,null,'U',0,'U',to_char(sanz.rata)))
                                   ,'E'||a_tipo_versamento
                                   ,sapr.importo
                                   ,0
                                   )
                             )
                end importo_reale
           into nImporto_sapr
              , nImporto_reale
           from sanzioni_pratica sapr
              , sanzioni         sanz
              , (select
                  case when prtr.tipo_tributo = 'TARSU' and cata.flag_lordo = 'S' then nvl(cata.addizionale_eca,0) else 0 end addizionale_eca,
                  case when prtr.tipo_tributo = 'TARSU' and cata.flag_lordo = 'S' then nvl(cata.maggiorazione_eca,0) else 0 end maggiorazione_eca,
                  case when prtr.tipo_tributo = 'TARSU' and cata.flag_lordo = 'S' then nvl(cata.addizionale_pro,0) else 0 end addizionale_pro,
                  case when prtr.tipo_tributo = 'TARSU' and cata.flag_lordo = 'S' then nvl(cata.aliquota,0) else 0 end aliquota
                from
                  pratiche_tributo prtr,
                  carichi_tarsu cata
                where
                  prtr.pratica = rec_prtr.pratica
                and prtr.anno = cata.anno(+)
                ) cata
          where pratica = rec_prtr.pratica
            and sapr.tipo_tributo  = sanz.tipo_tributo
            and sapr.cod_sanzione  = sanz.cod_sanzione
            and sapr.sequenza_sanz = sanz.sequenza
              ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            nImporto_sapr   := 0;
            nImporto_reale  := 0;
         WHEN others THEN
            nImporto_sapr   := 0;
            nImporto_reale  := 0;
      END;
      nImporto_sapr  := nvl(nImporto_sapr,0);
      nImporto_reale := nvl(nImporto_reale,0);
      --
    --dbms_output.put_line('SaPr : '||nImporto_sapr);
    --dbms_output.put_line('Real : '||nImporto_reale);
      --
      if nImporto_versato > 0 then
         -- Gestione Arrotondamenti
         if a_anno >= 2007 then
            nImporto_sapr  := round(nImporto_sapr,0);
            nImporto_reale := round(nImporto_reale,0);
         end if;
         if nImporto_versato >= nImporto_sapr then
            nImporto := nImporto + nImporto_reale + nImporto_versato - nImporto_sapr;
         else
            nImporto := nImporto + round( nImporto_reale * ( nImporto_versato / nImporto_sapr),2);
         end if;
      end if;
      --
    --dbms_output.put_line('Imp : '||nImporto);
      --
   END LOOP;
   --
   Return nImporto;
   --
EXCEPTION
  WHEN others THEN
       RAISE_APPLICATION_ERROR (-20999,'Errore in Calcolo Importo Versamenti Ravv'||'('||SQLERRM||')');
END;
/* End Function: F_IMPORTO_VERS_RAVV */
/
