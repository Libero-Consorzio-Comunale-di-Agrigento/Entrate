--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importi_acc stripComments:false runOnChange:true 
 
create or replace function F_IMPORTI_ACC
(a_pratica       in number
,a_ridotto       in varchar2
,a_tipo_importo  in varchar2
) return number
  /******************************************************************************
    NOME:        F_IMPORTI_ACC
    NOTE:
    Rev.  Data        Autore  Descrizione
    ----  ----------  ------  ----------------------------------------------------
    007   06/02/2025  RV      #77116
                              Flag sanz_min_rid da pratica non da inpa
    006   31/01/2025  RV      #71533
                              Aggiunto caso TASSA_EVASA_TOTALE
    005   10/12/2024  AB      #76942
                              Sistemato controllo su sanz con sequenza
    004   08/03/2024  RV      #55403 : aggiunto caso TASSA_EVASA_LORDA
    003   20/11/2023  RV      #65966 : sistemata per sanzione minima
    002   26/04/2022  VD      Corretto test tipo causale
    001   29/01/2015  VD      Sostituito codice sanzione 115 con codice 197
  ******************************************************************************/
is
nAdd_Eca_perc  number;
nMag_Eca_perc  number;
nAdd_Pro_perc  number;
nIva_perc      number;
sTipo_Tributo  varchar2(8);
nAnno          number;
nNetto         number := 0;
nNettoTot      number := 0;
nLordo         number := 0;
nLordoTot      number := 0;
nAdd_Eca       number := 0;
nAdd_EcaTot    number := 0;
nMag_Eca       number := 0;
nMag_EcaTot    number := 0;
nAdd_Pro       number := 0;
nAdd_ProTot    number := 0;
nIva           number := 0;
nIvaTot        number := 0;
nInteressi     number := 0;
nInteressiTot  number := 0;
nSanzioni      number := 0;
nSanzioniTot   number := 0;
nTassaEvasa    number := 0;
nTassaEvasaTot number := 0;
nSpese         number := 0;
nSpeseTot      number := 0;
nMaggiorazione number := 0;
nMaggiorazioneTot number := 0;
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
BEGIN
   BEGIN
      select prtr.anno
           , prtr.tipo_tributo
           , prtr.flag_sanz_min_rid
        into nAnno
           , sTipo_Tributo
           , w_sanz_min_rid
        from pratiche_tributo  prtr
       where prtr.pratica      = a_pratica
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
            into nAdd_Eca_perc
                ,nMag_Eca_perc
                ,nAdd_Pro_perc
                ,nIva_perc
            from carichi_tarsu   cata
           where cata.anno = nAnno
            ;
        EXCEPTION
           WHEN NO_DATA_FOUND THEN
           Return 0;
        END;
   end if;
   for rec_sapr in sel_sapr(a_pratica)
   loop
      if a_ridotto = 'S' then
         nNetto := round(rec_sapr.importo * (100 - nvl(rec_sapr.riduzione,0)) / 100,2);
         --
         if nvl(w_sanz_min_rid,'N') = 'S' then
           if rec_sapr.sanzione_minima is not null then
             if nNetto < rec_sapr.sanzione_minima then
                nNetto := rec_sapr.sanzione_minima;
             end if ;
           end if;
         end if;
      else
         nNetto := rec_sapr.importo;
      end if;
      --
      nNettoTot := nNettoTot + nNetto;
      --
      if (rec_sapr.cod_sanzione in (1,100,101,111)
      or (nvl(rec_sapr.tipo_causale,'*') = 'E' and nvl(rec_sapr.flag_magg_tares,'N') = 'N'))
      and sTipo_Tributo = 'TARSU' then
         nLordo   := round(nNetto * nAdd_Eca_perc / 100,2) +
                     round(nNetto * nMag_Eca_perc / 100,2) +
                     round(nNetto * nAdd_Pro_perc / 100,2) +
                     round(nNetto * nIva_perc / 100,2) + nNetto;
         nAdd_Eca := round(nNetto * nAdd_Eca_perc / 100,2);
         nMag_Eca := round(nNetto * nMag_Eca_perc / 100,2);
         nAdd_Pro := round(nNetto * nAdd_Pro_perc / 100,2);
         nIva     := round(nNetto * nIva_perc / 100,2);
      else
         nLordo   := nNetto;
         nAdd_Eca := 0;
         nMag_Eca := 0;
         nAdd_Pro := 0;
         nIva     := 0;
      end if;
      nLordoTot   := nLordoTot + nLordo;
      nAdd_EcaTot := nAdd_EcaTot + nAdd_Eca;
      nMag_EcaTot := nMag_EcaTot + nMag_Eca;
      nAdd_ProTot := nAdd_ProTot + nAdd_Pro;
      nIvaTot     := nIvaTot + nIva;
      if rec_sapr.cod_sanzione in (98,99,199)
      or (nvl(rec_sapr.tipo_causale,'*') = 'I' and nvl(rec_sapr.flag_magg_tares,'N') = 'N') then
         nInteressi     := nNetto;
         nInteressiTot  := nInteressiTot + nInteressi;
      elsif  rec_sapr.cod_sanzione in (1,100,101)
      -- (VD - 26/04/2022): corretto test tipo causale
      --or (nvl(rec_sapr.tipo_causale,'*') = 'I' and nvl(rec_sapr.flag_magg_tares,'N') = 'N')then
      or (nvl(rec_sapr.tipo_causale,'*') = 'E' and nvl(rec_sapr.flag_magg_tares,'N') = 'N')then
         nTassaEvasa    := nNetto;
         nTassaEvasaTot := nTassaEvasaTot + nTassaEvasa;
      elsif  rec_sapr.cod_sanzione = 197 then
         nSpese    := nNetto;
         nSpeseTot := nSpeseTot + nSpese;
      elsif  (nvl(rec_sapr.tipo_causale,'*') = 'E' and nvl(rec_sapr.flag_magg_tares,'N') = 'S') then
         nMaggiorazione    := nNetto;
         nMaggiorazioneTot := nMaggiorazioneTot + nMaggiorazione;
      else
         nSanzioni      := nNetto;
         nSanzioniTot   := nSanzioniTot + nSanzioni;
      end if;
   end loop;
   -- Gestione del valore d'uscita a seconda del parametro a_tipo_importo
   if a_tipo_importo = 'ADD_ECA' then
      Return nAdd_EcaTot;
   elsif a_tipo_importo = 'MAG_ECA' then
      Return nMag_EcaTot;
   elsif a_tipo_importo = 'ADD_PRO' then
      Return nAdd_ProTot;
   elsif a_tipo_importo = 'IVA' then
      Return nIvaTot;
   elsif a_tipo_importo = 'INTERESSI' then
      Return nInteressiTot;
   elsif a_tipo_importo = 'SANZIONI' then
      Return nSanzioniTot;
   elsif a_tipo_importo = 'TASSA_EVASA' then
      Return nTassaEvasaTot;
   elsif a_tipo_importo = 'TASSA_EVASA_LORDA' then
      Return nTassaEvasaTot + nMag_EcaTot + nMag_EcaTot + nAdd_ProTot;
   elsif a_tipo_importo = 'TASSA_EVASA_TOTALE' then
      Return nTassaEvasaTot + nMag_EcaTot + nMag_EcaTot + nAdd_ProTot + nMaggiorazioneTot;
   elsif a_tipo_importo = 'NETTO' then
      Return nNettoTot;
   elsif a_tipo_importo = 'LORDO' then
      Return nLordoTot;
   elsif a_tipo_importo = 'SPESE' then
      Return nSpeseTot;
   elsif a_tipo_importo = 'MAGGIORAZIONE' then
      Return nMaggiorazioneTot;
   else
      return 0;
   end if;
END;
/* End Function: F_IMPORTI_ACC */
/
