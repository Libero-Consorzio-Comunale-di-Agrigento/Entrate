--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_controllo_calcolo_imposta stripComments:false runOnChange:true 
 
create or replace function F_CONTROLLO_CALCOLO_IMPOSTA
( a_tipo_tributo           varchar2
, a_anno                   number
, a_pratica                number
) return number
is
  w_chk_rate               number;
begin
  if a_pratica is null then
     select max(nvl(rata,0))
       into w_chk_rate
       from versamenti vers
      where vers.tipo_tributo = a_tipo_tributo
        and vers.anno = a_anno;
  else
     select max(nvl(rata,0))
       into w_chk_rate
       from versamenti vers,
            pratiche_tributo prtr
      where vers.tipo_tributo = a_tipo_tributo
        and vers.anno = a_anno
        and prtr.pratica = a_pratica
        and prtr.cod_fiscale = vers.cod_fiscale;
  end if;
--
-- Se il risultato della query e' nullo, significa che non ci sono ancora
-- versamenti, quindi la scelta della rateizzazione è libera.
-- Se il risultato e' 0, significa che il calcolo imposta precedente e' stato
-- effettuato senza rateizzazione
-- Se il risultato è > 0, significa che il calcolo imposta precedente e' stato
-- effettuato con rateizzazione; in questo caso, se la pratica non e' nulla,
-- la rateizzazione e' per utenza, altrimenti e' per contribuente
--
  if nvl(w_chk_rate,0) > 0 then
     if a_pratica is null then
        w_chk_rate := 1;
     else
        w_chk_rate := 2;
     end if;
  end if;
--
  return w_chk_rate;
--
end;
/* End Function: F_CONTROLLO_CALCOLO_IMPOSTA */
/

