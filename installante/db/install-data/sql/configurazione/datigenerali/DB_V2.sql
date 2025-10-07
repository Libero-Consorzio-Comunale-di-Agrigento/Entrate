--liquibase formatted sql
--changeset dmarotta:20250326_152438_DB_V2 stripComments:false context:"TRV2" failOnError:false
--validCheckSum: 1:any

begin
  update dati_generali
     set flag_integrazione_gsd 	= 'S',
	   flag_integrazione_trb 	= 'S'
  ;
  if SQL%notfound then
     begin
	 insert into dati_generali 
	        (chiave, pro_cliente, com_cliente, flag_integrazione_gsd,
               flag_integrazione_trb, fase_euro, cambio_euro, flag_provincia)
	 values(1,${codiceProvincia},${codiceComune},'S','S',2,1936.27,
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
