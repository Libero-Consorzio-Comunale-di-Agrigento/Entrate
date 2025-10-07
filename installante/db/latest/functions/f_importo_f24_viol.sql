--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importo_f24_viol stripComments:false runOnChange:true 
 
create or replace function F_IMPORTO_F24_VIOL
(a_importo              in number
,a_riduzione            in number
,a_flag_ridotto         in varchar2
,a_tipo_tributo         in varchar2
,a_anno                 in number
,a_tipo_causale         in varchar2
,a_flag_magg_tares      in varchar2
,a_sanzione_minima      in number default null
) return number
/**
   Rev.  Data        Autore  Descrizione
   ----  ----------  ------  ----------------------------------------------------
   001   20/11/2023  RV      #65966 - Sanzione minima su riduzione
                             Aggiunto parametro a_sanzione_minima e logica gestione
   000   11/12/2014  XX      Prima emissione
**/
is
  --
  nImporto            number;
  nAdd_Eca_perc       number;
  nMag_Eca_perc       number;
  nAdd_Pro_perc       number;
  nIva_perc           number;
  --
  w_importo           number;
  --
BEGIN
   --
   if nvl(a_flag_ridotto,'N') = 'S' then
      --
      w_importo := (a_importo  * (100 - nvl(a_riduzione,0)) / 100);
      --
      if w_importo > 0 and a_sanzione_minima is not null then
        if(w_importo < a_sanzione_minima) then
          w_importo := a_sanzione_minima;
        end if;
      end if;
   else 
      w_importo := a_importo;
   end if;
  --
   if nvl(a_tipo_causale,'*') = 'E' and nvl(a_flag_magg_tares,'N') = 'N' 
      and a_tipo_tributo = 'TARSU' then
      BEGIN
         select nvl(cata.addizionale_eca,0)
              , nvl(cata.maggiorazione_eca,0)
              , nvl(cata.addizionale_pro,0)
              , nvl(cata.aliquota,0)
           into nAdd_Eca_perc
              , nMag_Eca_perc
              , nAdd_Pro_perc
              , nIva_perc
           from carichi_tarsu   cata
          where cata.anno = a_anno
           ;
      EXCEPTION
         WHEN NO_DATA_FOUND THEN
            nAdd_Eca_perc  := 0;
            nMag_Eca_perc  := 0;
            nAdd_Pro_perc  := 0;
            nIva_perc      := 0;
      END;
      nImporto   := round(w_importo * nAdd_Eca_perc / 100,2)
                  + round(w_importo * nMag_Eca_perc / 100,2)
                  + round(w_importo * nAdd_Pro_perc / 100,2)
                  + round(w_importo * nIva_perc / 100,2)
                  + round(w_importo,2);
   else
      nImporto   := round(w_importo,2);
   end if;
   Return nImporto;
END;
/* End Function: F_IMPORTO_F24_VIOL */
/
