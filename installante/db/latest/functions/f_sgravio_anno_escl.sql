--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_sgravio_anno_escl stripComments:false runOnChange:true 
 
create or replace function F_SGRAVIO_ANNO_ESCL
/******************************************************************************
 NOME:        F_SGRAVIO_ANNO_ESCL
 DESCRIZIONE: Dato un ruolo a saldo e un contribuente, restituisce il totale
              degli sgravi emessi per il contribuente stesso nei ruoli in
              acconto
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
 0     03/10/2017  VD        Prima emissione
*************************************************************************/
( a_ruolo                  number
, a_cod_fiscale            varchar2
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
        ,(select ruol_prec.ruolo
            from ruoli, ruoli ruol_prec
           where nvl(ruol_prec.tipo_emissione(+), 'T') = 'A'
             and ruol_prec.invio_consorzio(+) is not null
             and ruol_prec.anno_ruolo(+) = ruoli.anno_ruolo
             and ruol_prec.tipo_tributo(+) || '' = ruoli.tipo_tributo
             and ruoli.ruolo = a_ruolo
             and nvl(ruoli.tipo_emissione, 'T') = 'S'
             and ruol_prec.ruolo != ruoli.ruolo
          union
          select a_ruolo from dual) ruolo_prec
   where sgra.motivo_sgravio != 99
     and sgra.ruolo = ruolo_prec.ruolo
     and sgra.cod_fiscale = a_cod_fiscale
     and w_cod_istat in ('050029','037006')
     and nvl(substr(sgra.note,1,1),' ') = '*'
     and r.ruolo = a_ruolo
     and nvl(r.tipo_emissione, 'T') = 'S';
--
  return nvl(w_importo,0);
end;
/* End Function: F_SGRAVIO_ANNO_ESCL */
/

