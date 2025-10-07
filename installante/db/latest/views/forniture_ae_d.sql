--liquibase formatted sql 
--changeset abrandolini:20250326_152401_forniture_ae_d stripComments:false runOnChange:true 
 
create or replace force view forniture_ae_d as
select documento_id
       ,progressivo
       ,tipo_record
       ,'VERSAMENTO' des_tipo_record
       ,data_fornitura
       ,progr_fornitura
       ,data_ripartizione
       ,progr_ripartizione
       ,data_bonifico
       ,progr_delega
       ,progr_riga
       ,cod_ente
       ,decode(cod_ente
              ,07601, 'Poste'
              ,99999, 'Internet'
              ,decode(greatest(cod_ente
                              ,999
                              )
                     ,999, 'Concessionario - Codice '
                     ,'Banca - ABI '
                     ) ||
               cod_ente
              )
         des_ente
       ,tipo_ente
       ,decode(tipo_ente
              ,'B', 'Delega riscossa tramite banca'
              ,'C', 'Delega riscossa tramite Agente della riscossione'
              ,'P', 'Delega riscossa tramite agenzia postale'
              ,'I', 'Delega riscossa tramite Internet'
              ,''
              )
         des_tipo_ente
       ,cab
       ,cod_fiscale
       ,flag_err_cod_fiscale
       ,data_riscossione
       ,cod_ente_comunale
       ,cod_tributo
       ,flag_err_cod_tributo
       ,rateazione
       ,anno_rif
       ,flag_err_anno
       ,cod_valuta
       ,importo_debito
       ,importo_credito
       ,ravvedimento
       ,immobili_variati
       ,acconto
       ,saldo
       ,num_fabbricati
       ,flag_err_dati
       ,detrazione
       ,cognome_denominazione
       ,cod_fiscale_orig
       ,nome
       ,sesso
       ,data_nas
       ,comune_stato
       ,provincia
       ,tipo_imposta
       ,decode(tipo_imposta
              ,'I', 'ICI/IMU'
              ,'O', 'TOSAP/COSAP'
              ,'T', 'TARSU/TARIFFA'
              ,'S', 'TASSA DI SCOPO'
              ,'R', 'Contributo/Imposta di soggiorno'
              ,'A', 'TARES/TARI'
              ,'U', 'TASI'
              ,'M', 'IMIS'
              ,''
              )
         des_tipo_imposta
       ,cod_fiscale_2
       ,cod_identificativo_2
       ,id_operazione
       ,importo_netto
       ,importo_ifel
     ,importo_lordo
   from forniture_ae
  where tipo_record = 'D';
comment on table FORNITURE_AE_D is 'FAED - Forniture AE D';

