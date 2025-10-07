--liquibase formatted sql 
--changeset abrandolini:20250326_152423_crea_ravvedimento stripComments:false runOnChange:true 
 
create or replace procedure CREA_RAVVEDIMENTO
/***************************************************************************
  NOME:        CREA_RAVVEDIMENTO
  DESCRIZIONE: Crea una pratica di ravvedimento.
               A seconda del tipo tributo lancia procedure diverse:
               - per ICI/IMU e TASI: CREA_RAVVEDIMENTO_ICI_TASI
               - per CUNI: CREA_RAVVEDIMENTO_ALTRI_TRIBUTI
  ANNOTAZIONI: Utilizzata da TributiWeb in fase di creazione ravvedimento da
               applicativo
  REVISIONI:
  Rev.  Data        Autore  Note
  ----  ----------  ------  ----------------------------------------------------
  000   23/02/2022  --      Prima emissione
***************************************************************************/
(a_cod_fiscale      IN  VARCHAR2
,a_anno             IN  NUMBER
,a_data_versamento  IN  DATE
,a_tipo_versamento  IN  VARCHAR2
,a_flag_infrazione  IN  VARCHAR2
,a_utente           IN  VARCHAR2
,a_tipo_tributo     IN  varchar2
,a_pratica          IN OUT NUMBER
,a_provenienza      IN  varchar2 default null
,a_rata             IN  number   default null
,a_gruppo_tributo   IN  VARCHAR2 default null
) IS
w_errore                       varchar(2000) := NULL;
errore                         exception;
--------------------------------------------------------------------------------
--                              INIZIO                                        --
--------------------------------------------------------------------------------
BEGIN
  if a_tipo_tributo in ('ICI','TASI') then
     CREA_RAVVEDIMENTO_ICI_TASI ( a_cod_fiscale
                                , a_anno
                                , a_data_versamento
                                , a_tipo_versamento
                                , a_flag_infrazione
                                , a_utente
                                , a_tipo_tributo
                                , a_pratica
                                , a_provenienza
                                );
  elsif
     a_tipo_tributo = 'CUNI' then
     CREA_RAVVEDIMENTO_TRMI ( a_cod_fiscale
                            , a_anno
                            , a_data_versamento
                            , a_tipo_versamento
                            , a_flag_infrazione
                            , a_utente
                            , a_tipo_tributo
                            , a_pratica
                            , a_provenienza
                            , a_rata
                            , a_gruppo_tributo
                            );
  else
     w_errore := 'Tipo tributo ('||a_tipo_tributo||') non previsto';
     raise ERRORE;
  end if;
EXCEPTION
   WHEN ERRORE THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,nvl(w_errore,'vuoto'));
   WHEN OTHERS THEN
      ROLLBACK;
      RAISE_APPLICATION_ERROR(-20999,to_char(SQLCODE)||' - '||SQLERRM);
END;
/* End Procedure: CREA_RAVVEDIMENTO */
/

