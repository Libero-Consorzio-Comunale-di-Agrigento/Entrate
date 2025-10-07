--liquibase formatted sql 
--changeset abrandolini:20250326_152423_denunce_v_automatiche stripComments:false runOnChange:true 
 
create or replace procedure DENUNCE_V_AUTOMATICHE
(a_tipo_tributo         IN varchar2,
 a_anno                 IN number,
 a_cod_via              IN number,
 a_data_denuncia        IN date,
 a_data_decorrenza      IN date,
 a_tributo              IN number,
 a_da_categoria         IN number,
 a_a_categoria          IN number,
 a_da_tariffa           IN number,
 a_a_tariffa            IN number,
 a_cod_fiscale          IN varchar2,
 a_utente               IN varchar2
)
/******************************************************************************
 NOME:        DENUNCE_V_AUTOMATICHE
 DESCRIZIONE: Crea Denunce di Variazione Automatiche

 REVISIONI:
 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 001   17/04/2023  RV      #Issue55400
                           Semplice wrapper alla nuova F_DENUNCE_V_AUTOMATICHE
 000   xx/xx/xxxx  --      Prima emissione
******************************************************************************/
IS
  w_messaggio varchar2(2000) := null;
  w_result number := 0;
BEGIN -- DENUNCE_V_AUTOMATICHE
  w_result := F_DENUNCE_V_AUTOMATICHE(a_tipo_tributo, a_anno, a_cod_via, a_data_denuncia, a_data_decorrenza, 
                                             a_tributo, a_da_categoria, a_a_categoria, a_da_tariffa, a_a_tariffa, 
                                                                                 a_cod_fiscale, a_utente, w_messaggio);
  --
  dbms_output.put_line('Risultato : '||w_result|| ' - : '||w_messaggio);
  --
END;
/* End Procedure: DENUNCE_V_AUTOMATICHE */
/

