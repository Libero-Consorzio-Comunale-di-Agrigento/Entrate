--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_sgravio_ruco_escl stripComments:false runOnChange:true 
 
create or replace function F_SGRAVIO_RUCO_ESCL
/******************************************************************************
 NOME:        F_SGRAVIO_RUCO_ESCL
 DESCRIZIONE: Dato un ruolo a saldo, un contribuente e una sequenza di
              ruoli_contribuente, restituisce il totale degli sgravi
              emessi relativi a sconti per conferimenti (Pontedera)
              Il risultato dipende dal valore del parametro tipo_importo:
              N - Importo netto, al netto di tutte le addizionali
              L - Importo lordo, comprensivo di tutte le addizionali
              M - Importo di maggiorazione TARES
              E - Importo di addizionale + maggiorazione ECA
              P - Importo di addizionale provinciale
              I - Importo IVA
 ANNOTAZIONI: PONTEDERA: tratta solo le righe con il primo carattere del
              campo note = '*', per gli sconti relativi ai conferimenti
 REVISIONI: .
 Rev.  Data        Autore    Descrizione.
 0     06/10/2017  VD        Prima emissione
*************************************************************************/
( a_ruolo                  number
, a_cod_fiscale            varchar2
, a_sequenza               number
, a_tipo_importo           varchar2
) return number
is
  w_importo                number;
  w_cod_istat              varchar2(6);
begin
  --
  begin
    select lpad(pro_cliente,3,'0')||
           lpad(com_cliente,3,'0')
      into w_cod_istat
      from dati_generali;
  exception
    when others then
      raise_application_error(-20999,'Dati generali non presenti o multipli');
  end;
  --
  if w_cod_istat in ('050029','037006') then
     select sum(decode(a_tipo_importo,'L',nvl(sgra.importo,0)
                                     ,'N',nvl(sgra.importo,0) - (nvl(sgra.addizionale_eca,0) +
                                                                 nvl(sgra.maggiorazione_eca,0) +
                                                                 nvl(sgra.addizionale_pro,0) +
                                                                 nvl(sgra.iva,0) +
                                                                 nvl(sgra.maggiorazione_tares,0))
                                     ,'M',nvl(sgra.maggiorazione_tares,0)
                                     ,'E',nvl(sgra.addizionale_eca,0) + nvl(sgra.maggiorazione_eca,0)
                                     ,'P',nvl(sgra.addizionale_pro,0)
                                     ,'I',nvl(sgra.iva,0)))
       into w_importo
       from sgravi sgra
           ,ruoli r
      where sgra.motivo_sgravio != 99
        and sgra.ruolo = a_ruolo
        and sgra.cod_fiscale = a_cod_fiscale
        and sgra.sequenza    = a_sequenza
        and nvl(substr(sgra.note,1,1),' ') = '*'
        and r.ruolo = a_ruolo
        and nvl(r.tipo_emissione, 'T') = 'S';
  else
     w_importo := 0;
  end if;
--
  return nvl(w_importo,0) * - 1;
end;
/* End Function: F_SGRAVIO_RUCO_ESCL */
/

