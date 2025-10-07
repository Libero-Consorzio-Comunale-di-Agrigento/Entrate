--liquibase formatted sql 
--changeset abrandolini:20250326_152401_forniture_ae_g5 stripComments:false runOnChange:true 
 
create or replace force view forniture_ae_g5 as
select documento_id
     , progressivo
     , tipo_record
     , 'IDENTIFICAZIONE ACCREDITO' des_tipo_record
     , data_fornitura
     , progr_fornitura
     , stato stato_mandat
     , decode(stato,'A','Mandato finalizzato'
                   ,'B','Mandato scartato'
                   ,'C','Mandato stornato'
                   ,'D','Mandato riemesso'
                   ,''
             ) des_stato_mandato     
     , cod_ente_comunale
     , cod_valuta
     , importo_accredito
     , cro
     , data_accreditamento
     , data_ripartizione_orig
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
     , iban
     , sezione_conto_tu
     , numero_conto_tu
     , cod_movimento
     , des_movimento
     , data_storno_scarto
     , data_elaborazione_nuova
     , progr_elaborazione_nuova
  from forniture_ae
 where tipo_record = 'G5';

