--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_stampa_com_ruolo stripComments:false runOnChange:true 
 
create or replace function F_STAMPA_COM_RUOLO
/*************************************************************************
 NOME:        F_STAMPA_COM_RUOLO
 DESCRIZIONE: Restituisce 1 per impostare la modalita' di stampa
              richiesta nella comunicazione a ruolo.
              Attivato per Pontedera (stampa temporanea conferimenti)
                       e Bologna (prove ADS)
 RITORNA:     varchar2      Valore del campo richiesto
*************************************************************************/
( p_ruolo                   number
) return number
is
  d_return                  number;
  d_cod_istat               varchar2(6);
  d_conta_sgravi            number;
begin
  begin
    select lpad(pro_cliente,3,'0')||
           lpad(com_cliente,3,'0')
      into d_cod_istat
      from dati_generali;
  exception
    when others then
      raise_application_error(-20999,'Dati generali non presenti o multipli');
  end;
--
  if d_cod_istat in ('050029','037006') then
     select max(conta_sgravi)
       into d_conta_sgravi
       from (select cod_fiscale,sequenza,count(sequenza_sgravio) conta_sgravi
               from sgravi
              where ruolo = p_ruolo
                and motivo_sgravio <> 99
                and nvl(substr(note,1,1),' ') = '*'
              group by cod_fiscale,sequenza);
     if d_conta_sgravi > 3 then
        d_return := 0;
     else
        d_return := 1;
     end if;
  else
     d_return := 0;
  end if;
--
  return d_return;
--
end;
/* End Function: F_STAMPA_COM_RUOLO */
/

