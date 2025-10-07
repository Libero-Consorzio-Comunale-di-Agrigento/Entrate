--liquibase formatted sql
--changeset dmarotta:20250326_152438_DB_v4 stripComments:false context:"TRV4" failOnError:false
--validCheckSum: 1:any

begin
  if '${province}' = 'S' then
    update dati_generali
       set flag_provincia = 'S'
    ;
  end if;
  update dati_generali
     set flag_integrazione_gsd 	= null,
	   flag_integrazione_trb 	= null
  ;
  if SQL%notfound then
     begin
	 insert into dati_generali
	        (chiave, pro_cliente, com_cliente, flag_integrazione_gsd,
               flag_integrazione_trb, fase_euro, cambio_euro, flag_provincia)
	 values(1,${codiceProvincia},${codiceComune},'','',2,1936.27,
	        case when '${province}' = 'S' then 'S' else '' end)
	 ;
     exception
	 when others then
		raise_application_error(-20999,'Errore in inserimento Dati Generali'||
							 ' ('||SQLERRM||')');
     end;
  end if;
exception
    when others then
  	 raise_application_error(-20999,'Errore in aggiornamento Dati Generali'||
						  ' ('||SQLERRM||')');
end;
/
