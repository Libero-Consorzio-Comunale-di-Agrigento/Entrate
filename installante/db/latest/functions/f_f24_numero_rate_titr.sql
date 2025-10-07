--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_f24_numero_rate_titr stripComments:false runOnChange:true 
 
create or replace function F_F24_NUMERO_RATE_TITR
/*************************************************************************
 NOME:        F_F24_NUMERO_RATE_TITR
 DESCRIZIONE: Determina la massima rata presente per tipo tributo,
              contribuente ed eventuale oggetto_pratica.
 RITORNA:     number              Numero massima rata
 NOTE:        Utilizzata per F24 TOSAP/ICP.
 Rev.    Date         Author      Note
 000     14/03/2018   VD          Prima emissione.
*************************************************************************/
(a_cod_fiscale             varchar2,
 a_anno                    number,
 a_titr                    varchar2,
 a_ogim                    number
) RETURN                   number
IS
   w_max_rata              number;
BEGIN
   select max(rata)
     into w_max_rata
     from rate_imposta
    where cod_fiscale = a_cod_fiscale
      and anno = a_anno
      and tipo_tributo = a_titr
      and nvl(oggetto_imposta,0) = nvl(a_ogim,nvl(oggetto_imposta,0));
--
  return w_max_rata;
--
END;
/* End Function: F_F24_NUMERO_RATE_TITR */
/

