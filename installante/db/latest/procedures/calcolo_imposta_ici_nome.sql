--liquibase formatted sql 
--changeset abrandolini:20250326_152423_calcolo_imposta_ici_nome stripComments:false runOnChange:true 
 
create or replace procedure CALCOLO_IMPOSTA_ICI_NOME
(a_anno            number,
 a_nome            varchar2,
 a_utente         varchar2
)
IS
CURSOR sel_cf IS
   select contribuenti.cod_fiscale
     from soggetti,contribuenti
    where soggetti.ni       = contribuenti.ni
      and soggetti.cognome_nome_ric like a_nome
    ;
BEGIN
  for w_cf in sel_cf loop
      calcolo_imposta_ici(a_anno,w_cf.cod_fiscale,a_utente,'N');
  end loop;
END;
/* End Procedure: CALCOLO_IMPOSTA_ICI_NOME */
/

