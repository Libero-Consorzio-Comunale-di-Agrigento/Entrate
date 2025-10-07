--liquibase formatted sql 
--changeset abrandolini:20250326_152401_forniture_ae_g2 stripComments:false runOnChange:true 
 
create or replace force view forniture_ae_g2 as
select documento_id
     , progressivo
     , tipo_record
     , 'ACCREDITO DISPOSTO' des_tipo_record
     , data_fornitura
     , progr_fornitura
     , data_ripartizione
     , progr_ripartizione
     , data_bonifico
     , stato stato_mandato
     , decode(stato,'A','Accredito disposto'
                   ,'B','Accredito sospeso'
                   ,'C','Accredito riemesso'
                   ,''
             ) des_stato_mandato
     , cod_ente_beneficiario
     , cod_valuta
     , importo_accredito
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
     , data_mandato
     , progr_mandato
  from forniture_ae
 where tipo_record = 'G2';

