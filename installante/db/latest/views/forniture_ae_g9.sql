--liquibase formatted sql 
--changeset abrandolini:20250326_152401_forniture_ae_g9 stripComments:false runOnChange:true 
 
create or replace force view forniture_ae_g9 as
select documento_id
     , progressivo
     , tipo_record
     , 'ANNULLAMENTO DELEGA' des_tipo_record
     , data_fornitura
     , progr_fornitura
     , data_ripartizione_orig
     , progr_ripartizione_orig
     , data_bonifico_orig
     , cod_ente
     , decode(cod_ente,07601,'Poste'
                      ,99999,'Internet'
                      ,decode(greatest(cod_ente,999)
                             ,999,'Concessionario - Codice '
                             ,'Banca - ABI ')||cod_ente
             ) des_ente
     , cod_fiscale
     , data_riscossione
     , cod_ente_comunale
     , cod_tributo
     , anno_rif
     , cod_valuta
     , importo_debito
     , importo_credito
     , tipo_operazione
     , decode(tipo_operazione,'A','ANNULLAMENTO'
                             ,'R','RIPRISTIMO'
                             ,''
             ) des_tipo_operazione
     , data_operazione
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
 where tipo_record = 'G9';

