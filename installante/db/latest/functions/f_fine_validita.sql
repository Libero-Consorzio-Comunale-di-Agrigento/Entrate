--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_fine_validita stripComments:false runOnChange:true 
 
create or replace function F_FINE_VALIDITA
(a_ogpr_rif          number
,a_cod_fiscale       varchar2
,a_data_decorrenza   date
,a_tipo_pratica      varchar2
) return date
is
w_return date;
begin
   select min(nvl(ogco.data_decorrenza - 1,ogco.data_cessazione))
     into w_return
     from pratiche_tributo       prtr
         ,oggetti_pratica        ogpr
         ,oggetti_contribuente   ogco
    where prtr.tipo_pratica      like a_tipo_pratica
      and prtr.pratica              = ogpr.pratica
      and ogco.oggetto_pratica      = ogpr.oggetto_pratica
      and ogco.cod_fiscale          = a_cod_fiscale
      and (nvl(ogco.data_decorrenza,decode(to_char(ogco.data_cessazione,'yyyy'),
                                           9999,ogco.data_cessazione,
                                                ogco.data_cessazione + 1))
                                    >
          nvl(a_data_decorrenza,to_date('01011950','ddmmyyyy'))
        )
      and nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
                                    = a_ogpr_rif
      and decode(prtr.tipo_pratica,'A',prtr.flag_denuncia,'S')
                                    = 'S'
      and decode(prtr.tipo_pratica
                ,'A',decode(prtr.flag_adesione
                           ,'S',to_date('01011950','ddmmyyyy')
                           ,nvl(prtr.data_notifica,to_date('31122999','ddmmyyyy')) + 60
                           )
                ,to_date('01011950','ddmmyyyy')
                )         < sysdate
      and nvl(prtr.stato_accertamento,'D')
                                    = 'D'
      and prtr.tipo_pratica        in ('D','A')
      and nvl(ogpr.tipo_occupazione,'P')
                                    = 'P'
   and prtr.flag_annullamento is null
   ;
   return w_return;
exception
   when no_data_found then
      return to_date(NULL);
   when others then
      raise_application_error(-20999,a_ogpr_rif||'/'||a_cod_fiscale||'/'||to_char(a_data_decorrenza,'dd/mm/yyyy')||' - '||sqlerrm);
end;
/* End Function: F_FINE_VALIDITA */
/

