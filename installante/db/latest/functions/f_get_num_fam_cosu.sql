--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_num_fam_cosu stripComments:false runOnChange:true 
 
create or replace function F_GET_NUM_FAM_COSU
/*************************************************************************
 NOME:        F_GET_NUM_FAM_COSU
 DESCRIZIONE: Ritorna il numero di familiari per l'oggetto pratica.
              Usata in d_ruoli_dettaglio (PB) per problemi di outer join
 RITORNA:     number              Numero di mesi di possesso
 NOTE:
 Rev.    Date         Author      Note
   002   29/05/2023   VM          #64021 Ritorna null solo se flag_domestica su categoria = null
                                  Negli altri casi se numero_familiari da ritornare è null, ritorna 0    
   001     04/07/2019   VD          Aggiunto parametro oggetto_imposta:
                                    se presente, per determinare il numero di
                familiari si utilizza la funzione
                f_ultimo_faog al 31/12 dell'anno,
                altrimenti si utilizza la funzione
                f_ultimo_faso (come prima).
 000     10/01/2014               Prima emissione.
*************************************************************************/
(p_oggetto_pratica      in number,
 p_flag_ab_principale   in varchar2,
 p_anno                 in number,
 p_oggetto_imposta      in number default null
)
  return number
is
  w_num_familiari   number;
  w_flag_cate_domestica varchar2(1);
begin
  select cate.flag_domestica
    into w_flag_cate_domestica
    from oggetti_pratica ogpr, categorie cate
   where cate.categoria = ogpr.categoria
     and cate.tributo = ogpr.tributo
     and ogpr.oggetto_pratica = p_oggetto_pratica;
  if (w_flag_cate_domestica is null) then
    return null;
  end if;
  begin
    select decode(p_flag_ab_principale,
                  null, nvl(ogpr.numero_familiari, nvl(cosu.numero_familiari, 0)),
                        decode(p_oggetto_imposta,
                               null,F_ultimo_faso(cont.ni,p_anno),
                                    f_ultimo_faog(p_oggetto_imposta,
                                                  to_date('31/12/' || p_anno, 'dd/mm/yyyy')
                                                                                                                                                   )
                                                                                          )
                                                   )
    into   w_num_familiari
    from   oggetti_pratica       ogpr,
           pratiche_tributo      prtr,
           contribuenti          cont,
           componenti_superficie cosu
    where  ogpr.oggetto_pratica = p_oggetto_pratica
    and    ogpr.pratica = prtr.pratica
    and    prtr.cod_fiscale = cont.cod_fiscale
    and    cosu.anno(+) = decode(p_anno, 9999, to_number(to_char(sysdate, 'yyyy')), p_anno)
    and    ogpr.consistenza between cosu.da_consistenza(+)
                                and cosu.a_consistenza(+);
  exception
    when others
    then
      w_num_familiari := 0;
  end;
  return w_num_familiari;
end;
/* End Function: F_GET_NUM_FAM_COSU */
/

