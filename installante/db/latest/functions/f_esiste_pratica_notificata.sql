--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_esiste_pratica_notificata stripComments:false runOnChange:true 
 
create or replace function F_ESISTE_PRATICA_NOTIFICATA
/*************************************************************************
 NOME:        F_ESISTE_PRATICA_NOTIFICATA
 DESCRIZIONE: Restituisce il numero di pratiche (A o L) con notifica di un
              contribuente in base all'anno e al tipo tributo
 PARAMETRI:   p_cod_fiscale         Codice fiscale
              p_anno               Anno
              p_tipo_tributo        Tipo tributo
              p_tipo_pratica        Tipo pratica, valori 'A' o 'L'
 RITORNA:     number                Numero di pratiche
 NOTE:
 Rev.    Date         Author      Note
 000     25/10/2022   AL          Prima emissione.
*************************************************************************/
( p_cod_fiscale          IN varchar2
, p_anno                 IN number
, p_tipo_tributo         IN varchar2
, p_tipo_pratica         IN varchar2
) return number
as
  w_pratiche             number;
begin
    IF p_tipo_pratica IN ('A', 'L') THEN
       IF  p_anno IS NOT NULL
       AND p_tipo_tributo IS NOT NULL
       AND p_cod_fiscale IS NOT NULL THEN
          SELECT COUNT(*)
            INTO w_pratiche
            FROM pratiche_tributo prtr
           WHERE prtr.cod_fiscale = p_cod_fiscale
             AND prtr.anno = p_anno
             AND prtr.tipo_tributo = p_tipo_tributo
             AND prtr.tipo_pratica = p_tipo_pratica
             AND prtr.data_notifica IS NOT NULL;
          RETURN w_pratiche;
        ELSE
          RETURN NULL;
        END IF;
    ELSE
      RETURN NULL;
    END IF;
end;
/* End Function: F_ESISTE_PRATICA_NOTIFICATA */
/

