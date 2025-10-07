--liquibase formatted sql 
--changeset abrandolini:20250326_152401_forniture_ae_m stripComments:false runOnChange:true 
 
create or replace force view forniture_ae_m as
select documento_id
     , progressivo
     , tipo_record
     , 'MANDATI TEFA' des_tipo_record
     , data_fornitura
     , progr_fornitura
     , data_ripartizione
     , progr_ripartizione
     , data_bonifico
     , tipo_imposta
     , decode(tipo_imposta,'I','ICI/IMU'
                          ,'O','TOSAP/COSAP'
                          ,'T','TARSU/TARIFFA'
                          ,'S','TASSA DI SCOPO'
                          ,'R','Contributo/Imposta di soggiorno'
                          ,'A','TARES/TARI'
                          ,'U','TASI'
                          ,'M','IMIS'
                          ,'TEF','TEFA'
                          ,''
             ) des_tipo_imposta
     , cod_provincia
     , adpr.denominazione as den_provincia
     , numero_conto_tu
     , cod_valuta
     , importo_accredito
     , data_mandato
     , cod_movimento
  from
     forniture_ae foae,
     ad4_province adpr
 where
     foae.tipo_record = 'M'
 and foae.cod_provincia = adpr.provincia(+);

