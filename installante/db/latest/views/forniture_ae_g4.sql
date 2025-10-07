--liquibase formatted sql 
--changeset abrandolini:20250326_152401_forniture_ae_g4 stripComments:false runOnChange:true 
 
create or replace force view forniture_ae_g4 as
select documento_id
     , progressivo
     , tipo_record
     , 'ANTICIPO FONDI DI BILANCIO' des_tipo_record
     , data_fornitura
     , progr_fornitura
     , data_ripartizione
     , progr_ripartizione
     , data_bonifico
     , cod_ente_comunale
     , cod_valuta
     , importo_anticipazione
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
  from forniture_ae
 where tipo_record = 'G4';

