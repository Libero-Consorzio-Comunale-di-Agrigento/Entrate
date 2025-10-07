--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_esiste_versamento_pratica stripComments:false runOnChange:true 
 
create or replace function F_ESISTE_VERSAMENTO_PRATICA
/*************************************************************************
 NOME:        F_ESISTE_VERSAMENTO_PRATICA
 DESCRIZIONE: Restituisce il numero di versamenti sulla base dell'anno e
              del tipo tributo della pratica di riferimento
 PARAMETRI: p_cod_fiscale         Codice fiscale
            p_anno                Anno
            p_tipo_tributo        Tipo tributo
 RITORNA:   number                Numero di versamenti
 NOTE:
 Rev.    Date         Author      Note
 000     25/10/2022   AL          Prima emissione.
*************************************************************************/
( p_cod_fiscale          varchar2
, p_anno                 number
, p_tipo_tributo         varchar2
) return number
as
  w_versamenti           number;
begin
    IF  p_anno         IS NOT NULL
    AND p_tipo_tributo IS NOT NULL
    AND p_cod_fiscale  IS NOT NULL THEN
-- Lascio la prima versione di Lettoli, non corretta per vedere come invece occorreva impostarla usando
-- corretamente gli indici, ma soprattuto i versamenti potrebbero essere anche di un anno
-- diverso dall'anno della prtatica ed essere cmq legato alla pratica  AB (11/01/2023)
--         SELECT COUNT(*)
--           INTO w_versamenti
--           FROM versamenti vers
--          WHERE vers.pratica in (SELECT prtr.pratica
--                                   FROM pratiche_tributo prtr
--                                  WHERE prtr.tipo_pratica in ('A', 'L')
--                        AND prtr.tipo_tributo = vers.tipo_tributo
--                        AND prtr.anno = vers.anno)
--            AND vers.tipo_tributo = p_tipo_tributo
--            AND vers.anno = p_anno
--            AND vers.cod_fiscale = p_cod_fiscale;
    SELECT COUNT(*)
          INTO w_versamenti
          FROM versamenti vers
         WHERE exists (SELECT 1
                         FROM pratiche_tributo prtr
                        WHERE prtr.tipo_pratica in ('A', 'L')
                          AND prtr.pratica = vers.pratica)
           AND vers.tipo_tributo||'' = p_tipo_tributo
           AND vers.anno = p_anno
           AND vers.pratica is not null
           AND vers.cod_fiscale = p_cod_fiscale;
       RETURN w_versamenti;
    ELSE
        RETURN NULL;
    END IF;
end;
/* End Function: F_ESISTE_VERSAMENTO_PRATICA */
/

