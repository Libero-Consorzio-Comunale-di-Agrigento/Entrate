--liquibase formatted sql 
--changeset rvattolo:20250717_124728_f_cope_dettagli stripComments:false runOnChange:true 

create or replace function f_cope_dettagli
/*******************************************************************************
 Estrae dettagli Componenti Perequative
 
 Rev.    Date         Author      Note
 000     17/07/2025   RV          Versione iniziale
*******************************************************************************/
( p_anno                    number
, p_totale                  number
, p_formato                 varchar2 default null
)
return varchar2
is
  w_quota                   number;
  w_importo                 number;
  w_totale                  number;
  w_residuo                 number;
  --
  w_componente              varchar2(200);
  w_componenti              varchar2(2000);
begin
  w_componenti := '';
  ---
  w_residuo := nvl(p_totale,0);
  if w_residuo = 0 then
    return w_componenti;
  end if;
  --
  for rec_cp in (select
                  anno, componente, descrizione, importo, sum(importo) over() as totale, rownum, count(importo) over() as rowcount
                from
                  componenti_perequative
                where anno = p_anno)
  loop
    w_totale := greatest(nvl(rec_cp.totale,0),0.01);
    w_importo := nvl(rec_cp.importo,0);
    --
    w_quota := round((w_importo * (p_totale / w_totale)),2);
    --
    if rec_cp.rownum = rec_cp.rowcount then
      w_importo := w_residuo;
    else
      w_residuo := w_residuo - w_quota;
      w_importo := w_quota;
    end if;
    --
    w_componente := rec_cp.componente || ' - ' || rec_cp.descrizione|| ' ';
    w_componente := w_componente || '€ ' || stampa_common.f_formatta_numero(w_importo,'I','S');
    --
    if length(w_componenti) > 0 then
      if p_formato is null then
          w_componenti := w_componenti || CHR(13) || CHR(10);
      else
          w_componenti := w_componenti || '; ';
      end if;
    end if;
    --
    w_componenti := w_componenti || w_componente;
  end loop;
  ---
  return trim(w_componenti);
end;
/
