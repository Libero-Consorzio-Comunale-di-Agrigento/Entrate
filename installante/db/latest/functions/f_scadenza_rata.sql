--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_scadenza_rata stripComments:false runOnChange:true 
 
create or replace function F_SCADENZA_RATA
/*************************************************************************
 NOME:        F_SCADENZA_RATA

 DESCRIZIONE: Determina la scadenza della rata per il tipo tributo e l'anno
              indicati.

 PARAMETRI:   Tipo tributo
              Anno
              Rata

 RITORNA:     date              Data scadenza rata

 NOTE:

 Rev.    Date         Author      Note
 002     14/12/2023   RV          #54732
                                  Aggiunto filtro per gruppo_tributo e tipo_occupazione
 001     28/03/2022   VD          Aggiunta gestione rata 0: si restituisce
                                  la relativa scadenza se esiste, altrimenti
                                  si restituisce la scadenza della rata 1.
 000     18/02/2000   XX          Prima emissione.
*************************************************************************/
( a_tipo_trib                         varchar2
, a_anno                              number
, a_rata                              number
, a_gruppo_tributo                    varchar2 default null
, a_tipo_occupazione                  varchar2 default null
) RETURN date
IS
  w_data_scad                      date;
BEGIN
  begin
    select data_scadenza
      into w_data_scad
      from scadenze
     where tipo_tributo      = a_tipo_trib
       and nvl(gruppo_tributo,'----')
                             = nvl(a_gruppo_tributo,'----')
       and nvl(tipo_occupazione,'P')
                             = nvl(a_tipo_occupazione,'P')
       and anno              = a_anno
       and rata              = a_rata
       and tipo_scadenza     = 'V'
     ;
  exception
    when others then
      w_data_scad := to_date(null);
  end;
  --
  if a_rata = 0 and w_data_scad is null then
     begin
       select data_scadenza
        into w_data_scad
        from scadenze
       where tipo_tributo = a_tipo_trib
         and anno  = a_anno
         and rata  = 1
         and tipo_scadenza = 'V'
       ;
     exception
       when others then
         null;
     end;
  end if;
  --
  RETURN w_data_scad;
EXCEPTION
   WHEN OTHERS THEN
        RETURN NULL;
END;
/* End Function: F_SCADENZA_RATA */
/
