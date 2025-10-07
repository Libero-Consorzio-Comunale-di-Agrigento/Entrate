--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importo_acc_lordo stripComments:false runOnChange:true 
 
create or replace function F_IMPORTO_ACC_LORDO
(a_pratica in number
,a_ridotto in varchar2
) return number
  /******************************************************************************
    NOME:        F_IMPORTO_ACC_LORDO
    NOTE:
    Rev.  Data        Autore  Descrizione
    ----  ----------  ------  ----------------------------------------------------
    002   20/11/2023  RV      #77116 : Flag sanz_min_rid da pratica non da inpa
    002   20/11/2023  RV      #65966 : sistemata per sanzione minima
    001   XX/XX/XXXX  XX      Versione iniziale
  ******************************************************************************/
is
nImp_Totale number;
nImporto    number;
nAdd_Eca    number;
nMag_Eca    number;
nAdd_Pro    number;
nIva        number;
sTipo_Tributo varchar2(8);
nAnno       number;
sFlag_Lordo varchar2(1);
--
w_sanz_min_rid varchar2(1);
--
cursor sel_sapr (p_pratica number) is
select sapr.cod_sanzione
      ,nvl(sapr.importo,0) importo
      ,sapr.riduzione
      ,sanz.tipo_causale
      ,sanz.flag_magg_tares
      ,sanz.sanzione_minima
  from sanzioni_pratica sapr
     , sanzioni sanz
 where sapr.pratica = p_pratica
   and sapr.cod_sanzione != decode(a_ridotto,'S',888,889)
   and sanz.tipo_tributo = sapr.tipo_tributo
   and sanz.cod_sanzione = sapr.cod_sanzione
   and sanz.sequenza     = sapr.sequenza_sanz
 order by
       sapr.cod_sanzione
;
--
BEGIN
   nImp_Totale := 0;
   BEGIN
      select prtr.anno
           , prtr.tipo_tributo
           , prtr.flag_sanz_min_rid
        into nAnno
           , sTipo_Tributo
           , w_sanz_min_rid
        from pratiche_tributo  prtr
       where prtr.pratica      = a_pratica
--         and prtr.tipo_pratica = 'A'      -- 25032009 tolto per gestire anche le Liq
      ;
   EXCEPTION
      WHEN NO_DATA_FOUND THEN
         Return 0;
   END;
   if sTipo_Tributo = 'TARSU' then
        BEGIN
          select nvl(cata.addizionale_eca,0)
                ,nvl(cata.maggiorazione_eca,0)
                ,nvl(cata.addizionale_pro,0)
                ,nvl(cata.aliquota,0)
                ,flag_lordo
            into nAdd_Eca
                ,nMag_Eca
                ,nAdd_Pro
                ,nIva
                ,sFlag_Lordo
            from carichi_tarsu     cata
           where cata.anno         = nAnno
            ;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
           Return 0;
        END;
   end if;
   for rec_sapr in sel_sapr(a_pratica)
   loop
      if a_ridotto = 'S' then
         nImporto := round(rec_sapr.importo * (100 - nvl(rec_sapr.riduzione,0)) / 100,2);
         --
         if nvl(w_sanz_min_rid,'N') = 'S' then
           if rec_sapr.sanzione_minima is not null then
             if nImporto < rec_sapr.sanzione_minima then
                nImporto := rec_sapr.sanzione_minima;
             end if ;
           end if;
         end if;
      else
         nImporto := rec_sapr.importo;
      end if;
      if (rec_sapr.cod_sanzione in (1,100,101)
      or (nvl(rec_sapr.tipo_causale,'*') = 'E' and nvl(rec_sapr.flag_magg_tares,'N') = 'N'))
      and sTipo_Tributo = 'TARSU' 
      and sFlag_Lordo = 'S' then
         nImporto := round(nImporto * nAdd_Eca / 100,2) +
                     round(nImporto * nMag_Eca / 100,2) +
                     round(nImporto * nAdd_Pro / 100,2) +
                     round(nImporto * nIva / 100,2) + nImporto;
      end if;
      nImp_Totale := nImp_Totale + nImporto;
   end loop;
   Return nImp_Totale;
END;
/* End Function: F_IMPORTO_ACC_LORDO */
/
