--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_esiste_oggetto_in_prat stripComments:false runOnChange:true 
 
create or replace function F_ESISTE_OGGETTO_IN_PRAT
( p_oggetto                 in number
, p_pratica                 in number
, p_tipo_tributo            in varchar2
) return varchar2
is
/*************************************************************************
 NOME:        F_ESISTE_OGGETTO_IN_PRAT
 DESCRIZIONE: Dati una pratica, un oggetto e il tipo tributo, controlla
              se l oggetto è già presente nella pratica indicata
 RITORNA:     varchar2            'S' - oggetto presente
                                  'N' - oggetto non presente
 NOTE:        La funzione tratta solo il tipo tributo ICP (per ora).
              Per gli altri tipi tributo restituisce sempre 'N'.
              Utilizzata in fase di cessazione di tutti gli oggetti di
              un contribuente oppure in fase di copia oggetti da
              contribuente cessato
 Rev.    Date         Author      Note
 001     20/03/2015   VD          Prima emissione.
 002     29/05/2015   VD          Eliminato controllo su tipo_tributo ICP:
                                  ora tratta tutti i tipi tributo.
                                  Non e' previsto che il parametro sia
                                  nullo.
*************************************************************************/
 d_result                         varchar2(1);
 w_tipo_tributo                   varchar2(5);
BEGIN
--  if p_tipo_tributo is null then
--     begin
--       select tipo_tributo
--         into w_tipo_tributo
--         from pratiche_tributo
--        where pratica = p_pratica;
--     exception
--       when others then
--         w_tipo_tributo := 'X';
--         d_result := 'N';
--     end;
--  end if;
--
  begin
    select 'S'
      into d_result
      from dual
     where exists (select 'x' from oggetti_pratica
                    where pratica = p_pratica
                      and oggetto = p_oggetto);
  exception
    when others then
      d_result := 'N';
  end;
--
  return d_result;
END;
/* End Function: F_ESISTE_OGGETTO_IN_PRAT */
/

