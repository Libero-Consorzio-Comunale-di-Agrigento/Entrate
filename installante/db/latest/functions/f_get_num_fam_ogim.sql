--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_num_fam_ogim stripComments:false runOnChange:true 
 
CREATE OR REPLACE function         F_GET_NUM_FAM_OGIM
/*************************************************************************
 NOME:        F_GET_NUM_FAM_OGIM
 DESCRIZIONE: Ritorna il numero di familiari per l'oggetto impopsta.
 RITORNA:     number              Numero di familiari
 NOTE:
 Rev.    Date         Author      Note
 002     26/06/2023     AB        #63043 Ritorna i familiari di ogpr se maggiore di 
                                  quelli di faog, nel caso di ab_principale null
 000     26/06/2023     AB        Prima emissione.
*************************************************************************/
(p_oggetto_imposta      IN number,
 p_dal                  IN date
)
  return number
is
  w_num_familiari   number;
begin
  begin
    select decode(ogco.flag_ab_principale,
                  null, nvl(ogpr.numero_familiari, nvl(faog.numero_familiari, 0)),
                        nvl(faog.numero_familiari, 0)) numero_familiari
      into w_num_familiari
      from oggetti_contribuente  ogco,
           oggetti_pratica       ogpr,
           oggetti_imposta       ogim,
           familiari_ogim        faog
     where ogpr.oggetto_pratica = ogim.oggetto_pratica
       and ogco.oggetto_pratica = ogpr.oggetto_pratica
       and ogco.cod_fiscale     = ogim.cod_fiscale
       and faog.oggetto_imposta (+) = ogim.oggetto_imposta
       and faog.dal (+)         = p_dal
       and ogim.oggetto_imposta = p_oggetto_imposta
     ;
  exception
    when others
    then
      w_num_familiari := 0;
  end;
  return w_num_familiari;
end;
/* End Function: F_GET_NUM_FAM_OGIM */
/
