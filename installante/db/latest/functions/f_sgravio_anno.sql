--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_sgravio_anno stripComments:false runOnChange:true 
 
create or replace function F_SGRAVIO_ANNO
/******************************************************************************
 NOME:        F_SGRAVIO_ANNO
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
              C - Compensazioni
              CN - Compensazioni al netto dell'addizionale provinciale
              CP - Compensazioni relative all'addizionale provinciale
 ANNOTAZIONI:
 REVISIONI: .
 Rev.  Data        Autore    Descrizione.
 3     17/01/2021  VD        Aggiunto arrotondamento a 2 decimali.
 2     11/03/2021  VD        Nuova gestione TEFA: si scorpora dall'importo
                             la parte relativa alla TEFA
 1     03/10/2017  VD        Modifica per Pontedera: per gestire gli
                             sconti su conferimento inseriti negli sgravi
                             tutti i calcoli scartano gli sgravi con il
                             primo carattere delle note = '*'
 0     29/12/2015  VD        Prima emissione
*************************************************************************/
( a_ruolo                  number
, a_cod_fiscale            varchar2
, a_tipo_importo           varchar2
) return number
is
  w_importo                number;
  w_cod_istat              varchar2(6);
  w_anno_ruolo             number;
  w_perc_add_pro           number;
begin
  --
  -- (VD - 03/10/2017); si selezionano i dati generali per verificare se
  --                    stiamo trattando Pontedera
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
  -- (VD - 11/03/2021); nuova gestione TEFA. Si seleziona l'anno del ruolo
  --                    per verificare se attivare o meno la nuova gestione
  --                    della TEFA.
  --
  begin
    select anno_ruolo
      into w_anno_ruolo
      from ruoli
     where ruolo = a_ruolo;
  exception
    when others then
      w_anno_ruolo := 0;
  end;
  --
  if a_tipo_importo like 'C%' then
     if w_anno_ruolo < 2021 then
        select sum(compensazione)
          into w_importo
          from compensazioni_ruolo
         where cod_fiscale = a_cod_fiscale
           and ruolo = a_ruolo;
     else
        select decode(a_tipo_importo
                     ,'C',sum(compensazione)
                     ,'CN',sum(round(compensazione - ((compensazione * nvl(cata.addizionale_pro,0)) /
                                                (100 + nvl(cata.addizionale_pro,0))),2))
                     ,'CP',sum(round((compensazione * nvl(cata.addizionale_pro,0)) /
                                       (100 + nvl(cata.addizionale_pro,0)),2))
                     )
          into w_importo
          from compensazioni_ruolo c
             , carichi_tarsu cata
         where c.cod_fiscale = a_cod_fiscale
           and c.ruolo = a_ruolo
           and cata.anno = w_anno_ruolo;
     end if;
  else
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
        --
        -- (VD - 03/10/2017): se il cliente NON e' Pontedera si sommano tutti i
        --                    record, se e' Pontedera si scartano gli sgravi con
        --                    il valore * nel primo carattere delle note
        --
        and (w_cod_istat not in ('050029','037006') or
            (w_cod_istat in ('050029','037006') and nvl(substr(sgra.note,1,1),' ') <> '*'))
        and r.ruolo = a_ruolo
        and nvl(r.tipo_emissione, 'T') = 'S';
  end if;
--
  return nvl(w_importo,0);
end;
/* End Function: F_SGRAVIO_ANNO */
/

