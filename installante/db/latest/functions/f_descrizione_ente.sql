--liquibase formatted sql 
--changeset abrandolini:20250326_152438_f_descrizione_ente stripComments:false runOnChange:true 
 
CREATE OR REPLACE function f_descrizione_ente
/******************************************************************************
 NOME:        DESCRIZIONE_ENTE
 DESCRIZIONE: Definisce la descrizione dell'ente per DEPAG, 
              recuperata da Pagonline_tr4, cosi da usarla anche per altre viste

 Rev.  Data        Autore  Descrizione
 ----  ----------  ------  ----------------------------------------------------
 000   04/04/2023  AB      Prima emissione.
******************************************************************************/
return varchar2 is
  w_des_cliente               varchar2(60);
begin
  w_des_cliente := f_inpa_valore('DEPA_ENTE');
  if trim(w_des_cliente) is null then
     begin
       select replace(replace(comu.denominazione,' ','_'),'''','_') -- provo qusta istruzione perch l'altra andava in palla
--              translate(comu.denominazione,' ''','__') -- necessario perche' codice ente di DEPAG non prevede ci siano spazi
         into w_des_cliente
         from ad4_comuni comu
            , dati_generali dage
        where dage.pro_cliente = comu.provincia_stato
          and dage.com_cliente = comu.comune
          and rownum = 1
       ;
     exception
       when others then
         w_des_cliente := 'ENTE_NON_CODIFICATO';
     end;
  end if;
    
  return w_des_cliente;
    
end;
/* End Function: F_DESCRIZIONE_ENTE */
/
