--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_importi_acc_totale_tarsu stripComments:false runOnChange:true 
 
create or replace function F_IMPORTI_ACC_TOTALE_TARSU
( p_pratica                       number
, p_tipo                          varchar2
)
  return number
is
/*************************************************************************
 NOME:        F_IMPORTI_ACC_TOTALE_TARSU
 DESCRIZIONE: Determina i totali dei vari importi di una pratica di
              accertamento totale.
              Utilizzata in situazione accertamenti TARSU in PB
 PARAMETRI:   Pratica             Numero pratica di accertamento totale
              Tipo                Identifica il tipo di importo che si
                                  vuole ottenere dalla funzione
                                  DOVUTO      imposta dovuta comprensiva
                                              di addizionali
 RITORNA:     number              Importo della tipologia prescelta
 NOTE:
 Rev.    Date         Author      Note
 000     05/03/2019   VD          Prima emissione.
*************************************************************************/
  w_importo_tot                   number(15,2);
--
begin
  if p_tipo = 'DOVUTO' then
     select sum(nvl(prtr.imposta_totale,0)
                + round(nvl(prtr.imposta_totale,0) * nvl(cata.addizionale_pro,0) / 100,2)
                + round(nvl(prtr.imposta_totale,0) *  nvl(cata.addizionale_eca,0) / 100,2)
                + round(nvl(prtr.imposta_totale,0) *  nvl(cata.maggiorazione_eca,0) / 100,2)
                + round(nvl(prtr.imposta_totale,0) *  nvl(cata.aliquota,0) / 100,2)
                + round(nvl(prtr.imposta_totale,0) *  nvl(cata.maggiorazione_tares,0) / 100,2))
       into w_importo_tot
       from pratiche_tributo prtr
          , carichi_tarsu cata
      where prtr.pratica_rif = p_pratica
        and prtr.anno = cata.anno (+);
  end if;
--
  return w_importo_tot;
--
end;
/* End Function: F_IMPORTI_ACC_TOTALE_TARSU */
/

