--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_data_variazione stripComments:false runOnChange:true 
 
CREATE OR REPLACE function     F_DATA_VARIAZIONE 
(a_cod_fiscale          varchar2,
 a_oggetto_pratica      number,
 a_oggetto_pratica_rif  number,
 a_al                   date default null
 )
return date
is
w_data_variazione date;

Begin
   if a_al is null then
       select ogco.data_variazione
         into w_data_variazione
         from oggetti_contribuente ogco
            , oggetti_validita ogva
        where ogva.tipo_tributo     = 'TARSU'
          and ogva.cod_fiscale      = ogco.cod_fiscale
          and ogva.oggetto_pratica  = ogco.oggetto_pratica 
          and ogva.cod_fiscale      = a_cod_fiscale
          and ogva.oggetto_pratica  = a_oggetto_pratica
          and ogva.al is null
        ;
   else
       select ogco.data_variazione
         into w_data_variazione
         from oggetti_pratica ogpr
            , pratiche_tributo prtr
            , oggetti_contribuente ogco
            , oggetti_validita ogva
        where ogva.tipo_tributo         = 'TARSU'
          and prtr.tipo_evento          = 'C'
          and prtr.pratica              = ogpr.pratica
          and ogpr.oggetto_pratica      = ogco.oggetto_pratica 
          and ogpr.oggetto_pratica_rif  = a_oggetto_pratica_rif
          and ogva.cod_fiscale          = a_cod_fiscale
          and ogva.oggetto_pratica      = a_oggetto_pratica
          and ogva.al is not null
        ;
   end if;
   
   return w_data_variazione;
      
end;
/* End Function: F_DATA_VARIAZIONE */
/
