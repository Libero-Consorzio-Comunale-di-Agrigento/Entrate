--liquibase formatted sql 
--changeset abrandolini:20250326_152423_carica_ver_sigai stripComments:false runOnChange:true 
 
create or replace procedure CARICA_VER_SIGAI
(a_conv    IN    varchar2)
IS
w_conta_anci         number;
cursor sel_ver is
   select 0 concessione,
      null ente,
      0 progr_quietanza,
      rownum progr_record,
      3 tipo_record,
      decode(DATA_VERSAME,'0000-00-00',to_date(null),
        to_date(DATA_VERSAME,'yyyy-mm-dd')) data_versamento,
      FISCALE, ANNO_FISCALE_IMM,
      0 quietanza,
       TOTALE_IMP,
      IMP_TERR_AGR, AREE_FABBRICA, ABIT_PRINCIP, ALTRI_FABBRIC,
       IMP_DET_AB_PR,
      null flag_quadratura,
      null flag_squadratura,
      null detrazione_effettiva,
      null imposta_calcolata,
      decode(flag_acconto,'1','1',
       decode(flag_saldo,'1','2','3')) tipo_versamento,
      to_char(trunc(sysdate),'j') data_reg,
      null flag_competenza,
       COMUNE_IMMOB,
      null cod_catasto,
       CAP_IMMOBILE,
       NUM_FABBRICATI,
       decode(FLAG_ACCONTO,'1','1',
       decode(FLAG_SALDO,'1','2')) acconto_saldo,
      null flag_ex_rurali,
      null flag_zero,
      null flag_identificazione,
      null tipo_anomalia
     from sigai_versamenti
   ;
begin
  for rec_ver in sel_ver loop
   begin
    insert into anci_ver
       (CONCESSIONE, ENTE, PROGR_QUIETANZA, PROGR_RECORD,
         TIPO_RECORD , DATA_VERSAMENTO, COD_FISCALE, ANNO_FISCALE,
        QUIETANZA, IMPORTO_VERSATO, TERRENI_AGRICOLI,
        AREE_FABBRICABILI, AB_PRINCIPALE, ALTRI_FABBRICATI,
         DETRAZIONE, FLAG_QUADRATURA, FLAG_SQUADRATURA,
        DETRAZIONE_EFFETTIVA, IMPOSTA_CALCOLATA, TIPO_VERSAMENTO,
        DATA_REG, FLAG_COMPETENZA_VER, COMUNE, COD_CATASTO,
        CAP, FABBRICATI, ACCONTO_SALDO, FLAG_EX_RURALI,
        FLAG_ZERO, FLAG_IDENTIFICAZIONE, TIPO_ANOMALIA)
    values(rec_ver.concessione,
       rec_ver.ente,
       rec_ver.progr_quietanza,
       rec_ver.progr_record,
       rec_ver.tipo_record,
       rec_ver.data_versamento,
       rec_ver.FISCALE,
       rec_ver.ANNO_FISCALE_IMM,
       rec_ver.quietanza,
        rec_ver.TOTALE_IMP,
       rec_ver.IMP_TERR_AGR,
       rec_ver.AREE_FABBRICA,
       rec_ver.ABIT_PRINCIP,
       rec_ver.ALTRI_FABBRIC,
        rec_ver.IMP_DET_AB_PR,
       rec_ver.flag_quadratura,
       rec_ver.flag_squadratura,
       rec_ver.detrazione_effettiva,
       rec_ver.imposta_calcolata,
       rec_ver.tipo_versamento,
       rec_ver.data_reg,
       rec_ver.flag_competenza,
        rec_ver.COMUNE_IMMOB,
       rec_ver.cod_catasto,
        rec_ver.CAP_IMMOBILE,
        rec_ver.NUM_FABBRICATI,
        rec_ver.acconto_saldo,
       rec_ver.flag_ex_rurali,
       rec_ver.flag_zero,
       rec_ver.flag_identificazione,
       rec_ver.tipo_anomalia)
    ;
   exception
    when others then
         raise_application_error
        (-20999,'Errore in inserimento ANCI_VER ('||SQLERRM||')');
   end;
  end loop;
  BEGIN
    select count(*)
      into w_conta_anci
      from anci_ver
    ;
  EXCEPTION
    WHEN others THEN
      RAISE_APPLICATION_ERROR
        (-20999,'Errore in ricerca ANCI_VER '||
                         '('||SQLERRM||')');
  END;
  IF w_conta_anci > 0 THEN
     CARICA_VERSAMENTI_ICI(a_conv);
  END IF;
exception
  when others then
    raise_application_error
      (-20999,'Errore finale ('||SQLERRM||')');
END;
/* End Procedure: CARICA_VER_SIGAI */
/

