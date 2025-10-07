--liquibase formatted sql 
--changeset abrandolini:20250326_152401_forniture_ae_g3 stripComments:false runOnChange:true 
 
create or replace force view forniture_ae_g3 as
select documento_id
     , progressivo
     , tipo_record
     , 'RECUPERO SALDI NEGATIVI' des_tipo_record
     , data_fornitura
     , progr_fornitura
     , data_ripartizione
     , progr_ripartizione
     , data_bonifico
     , cod_ente_comunale
     , cod_valuta
     , importo_recupero
     , periodo_ripartizione_orig
     , progr_ripartizione_orig
     , data_bonifico_orig
     , tipo_imposta
     , decode(tipo_imposta,'I','ICI/IMU'
                          ,'O','TOSAP/COSAP'
                          ,'T','TARSU/TARIFFA'
                          ,'S','TASSA DI SCOPO'
                          ,'R','Contributo/Imposta di soggiorno'
                          ,'A','TARES/TARI'
                          ,'U','TASI'
                          ,'M','IMIS'
                          ,''
             ) des_tipo_imposta     
     , tipo_recupero
     , des_recupero
  from forniture_ae
 where tipo_record = 'G3';

