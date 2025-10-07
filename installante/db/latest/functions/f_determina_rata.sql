--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_determina_rata stripComments:false runOnChange:true 
 
create or replace function F_DETERMINA_RATA
/******************************************************************************
 NOME:             F_DETERMINA_RATA

 DESCRIZIONE:      Calcola l'importo della rata arrotondata così come
                   da algoritmo storico, centralizzandolo.

 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
   000   13/02/2025  RV      #77805
                             Versione Iniziale
*****************************************************************************/
( p_importo                  number                    -- Importo
, p_rata                     number                    -- Numero della rata
, p_rate                     number                    -- Numero della rate
, p_arrotondamento           number                    -- 0 : Intero o 2: Centesimi
) return number
is
  --
  w_arrotondamento          number;
  --
  w_rate                    number;
  --
  w_importo                 number;
  w_importo_rata            number;
  --
  w_result                  number;
  --
begin
  --
  w_arrotondamento := round(p_arrotondamento,0);
  --
  w_rate := nvl(p_rate,1);
  if w_rate < 1 then
    w_rate := 1;
  end if;
  --
  w_importo := round(nvl(p_importo,0),w_arrotondamento);
  w_importo_rata := round((w_importo / w_rate),w_arrotondamento);
  --
  if p_rata = w_rate then
    w_result := w_importo - (w_importo_rata * (w_rate - 1));
  else
    w_result := w_importo_rata;
  end if;
  --
  return w_result;
  --
end;
/* End Function: F_DETERMINA_RATA */
/
