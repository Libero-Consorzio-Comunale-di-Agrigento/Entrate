--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_conta_altri_contribuenti stripComments:false runOnChange:true 
 
create or replace function F_CONTA_ALTRI_CONTRIBUENTI
/*************************************************************************
 NOME:        F_CONTA_ALTRI_CONTRIBUENTI
 DESCRIZIONE: Per vista OGGETTI_CONTRIBUENTE_ANNO.
              Conta i contribuenti, diversi dal contribuente passato come
              parametro, sull'oggetto per il tipo tributo e l'anno indicati.
              Se il contatore e' maggiore di zero restituisce 'S'.
 RITORNA:     varchar2              'S' se esiste almeno un record,
                                    altrimenti null
 NOTE:
 Rev.    Date         Author      Note
 000     05/05/2021   VD          Prima emissione.
*************************************************************************/
( p_cod_fiscale               varchar2
, p_tipo_tributo              varchar2
, p_anno                      number
, p_oggetto                   number
) return varchar2
is
  w_conta                     number;
begin
  -- Se il tipo_tributo richiedto è TARSU, si utilizza la vista
  -- PERIODI_OGCO_TARSU; per gli altri tributi si utilizza la vista
  -- PERIODI_OGCO.
  if p_tipo_tributo = 'TARSU' then
     select count(1)
       into w_conta
       from periodi_ogco_tarsu
      where oggetto = p_oggetto
        and nvl(data_decorrenza,to_date('01011900','ddmmyyyy')) <=
            to_date('3112'||p_anno,'ddmmyyyy')
        and nvl(data_cessazione,to_date('3112'||p_anno,'ddmmyyyy')) >=
            to_date('0101'||p_anno,'ddmmyyyy')
        and cod_fiscale <> p_cod_fiscale;
  else
     select count(1)
       into w_conta
       from periodi_ogco
      where tipo_tributo = p_tipo_tributo
        and oggetto = p_oggetto
        and nvl(inizio_validita,to_date('01011900','ddmmyyyy')) <=
            to_date('3112'||p_anno,'ddmmyyyy')
        and nvl(fine_validita,to_date('3112'||p_anno,'ddmmyyyy')) >=
            to_date('0101'||p_anno,'ddmmyyyy')
        and cod_fiscale <> p_cod_fiscale;
  end if;
  --
  if w_conta > 0 then
     return 'S';
  else
     return null;
  end if;
end;
/* End Function: F_CONTA_ALTRI_CONTRIBUENTI */
/

