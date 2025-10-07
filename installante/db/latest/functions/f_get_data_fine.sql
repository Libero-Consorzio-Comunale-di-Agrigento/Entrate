--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_get_data_fine stripComments:false runOnChange:true 
 
create or replace function F_GET_DATA_FINE
/*************************************************************************
 NOME:        F_GET_DATA_FINE
 DESCRIZIONE: Date le informazioni di un oggetto_pratica, restituisce
              la data fine occupazione o concessione dell'eventuale
              pratica di cessazione
 RITORNA:     date                     data fine
 *************************************************************************/
(a_ogpr_rif          number
,a_cod_fiscale       varchar2
,a_data_decorrenza   date
,a_tipo_pratica      varchar2
,a_tipo_data         varchar2
) return date
is
w_return date;
begin
   select min(decode(a_tipo_data,
                     'O',nvl(ogco.inizio_occupazione - 1,ogco.fine_occupazione),
                         nvl(ogpr.inizio_concessione - 1,ogpr.fine_concessione)))
     into w_return
     from pratiche_tributo       prtr
         ,oggetti_pratica        ogpr
         ,oggetti_contribuente   ogco
    where prtr.tipo_pratica      like a_tipo_pratica
      and prtr.pratica              = ogpr.pratica
      and ogco.oggetto_pratica      = ogpr.oggetto_pratica
      and ogco.cod_fiscale          = a_cod_fiscale
      and (nvl(ogco.inizio_occupazione,ogco.fine_occupazione + 1)
                                    >
          nvl(a_data_decorrenza,to_date('01011900','ddmmyyyy'))
        )
      and nvl(ogpr.oggetto_pratica_rif,ogpr.oggetto_pratica)
                                    = a_ogpr_rif
      and decode(prtr.tipo_pratica,'A',prtr.flag_denuncia,'S')
                                    = 'S'
      and decode(prtr.tipo_pratica
                ,'A',decode(prtr.flag_adesione
                           ,'S',to_date('01011900','ddmmyyyy')
                           ,nvl(prtr.data_notifica,to_date('31122999','ddmmyyyy')) + 60
                           )
                ,to_date('01011900','ddmmyyyy')
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
      return NULL;
end;
/* End Function: F_GET_DATA_FINE */
/

