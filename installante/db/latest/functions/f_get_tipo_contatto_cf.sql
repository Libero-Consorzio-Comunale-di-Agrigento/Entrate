--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_tipo_contatto_cf stripComments:false runOnChange:true 
 
create or replace function F_GET_TIPO_CONTATTO_CF
/*************************************************************************
 NOME:        F_GET_TIPO_CONTATTO_CF
 DESCRIZIONE: Verifica l'esistenza di una riga di CONTATTI_CONTRIBUENTE
              relativa a codice fiscale, anno, tipo tributo e tipo
              contatto indicati.
 RITORNA:     number             1 - Riga esistente
                                 0 - Riga non esistente
 NOTE:        Funzione creata per sostituire 2 select nella
              ue_initfrstobj di w_tr4_rte_stampa (per problemi di
              dimensioni codice).
 Rev.    Date         Author      Note
 000     12/07/2018   VD          Prima emissione.
**************************************************************************/
( a_cod_fiscale                   varchar2
, a_anno                          number
, a_tipo_tributo                  varchar2
, a_tipo_contatto                 number
) return number
is
  d_return                        number;
begin
  select nvl(max(1),0)
    into d_return
    from contatti_contribuente
   where cod_fiscale = a_cod_fiscale
     and anno = a_anno
     and nvl(tipo_tributo,' ') = a_tipo_tributo
     and tipo_contatto = a_tipo_contatto;
--
  return d_return;
--
end;
/* End Function: F_GET_TIPO_CONTATTO_CF */
/

