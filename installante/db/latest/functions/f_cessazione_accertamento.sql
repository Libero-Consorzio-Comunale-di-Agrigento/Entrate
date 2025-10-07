--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_cessazione_accertamento stripComments:false runOnChange:true 
 
create or replace function F_CESSAZIONE_ACCERTAMENTO
(a_cod_fiscale      varchar2
,a_oggetto          number
,a_data_decorrenza  date
,a_tipo_tributo     varchar2
) return date
IS
w_cessazione   date;
BEGIN
   select min(data_decorrenza) - 1
     into w_cessazione
     from pratiche_tributo     prtr
         ,oggetti_pratica      ogpr
         ,oggetti_contribuente ogco
    where prtr.pratica            = ogpr.pratica
      and ogpr.oggetto_pratica    = ogco.oggetto_pratica
      and prtr.tipo_tributo||''   = a_tipo_tributo
      and ogpr.oggetto            = a_oggetto
      and ogco.cod_fiscale        = a_cod_fiscale
      and ogco.data_decorrenza    >
          nvl(a_data_decorrenza,to_date('01011900','ddmmyyyy'))
      and decode(prtr.tipo_pratica,'A',prtr.flag_denuncia,'S')
                                  = 'S'
      and prtr.tipo_pratica      in ('D','A')
      and nvl(ogpr.tipo_occupazione,'P')
                                  = 'P'
      and nvl(prtr.stato_accertamento,'D')
                                  = 'D'
      and prtr.flag_annullamento is null
   ;
   RETURN w_cessazione;
EXCEPTION
   WHEN others THEN
      RETURN NULL;
END;
/* End Function: F_CESSAZIONE_ACCERTAMENTO */
/

